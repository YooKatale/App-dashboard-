# Google Play Store Setup Guide

## How to Get Your Play Store Link for Rating Prompt

### Step 1: Create Your App in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your developer account
3. Click **"Create app"**
4. Fill in:
   - **App name**: Yookatale (or your preferred name)
   - **Default language**: English
   - **App or game**: App
   - **Free or paid**: Free
   - **Declarations**: Accept terms

### Step 2: Get Your Package Name

Your package name is already configured in the app:
- **Package name**: `com.yookataleapp.app`
- Location: `android/app/build.gradle.kts` → `applicationId`

**Important**: This package name must be unique and cannot be changed after publishing!

### Step 3: Upload Your First AAB

1. Build your AAB file using: `.\build_aab_release.ps1`
2. In Play Console, go to **Production** → **Create new release**
3. Upload the AAB file from: `build\app\outputs\bundle\release\app-release.aab`
4. Fill in release notes
5. Review and roll out

### Step 4: Get Your Play Store Link

**After your app is published** (can take a few hours to days for review):

1. Go to your app in Play Console
2. Click on **Store presence** → **Main store listing**
3. Scroll down to find **"Store listing URL"**
4. Or use this format directly:
   ```
   https://play.google.com/store/apps/details?id=com.yookataleapp.app
   ```

### Step 5: Update the Rating Link in Your App

Once you have your Play Store link, update it in the code:

**File**: `lib/services/ratings_service.dart`

```dart
static Future<void> openPlayStore() async {
  // Replace with your actual Play Store link after publishing
  const url = 'https://play.google.com/store/apps/details?id=com.yookataleapp.app';
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

### Step 6: Test the Link

1. Build and install your app
2. Trigger the rating prompt (after 5 app opens)
3. Click "Rate Now"
4. It should open your Play Store listing

## Important Notes

- ⚠️ **Package name cannot be changed** after first upload
- ⚠️ **Link won't work** until app is published and live
- ⚠️ **Review process** can take 1-7 days
- ✅ You can test with internal testing track first
- ✅ Link format: `https://play.google.com/store/apps/details?id=PACKAGE_NAME`

## Testing Before Publishing

If you want to test the rating flow before publishing:

1. Use **Internal testing** track in Play Console
2. Upload AAB to internal testing
3. Share with testers
4. The link will work once internal testing is live

## Current Configuration

- **Package Name**: `com.yookataleapp.app`
- **Expected Play Store Link**: `https://play.google.com/store/apps/details?id=com.yookataleapp.app`
- **Rating Prompt**: Shows after 5 app opens (configurable in `ratings_service.dart`)
