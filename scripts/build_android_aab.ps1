<#
PowerShell script to:
- generate a keystore (if missing) via `keytool`
- create `android/key.properties`
- run `flutter pub get` and `flutter build appbundle --release`
- validate the resulting .aab with `jarsigner -verify`

Prerequisites:
- Java JDK (keytool & jarsigner available on PATH)
- Flutter on PATH
- Android SDK with cmdline-tools installed and ANDROID_HOME/ANDROID_SDK_ROOT set

Usage:
  cd App-dashboard-
  powershell -ExecutionPolicy Bypass -File .\scripts\build_android_aab.ps1

The script will prompt for keystore passwords (secure input). If a keystore already
exists at `android/upload-keystore.jks` you can reuse it.
#>

param(
    [string]$ProjectPath = "$(Resolve-Path ..)\App-dashboard-",
    [string]$KeystoreRelativePath = "android\upload-keystore.jks",
    [string]$KeyAlias = "upload",
    [int]$ValidityDays = 10000,
    [switch]$NonInteractive
)

function Test-Command($name) {
    $exe = Get-Command $name -ErrorAction SilentlyContinue
    return $null -ne $exe
}

Write-Host "Starting Android AAB build helper..." -ForegroundColor Cyan

# Normalize paths
$ProjectPath = (Resolve-Path $ProjectPath).Path
$KeystorePath = Join-Path $ProjectPath $KeystoreRelativePath

if (-not (Test-Command "flutter")) {
    Write-Error "Flutter not found on PATH. Install Flutter and ensure `flutter` is available in PATH."; exit 2
}

if (-not (Test-Command "keytool")) {
    Write-Error "keytool not found. Install a Java JDK and ensure keytool is on PATH."; exit 3
}

if (-not (Test-Command "jarsigner")) {
    Write-Warning "jarsigner not found — .aab validation will be skipped.";
}

# Check Android SDK presence
if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) {
    Write-Warning "ANDROID_HOME / ANDROID_SDK_ROOT not set. Ensure Android SDK and cmdline-tools are installed.";
}

# Ensure android directory exists
$androidDir = Join-Path $ProjectPath "android"
if (-not (Test-Path $androidDir)) {
    Write-Error "Android project directory not found at: $androidDir"; exit 4
}

# Decide interactive vs non-interactive/CI mode
$ciMode = $NonInteractive.IsPresent -or ($env:CI_MODE -and ($env:CI_MODE -eq '1' -or $env:CI_MODE.ToLower() -eq 'true'))

