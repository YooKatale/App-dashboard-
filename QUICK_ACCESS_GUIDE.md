# Quick Access Guide - YooKatale Flutter App

## 🚀 Quick Start

### Step 1: Install Flutter (One-Time Setup)

**Download Flutter:**
1. Go to: https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK (stable release)
3. Extract to: `C:\src\flutter` (or any location you prefer)

**Add Flutter to PATH:**
1. Open "Edit environment variables" (search in Start menu)
2. Click "Environment Variables"
3. Under "System variables", find "Path" and click "Edit"
4. Click "New" and add: `C:\src\flutter\bin` (or your Flutter location)
5. Click "OK" on all windows
6. **Restart PowerShell/Terminal**

**Verify Installation:**
```powershell
flutter --version
flutter doctor
```

**Install Missing Tools:**
- `flutter doctor` will show what's missing
- Install Android Studio for Android development
- Install Xcode (Mac only) for iOS development
- Or use Chrome for web testing (easiest option!)

---

## 🏃 Run the App (After Flutter is Installed)

### Option 1: Run on Web Browser (Easiest - No Additional Setup!)

```powershell
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
flutter pub get
flutter run -d chrome
```

**What happens:**
- Chrome browser opens automatically
- App runs at: `http://localhost:xxxxx` (port shown in terminal)
- You can access it immediately!

---

### Option 2: Run on Android Emulator

**Setup Android Emulator:**
1. Install Android Studio: https://developer.android.com/studio
2. Open Android Studio → More Actions → SDK Manager
3. Install Android SDK (latest version)
4. Go to Tools → Device Manager → Create Device
5. Choose a device (e.g., Pixel 5) and click "Finish"
6. Click the Play button ▶️ to start emulator

**Run on Android:**
```powershell
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
flutter pub get
flutter run
```

**What happens:**
- App installs on emulator
- App opens automatically
- Look for "yookatale" icon on emulator home screen

---

### Option 3: Run on Physical Android Phone

**Enable Developer Mode:**
1. Go to Settings → About Phone
2. Tap "Build Number" 7 times
3. Go back to Settings → Developer Options
4. Enable "USB Debugging"

**Connect & Run:**
```powershell
# Connect phone via USB
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
flutter pub get
flutter run
```

**What happens:**
- App installs on your phone
- App opens automatically
- Find "yookatale" icon in your app drawer

---

### Option 4: Run on iOS (Mac Only)

**Setup iOS Simulator:**
1. Install Xcode from App Store
2. Open Xcode → Preferences → Locations
3. Install Command Line Tools
4. Open Simulator: Xcode → Open Developer Tool → Simulator

**Run on iOS:**
```powershell
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
flutter pub get
flutter run -d ios
```

---

## 📱 How to Access the Running App

### On Web Browser:
- **URL**: `http://localhost:xxxxx` (shown in terminal)
- Browser opens automatically
- Share URL to access from other devices on same network

### On Android Emulator:
- **Location**: Emulator screen (opens automatically)
- **Icon**: Look for "yookatale" app icon
- **Home Screen**: Tap icon to launch

### On Physical Phone:
- **Location**: App drawer/home screen
- **Icon**: "yookatale" app icon
- **Launch**: Tap icon to open

### On iOS Simulator:
- **Location**: Simulator screen (opens automatically)
- **Icon**: "yookatale" app icon
- **Home Screen**: Tap icon to launch

---

## 🎮 While App is Running

**Hot Reload** (update code without restart):
- Press `r` in terminal
- Changes appear instantly!

**Hot Restart** (full restart):
- Press `R` in terminal

**Quit App**:
- Press `q` in terminal

**View Logs**:
- All logs appear in terminal
- Look for API calls, errors, FCM tokens, etc.

---

## 🔍 Check What's Available

**See all available devices:**
```powershell
flutter devices
```

**Example output:**
```
2 connected devices:

Chrome (web)          • chrome          • web-javascript • Google Chrome
Android SDK built for • emulator-5554   • android        • Android 13
```

---

## ✅ Recommended Quick Start

**For fastest testing (no Android Studio needed):**

```powershell
# 1. Install Flutter (if not installed)
# Download from: https://docs.flutter.dev/get-started/install/windows
# Extract to C:\src\flutter
# Add C:\src\flutter\bin to PATH
# Restart PowerShell

# 2. Navigate to project
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"

# 3. Install dependencies
flutter pub get

# 4. Run on Chrome (easiest!)
flutter run -d chrome
```

**That's it! The app opens in Chrome automatically! 🎉**

---

## 🐛 Troubleshooting

### "Flutter not found"
- Install Flutter: https://docs.flutter.dev/get-started/install/windows
- Add to PATH: `C:\src\flutter\bin`
- Restart terminal

### "No devices found"
```powershell
flutter devices
```
- For web: Just use `flutter run -d chrome`
- For Android: Start emulator in Android Studio first
- For iOS: Start simulator in Xcode first

### "Build failed"
```powershell
flutter clean
flutter pub get
flutter run
```

### "Chrome not found"
- Install Google Chrome
- Or use Edge: `flutter run -d edge`

---

## 📋 Checklist

- [ ] Flutter installed and in PATH
- [ ] Run `flutter doctor` to check setup
- [ ] Navigate to `App-dashboard-` directory
- [ ] Run `flutter pub get`
- [ ] Run `flutter devices` to see available options
- [ ] Run `flutter run -d chrome` (or your preferred device)
- [ ] App opens and you can access it!

---

## 🎯 Next Steps After App Opens

1. **Test Backend Sync**: Products should load from API
2. **Test Features**: Navigation, product viewing, etc.
3. **Test Ratings**: If you've added the rating widget to a page
4. **Check Console**: Look at terminal logs for API calls and errors

