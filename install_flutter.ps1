# Flutter Installation Script
# This script downloads and installs Flutter manually

Write-Host "=== Flutter Installation Script ===" -ForegroundColor Green
Write-Host ""

# Check if Flutter is already installed
$flutterPath = "C:\src\flutter\bin\flutter.bat"
if (Test-Path $flutterPath) {
    Write-Host "Flutter is already installed at C:\src\flutter" -ForegroundColor Green
    Write-Host "Adding to PATH..." -ForegroundColor Yellow
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*C:\src\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\src\flutter\bin", "User")
        Write-Host "Flutter added to PATH. Please restart PowerShell." -ForegroundColor Green
    }
    exit 0
}

# Create directory
$installDir = "C:\src\flutter"
Write-Host "Creating installation directory: $installDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Download Flutter
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
$zipFile = "$env:TEMP\flutter_windows.zip"

Write-Host "Downloading Flutter (this may take several minutes)..." -ForegroundColor Yellow
Write-Host "URL: $flutterUrl" -ForegroundColor Gray
Write-Host "Destination: $zipFile" -ForegroundColor Gray

try {
    # Download with progress
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $flutterUrl -OutFile $zipFile -UseBasicParsing
    
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host "Extracting Flutter..." -ForegroundColor Yellow
    
    # Extract
    Expand-Archive -Path $zipFile -DestinationPath "C:\src" -Force
    
    Write-Host "Extraction complete!" -ForegroundColor Green
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*C:\src\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\src\flutter\bin", "User")
        Write-Host "Flutter added to PATH!" -ForegroundColor Green
    }
    
    # Clean up
    Remove-Item $zipFile -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "=== Installation Complete! ===" -ForegroundColor Green
    Write-Host "Please restart PowerShell and run: flutter --version" -ForegroundColor Yellow
    Write-Host "Then run: flutter doctor" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "You may need to download Flutter manually from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
}