if ($ciMode) {
    Write-Host "Running in non-interactive/CI mode" -ForegroundColor Cyan

    # If CI provides keystore in base64, decode it into the keystore path
    if ($env:CI_KEYSTORE_BASE64) {
        $ksDir = Split-Path $KeystorePath -Parent
        if (-not (Test-Path $ksDir)) { New-Item -ItemType Directory -Path $ksDir | Out-Null }
        $bytes = [Convert]::FromBase64String($env:CI_KEYSTORE_BASE64)
        [IO.File]::WriteAllBytes($KeystorePath, $bytes)
        Write-Host "Wrote keystore from CI_KEYSTORE_BASE64 to $KeystorePath" -ForegroundColor Green
    } elseif ($env:CI_KEYSTORE_PATH) {
        Copy-Item -Path $env:CI_KEYSTORE_PATH -Destination $KeystorePath -Force
        Write-Host "Copied keystore from CI_KEYSTORE_PATH to $KeystorePath" -ForegroundColor Green
    }

    if (-not (Test-Path $KeystorePath)) {
        Write-Error "Keystore not found at $KeystorePath in CI mode. Set CI_KEYSTORE_BASE64 or CI_KEYSTORE_PATH."; exit 5
    }

    # Read passwords from environment vars
    $storePassword = $env:CI_KEYSTORE_PASSWORD
    $keyPassword = $env:CI_KEY_PASSWORD
    if (-not $keyPassword) { $keyPassword = $storePassword }

    if (-not $storePassword) { Write-Error "CI_KEYSTORE_PASSWORD is not set in CI mode."; exit 6 }

    # Write key.properties
    $keyPropsPath = Join-Path $androidDir 'key.properties'
    $keyPropsContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$KeyAlias`nstoreFile=$KeystoreRelativePath`n"
    Write-Host "Writing key.properties to $keyPropsPath (contains sensitive passwords)." -ForegroundColor Yellow
    $keyPropsContent | Out-File -FilePath $keyPropsPath -Encoding ASCII -Force
    Write-Host "Written key.properties in CI mode. Ensure this file is not checked into source control." -ForegroundColor Yellow

} else {
    # Interactive flow: ask whether to generate keystore if missing
    if (-not (Test-Path $KeystorePath)) {
        Write-Host "Keystore not found at $KeystorePath" -ForegroundColor Yellow
        $gen = Read-Host "Generate a new keystore at this path? (y/n)"
        if ($gen -ne 'y' -and $gen -ne 'Y') {
            Write-Error "Keystore missing, and generation declined. Aborting."; exit 5
        }

        # Prompt for passwords securely
        $storePasswordSecure = Read-Host "Enter keystore password" -AsSecureString
        $keyPasswordSecure = Read-Host "Enter key password (press Enter to use same as keystore)" -AsSecureString

        function Convert-SecureStringToPlain($s) {
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
            try { [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        }

        $storePassword = Convert-SecureStringToPlain $storePasswordSecure
        if ($keyPasswordSecure.Length -eq 0) { $keyPassword = $storePassword } else { $keyPassword = Convert-SecureStringToPlain $keyPasswordSecure }

        # Default distinguished name
        $dname = Read-Host "Enter certificate DName (example: CN=Your Name, OU=Dev, O=Company, L=City, ST=State, C=US)" -Default "CN=Yookatale, OU=App, O=Yookatale, L=City, ST=State, C=US"

        # Ensure output folder exists
        $ksDir = Split-Path $KeystorePath -Parent
        if (-not (Test-Path $ksDir)) { New-Item -ItemType Directory -Path $ksDir | Out-Null }

        $keytoolArgs = @( '-genkeypair', '-v', '-keystore', $KeystorePath, '-alias', $KeyAlias, '-keyalg', 'RSA', '-keysize', '2048', '-validity', "$ValidityDays", '-storepass', $storePassword, '-keypass', $keyPassword, '-dname', $dname )

        Write-Host "Generating keystore..." -ForegroundColor Green
        $proc = Start-Process -FilePath keytool -ArgumentList $keytoolArgs -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -ne 0) { Write-Error "keytool failed with exit code $($proc.ExitCode)"; exit 6 }
        Write-Host "Keystore generated: $KeystorePath" -ForegroundColor Green

        # Write key.properties
        $keyPropsPath = Join-Path $androidDir 'key.properties'
        $keyPropsContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$KeyAlias`nstoreFile=$KeystoreRelativePath`n"
        Write-Host "Writing key.properties to $keyPropsPath (contains sensitive passwords)." -ForegroundColor Yellow
        $keyPropsContent | Out-File -FilePath $keyPropsPath -Encoding ASCII -Force
        Write-Host "Written key.properties. Consider adding android/key.properties to .gitignore and securing the keystore." -ForegroundColor Yellow
    }
    else {
        Write-Host "Using existing keystore: $KeystorePath" -ForegroundColor Green
    }
}

# Run flutter pub get
Write-Host "Running flutter pub get..." -ForegroundColor Cyan
Push-Location $ProjectPath
try {
    $pub = Start-Process -FilePath flutter -ArgumentList 'pub','get' -NoNewWindow -Wait -PassThru
    if ($pub.ExitCode -ne 0) { Write-Error "flutter pub get failed (exit $($pub.ExitCode))."; Pop-Location; exit 7 }

    Write-Host "Building release AAB (this may take a while)..." -ForegroundColor Cyan
    $build = Start-Process -FilePath flutter -ArgumentList 'build','appbundle','--release' -NoNewWindow -Wait -PassThru
    if ($build.ExitCode -ne 0) { Write-Error "flutter build appbundle failed (exit $($build.ExitCode))."; Pop-Location; exit 8 }

    # Attempt to find the produced .aab
    $aab = Get-ChildItem -Path (Join-Path $ProjectPath 'build') -Filter *.aab -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1
    if (-not $aab) { Write-Error "No .aab found under build/ — build may have failed."; Pop-Location; exit 9 }

    Write-Host "AAB produced: $($aab.FullName)" -ForegroundColor Green

    if (Test-Command "jarsigner") {
        Write-Host "Validating AAB signature with jarsigner..." -ForegroundColor Cyan
        $verify = Start-Process -FilePath jarsigner -ArgumentList '-verify','-verbose','-certs', $aab.FullName -NoNewWindow -Wait -PassThru
        if ($verify.ExitCode -eq 0) { Write-Host "jarsigner verification passed." -ForegroundColor Green } else { Write-Warning "jarsigner returned exit code $($verify.ExitCode). Review output above." }
    } else {
        Write-Warning "jarsigner not found; skipping AAB signature validation.";
    }

    Write-Host "Build and validation finished. You can upload the AAB to Play Console for closed testing." -ForegroundColor Green
}
finally { Pop-Location }

exit 0
