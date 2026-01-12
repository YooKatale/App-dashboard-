# Build AAB Release Script for Yookatale
# This script cancels any running builds and creates a fresh AAB file

$ErrorActionPreference = "Continue"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Yookatale AAB Release Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill any running Java/Gradle processes
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

# Step 2: Clean build
Write-Host "Step 2: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "Clean completed." -ForegroundColor Green
Write-Host ""

# Step 3: Get dependencies
Write-Host "Step 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies retrieved." -ForegroundColor Green
Write-Host ""

# Step 4: Build AAB
Write-Host "Step 4: Building AAB file (this may take 5-15 minutes)..." -ForegroundColor Yellow
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
        Write-Host "Ready to upload to Google Play Store!" -ForegroundColor Cyan
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
