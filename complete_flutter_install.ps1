# Complete Flutter Installation Script
# Run this after the download completes

Write-Host "=== Completing Flutter Installation ===" -ForegroundColor Green

$flutterPath = "C:\src\flutter\bin\flutter.bat"
$zipPath = "$env:TEMP\flutter.zip"

# Check if already installed
if (Test-Path $flutterPath) {
    Write-Host "Flutter is already installed!" -ForegroundColor Green
    exit 0
}

# Wait for zip file to be available
Write-Host "Waiting for download to complete..." -ForegroundColor Yellow
$maxWait = 300 # 5 minutes
$waited = 0
while (-not (Test-Path $zipPath) -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 10
    $waited += 10
    Write-Host "Waiting... ($waited seconds)" -ForegroundColor Gray
}

if (-not (Test-Path $zipPath)) {
    Write-Host "Zip file not found. Please download Flutter manually." -ForegroundColor Red
    exit 1
}

# Extract Flutter
Write-Host "Extracting Flutter..." -ForegroundColor Yellow
try {
    New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null
    
    # Try to extract, retry if locked
    $retries = 5
    $extracted = $false
    for ($i = 1; $i -le $retries; $i++) {
        try {
            Expand-Archive -Path $zipPath -DestinationPath "C:\src" -Force -ErrorAction Stop
            $extracted = $true
            break
        } catch {
            if ($i -lt $retries) {
                Write-Host "Extraction locked, retrying in 10 seconds... (Attempt $i/$retries)" -ForegroundColor Yellow
                Start-Sleep -Seconds 10
            } else {
                throw
            }
        }
    }
    
    if (-not $extracted) {
        throw "Failed to extract after $retries attempts"
    }
    
    Write-Host "Extraction complete!" -ForegroundColor Green
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*C:\src\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\src\flutter\bin", "User")
        Write-Host "Flutter added to PATH!" -ForegroundColor Green
    }
    
    # Clean up
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "=== Installation Complete! ===" -ForegroundColor Green
    Write-Host "Please restart PowerShell and run: flutter --version" -ForegroundColor Yellow
    Write-Host "Then run: flutter doctor" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "You may need to extract manually from: $zipPath" -ForegroundColor Yellow
}

