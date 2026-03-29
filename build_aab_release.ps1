# ============================================================
# Yookatale AAB Release Builder with Auto Version Increment
# ============================================================
# This script automatically increments the version code and builds AAB
# 
# Usage:
#   .\build_aab_release.ps1
#
# Requirements:
#   - Flutter SDK installed and in PATH
#   - Android SDK configured
#   - Keystore file (key.properties) configured for signing
# ============================================================

$ErrorActionPreference = "Stop"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Yookatale AAB Release Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Auto-increment version code
Write-Host "Step 0: Auto-incrementing version code..." -ForegroundColor Cyan
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    
    # Extract current version (format: X.Y.Z+BUILD_NUMBER)
    if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        $versionName = $matches[1]
        $currentVersionCode = [int]$matches[2]
        $newVersionCode = $currentVersionCode + 1
        
        Write-Host "  Current version: $versionName+$currentVersionCode" -ForegroundColor Gray
        Write-Host "  New version code: $newVersionCode" -ForegroundColor Yellow
        
        # Replace version in pubspec.yaml
        $newVersionLine = "version: $versionName+$newVersionCode"
        $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newVersionLine
        
        # Write back to file
        Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline
        
        Write-Host "  Version updated to: $newVersionLine" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Could not parse version from pubspec.yaml" -ForegroundColor Yellow
        Write-Host "Please manually update version in pubspec.yaml (format: X.Y.Z+BUILD_NUMBER)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: pubspec.yaml not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check Flutter installation
Write-Host "Step 1: Checking Flutter installation..." -ForegroundColor Cyan
try {
    $flutterOutput = flutter --version 2>&1 | Out-String
    if ($flutterOutput -match "Flutter") {
        Write-Host "  Flutter found" -ForegroundColor Green
    } else {
        throw "Flutter not found"
    }
} catch {
    Write-Host "ERROR: Flutter not found. Please install Flutter and add it to PATH." -ForegroundColor Red
    exit 1
}

# Check if key.properties exists
Write-Host "Step 2: Checking signing configuration..." -ForegroundColor Cyan
if (Test-Path "android\key.properties") {
    Write-Host "  Keystore configuration found" -ForegroundColor Green
} else {
    Write-Host "WARNING: key.properties not found. The app will be built but NOT signed." -ForegroundColor Yellow
    Write-Host "For Play Store, you MUST configure signing. See: https://docs.flutter.dev/deployment/android" -ForegroundColor Yellow
    $continue = Read-Host "Continue without signing? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

Write-Host ""

# Step 3: Stop any running Java/Gradle processes
Write-Host "Step 3: Stopping any running build processes..." -ForegroundColor Cyan
$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    $count = $javaProcesses.Count
    Write-Host "  Found $count Java process(es), stopping..." -ForegroundColor Gray
    $javaProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "  Processes stopped" -ForegroundColor Green
} else {
    Write-Host "  No running processes found" -ForegroundColor Gray
}

Write-Host ""

# Step 4: Clean build
Write-Host "Step 4: Cleaning previous builds..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Clean completed" -ForegroundColor Green
Write-Host ""

# Step 5: Get dependencies
Write-Host "Step 5: Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "  Dependencies retrieved" -ForegroundColor Green
Write-Host ""

# Step 6: Build AAB
Write-Host "Step 6: Building AAB file (this may take 5-15 minutes)..." -ForegroundColor Cyan
Write-Host "  This is a release build for production" -ForegroundColor Gray
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
        Write-Host "AAB File Details:" -ForegroundColor Cyan
        Write-Host "  Name: $($file.Name)" -ForegroundColor White
        Write-Host "  Size: $sizeMB MB" -ForegroundColor White
        Write-Host "  Location: $($file.FullName)" -ForegroundColor White
        Write-Host "  Build time: $($duration.ToString('mm\:ss'))" -ForegroundColor White
        Write-Host ""
        
        # Get package name and version from pubspec.yaml
        $packageName = "com.yookataleapp.app"
        $versionInfo = ""
        try {
            $buildGradle = Get-Content "android\app\build.gradle.kts" -Raw
            if ($buildGradle -match 'applicationId\s*=\s*"([^"]+)"') {
                $packageName = $matches[1]
            }
            
            $pubspecContent = Get-Content "pubspec.yaml" -Raw
            if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+\+\d+)') {
                $versionInfo = $matches[1]
            }
        } catch {
            Write-Host "WARNING: Could not read package name or version" -ForegroundColor Yellow
        }
        
        Write-Host "Version Information:" -ForegroundColor Cyan
        Write-Host "  Version: $versionInfo" -ForegroundColor White
        Write-Host "  Package: $packageName" -ForegroundColor White
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "  1. Upload the AAB file to Google Play Console" -ForegroundColor White
        Write-Host "  2. Play Store link (after publishing):" -ForegroundColor White
        Write-Host "     https://play.google.com/store/apps/details?id=$packageName" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Ready to upload to Google Play Store!" -ForegroundColor Green
        Write-Host ""
        
        # Ask if user wants to open the file location
        $openLocation = Read-Host "Open file location? (Y/n)"
        if ($openLocation -ne "n" -and $openLocation -ne "N") {
            explorer.exe /select,"$($file.FullName)"
        }
    } else {
        Write-Host "  BUILD COMPLETED BUT AAB FILE NOT FOUND" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "WARNING: Build exited with code 0, but AAB file was not created." -ForegroundColor Yellow
        Write-Host "Check the output above for warnings or errors." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Build exited with code: $buildExitCode" -ForegroundColor Red
    Write-Host "Check the output above for error messages." -ForegroundColor Red
    Write-Host ""
    exit 1
}
