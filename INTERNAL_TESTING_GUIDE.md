# Google Play Internal Testing Setup Guide

## Why You're Getting 404 Error

The link `https://play.google.com/apps/test/com.yookataleapp.app/8` returns 404 because:
- The app hasn't been uploaded to Internal Testing track yet
- The app needs to be published to a testing track first
- The URL format might be different

## Step-by-Step: Setting Up Internal Testing

### Step 1: Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in:
   - **App name**: Yookatale
   - **Default language**: English
   - **App or game**: App
   - **Free or paid**: Free
   - **Declarations**: Accept terms

### Step 2: Set Up Internal Testing Track

1. In Play Console, go to your app
2. Click **"Testing"** in the left menu
3. Click **"Internal testing"**
4. Click **"Create new release"**

### Step 3: Upload Your AAB

1. Build your AAB using: `.\build_aab_release.ps1`
2. In the Internal Testing release page:
   - Click **"Upload"** or drag and drop
   - Select: `build\app\outputs\bundle\release\app-release.aab`
   - Add release notes (e.g., "Initial release for testing")
   - Click **"Save"**

### Step 4: Add Testers

1. Still in Internal Testing, go to **"Testers"** tab
2. Click **"Create email list"**
3. Add tester emails (or use Google Groups)
4. Save the list
5. Copy the **"Opt-in URL"** - this is your testing link!

### Step 5: Review and Roll Out

1. Go back to **"Releases"** tab
2. Click **"Review release"**
3. Complete any required information:
   - App content rating
   - Privacy policy (if required)
   - Store listing (at least app name and description)
4. Click **"Start rollout to Internal testing"**

### Step 6: Wait for Processing

- Google processes the AAB (usually 1-2 hours)
- Once processed, the app will be available to testers
- You'll get an email when it's ready

## Correct Testing URLs

### Internal Testing Link Format:
```
https://play.google.com/apps/internaltest/[TESTER_OPT_IN_CODE]
```

**OR** the opt-in URL you copied from Testers tab:
```
https://play.google.com/apps/internaltest/XXXXXXXXXXXXXXXX
```

### After Publishing to Production:
```
https://play.google.com/store/apps/details?id=com.yookataleapp.app
```

## Common Issues

### Issue 1: "App not found" or 404
**Solution**: 
- Make sure you've uploaded the AAB to a testing track
- Wait for Google to process the upload (1-2 hours)
- Use the opt-in URL from the Testers tab, not a direct link

### Issue 2: "Version code already used"
**Solution**: 
- Run `.\build_aab_release.ps1` - it auto-increments version code
- Or manually update `pubspec.yaml`: `version: 2.0.0+9` (increment the number after +)

### Issue 3: Can't find Internal Testing
**Solution**:
- Make sure you've created the app in Play Console first
- Internal Testing appears after you create the app
- You might need to complete initial app setup first

## Quick Checklist

- [ ] App created in Play Console
- [ ] AAB file built (version code 8 or higher)
- [ ] AAB uploaded to Internal Testing track
- [ ] Testers added to Internal Testing
- [ ] Opt-in URL copied from Testers tab
- [ ] Release reviewed and rolled out
- [ ] Waited for processing (1-2 hours)

## Testing the App

1. Share the opt-in URL with testers
2. Testers click the link and opt-in
3. They can then install from Play Store
4. The app will appear in their Play Store under "Early access"

## Current Status

- **Package Name**: `com.yookataleapp.app`
- **Current Version**: `2.0.0+8` (from pubspec.yaml)
- **Next Version**: Will auto-increment to `2.0.0+9` on next build

## Important Notes

⚠️ **The direct link format you tried won't work until:**
- The app is uploaded to a testing track
- The release is rolled out
- Google has processed the upload

✅ **Use the opt-in URL from Play Console Testers tab instead**

## Need Help?

- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Internal Testing Guide](https://support.google.com/googleplay/android-developer/answer/9845334)
