# iOS Setup & Testing Requirements for YooKatale App

## 📋 Overview

This document outlines all requirements, configurations, and testing procedures needed to successfully build, deploy, and test the YooKatale iOS application on iPhone devices.

---

## 🖥️ Development Environment Requirements

### 1. Hardware Requirements

#### Minimum Requirements
- **Mac Computer** (Required - iOS development cannot be done on Windows/Linux)
  - macOS 12.0 (Monterey) or later
  - Intel or Apple Silicon (M1/M2/M3) processor
  - At least 8GB RAM (16GB recommended)
  - 50GB+ free disk space

#### Physical iPhone Device (Required for Testing)
- **iOS 12.0 or later** (recommended: iOS 15.0+)
- iPhone 6s or newer
- USB cable for connection
- Apple ID account (free developer account works)

### 2. Software Requirements

#### Required Software
1. **Xcode** (Latest version recommended)
   - Download from Mac App Store
   - Includes iOS SDK, Simulator, and development tools
   - **Minimum Version:** Xcode 14.0+
   - **Recommended:** Xcode 15.0+ or latest

2. **Flutter SDK**
   - Version: >=3.0.0 <4.0.0
   - Install from: https://flutter.dev/docs/get-started/install/macos
   - Add to PATH: `export PATH="$PATH:[PATH_TO_FLUTTER]/bin"`

3. **CocoaPods** (iOS dependency manager)
   ```bash
   sudo gem install cocoapods
   ```

4. **Command Line Tools**
   ```bash
   xcode-select --install
   ```

#### Optional but Recommended
- **Xcode Command Line Tools**
- **Homebrew** (package manager)
- **Git** (version control)

---

## 🔧 iOS Configuration Requirements

### 1. Apple Developer Account

#### Free Account (For Testing)
- **Cost:** Free
- **Limitations:**
  - Apps expire after 7 days
  - Limited to 3 apps per device
  - Cannot distribute to App Store
  - **Good for:** Development and testing

#### Paid Account ($99/year) (For App Store)
- **Benefits:**
  - No app expiration
  - Unlimited apps
  - App Store distribution
  - TestFlight beta testing
  - **Required for:** Production releases

#### Setup Steps
1. Go to: https://developer.apple.com/account
2. Sign in with Apple ID
3. Accept Apple Developer Agreement
4. For paid account: Complete payment

### 2. Bundle Identifier Configuration

#### Current Bundle ID
- **Current:** `com.example.yookatale`
- **Recommended:** `com.yookataleapp.app` (matches Android)

#### Update Bundle ID
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select "Runner" project
3. Go to "Signing & Capabilities"
4. Change Bundle Identifier to: `com.yookataleapp.app`
5. Update in `firebase_options.dart` iOS config

### 3. Signing & Certificates

#### Automatic Signing (Recommended)
1. Open Xcode project
2. Select "Runner" target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your Team (Apple Developer account)
6. Xcode will automatically create certificates

#### Manual Signing (Advanced)
- Requires creating certificates in Apple Developer Portal
- More complex but gives more control

### 4. Capabilities & Permissions

#### Required Capabilities (Already Configured)
- ✅ **Push Notifications** - For FCM
- ✅ **Background Modes** - Remote notifications
- ✅ **Location Services** - When in use
- ✅ **Face ID** - Biometric authentication

#### Info.plist Permissions (Already Configured)
- ✅ `NSLocationWhenInUseUsageDescription` - Location access
- ✅ `NSFaceIDUsageDescription` - Face ID authentication
- ✅ `UIBackgroundModes` - Background notifications

---

## 🔥 Firebase iOS Configuration

### 1. Firebase Project Setup

#### Current Configuration
- **Project ID:** `yookatale-b6513`
- **iOS App ID:** `1:573491167004:ios:025507df8b423ea2c6c4d9`
- **Bundle ID:** `com.example.yookatale` (needs update)

#### Required Steps

1. **Download GoogleService-Info.plist**
   - Go to Firebase Console → Project Settings
   - Select iOS app
   - Download `GoogleService-Info.plist`
   - Replace existing file: `ios/Runner/GoogleService-Info.plist`

2. **Update Bundle ID in Firebase**
   - Firebase Console → Project Settings → iOS app
   - Update Bundle ID to match Xcode project
   - Re-download `GoogleService-Info.plist` if changed

3. **Verify Firebase Configuration**
   - Check `lib/firebase_options.dart` has correct iOS config
   - Verify API keys match Firebase Console

### 2. APNs (Apple Push Notification Service) Setup

#### Critical: Push Notifications Won't Work Without This!

#### Option A: APNs Authentication Key (Recommended)
1. **Create Key in Apple Developer Portal:**
   - Go to: https://developer.apple.com/account/resources/authkeys/list
   - Click "+" to create new key
   - Enable "Apple Push Notifications service (APNs)"
   - Download `.p8` key file (only downloadable once!)
   - Note the Key ID

2. **Upload to Firebase:**
   - Firebase Console → Project Settings → Cloud Messaging
   - iOS app configuration → APNs Authentication Key
   - Upload `.p8` file
   - Enter Key ID and Team ID

