# iOS Testing Checklist - YooKatale App

## 📋 Quick Reference Testing Guide

This checklist helps ensure all features work correctly on iOS devices before release.

---

## 🚀 Pre-Testing Setup

### Environment Check
- [ ] Mac computer available with macOS 12.0+
- [ ] Xcode installed (14.0+)
- [ ] Flutter SDK installed and in PATH
- [ ] CocoaPods installed (`pod --version`)
- [ ] Physical iPhone connected and trusted
- [ ] Developer Mode enabled on iPhone (iOS 16+)

### Configuration Check
- [ ] Bundle ID set to `com.yookataleapp.app`
- [ ] Apple Developer account signed in Xcode
- [ ] Signing configured (automatic or manual)
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] APNs key uploaded to Firebase Console
- [ ] Google Maps API key configured in Info.plist
- [ ] `pod install` completed successfully

### Build Check
- [ ] `flutter pub get` completed
- [ ] `flutter clean` executed
- [ ] `flutter build ios` succeeds
- [ ] App installs on device without errors

---

## ✅ Core Functionality Tests

### 1. App Launch & Initialization
- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] Splash screen displays correctly
- [ ] Initial screen loads (home page)
- [ ] No console errors on launch
- [ ] Firebase initializes correctly

### 2. Authentication
- [ ] **Email/Password Login**
  - [ ] Login form displays
  - [ ] Valid credentials log in successfully
  - [ ] Invalid credentials show error
  - [ ] Password visibility toggle works
  - [ ] Session persists after app restart

- [ ] **Google Sign-In**
  - [ ] Google Sign-In button works
  - [ ] Google account selection works
  - [ ] Sign-in completes successfully
  - [ ] User data loads after sign-in

- [ ] **Biometric Authentication**
  - [ ] Face ID/Touch ID prompt appears
  - [ ] Biometric authentication works
  - [ ] Fallback to password works
  - [ ] Biometric settings toggle works

- [ ] **Registration**
  - [ ] Registration form displays
  - [ ] Form validation works
  - [ ] Account creation succeeds
  - [ ] Email verification (if required)

- [ ] **Logout**
  - [ ] Logout button works
  - [ ] User session cleared
  - [ ] Redirects to login screen

### 3. Products & Catalog
- [ ] **Product Listing**
  - [ ] Products load from API
  - [ ] Product images display correctly
  - [ ] Loading indicators show
  - [ ] Error handling works (no internet)
  - [ ] Fallback to cached data works

- [ ] **Product Details**
  - [ ] Product detail page opens
  - [ ] Product images display (multiple if available)
  - [ ] Product description shows
  - [ ] Price displays correctly
  - [ ] Add to cart button works
  - [ ] Back navigation works

- [ ] **Search**
  - [ ] Search bar displays
  - [ ] Search input works
  - [ ] Search results filter correctly
  - [ ] No results message shows
  - [ ] Clear search works

- [ ] **Categories**
  - [ ] Categories display
  - [ ] Category filtering works
  - [ ] Category navigation works
  - [ ] Selected category highlights

- [ ] **Ratings & Reviews**
  - [ ] Ratings display on product page
  - [ ] Average rating shows correctly
  - [ ] Review list displays
  - [ ] Submit rating form works
  - [ ] Comment submission works
  - [ ] Ratings sync with backend

### 4. Shopping Cart
- [ ] **Add to Cart**
  - [ ] Add button works
  - [ ] Item added to cart
  - [ ] Cart count updates
  - [ ] Success message shows

- [ ] **Cart Page**
  - [ ] Cart icon navigates to cart
  - [ ] Cart items display
  - [ ] Item quantities show
  - [ ] Item prices display
  - [ ] Total price calculates correctly

- [ ] **Modify Cart**
  - [ ] Increase quantity works
  - [ ] Decrease quantity works
  - [ ] Remove item works
  - [ ] Empty cart message shows
  - [ ] Cart updates persist

- [ ] **Checkout Navigation**
  - [ ] Checkout button works
  - [ ] Navigates to checkout page

### 5. Checkout & Payment
- [ ] **Checkout Form**
  - [ ] Delivery form displays
  - [ ] Form fields accept input
  - [ ] Form validation works
  - [ ] Address input works
  - [ ] Special requests field works

- [ ] **Location Services**
  - [ ] Location permission requested
  - [ ] Current location detected
  - [ ] Map displays correctly
  - [ ] Location picker works
  - [ ] Address geocoding works
  - [ ] Manual address entry works

