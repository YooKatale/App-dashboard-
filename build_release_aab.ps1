# Build AAB Release Script for Yookatale App
# This script builds a signed AAB file ready for Google Play Store upload

$ErrorActionPreference = "Continue"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Yookatale AAB Release Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter installation
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCheck) {
    Write-Host "ERROR: Flutter not found in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter and add it to your PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Package Name: com.yookataleapp.app" -ForegroundColor Yellow
Write-Host ""

# Step 1: Kill any running build processes
Write-Host "Step 1: Stopping any running build processes..." -ForegroundColor Yellow
$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    $count = $javaProcesses.Count
    Write-Host "Found $count Java process(es), stopping..." -ForegroundColor Gray
    $javaProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "Processes stopped." -ForegroundColor Green
} else {
    Write-Host "No running processes found." -ForegroundColor Gray
}
Write-Host ""

# Step 2: Verify signing configuration
Write-Host "Step 2: Verifying signing configuration..." -ForegroundColor Yellow
$keyPropertiesPath = "android\key.properties"
$keystorePath = "android\upload-keystore.jks"

if (-not (Test-Path $keyPropertiesPath)) {
    Write-Host "WARNING: key.properties not found!" -ForegroundColor Red
    Write-Host "Location: $keyPropertiesPath" -ForegroundColor Red
    Write-Host "Build will use debug signing (NOT for production!)" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Build cancelled." -ForegroundColor Yellow
        exit 1
    }
} else {
    if (-not (Test-Path $keystorePath)) {
        Write-Host "WARNING: Keystore file not found!" -ForegroundColor Red
        Write-Host "Expected: $keystorePath" -ForegroundColor Red
        Write-Host "Build will use debug signing (NOT for production!)" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "Build cancelled." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Signing configuration found. Build will be signed for production." -ForegroundColor Green
    }
}
Write-Host ""

# Step 3: Verify Firebase configuration
Write-Host "Step 3: Verifying Firebase configuration..." -ForegroundColor Yellow
$googleServicesPath = "android\app\google-services.json"
if (Test-Path $googleServicesPath) {
    Write-Host "google-services.json found." -ForegroundColor Green
} else {
    Write-Host "WARNING: google-services.json not found!" -ForegroundColor Yellow
    Write-Host "Location: $googleServicesPath" -ForegroundColor Yellow
    Write-Host "Firebase features may not work properly." -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Clean build
Write-Host "Step 4: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "Clean completed." -ForegroundColor Green
Write-Host ""

# Step 5: Get dependencies
Write-Host "Step 5: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies retrieved." -ForegroundColor Green
Write-Host ""

# Step 6: Build AAB
Write-Host "Step 6: Building AAB file (this may take 5-15 minutes)..." -ForegroundColor Yellow
Write-Host "Please be patient, Gradle builds can take a while..." -ForegroundColor Gray
Write-Host ""
$startTime = Get-Date
flutter build appbundle --release
$buildExitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($buildExitCode -eq 0) {
    $AAB_PATH = "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $AAB_PATH) {
        $file = Get-Item $AAB_PATH
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        
        Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "AAB file created:" -ForegroundColor Green
        Write-Host "  File: $($file.Name)" -ForegroundColor White
        Write-Host "  Size: $sizeMB MB" -ForegroundColor White
        Write-Host "  Location: $($file.FullName)" -ForegroundColor White
        Write-Host "  Build time: $($duration.ToString('mm\:ss'))" -ForegroundColor White
        Write-Host ""
        Write-Host "Package Name: com.yookataleapp.app" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Ready to upload to Google Play Store!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Go to Google Play Console" -ForegroundColor White
        Write-Host "2. Select your app (package: com.yookataleapp.app)" -ForegroundColor White
        Write-Host "3. Create a new release" -ForegroundColor White
        Write-Host "4. Upload the AAB file from the location above" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  BUILD COMPLETED BUT AAB FILE NOT FOUND" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Build exited with code 0, but AAB file was not created." -ForegroundColor Yellow
        Write-Host "Check the output above for warnings or errors." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Build exited with code: $buildExitCode" -ForegroundColor Red
    Write-Host "Check the output above for error messages." -ForegroundColor Red
    Write-Host ""
    exit 1
}
