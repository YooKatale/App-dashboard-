# Quick Start Guide - App Signing & Release

## For Existing Play Store App (Your Situation)

Since you already have version 1.0.0 on Play Store, follow these steps:

### Step 1: Check Your Signing Setup

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Setup** → **App Integrity** → **App Signing**

**If you see "Google Play App Signing is enabled":**
- ✅ Google is managing your key
- You can create an upload key (see Step 2)

**If you see your own keystore:**
- ✅ You need to use that same keystore
- Find your original keystore file and use it

**If you're not sure:**
- Check your email/backups for a `.jks` or `.keystore` file
- If you can't find it, you may need to create a new upload key

### Step 2: Set Up Signing

#### Option A: Create Upload Key (If Google Play App Signing is enabled)

1. **Generate upload keystore:**
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create `android/key.properties`:**
   ```properties
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. **Upload the key to Play Console:**
   - Go to **App Integrity** → **App Signing**
   - Upload your upload key certificate

#### Option B: Use Existing Keystore

1. **Copy your existing keystore** to `android/upload-keystore.jks`

2. **Create `android/key.properties`** with your keystore details:
   ```properties
   storePassword=YOUR_EXISTING_PASSWORD
   keyPassword=YOUR_EXISTING_PASSWORD
   keyAlias=YOUR_EXISTING_ALIAS
   storeFile=../upload-keystore.jks
   ```

### Step 3: Build Your App

**Easy way (automated):**
```bash
# Windows
build_release.bat

# Linux/Mac
chmod +x build_release.sh
./build_release.sh
```

**Manual way:**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### Step 4: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Choose your track:
   - **Internal Testing** (for quick testing)
   - **Closed Testing** (for beta testing)
   - **Production** (for live release)

4. Click **Create new release**
5. Upload `build/app/outputs/bundle/release/app-release.aab`
6. Add release notes
7. Review and submit

---

## Testing Tracks Quick Reference

### Internal Testing (Recommended First)
- **Use for:** Team testing, quick validation
- **Max testers:** 100
- **Review:** Instant
- **How:** Testing → Internal testing → Create release

### Closed Testing
- **Use for:** Beta testing with specific users
- **Max testers:** Unlimited (you control)
- **Review:** Instant
- **How:** Testing → Closed testing → Create release

### Production
- **Use for:** Live app for all users
- **Review:** 1-7 days
- **How:** Production → Create new release
- **Tip:** Use staged rollout (10% → 50% → 100%)

---

## Version Update Quick Reference

Your current version: `1.0.0+1`

**For next update:**
- Bug fix: `1.0.1+2`
- New feature: `1.1.0+2`
- Major update: `2.0.0+2`

**Update automatically:**
```bash
# Windows
update_version.bat patch    # for bug fix
update_version.bat minor     # for feature
update_version.bat major     # for major update

# Linux/Mac
./update_version.sh patch
./update_version.sh minor
./update_version.sh major
```

---

## Complete Workflow Example

### Making Your First Update

1. **Make code changes** (fix bugs, add features)

2. **Update version:**
   ```bash
   update_version.bat patch
   ```

3. **Build:**
   ```bash
   build_release.bat
   ```

4. **Test internally:**
   - Upload to Internal Testing
   - Test with your team
   - Fix any issues

5. **Release:**
   - Upload to Production
   - Start with 10% rollout
   - Monitor for 24-48 hours
   - Increase to 100% if stable

---

## Important Files

- `android/key.properties` - Your signing credentials (NEVER commit to Git!)
- `android/upload-keystore.jks` - Your signing key (NEVER commit to Git!)
- `pubspec.yaml` - Contains version number
- `build_release.bat` / `build_release.sh` - Automated build script
- `update_version.bat` / `update_version.sh` - Version update script

---

## Security Reminders

⚠️ **NEVER commit these to Git:**
- `android/key.properties`
- `android/*.keystore`
- `android/*.jks`

✅ **Always:**
- Backup your keystore in multiple secure locations
- Use strong passwords
- Keep passwords in a password manager

---

## Need Help?

- **Signing Setup:** See `SETUP_SIGNING.md`
- **Testing Tracks:** See `TESTING_TRACKS_GUIDE.md`
- **Play Store Updates:** See `PLAY_STORE_UPDATE_GUIDE.md`
- **Google Play Console:** https://play.google.com/console

---

## Quick Checklist

Before releasing:
- [ ] Version updated in `pubspec.yaml`
- [ ] Code tested locally
- [ ] Signing configured (`android/key.properties` exists)
- [ ] Build successful (`flutter build appbundle --release`)
- [ ] Tested on device
- [ ] Release notes prepared
- [ ] Ready to upload to Play Console
