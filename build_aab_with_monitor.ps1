# Build AAB with Monitoring Script
# This script builds the AAB file and monitors progress

$ErrorActionPreference = "Continue"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Yookatale AAB Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCheck) {
    Write-Host "ERROR: Flutter not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean | Out-Null

Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null

Write-Host ""
Write-Host "Step 3: Starting AAB build..." -ForegroundColor Yellow
Write-Host "This will run in the background. The monitor script will track progress." -ForegroundColor Gray
Write-Host ""

# Start the build in a separate process
$buildJob = Start-Job -ScriptBlock {
    Set-Location $using:appDir
    flutter build appbundle --release 2>&1
}

Write-Host "Build started (Job ID: $($buildJob.Id))" -ForegroundColor Green
Write-Host ""
Write-Host "Starting monitor in a new window..." -ForegroundColor Cyan
Write-Host ""

# Start monitor in new window
Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "$appDir\monitor_build.ps1", "-AutoOpen"

Write-Host "Monitor window opened. The build is running in the background." -ForegroundColor Green
Write-Host ""
Write-Host "To check build status manually, run:" -ForegroundColor Gray
Write-Host "  .\monitor_build.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To check the build job status:" -ForegroundColor Gray
Write-Host "  Get-Job | Receive-Job" -ForegroundColor White
Write-Host ""

# Wait for build to complete and show results
Write-Host "Waiting for build to complete..." -ForegroundColor Yellow
$buildJob | Wait-Job | Out-Null
$output = $buildJob | Receive-Job
$buildJob | Remove-Job

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Output" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host $output

$AAB_PATH = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $AAB_PATH) {
    $file = Get-Item $AAB_PATH
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "AAB file: $($file.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($file.Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "AAB file not found. Check the output above for errors." -ForegroundColor Red
    Write-Host ""
}