#### Option B: APNs Certificate (Legacy)
1. Create certificate in Apple Developer Portal
2. Download and install in Keychain
3. Export as `.p12` file
4. Upload to Firebase Console

#### Team ID
- Find in: https://developer.apple.com/account
- Top right corner → Membership → Team ID

---

## 🗺️ Google Maps iOS Configuration

### 1. Google Maps API Key

#### Create iOS API Key
1. Go to: https://console.cloud.google.com/apis/credentials
2. Select project: `yookatale-b6513`
3. Create credentials → API Key
4. Restrict to iOS apps
5. Add Bundle ID: `com.yookataleapp.app`

#### Configure in iOS
1. Open `ios/Runner/Info.plist`
2. Add Google Maps API key:
   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_IOS_GOOGLE_MAPS_API_KEY</string>
   ```

#### Enable APIs
- Maps SDK for iOS
- Places API (if using places)
- Geocoding API (for address conversion)

---

## 📦 CocoaPods Dependencies

### 1. Podfile Setup

#### Create/Update Podfile
The Podfile should be auto-generated by Flutter, but verify it exists:
```bash
cd ios
pod install
```

#### Required Pods (Auto-installed by Flutter plugins)
- Firebase/Core
- Firebase/Auth
- Firebase/Messaging
- Firebase/Firestore
- Firebase/Storage
- GoogleMaps
- GoogleSignIn
- And others based on pubspec.yaml plugins

### 2. Pod Installation

```bash
cd ios
pod deintegrate  # Clean previous installs
pod install      # Install dependencies
```

---

## 🧪 Testing Requirements

### 1. Physical Device Testing (Required)

#### Why Physical Device?
- **Push Notifications:** Don't work on iOS Simulator
- **Location Services:** Limited on Simulator
- **Biometric Auth:** Not available on Simulator
- **Performance:** Real device performance testing
- **App Store:** Required for TestFlight/App Store

#### Setup Physical Device
1. **Connect iPhone via USB**
2. **Trust Computer:**
   - On iPhone: "Trust This Computer" prompt
   - Enter passcode

3. **Enable Developer Mode (iOS 16+):**
   - Settings → Privacy & Security → Developer Mode
   - Enable Developer Mode
   - Restart iPhone

4. **Register Device in Xcode:**
   - Xcode → Window → Devices and Simulators
   - Select your iPhone
   - Click "Use for Development"
   - Select your Team

### 2. iOS Simulator Testing (Optional)

#### Use Cases
- UI/UX testing
- Basic functionality testing
- Quick iteration during development

#### Limitations
- ❌ Push notifications don't work
- ❌ Limited location services
- ❌ No biometric authentication
- ❌ Different performance characteristics

#### Setup Simulator
```bash
# List available simulators
flutter devices

# Run on simulator
flutter run -d "iPhone 14 Pro"
```

### 3. TestFlight Beta Testing (Paid Account Required)

#### Benefits
- Test on multiple devices
- Get feedback from testers
- Test App Store distribution process
- No 7-day expiration limit

#### Setup Steps
1. Build iOS app: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Create TestFlight build
5. Add internal/external testers

---

## 🚀 Build & Run Procedures

### 1. Initial Setup

```bash
# Navigate to project
cd "App-dashboard-"

# Get Flutter dependencies
flutter pub get

# Install iOS dependencies
cd ios
pod install
cd ..

# Verify setup
flutter doctor
```

### 2. Build for Device

```bash
# Debug build
flutter build ios --debug

# Release build (for testing)
flutter build ios --release

# Run on connected device
flutter run -d <device-id>
```

### 3. Build in Xcode

```bash
# Open Xcode workspace (NOT .xcodeproj)
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select your iPhone as target device
2. Select "Runner" scheme
3. Click "Run" (▶️) or press Cmd+R
4. Wait for build and installation

---

## ✅ Pre-Flight Testing Checklist

### Before First Build

- [ ] **Mac Computer Available**
  - [ ] macOS 12.0+ installed
  - [ ] Xcode installed and updated
  - [ ] Command Line Tools installed

- [ ] **Flutter Setup**
  - [ ] Flutter SDK installed
  - [ ] Flutter added to PATH
  - [ ] `flutter doctor` shows no critical issues

- [ ] **Apple Developer Account**
  - [ ] Account created (free or paid)
  - [ ] Signed in to Xcode
  - [ ] Team selected in Xcode project

- [ ] **Firebase Configuration**
  - [ ] `GoogleService-Info.plist` downloaded and placed correctly
  - [ ] Bundle ID matches Firebase iOS app
  - [ ] APNs key/certificate uploaded to Firebase
  - [ ] Firebase project has iOS app registered

- [ ] **iOS Project Configuration**
  - [ ] Bundle ID updated to `com.yookataleapp.app`
  - [ ] Signing configured (automatic or manual)
  - [ ] Capabilities enabled (Push Notifications, Background Modes)
  - [ ] Info.plist permissions configured

- [ ] **Dependencies**
  - [ ] CocoaPods installed
  - [ ] `pod install` completed successfully
  - [ ] No pod installation errors

