# Google Play Store Update Guide

## Understanding App Updates on Google Play Store

### How Updates Work

1. **You make changes** to your app code
2. **Increment the version** (required for each update)
3. **Build a new APK/AAB** (Android App Bundle is recommended)
4. **Upload to Google Play Console**
5. **Google reviews and publishes** (usually within hours to days)
6. **Users automatically get the update** (if auto-update is enabled)

---

## Version Management

### Current Version
Your app is currently at: **1.0.0+1**
- **Version Name (1.0.0)**: What users see (e.g., "Version 1.0.0")
- **Version Code (1)**: Internal number that MUST increase with each update

### How to Update Versions

#### For Minor Updates (Bug Fixes, Small Features)
```
1.0.0+1  →  1.0.1+2
1.0.1+2  →  1.0.2+3
```

#### For Feature Updates
```
1.0.0+1  →  1.1.0+2
1.1.0+2  →  1.2.0+3
```

#### For Major Updates
```
1.0.0+1  →  2.0.0+2
2.0.0+2  →  3.0.0+3
```

**Important Rules:**
- ✅ Version Code MUST always increase (1 → 2 → 3 → 4...)
- ✅ Version Code can NEVER decrease
- ✅ Version Name can be any format (1.0.0, 1.0.1, 2.0.0, etc.)
- ✅ Each update needs a higher version code than the previous one

---

## Step-by-Step Update Process

### Step 1: Make Your Code Changes
Make any modifications to your app code as needed.

### Step 2: Update Version in `pubspec.yaml`

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Changed from 1.0.0+1
```

**Example progression:**
- First release: `1.0.0+1`
- First update: `1.0.1+2`
- Second update: `1.0.2+3`
- Feature update: `1.1.0+4`
- Major update: `2.0.0+5`

### Step 3: Build the Release Bundle (Recommended)

**Option A: Android App Bundle (AAB) - RECOMMENDED**
```bash
flutter build appbundle --release
```
- Location: `build/app/outputs/bundle/release/app-release.aab`
- Smaller file size
- Google Play generates optimized APKs for different devices
- **This is what Google Play Store prefers**

**Option B: APK (Alternative)**
```bash
flutter build apk --release
```
- Location: `build/app/outputs/flutter-apk/app-release.apk`
- Can be used for direct installation or Play Store

### Step 4: Sign Your App (Required for Play Store)

**Important:** For production releases, you need a signing key.

1. **Generate a keystore** (if you haven't already):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Create `android/key.properties`:**
```properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=upload
storeFile=<location of the keystore file>
```

3. **Update `android/app/build.gradle.kts`** to use signing config:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

### Step 5: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Production** (or **Internal testing** / **Closed testing**)
4. Click **Create new release**
5. Upload your `.aab` file (or `.apk`)
6. Fill in **Release notes** (what's new in this update)
7. Review and **Start rollout**

### Step 6: Review and Publishing

- Google reviews your update (usually 1-3 days for first releases, faster for updates)
- Once approved, the update goes live
- Users with auto-update enabled will get it automatically
- Other users will see an "Update" button in Play Store

---

## Update Types

### 1. Production Release (Live to All Users)
- Full review process
- Visible to all users
- Can take 1-7 days for review

### 2. Internal Testing
- Quick testing with up to 100 testers
- Fast review (usually hours)
- Good for testing before production

### 3. Closed Testing (Alpha/Beta)
- Test with specific user groups
- Can have multiple tracks
- Good for staged rollouts

### 4. Open Testing
- Public beta testing
- Anyone can join
- Good for gathering feedback

---

## Best Practices

### ✅ Do's
- Always increment version code
- Test thoroughly before uploading
- Write clear release notes
- Use AAB format for Play Store
- Keep signing key secure (back it up!)
- Use staged rollouts (10% → 50% → 100%)
- Monitor crash reports after updates

### ❌ Don'ts
- Never decrease version code
- Don't skip version codes (1 → 3 is okay, but 1 → 2 → 3 is better)
- Don't upload debug builds to production
- Don't lose your signing key (you can't update without it!)

---

## Quick Update Checklist

- [ ] Make code changes
- [ ] Update version in `pubspec.yaml`
- [ ] Test the app thoroughly
- [ ] Build release bundle: `flutter build appbundle --release`
- [ ] Upload to Play Console
- [ ] Write release notes
- [ ] Submit for review
- [ ] Monitor after release

---

## Example: Making Your First Update

Let's say you want to fix a bug:

1. **Fix the bug** in your code
2. **Update `pubspec.yaml`:**
   ```yaml
   version: 1.0.1+2  # Changed from 1.0.0+1
   ```
3. **Build:**
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```
4. **Upload** `app-release.aab` to Play Console
5. **Add release notes:** "Bug fixes and performance improvements"
6. **Submit** and wait for approval

---

## Troubleshooting

### "Version code already used"
- Solution: Increment the version code in `pubspec.yaml`

### "App not signed"
- Solution: Set up signing configuration (see Step 4)

### "Update rejected"
- Check Play Console for specific reasons
- Fix issues and resubmit with a new version code

---

## Need Help?

- [Flutter Release Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
