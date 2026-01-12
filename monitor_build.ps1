# Build Progress Monitor Script for Yookatale AAB Build
# This script monitors the Flutter AAB build process and shows real-time progress

param(
    [int]$CheckInterval = 5,  # Check every 5 seconds
    [switch]$AutoOpen = $false  # Automatically open output folder when done
)

$ErrorActionPreference = "Continue"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

$AAB_PATH = "build\app\outputs\bundle\release\app-release.aab"
$BUNDLE_DIR = "build\app\outputs\bundle"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Yookatale AAB Build Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoring build progress..."
Write-Host "AAB file location: $AAB_PATH"
Write-Host "Check interval: $CheckInterval seconds"
Write-Host "Press Ctrl+C to stop monitoring"
Write-Host ""

$startTime = Get-Date
$lastFileCount = 0
$lastActivityTime = Get-Date
$stuckThreshold = 120  # 2 minutes of no activity = stuck

while ($true) {
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    # Check if AAB file exists
    if (Test-Path $AAB_PATH) {
        $file = Get-Item $AAB_PATH
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "File: $($file.Name)" -ForegroundColor Green
        Write-Host "Size: $sizeMB MB" -ForegroundColor Green
        Write-Host "Location: $($file.FullName)" -ForegroundColor Green
        Write-Host "Total build time: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
        Write-Host ""
        
        if ($AutoOpen) {
            Start-Process explorer.exe -ArgumentList "/select,`"$($file.FullName)`""
        }
        
        break
    }
    
    # Check for build activity
    $currentFileCount = 0
    $newestFileTime = $null
    
    if (Test-Path "build\app\intermediates") {
        $files = Get-ChildItem "build\app\intermediates" -Recurse -File -ErrorAction SilentlyContinue | 
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($files) {
            $currentFileCount = 1
            $newestFileTime = $files[0].LastWriteTime
        }
    }
    
    # Check Java processes
    $javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
    $javaCount = $javaProcesses.Count
    $totalCpu = ($javaProcesses | Measure-Object -Property CPU -Sum).Sum
    
    # Status display
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Build Progress Monitor" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Elapsed time: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Yellow
    Write-Host "Status: " -NoNewline
    
    if ($javaCount -gt 0) {
        Write-Host "BUILDING" -ForegroundColor Green -NoNewline
        Write-Host " (Java processes: $javaCount, CPU: $([math]::Round($totalCpu, 1))s)"
        
        if ($newestFileTime) {
            $timeSinceActivity = $currentTime - $newestFileTime
            if ($timeSinceActivity.TotalSeconds -gt $stuckThreshold) {
                Write-Host "WARNING: No activity for $([math]::Round($timeSinceActivity.TotalSeconds)) seconds" -ForegroundColor Red
                Write-Host "Build may be stuck. Consider restarting." -ForegroundColor Red
            } else {
                Write-Host "Last activity: $($newestFileTime.ToString('HH:mm:ss')) ($([math]::Round($timeSinceActivity.TotalSeconds))s ago)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "WAITING/STUCK" -ForegroundColor Red
        Write-Host "No Java processes found. Build may have stopped." -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check build stages
    Write-Host "Build Stages:" -ForegroundColor Cyan
    $stages = @{
        "Resources merged" = (Test-Path "build\app\intermediates\merged_res")
        "Assets processed" = (Test-Path "build\app\intermediates\assets\release\mergeReleaseAssets")
        "Java compiled" = (Test-Path "build\app\intermediates\javac\release")
        "Native libs merged" = (Test-Path "build\app\intermediates\merged_native_libs")
        "Bundle directory" = (Test-Path $BUNDLE_DIR)
        "AAB file" = (Test-Path $AAB_PATH)
    }
    
    foreach ($stage in $stages.GetEnumerator()) {
        $status = if ($stage.Value) { "[OK]" } else { "[  ]" }
        $color = if ($stage.Value) { "Green" } else { "Gray" }
        Write-Host "  $status $($stage.Key)" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Next check in $CheckInterval seconds... (Press Ctrl+C to stop)" -ForegroundColor Gray
    
    Start-Sleep -Seconds $CheckInterval
}

Write-Host ""
Write-Host "Monitoring stopped." -ForegroundColor Yellow