- [ ] **Physical Device**
  - [ ] iPhone connected via USB
  - [ ] Device trusted on Mac
  - [ ] Developer Mode enabled (iOS 16+)
  - [ ] Device registered in Xcode

---

## 🧪 Testing Checklist

### Core Functionality

- [ ] **App Launch**
  - [ ] App installs successfully
  - [ ] App launches without crashes
  - [ ] Splash screen displays
  - [ ] Initial screen loads

- [ ] **Authentication**
  - [ ] Email/password login works
  - [ ] Google Sign-In works
  - [ ] Biometric authentication works (Face ID/Touch ID)
  - [ ] User session persists

- [ ] **Products**
  - [ ] Products load from API
  - [ ] Product images display
  - [ ] Product details page works
  - [ ] Search functionality works
  - [ ] Categories filter correctly

- [ ] **Cart & Checkout**
  - [ ] Add to cart works
  - [ ] Cart displays items
  - [ ] Update quantities works
  - [ ] Remove items works
  - [ ] Checkout flow works
  - [ ] Payment integration works

- [ ] **Location Services**
  - [ ] Location permission requested
  - [ ] Map displays correctly
  - [ ] Location picker works
  - [ ] Address geocoding works

- [ ] **Push Notifications**
  - [ ] Notification permission requested
  - [ ] FCM token obtained
  - [ ] Notifications received when app is open
  - [ ] Notifications received when app is in background
  - [ ] Notifications received when app is closed
  - [ ] Notification tap opens app
  - [ ] Notification badge updates

- [ ] **Subscriptions**
  - [ ] Subscription packages display
  - [ ] Subscribe flow works
  - [ ] Payment processing works

- [ ] **Schedule/Calendar**
  - [ ] Meal calendar displays
  - [ ] Schedule creation works
  - [ ] Notifications for scheduled meals work

- [ ] **Account Management**
  - [ ] Profile displays correctly
  - [ ] Orders list displays
  - [ ] Subscriptions list displays
  - [ ] Settings page works

- [ ] **Ratings & Reviews**
  - [ ] Submit rating works
  - [ ] Comments display correctly
  - [ ] Ratings sync with backend

---

## 🔍 Debugging & Troubleshooting

### Common Issues

#### 1. "No devices found"
```bash
# Check connected devices
flutter devices

# In Xcode: Window → Devices and Simulators
# Ensure device is connected and trusted
```

#### 2. "Signing for Runner requires a development team"
- Open Xcode → Runner project → Signing & Capabilities
- Select your Team
- Enable "Automatically manage signing"

#### 3. "Pod install fails"
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
```

#### 4. "Push notifications not working"
- Verify APNs key uploaded to Firebase
- Check Bundle ID matches Firebase
- Ensure device is physical (not simulator)
- Check notification permissions granted

#### 5. "Build fails with Firebase errors"
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Check Bundle ID matches Firebase config
- Run `pod install` again

#### 6. "Location services not working"
- Check Info.plist has location permission descriptions
- Verify location permission granted in Settings
- Test on physical device (simulator has limitations)

---

## 📱 Device-Specific Testing

### Test on Multiple Devices

#### Recommended Test Devices
- **iPhone SE (2nd/3rd gen)** - Smallest screen
- **iPhone 14/15** - Standard size
- **iPhone 14/15 Pro Max** - Largest screen
- **iPad** (if supporting tablets)

#### Test Scenarios
- Different screen sizes
- Different iOS versions (12.0, 15.0, 16.0, 17.0+)
- Portrait and landscape orientations
- Dark mode vs light mode

---

## 🚨 Critical Requirements Summary

### Must Have (Cannot Test Without)
1. ✅ **Mac Computer** - iOS development requires macOS
2. ✅ **Xcode** - iOS development IDE
3. ✅ **Physical iPhone** - Push notifications require real device
4. ✅ **Apple Developer Account** - Free account works for testing
5. ✅ **Firebase APNs Setup** - Push notifications won't work without this
6. ✅ **Google Maps API Key** - For location/maps features

### Should Have (Recommended)
1. ✅ **Paid Apple Developer Account** - For App Store distribution
2. ✅ **Multiple Test Devices** - Different screen sizes/iOS versions
3. ✅ **TestFlight Account** - For beta testing

### Nice to Have (Optional)
1. ✅ **CI/CD Setup** - Automated builds
2. ✅ **Crash Reporting** - Firebase Crashlytics
3. ✅ **Analytics** - Firebase Analytics

---

## 📚 Additional Resources

### Documentation
- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)

### Tools
- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com/)

---

## ✅ Next Steps

1. **Set up development environment** (Mac, Xcode, Flutter)
2. **Configure Apple Developer account**
3. **Set up Firebase APNs** (critical for notifications)
4. **Update Bundle ID** to match Android
5. **Test on physical device**
6. **Verify all features work**
7. **Prepare for App Store submission** (if using paid account)

---

**Last Updated:** February 2026  
**App Version:** 2.0.0+9  
**Flutter Version:** >=3.0.0 <4.0.0
