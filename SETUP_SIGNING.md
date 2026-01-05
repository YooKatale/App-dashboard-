# App Signing Setup Guide

## Important: If You Already Have an App on Play Store

Since you already have version 1.0.0 on Play Store, you likely have one of these scenarios:

### Scenario 1: Google Play App Signing (Recommended)
If Google Play is managing your signing key (most common), you don't need to create a new keystore. Google Play Console will show you if this is enabled.

**Check:** Go to Play Console → Your App → Setup → App Integrity → App Signing

### Scenario 2: You Have an Existing Keystore
If you created a keystore when you first uploaded, you need to use that SAME keystore for all future updates.

**Action:** Find your original keystore file and use it.

### Scenario 3: You Need to Create a New Keystore
If you don't have a keystore and Google Play isn't managing it, create one now.

---

## Creating a New Keystore (If Needed)

### Step 1: Generate the Keystore

Run this command in your project root:

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be asked for:**
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name
- Organizational unit
- Organization
- City
- State
- Country code (e.g., US, UG)

**Example:**
```
Enter keystore password: [YourPassword123!]
Re-enter new password: [YourPassword123!]
What is your first and last name?
  [Unknown]: Yookatale Admin
What is the name of your organizational unit?
  [Unknown]: Development
What is the name of your organization?
  [Unknown]: Yookatale
What is the name of your City or Locality?
  [Unknown]: Kampala
What is the name of your State or Province?
  [Unknown]: Central
What is the two-letter country code for this unit?
  [Unknown]: UG
```

### Step 2: Create key.properties File

1. Copy the template:
```bash
copy android\key.properties.template android\key.properties
```

2. Edit `android/key.properties` and fill in your passwords:
```properties
storePassword=YourPassword123!
keyPassword=YourPassword123!
keyAlias=upload
storeFile=../upload-keystore.jks
```

### Step 3: Add key.properties to .gitignore

**IMPORTANT:** Never commit your keystore or key.properties to Git!

Add to `.gitignore`:
```
android/key.properties
android/upload-keystore.jks
android/*.keystore
*.jks
```

### Step 4: Backup Your Keystore

**CRITICAL:** If you lose your keystore, you CANNOT update your app on Play Store!

1. Copy `android/upload-keystore.jks` to a secure location
2. Store passwords in a password manager
3. Keep multiple backups (cloud + physical)

---

## If Using Google Play App Signing

If Google Play is managing your key, you can use an upload key instead:

1. Generate an upload keystore (same as above)
2. Upload it to Google Play Console
3. Google will use it to sign your app

---

## Verifying Your Setup

After setup, your `build.gradle.kts` should be configured (already done in this project).

Test the signing:
```bash
flutter build appbundle --release
```

The build should complete without signing errors.

---

## Troubleshooting

### "Keystore file not found"
- Make sure `upload-keystore.jks` is in `android/` directory
- Check the path in `key.properties`

### "Wrong password"
- Double-check passwords in `key.properties`
- Make sure there are no extra spaces

### "Alias not found"
- Make sure `keyAlias=upload` matches the alias used when creating the keystore

---

## Security Best Practices

1. ✅ Never commit keystore files to Git
2. ✅ Use strong passwords (20+ characters)
3. ✅ Store backups in multiple secure locations
4. ✅ Use Google Play App Signing if possible
5. ✅ Limit access to keystore files
6. ✅ Document keystore location and passwords securely