- [ ] **Payment**
  - [ ] Payment method selection works
  - [ ] Order total displays correctly
  - [ ] Payment gateway opens
  - [ ] Payment processing works
  - [ ] Payment success handling
  - [ ] Payment failure handling
  - [ ] Order confirmation shows

### 6. Subscriptions
- [ ] **Subscription Page**
  - [ ] Subscription packages display
  - [ ] Package details show correctly
  - [ ] Package prices display
  - [ ] Package features list shows

- [ ] **Subscribe Flow**
  - [ ] Subscribe button works
  - [ ] Subscription confirmation shows
  - [ ] Payment flow initiates
  - [ ] Subscription activates after payment

- [ ] **Account Subscriptions**
  - [ ] Active subscriptions display
  - [ ] Subscription details show
  - [ ] Subscription status correct

### 7. Schedule & Calendar
- [ ] **Meal Calendar**
  - [ ] Calendar displays
  - [ ] Date selection works
  - [ ] Meal times display
  - [ ] Schedule creation works

- [ ] **Schedule Creation**
  - [ ] Product selection works
  - [ ] Day selection works
  - [ ] Time selection works
  - [ ] Repeat option works
  - [ ] Schedule saves successfully

- [ ] **Schedule Notifications**
  - [ ] Notifications scheduled correctly
  - [ ] Notification received at scheduled time
  - [ ] Notification content correct

### 8. Orders
- [ ] **Order History**
  - [ ] Orders list displays
  - [ ] Order details show correctly
  - [ ] Order status displays
  - [ ] Order date/time shows
  - [ ] Order total displays

- [ ] **Order Tracking**
  - [ ] Order tracking page opens
  - [ ] Order status updates
  - [ ] Delivery location shows
  - [ ] Estimated delivery time shows

### 9. Account Management
- [ ] **Profile Page**
  - [ ] Profile displays correctly
  - [ ] User information shows
  - [ ] Profile picture displays (if set)
  - [ ] Edit profile works

- [ ] **Account Tabs**
  - [ ] General tab works
  - [ ] Orders tab works
  - [ ] Subscriptions tab works
  - [ ] Settings tab works
  - [ ] Tab switching works

- [ ] **Settings**
  - [ ] Notification settings work
  - [ ] App settings display
  - [ ] Logout works
  - [ ] Settings persist

### 10. Notifications
- [ ] **Permission Request**
  - [ ] Notification permission requested
  - [ ] Permission granted handling
  - [ ] Permission denied handling

- [ ] **Push Notifications**
  - [ ] FCM token obtained (check logs)
  - [ ] Token sent to backend
  - [ ] **Foreground Notifications**
    - [ ] Notification received when app open
    - [ ] Notification displays correctly
    - [ ] Notification tap opens app
  - [ ] **Background Notifications**
    - [ ] Notification received when app backgrounded
    - [ ] Notification displays in notification center
    - [ ] Notification tap opens app
  - [ ] **Terminated App Notifications**
    - [ ] Notification received when app closed
    - [ ] Notification displays in notification center
    - [ ] Notification tap opens app
    - [ ] App state restored correctly

- [ ] **Notification Center**
  - [ ] Notification icon shows unread count
  - [ ] Notification page opens
  - [ ] Notifications list displays
  - [ ] Notification details show
  - [ ] Mark as read works
  - [ ] Notification history persists

- [ ] **Scheduled Notifications**
  - [ ] Meal reminder notifications work
  - [ ] Notifications arrive at correct time
  - [ ] Notification content correct

### 11. Location Services
- [ ] **Location Permission**
  - [ ] Permission requested on first use
  - [ ] "When in Use" permission works
  - [ ] Permission denied handling

- [ ] **Map Display**
  - [ ] Google Maps loads
  - [ ] Map displays correctly
  - [ ] Current location marker shows
  - [ ] Map zoom works
  - [ ] Map pan works

- [ ] **Location Picker**
  - [ ] Location picker dialog opens
  - [ ] Map displays in picker
  - [ ] Location selection works
  - [ ] Address displays
  - [ ] Confirm location works

### 12. File & Media
- [ ] **File Picker**
  - [ ] File picker opens
  - [ ] Photo library access works
  - [ ] File selection works
  - [ ] Selected file displays

- [ ] **Image Upload**
  - [ ] Image upload works
  - [ ] Upload progress shows
  - [ ] Upload success handling
  - [ ] Upload failure handling

### 13. Wishlist
- [ ] **Add to Wishlist**
  - [ ] Add button works
  - [ ] Item added to wishlist
  - [ ] Success feedback shows

- [ ] **Wishlist Page**
  - [ ] Wishlist page opens
  - [ ] Wishlist items display
  - [ ] Remove from wishlist works
  - [ ] Empty wishlist message shows

