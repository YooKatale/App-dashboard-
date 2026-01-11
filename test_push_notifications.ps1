# Push Notification Testing Script
# This script helps test push notifications on a connected Android device

Write-Host "=== YooKatale Push Notification Tester ===" -ForegroundColor Green
Write-Host ""

# Check if ADB is available
$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    Write-Host "❌ ADB not found at: $adbPath" -ForegroundColor Red
    Write-Host "Please ensure Android SDK is installed." -ForegroundColor Yellow
    exit 1
}

# Check for connected devices
Write-Host "Checking for connected devices..." -ForegroundColor Cyan
$devices = & $adbPath devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "❌ No devices connected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Enable USB Debugging on your phone" -ForegroundColor Yellow
    Write-Host "2. Connect your phone via USB" -ForegroundColor Yellow
    Write-Host "3. Allow USB debugging when prompted" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or use wireless debugging:" -ForegroundColor Cyan
    Write-Host "  adb connect <phone-ip>:5555" -ForegroundColor White
    exit 1
}

Write-Host "✅ Found $($devices.Count) device(s)" -ForegroundColor Green
$devices | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
Write-Host ""

# Get device info
Write-Host "Device Information:" -ForegroundColor Cyan
& $adbPath shell getprop ro.product.model
& $adbPath shell getprop ro.build.version.release
Write-Host ""

# Check if app is installed
Write-Host "Checking if YooKatale app is installed..." -ForegroundColor Cyan
$packageName = "com.yookataleapp.app"
$appInstalled = & $adbPath shell pm list packages | Select-String -Pattern $packageName

if ($appInstalled) {
    Write-Host "✅ App is installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  App not installed. Building and installing..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Building APK..." -ForegroundColor Cyan
    flutter build apk --debug
    Write-Host ""
    Write-Host "Installing APK..." -ForegroundColor Cyan
    & $adbPath install -r "build\app\outputs\flutter-apk\app-debug.apk"
}

Write-Host ""
Write-Host "=== Testing Push Notifications ===" -ForegroundColor Green
Write-Host ""
Write-Host "To test push notifications, you can:" -ForegroundColor Cyan
Write-Host "1. Open the app on your phone" -ForegroundColor White
Write-Host "2. Log in to your account" -ForegroundColor White
Write-Host "3. Allow notification permissions when prompted" -ForegroundColor White
Write-Host "4. Wait for scheduled meal notifications:" -ForegroundColor White
Write-Host "   - Breakfast: 6:00, 7:00, 8:00, 9:00, 10:00 AM" -ForegroundColor White
Write-Host "   - Lunch: 12:00, 1:00, 2:00, 3:00 PM" -ForegroundColor White
Write-Host "   - Supper: 5:00, 6:00, 7:00, 8:00, 9:00, 10:00 PM" -ForegroundColor White
Write-Host ""
Write-Host "Or trigger a test notification from the server." -ForegroundColor Cyan
Write-Host ""

# Check notification permissions
Write-Host "Checking notification permissions..." -ForegroundColor Cyan
$notificationPerms = & $adbPath shell dumpsys package $packageName | Select-String -Pattern "notification"
if ($notificationPerms) {
    Write-Host "Notification permissions:" -ForegroundColor White
    $notificationPerms | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "⚠️  Could not check notification permissions" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Useful ADB Commands ===" -ForegroundColor Green
Write-Host "View app logs:        adb logcat | Select-String 'flutter'" -ForegroundColor White
Write-Host "Clear app data:       adb shell pm clear $packageName" -ForegroundColor White
Write-Host "Uninstall app:        adb uninstall $packageName" -ForegroundColor White
Write-Host "Open app:             adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1" -ForegroundColor White
Write-Host ""
