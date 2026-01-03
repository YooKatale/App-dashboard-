# Auto-run Flutter script
# This will automatically extract Flutter (when ready) and run the app

Write-Host "=== Auto-Run Flutter Script ===" -ForegroundColor Cyan
Write-Host ""

$flutterPath = "C:\src\flutter\bin\flutter.bat"
$zipPath = "$env:TEMP\flutter.zip"
$projectPath = "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"

# Check if Flutter is already installed
if (Test-Path $flutterPath) {
    Write-Host "✅ Flutter is already installed!" -ForegroundColor Green
    $env:PATH += ";C:\src\flutter\bin"
} else {
    Write-Host "Flutter not found. Checking for zip file..." -ForegroundColor Yellow
    
    if (Test-Path $zipPath) {
        $zipSize = (Get-Item $zipPath).Length / 1MB
        Write-Host "Zip file found: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Cyan
        
        # Try extraction
        Write-Host "Attempting to extract..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null
            
            # Try with Expand-Archive first
            try {
                Expand-Archive -Path $zipPath -DestinationPath "C:\src" -Force -ErrorAction Stop
                Write-Host "✅ Extraction successful!" -ForegroundColor Green
            } catch {
                # If that fails, try .NET method
                Write-Host "Trying alternative extraction method..." -ForegroundColor Yellow
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, "C:\src")
                Write-Host "✅ Extraction successful!" -ForegroundColor Green
            }
            
            if (Test-Path $flutterPath) {
                # Add to PATH
                $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
                if ($currentPath -notlike "*C:\src\flutter\bin*") {
                    [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\src\flutter\bin", "User")
                }
                $env:PATH += ";C:\src\flutter\bin"
                Write-Host "✅ Flutter added to PATH" -ForegroundColor Green
            } else {
                Write-Host "❌ Flutter not found after extraction" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "❌ Extraction failed: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "The zip file may be split/spanned or still downloading." -ForegroundColor Yellow
            Write-Host "Please extract manually:" -ForegroundColor Yellow
            Write-Host "  1. Right-click on: $zipPath" -ForegroundColor White
            Write-Host "  2. Select 'Extract All...'" -ForegroundColor White
            Write-Host "  3. Extract to: C:\src\" -ForegroundColor White
            Write-Host "  4. Then run this script again" -ForegroundColor White
            exit 1
        }
    } else {
        Write-Host "❌ Flutter zip file not found at: $zipPath" -ForegroundColor Red
        Write-Host "Please download Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Navigate to project
Set-Location $projectPath
Write-Host ""
Write-Host "Project directory: $projectPath" -ForegroundColor Cyan
Write-Host ""

# Run flutter pub get
Write-Host "=== Step 1: Running 'flutter pub get' ===" -ForegroundColor Yellow
Write-Host ""
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== Step 2: Running 'flutter run' ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Starting the app..." -ForegroundColor Cyan
    Write-Host ""
    flutter run
} else {
    Write-Host ""
    Write-Host "❌ 'flutter pub get' failed. Please check the errors above." -ForegroundColor Red
    exit 1
}



