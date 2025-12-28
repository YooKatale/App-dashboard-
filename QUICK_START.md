# Quick Start Guide - Testing Mobile Apps

## 🚀 Quick Setup Commands

### 1. Install Dependencies
```bash
cd App-dashboard-
flutter pub get
```

### 2. Test on Android
```bash
# Connect Android device or start emulator
flutter devices

# Run app
flutter run

# Or build APK
flutter build apk --debug
```

### 3. Test on iOS
```bash
# Connect iOS device (push notifications need physical device)
flutter devices

# Run app
flutter run

# Or open in Xcode
open ios/Runner.xcworkspace
```

## 🔔 Push Notifications Setup

### Android - Already Configured ✅
- Permissions added to AndroidManifest.xml
- Firebase Messaging dependency added
- No additional setup needed!

### iOS - Requires APNs Configuration ⚠️

**Important**: Push notifications on iOS require APNs certificate/key in Firebase Console.

1. **Get APNs Key** (Recommended):
   - Go to Apple Developer Portal → Keys
   - Create new key with Apple Push Notifications service (APNs)
   - Download .p8 key file
   - Note the Key ID

2. **Upload to Firebase**:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Under "Apple app configuration"
   - Click "Upload" next to APNs Authentication Key
   - Upload the .p8 file
   - Enter Key ID and Team ID

3. **Or Use APNs Certificate**:
   - Generate APNs certificate in Apple Developer Portal
   - Export as .p12 file
   - Upload to Firebase Console

## 📊 Verify Backend Sync

1. **Check Products Load from API**:
   - Open app
   - Navigate to products/home page
   - Check Flutter logs: `flutter logs`
   - Should see "Fetching products from API..."

2. **Compare with Web App**:
   - Open web app: https://www.yookatale.app
   - Compare product list with mobile app
   - Products should match!

## ⭐ Test Ratings Feature

The rating widget is ready to use. Add it to your product detail page:

```dart
import 'package:yookatale/features/products/widgets/product_rating_widget.dart';

// In your product detail/widget:
ProductRatingWidget(
  productId: 'your-product-id',
  userId: user?.id,
  userName: user?.name,
  userEmail: user?.email,
)
```

## 🧪 Test Push Notifications

### Android:
1. Run app on Android device/emulator
2. Grant notification permission when prompted
3. Check logs for FCM token: `flutter logs | grep FCM`
4. Go to Firebase Console → Cloud Messaging → Send test message
5. Paste FCM token and send
6. Notification should appear!

### iOS:
1. **Must use physical device** (not simulator)
2. Build and install app
3. Grant notification permission
4. Check logs for FCM token
5. Send test notification from Firebase Console
6. Notification should appear!

## 🐛 Troubleshooting

**Products not loading?**
- Check backend URL in `lib/services/api_service.dart`
- Verify backend is accessible: https://yookatale-server.onrender.com/api/products
- Check network logs: `flutter logs`

**Notifications not working on Android?**
- Check notification permissions in device Settings
- Verify `google-services.json` is in `android/app/`
- Check Firebase Console for FCM token registration

**Notifications not working on iOS?**
- Must use physical device (simulator doesn't support)
- Verify APNs certificate/key is uploaded to Firebase
- Check notification permissions in Settings
- Verify bundle ID matches Firebase project

## 📝 Notes

- Backend URL: `https://yookatale-server.onrender.com/api`
- All products now sync from backend
- Ratings/comments sync with web app
- Push notifications enabled for both platforms

