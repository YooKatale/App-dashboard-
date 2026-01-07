# Google Play Store Readiness Checklist

This document ensures your Yookatale app meets all Google Play Store requirements before submission.

## ✅ Completed Requirements

### 1. Unique Application ID
- ✅ Changed from `com.example.yookatale` to `com.yookatale.app`
- ✅ Updated in `build.gradle.kts`
- ✅ Updated MainActivity package structure
- ⚠️ **ACTION REQUIRED**: Update `google-services.json` in Firebase Console to add new package name

### 2. Permissions and Features
- ✅ All permissions properly declared with comments
- ✅ Location permissions documented for delivery tracking
- ✅ Biometric permissions properly declared
- ✅ Push notification permissions configured
- ✅ Hardware features marked as optional (`required="false"`)

### 3. Build Configuration
- ✅ Signing configuration set up (needs keystore file)
- ✅ Version management configured
- ✅ ProGuard/R8 rules ready (if needed)

## ⚠️ Required Actions Before Publishing

### 1. Firebase Configuration (CRITICAL)
**Issue**: Your `google-services.json` still references `com.example.yookatale`

**Solution**: 
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `yookatale-b6513`
3. Add a new Android app with package name: `com.yookatale.app`
4. Download the new `google-services.json` and replace the existing one
5. OR update the existing app's package name if this is an update

**Location**: `android/app/google-services.json`

### 2. Google Maps API Key (CRITICAL)
**Issue**: Maps API key is using placeholder

**Solution**:
1. Get your Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Add to `android/gradle.properties`:
   ```
   MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```
3. Restrict the API key to your app's package name and SHA-1 fingerprint

### 3. App Signing Keystore (CRITICAL)
**Status**: Configuration exists but keystore file needed

**Steps to Create**:
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**IMPORTANT**: 
- Backup this keystore file securely
- Never commit it to Git
- You cannot update your app on Play Store without this file

### 4. App Icons
**Status**: Configured in `pubspec.yaml`

**Verify**:
- [ ] Run `flutter pub run flutter_launcher_icons` to generate icons
- [ ] Check `android/app/src/main/res/mipmap-*/ic_launcher.png` exists
- [ ] Verify adaptive icon is properly configured

### 5. Version Information
**Current**: `1.0.0+1` (in `pubspec.yaml`)
- Version Name: 1.0.0 (user-visible)
- Version Code: 1 (must increase with each update)

### 6. Privacy Policy (REQUIRED for Play Store)
**Action Required**: 
- [ ] Create a privacy policy webpage
- [ ] Host it online (GitHub Pages, your website, etc.)
- [ ] Add URL in Play Console when submitting

**Required Content**:
- Data collection practices
- How location data is used
- Firebase services used
- Third-party SDKs (Google Sign-In, Maps, etc.)
- User rights and data deletion

### 7. App Content Rating
**Action Required**:
- [ ] Complete content rating questionnaire in Play Console
- [ ] Be honest about app content

### 8. Store Listing Requirements
**Action Required**:
- [ ] App name: "Yookatale" (max 50 characters) ✅
- [ ] Short description (80 characters)
- [ ] Full description (4000 characters)
- [ ] Feature graphic (1024 x 500 px)
- [ ] Phone screenshots (at least 2, up to 8)
- [ ] Tablet screenshots (optional but recommended)
- [ ] App icon (512 x 512 px, 32-bit PNG)

### 9. Target Audience and Content
**Action Required**:
- [ ] Set target audience (all ages, teens, etc.)
- [ ] Declare if app contains ads
- [ ] Declare if app contains in-app purchases

### 10. Data Safety Section (REQUIRED)
**Action Required**: Fill out in Play Console:
- [ ] What data is collected? (Location, Personal info, etc.)
- [ ] Why is data collected? (App functionality, analytics, etc.)
- [ ] How is data shared? (With third parties, internally, etc.)
- [ ] Security practices (Data encryption, etc.)

### 11. Background Location Permission
**Status**: Declared in manifest

**Play Store Requirements**:
- [ ] Must request runtime permission from user
- [ ] Must show persistent notification when using background location
- [ ] Must allow user to revoke permission easily
- [ ] Must explain why background location is needed

**Implementation Check**:
- Verify your app requests `ACCESS_BACKGROUND_LOCATION` at runtime (Android 10+)
- Show notification when tracking delivery
- Provide clear explanation to users

## Play Store Submission Checklist

### Before Building Release:
- [x] Application ID updated to unique package name
- [ ] Firebase project updated with new package name
- [ ] Google Maps API key configured
- [ ] Keystore created and configured
- [ ] App icons generated
- [ ] Version number set correctly

### Build Release:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Before Uploading to Play Console:
- [ ] Test the AAB file thoroughly
- [ ] Test on multiple Android versions
- [ ] Test all features (location, maps, notifications, etc.)
- [ ] Verify app works offline (if required)
- [ ] Check for crashes and fix issues

### Play Console Setup:
- [ ] Create app listing
- [ ] Upload AAB file
- [ ] Complete store listing (description, screenshots, etc.)
- [ ] Set content rating
- [ ] Complete Data Safety section
- [ ] Add privacy policy URL
- [ ] Set up pricing and distribution
- [ ] Review and publish

## Common Rejection Reasons

### 1. Missing Privacy Policy
**Fix**: Add privacy policy URL in Play Console

### 2. Misleading Permissions
**Fix**: Ensure all permissions are necessary and properly explained

### 3. Background Location Not Justified
**Fix**: Clearly explain in app and Play Console why background location is needed

### 4. Broken Functionality
**Fix**: Test thoroughly before submission

### 5. Incomplete Store Listing
**Fix**: Complete all required fields and upload screenshots

### 6. Wrong Package Name in Firebase
**Fix**: Update Firebase project with correct package name

### 7. App Crashes on Launch
**Fix**: Test release build before uploading

## Testing Before Submission

### Internal Testing Track (Recommended First Step):
1. Upload AAB to Internal Testing track
2. Add testers (up to 100)
3. Test thoroughly
4. Fix any issues
5. Then promote to Production

### Testing Checklist:
- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] All screens load properly
- [ ] User registration/login works
- [ ] Location permissions request works
- [ ] Maps display correctly
- [ ] Push notifications work
- [ ] Biometric authentication works
- [ ] Payment integration works (if applicable)
- [ ] App handles network errors gracefully

## Next Steps

1. **Immediate**: Update Firebase project with new package name
2. **Immediate**: Configure Google Maps API key
3. **Before First Build**: Create signing keystore
4. **Before Submission**: Create privacy policy
5. **Before Submission**: Prepare store listing materials
6. **Before Submission**: Complete Data Safety section

## Resources

- [Flutter Release Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)
- [Data Safety Requirements](https://support.google.com/googleplay/android-developer/answer/10787469)

---

**Last Updated**: Ready for Play Store submission after completing required actions above.
