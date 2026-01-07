# Security Setup Guide

## Google Maps API Key Setup

**IMPORTANT:** Never commit your actual API key to Git!

### Steps to Set Up Your API Key:

1. **Get your API key from Google Cloud Console:**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Create a new API key or use an existing one
   - **IMPORTANT:** Restrict the key to:
     - Android apps (add your app's package name: `com.yookatale.app`)
     - Maps SDK for Android

2. **Create local configuration file:**
   ```bash
   # Copy the example file
   cp android/gradle.properties.local.example android/gradle.properties.local
   ```

3. **Add your API key to `android/gradle.properties.local`:**
   ```properties
   MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

4. **Verify the file is gitignored:**
   - The file `android/gradle.properties.local` is already in `.gitignore`
   - Never commit this file!

### If You Need to Regenerate Your API Key:

If your API key was exposed (like in this case), you should:

1. **Go to Google Cloud Console:**
   - Navigate to: https://console.cloud.google.com/apis/credentials
   - Find the exposed key: `AIzaSyA0UmPmQUUscJ6ITKS0rKTS5GBlYTL07EM`
   - Click "Edit" → "Regenerate Key"

2. **Update your local configuration:**
   - Update `android/gradle.properties.local` with the new key

3. **Add restrictions to the new key:**
   - Restrict to Android apps only
   - Add your app's package name
   - Restrict to Maps SDK for Android only

### Security Best Practices:

- ✅ Always use `gradle.properties.local` (gitignored) for API keys
- ✅ Never commit API keys to version control
- ✅ Restrict API keys in Google Cloud Console
- ✅ Regenerate keys if they're exposed
- ✅ Use different keys for development and production

## Notification Setup

Notifications are configured to send every minute in test mode. The server scheduler handles this automatically.

To disable test mode and use production schedule:
- Edit `yookatale-server/services/notificationScheduler.js`
- Set `TEST_MODE = false`
