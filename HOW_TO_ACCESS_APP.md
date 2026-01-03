# How to Access the YooKatale Flutter App

## Prerequisites

1. **Install Flutter** (if not already installed):
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Extract to `C:\src\flutter` (or any location)
   - Add to PATH: `C:\src\flutter\bin`

2. **Install Required Tools**:
   ```powershell
   flutter doctor
   ```
   This will tell you what's missing (Android Studio, Xcode, etc.)

## Step 1: Install Dependencies

```powershell
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
flutter pub get
```

## Step 2: Check Available Devices

```powershell
flutter devices
```

This will show:
- Connected physical devices (Android/iOS phones)
- Available emulators/simulators
- Chrome (for web testing)

## Step 3: Run the App

### Option A: Android (Emulator or Physical Device)

**Start Android Emulator:**
1. Open Android Studio
2. Go to Tools → Device Manager
3. Click the play button on an emulator
4. Wait for it to boot

**Run on Android:**
```powershell
flutter run
# Or specify Android:
flutter run -d android
```

**To see the app:**
- The app will automatically install and launch on the connected device/emulator
- Look for the "yookatale" app icon on the device
- The app will open automatically after installation

### Option B: iOS (Simulator or Physical Device) - Mac Only

**Start iOS Simulator:**
1. Open Xcode
2. Go to Xcode → Open Developer Tool → Simulator
3. Choose a device (iPhone 14, etc.)

**Run on iOS:**
```powershell
flutter run -d ios
# Or for simulator:
flutter run -d "iPhone 14 Pro"
```

**To see the app:**
- The app will install on the simulator
- Look for the "yookatale" app icon
- The app opens automatically

### Option C: Web Browser

```powershell
flutter run -d chrome
# Or for Edge:
flutter run -d edge
```

**To see the app:**
- Browser opens automatically
- App runs at: `http://localhost:xxxxx` (port shown in terminal)

### Option D: Physical Device (Recommended for Testing)

**Android Phone:**
1. Enable Developer Options on your phone:
   - Settings → About Phone → Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging (ON)
3. Connect phone via USB
4. Allow USB debugging when prompted on phone
5. Run:
   ```powershell
   flutter run
   ```

**iPhone (Mac Required):**
1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. In Xcode: Window → Devices and Simulators
4. Select your iPhone and click "Use for Development"
5. Run:
   ```powershell
   flutter run
   ```

## Step 4: Access the Running App

### Once the app is running:

1. **On Device/Emulator:**
   - Look for the "YooKatale" app icon on your home screen
   - Tap to open
   - The app should show the home page with products

2. **On Web:**
   - Browser opens automatically
   - URL is shown in terminal (usually `http://localhost:xxxxx`)
   - Share URL to access from other devices on same network

3. **Hot Reload:**
   - Press `r` in terminal to hot reload
   - Press `R` to hot restart
   - Press `q` to quit

## Testing the Features

### 1. Backend Sync
- Open the app
- Navigate to products/home page
- Products should load from backend API
- Compare with web app: https://www.yookatale.app

### 2. Push Notifications
- **Android**: Grant notification permission when prompted
- **iOS**: Grant permission (physical device only)
- Check logs for FCM token
- Send test notification from Firebase Console

### 3. Ratings & Comments
- Navigate to a product detail page
- Look for ratings widget (if integrated on the page)
- Submit a rating/comment
- Verify it appears on web app

## Troubleshooting

### "No devices found"
```powershell
# List all devices:
flutter devices

# For Android, start emulator first:
# Open Android Studio → Device Manager → Start Emulator

# For iOS (Mac):
# Open Xcode → Simulator → Choose Device
```

### "Flutter not found"
- Add Flutter to PATH: `C:\src\flutter\bin`
- Restart PowerShell/terminal
- Or use full path: `C:\src\flutter\bin\flutter.bat run`

### "Build failed"
```powershell
# Clean build:
flutter clean
flutter pub get
flutter run
```

### App doesn't connect to backend
- Check internet connection
- Verify backend URL in `lib/services/api_service.dart`
- Check backend is running: https://yookatale-server.onrender.com/api/products

## Quick Start Commands

```powershell
# 1. Navigate to project
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"

# 2. Get dependencies
flutter pub get

# 3. Check devices
flutter devices

# 4. Run (on first available device)
flutter run

# 5. Or run on specific device
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS (Mac only)
```

## App URLs & Access Points

Once running:
- **Web**: `http://localhost:xxxxx` (shown in terminal)
- **Mobile**: Look for app icon on device/emulator
- **Network Access**: Use your computer's IP + port for same-network access

## Next Steps After Running

1. Test product loading from backend
2. Test user authentication (if implemented)
3. Test ratings/comments functionality
4. Test push notifications
5. Verify data syncs with web app