### 14. Help & Support
- [ ] **Help Page**
  - [ ] Help page opens
  - [ ] Help content displays
  - [ ] Contact support works

- [ ] **Legal Pages**
  - [ ] Privacy policy opens
  - [ ] Terms of service opens
  - [ ] Content displays correctly

---

## 🔍 Performance & Stability Tests

### Performance
- [ ] App launches quickly (< 3 seconds)
- [ ] Screen transitions smooth
- [ ] No lag when scrolling
- [ ] Images load efficiently
- [ ] API calls complete in reasonable time
- [ ] Memory usage acceptable
- [ ] Battery usage reasonable

### Stability
- [ ] No crashes during normal use
- [ ] App handles network errors gracefully
- [ ] App handles API errors gracefully
- [ ] App recovers from errors
- [ ] No memory leaks (test extended use)
- [ ] Background/foreground transitions work

### Network Handling
- [ ] Works with good internet connection
- [ ] Works with slow internet connection
- [ ] Handles no internet connection
- [ ] Shows appropriate loading states
- [ ] Error messages are user-friendly
- [ ] Retry mechanisms work

---

## 📱 Device-Specific Tests

### Screen Sizes
- [ ] iPhone SE (small screen) - UI fits correctly
- [ ] iPhone 14/15 (standard) - UI displays correctly
- [ ] iPhone 14/15 Pro Max (large) - UI scales correctly
- [ ] iPad (if supported) - UI adapts correctly

### Orientations
- [ ] Portrait mode works
- [ ] Landscape mode works (if supported)
- [ ] Orientation changes handled smoothly

### iOS Versions
- [ ] iOS 15.0+ works
- [ ] iOS 16.0+ works
- [ ] iOS 17.0+ works
- [ ] Latest iOS version works

### Dark Mode
- [ ] Light mode displays correctly
- [ ] Dark mode displays correctly
- [ ] Mode switching works smoothly

---

## 🔐 Security Tests

### Authentication
- [ ] Passwords not stored in plain text
- [ ] Tokens stored securely
- [ ] Session expires correctly
- [ ] Biometric data handled securely

### Data Protection
- [ ] Sensitive data encrypted
- [ ] API calls use HTTPS
- [ ] No sensitive data in logs
- [ ] Secure storage used for credentials

---

## 🐛 Bug Testing

### Edge Cases
- [ ] Empty states handled
- [ ] Very long text handled
- [ ] Special characters handled
- [ ] Rapid button tapping handled
- [ ] Multiple rapid API calls handled
- [ ] App switching during operations

### Error Scenarios
- [ ] Network timeout handled
- [ ] Server error (500) handled
- [ ] Not found (404) handled
- [ ] Unauthorized (401) handled
- [ ] Invalid data handled

---

## 📊 Analytics & Monitoring

### Firebase Analytics
- [ ] Events tracked correctly
- [ ] User properties set
- [ ] Screen views tracked
- [ ] Custom events work

### Crash Reporting
- [ ] Crashes reported (if implemented)
- [ ] Error logs captured
- [ ] Debug information included

---

## ✅ Final Checks

### Before Release
- [ ] All critical features work
- [ ] No blocking bugs
- [ ] Performance acceptable
- [ ] UI/UX polished
- [ ] Error messages user-friendly
- [ ] App Store guidelines met
- [ ] Privacy policy accessible
- [ ] Terms of service accessible

### Documentation
- [ ] Release notes prepared
- [ ] Known issues documented
- [ ] Testing completed documented

---

## 📝 Test Results Template

### Test Session
- **Date:** ___________
- **Tester:** ___________
- **Device:** ___________
- **iOS Version:** ___________
- **App Version:** ___________

### Results Summary
- **Total Tests:** ___________
- **Passed:** ___________
- **Failed:** ___________
- **Blocking Issues:** ___________

### Issues Found
1. **Issue:** ___________
   - **Severity:** Critical / High / Medium / Low
   - **Steps to Reproduce:** ___________
   - **Expected:** ___________
   - **Actual:** ___________

---

## 🚨 Critical Issues (Must Fix)

These issues must be resolved before release:

- [ ] App crashes on launch
- [ ] Authentication doesn't work
- [ ] Payment processing fails
- [ ] Push notifications don't work
- [ ] Critical data loss
- [ ] Security vulnerabilities

---

## 📚 Notes

- Test on physical device for accurate results
- Simulator testing has limitations (notifications, location, etc.)
- Test with real user accounts and data when possible
- Document any workarounds or known issues
- Keep test results for future reference

---

**Last Updated:** February 2026  
**App Version:** 2.0.0+9
