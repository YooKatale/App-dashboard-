# YooKatale Mobile App Testing Guide

## Overview
This guide will help you test the iOS and Android apps with backend sync and push notifications enabled.

## Prerequisites

1. **Flutter SDK**: Make sure you have Flutter installed (>=3.0.0)
   ```bash
   flutter --version
   ```

2. **Firebase Setup**: 
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are configured
   - Enable Firebase Cloud Messaging in Firebase Console

3. **Backend Server**: 
   - Ensure `https://yookatale-server.onrender.com/api` is accessible
   - Verify all endpoints are working

## Android Setup & Testing

### 1. Configure Android
- The `AndroidManifest.xml` has been updated with notification permissions
- Push notification permissions are automatically requested at runtime (Android 13+)

### 2. Build Android APK
```bash
cd App-dashboard-
flutter pub get
flutter build apk --release
# Or for debug:
flutter build apk --debug
```

### 3. Test on Android Device/Emulator
```bash
flutter run
```

### 4. Test Push Notifications on Android
1. Install the app on an Android device
2. Grant notification permissions when prompted
3. Check logs for FCM token: `flutter logs`
4. Send a test notification from Firebase Console:
   - Go to Firebase Console → Cloud Messaging
   - Click "Send test message"
   - Enter the FCM token from logs
   - Send notification

### 5. Verify Backend Sync
- Products should load from backend API instead of JSON files
- Check network logs to confirm API calls
- Test product ratings/comments functionality

## iOS Setup & Testing

### 1. Configure iOS
- The `Info.plist` has been updated with background modes for push notifications
- APNs (Apple Push Notification Service) certificate must be configured in Firebase Console

### 2. iOS Requirements
- Xcode installed
- Apple Developer Account
- APNs certificate configured in Firebase

### 3. Build iOS App
```bash
cd App-dashboard-
flutter pub get
flutter build ios --release
# Or open in Xcode:
open ios/Runner.xcworkspace
```

### 4. Test on iOS Device/Simulator
```bash
flutter run
# Or use Xcode to run on device
```

### 5. Test Push Notifications on iOS
1. Build and install on a physical iOS device (push notifications don't work on simulator)
2. Grant notification permissions when prompted
3. Check logs for FCM token
4. Send test notification from Firebase Console

### 6. APNs Configuration
If notifications aren't working:
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Upload APNs certificate or key
3. For development: Use APNs Authentication Key (recommended)
4. For production: Use APNs Certificate

## Backend API Integration

### Endpoints Used
- `GET /api/products` - Fetch all products
- `GET /api/product/:id` - Fetch single product
- `GET /api/products/:category` - Fetch products by category
- `GET /api/products/:productId/comments` - Fetch product comments/ratings
- `POST /api/products/comment` - Create product comment with rating
- `POST /api/ratings/platform` - Platform feedback
- `POST /api/ratings/app` - App rating
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Testing Backend Sync
1. Open the app
2. Navigate to products page
3. Verify products load from backend (check network logs)
4. Test rating/comment submission
5. Verify data syncs with web app

## Push Notification Testing

### Test Notification Scenarios

1. **Foreground Notifications** (App is open):
   - Send notification from Firebase Console
   - Should see notification banner
   - Notification should appear in notification tray

2. **Background Notifications** (App is in background):
   - Send notification from Firebase Console
   - Notification should appear in system tray
   - Tapping should open the app

3. **Terminated State** (App is closed):
   - Send notification from Firebase Console
   - Notification should appear in system tray
   - Tapping should launch the app

### Testing Meal Notification Schedule
The backend sends notifications at scheduled times:
- **Breakfast**: 6:00 AM, 7:00 AM, 8:00 AM, 9:00 AM, 10:00 AM
- **Lunch**: 12:00 PM, 1:00 PM, 2:00 PM, 3:00 PM
- **Supper**: 5:00 PM, 6:00 PM, 7:00 PM, 8:00 PM, 9:00 PM, 10:00 PM

## Troubleshooting

### Android Issues

**Notifications not working:**
- Check notification permissions in Settings → Apps → YooKatale → Notifications
- Verify `google-services.json` is in `android/app/`
- Check Firebase Console for FCM token registration

**Backend API not connecting:**
- Verify internet permission in AndroidManifest.xml
- Check backend URL is correct in `api_service.dart`
- For emulator, use `10.0.2.2` instead of `localhost`

### iOS Issues

**Notifications not working:**
- Push notifications only work on physical devices (not simulator)
- Verify APNs certificate is uploaded to Firebase
- Check notification permissions in Settings → YooKatale → Notifications
- Verify `GoogleService-Info.plist` is in `ios/Runner/`

**Backend API not connecting:**
- Check backend URL is accessible
- Verify Info.plist has proper permissions
- Check network logs for errors

### Common Errors

**"PlatformException(Platform channel error)":**
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

**"Failed to register for remote notifications":**
- Check APNs certificate configuration
- Verify bundle identifier matches Firebase project
- Ensure device has internet connection

**"API connection failed":**
- Verify backend server is running
- Check URL in `api_service.dart`
- Test endpoint in browser/Postman

## Next Steps

1. **Test on real devices** (both Android and iOS)
2. **Verify push notifications** work in all states
3. **Test product ratings/comments** functionality
4. **Verify backend sync** between web and mobile
5. **Test user authentication** and data persistence

## Production Checklist

- [ ] APNs certificate uploaded to Firebase (iOS)
- [ ] FCM configuration verified in Firebase Console
- [ ] Backend API URL updated to production
- [ ] Notification permissions tested
- [ ] Products sync with backend verified
- [ ] Ratings/comments functionality tested
- [ ] Push notifications tested on both platforms
- [ ] App tested on physical devices

