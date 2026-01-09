# Fix Android Emulator Issues
# This script helps resolve common emulator problems

Write-Host "=== Fixing Android Emulator Issues ===" -ForegroundColor Green

# Step 1: Kill all emulator processes
Write-Host "`n1. Stopping all emulator processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*qemu*" -or $_.ProcessName -like "*emulator*" -or $_.ProcessName -like "*adb*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Step 2: Clean Flutter build
Write-Host "`n2. Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Step 3: Reset ADB
Write-Host "`n3. Resetting ADB..." -ForegroundColor Yellow
$env:ANDROID_HOME = $env:LOCALAPPDATA + "\Android\Sdk"
$adbPath = "$env:ANDROID_HOME\platform-tools\adb.exe"
if (Test-Path $adbPath) {
    & $adbPath kill-server
    Start-Sleep -Seconds 2
    & $adbPath start-server
} else {
    Write-Host "   ADB not found at $adbPath" -ForegroundColor Red
    Write-Host "   Trying to find ADB via Flutter..." -ForegroundColor Yellow
    flutter doctor -v | Select-String "Android SDK" | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Cyan
    }
}

# Step 4: List available emulators
Write-Host "`n4. Available emulators:" -ForegroundColor Yellow
flutter emulators

# Step 5: Try to launch emulator
Write-Host "`n5. Launching emulator (yookatle_avd)..." -ForegroundColor Yellow
Write-Host "   This may take 30-60 seconds..." -ForegroundColor Cyan
flutter emulators --launch yookatle_avd

# Step 6: Wait and check status
Write-Host "`n6. Waiting for emulator to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`n7. Checking device status..." -ForegroundColor Yellow
flutter devices

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "If emulator still doesn't work, try:" -ForegroundColor Yellow
Write-Host "  1. Restart Android Studio" -ForegroundColor Cyan
Write-Host "  2. Delete and recreate the AVD" -ForegroundColor Cyan
Write-Host "  3. Increase emulator RAM in AVD settings" -ForegroundColor Cyan
Write-Host "  4. Use a physical device instead" -ForegroundColor Cyan
