# Real-time Log Monitor for Push Notifications
# Monitors Flutter and notification-related logs

$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"

Write-Host "=== YooKatale App Log Monitor ===" -ForegroundColor Green
Write-Host "Monitoring push notifications and app logs..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Clear log buffer
& $adbPath logcat -c

# Monitor logs - filter for Flutter, notifications, and FCM
& $adbPath logcat | Select-String -Pattern "flutter|notification|FCM|FirebaseMessaging|YooKatale|meal|breakfast|lunch|supper" -CaseSensitive:$false
