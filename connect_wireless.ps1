# Wireless ADB Connection Script
# Connect your phone wirelessly for testing

$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"

Write-Host "=== Wireless ADB Connection ===" -ForegroundColor Green
Write-Host ""

# Check if ADB is available
if (-not (Test-Path $adbPath)) {
    Write-Host "❌ ADB not found!" -ForegroundColor Red
    exit 1
}

Write-Host "To connect wirelessly:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. On your phone, go to:" -ForegroundColor Yellow
Write-Host "   Settings → Developer Options → Wireless debugging" -ForegroundColor White
Write-Host ""
Write-Host "2. Enable 'Wireless debugging'" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Tap 'Pair device with pairing code'" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. You'll see:" -ForegroundColor Yellow
Write-Host "   - IP address and port (e.g., 192.168.1.100:12345)" -ForegroundColor White
Write-Host "   - Pairing code (6 digits)" -ForegroundColor White
Write-Host ""
Write-Host "5. Run this command (replace with your values):" -ForegroundColor Yellow
Write-Host "   adb pair <ip-address>:<port>" -ForegroundColor White
Write-Host "   (Enter the pairing code when prompted)" -ForegroundColor Gray
Write-Host ""
Write-Host "6. After pairing, you'll see a new port. Run:" -ForegroundColor Yellow
Write-Host "   adb connect <ip-address>:<new-port>" -ForegroundColor White
Write-Host ""
Write-Host "Example:" -ForegroundColor Cyan
Write-Host "   adb pair 192.168.1.100:12345" -ForegroundColor White
Write-Host "   (Enter pairing code: 123456)" -ForegroundColor Gray
Write-Host "   adb connect 192.168.1.100:45678" -ForegroundColor White
Write-Host ""

# Check current connections
Write-Host "Current ADB connections:" -ForegroundColor Cyan
& $adbPath devices
Write-Host ""
