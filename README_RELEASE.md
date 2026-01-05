# Yookatale App - Release Management

## 📦 Complete Setup for Play Store Updates

This project includes everything you need to manage app updates on Google Play Store.

---

## 🚀 Quick Start

Since you already have version **1.0.0** on Play Store, here's what to do:

### 1. Set Up Signing (One-Time Setup)

**Check your Play Console first:**
- Go to **Setup** → **App Integrity** → **App Signing**
- See if Google Play App Signing is enabled

**Then follow:** `SETUP_SIGNING.md`

### 2. Make Your First Update

```bash
# Update version automatically
update_version.bat patch

# Build release bundle
build_release.bat
```

### 3. Upload to Play Store

- Go to [Google Play Console](https://play.google.com/console)
- Upload `build/app/outputs/bundle/release/app-release.aab`
- Add release notes
- Submit for review

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **QUICK_START.md** | Start here! Quick reference for everything |
| **SETUP_SIGNING.md** | Detailed signing setup guide |
| **TESTING_TRACKS_GUIDE.md** | Complete guide to testing tracks |
| **PLAY_STORE_UPDATE_GUIDE.md** | How updates work on Play Store |
| **README_RELEASE.md** | This file - overview |

---

## 🛠️ Scripts Available

### Version Management
- **`update_version.bat`** (Windows) / **`update_version.sh`** (Linux/Mac)
  - Automatically increments version numbers
  - Usage: `update_version.bat patch|minor|major`

### Build Automation
- **`build_release.bat`** (Windows) / **`build_release.sh`** (Linux/Mac)
  - Complete automated build process
  - Cleans, updates version, builds, and provides next steps

---

## 📋 Typical Workflow

### For a Bug Fix Update

1. **Fix the bug** in your code
2. **Update version:**
   ```bash
   update_version.bat patch
   ```
3. **Build:**
   ```bash
   build_release.bat
   ```
4. **Test internally:**
   - Upload to Internal Testing track
   - Test with your team
5. **Release:**
   - Upload to Production
   - Start with 10% rollout
   - Monitor for 24-48 hours
   - Increase to 100% if stable

### For a Feature Update

1. **Add the feature** to your code
2. **Update version:**
   ```bash
   update_version.bat minor
   ```
3. **Build and test** (same as above)
4. **Release** (same as above)

---

## 🔐 Signing Configuration

### Current Status
- ✅ Build configuration updated (`build.gradle.kts`)
- ⚠️ You need to create `android/key.properties` (see `SETUP_SIGNING.md`)

### Files Needed
- `android/key.properties` - Your signing credentials
- `android/upload-keystore.jks` - Your signing key

**⚠️ NEVER commit these files to Git!** (Already in `.gitignore`)

---

## 🧪 Testing Tracks

### Recommended Flow
```
Internal Testing → Closed Testing → Production
```

### Quick Reference

| Track | Max Testers | Review Time | Use For |
|-------|-------------|-------------|---------|
| **Internal** | 100 | Instant | Team testing |
| **Closed** | Unlimited | Instant | Beta testing |
| **Open** | Unlimited | Instant | Public beta |
| **Production** | All users | 1-7 days | Live release |

**See `TESTING_TRACKS_GUIDE.md` for complete details.**

---

## 📊 Version Management

### Current Version
Your app is at: **1.0.0+1**

### Version Format
- **Version Name** (`1.0.0`): What users see
- **Version Code** (`1`): Must increase with each update

### Update Types

| Type | Example | When to Use |
|------|---------|-------------|
| **Patch** | `1.0.0` → `1.0.1` | Bug fixes |
| **Minor** | `1.0.0` → `1.1.0` | New features |
| **Major** | `1.0.0` → `2.0.0` | Major changes |

### Important Rules
- ✅ Version Code MUST always increase
- ✅ Version Code can NEVER decrease
- ✅ Each update needs a higher version code

---

## 🔄 Update Process Summary

```
1. Make Code Changes
   ↓
2. Update Version (update_version.bat)
   ↓
3. Build Release (build_release.bat)
   ↓
4. Test Internally (Internal Testing track)
   ↓
5. Upload to Production
   ↓
6. Staged Rollout (10% → 50% → 100%)
   ↓
7. Monitor & Iterate
```

---

## 📁 Project Structure

```
App-dashboard-/
├── android/
│   ├── app/
│   │   └── build.gradle.kts      # Updated with signing config
│   ├── key.properties            # Your signing credentials (create this)
│   └── upload-keystore.jks       # Your signing key (create this)
├── build_release.bat             # Automated build script (Windows)
├── build_release.sh              # Automated build script (Linux/Mac)
├── update_version.bat            # Version update script (Windows)
├── update_version.sh             # Version update script (Linux/Mac)
├── pubspec.yaml                  # Contains version number
└── Documentation/
    ├── QUICK_START.md
    ├── SETUP_SIGNING.md
    ├── TESTING_TRACKS_GUIDE.md
    └── PLAY_STORE_UPDATE_GUIDE.md
```

---

## ✅ Pre-Release Checklist

Before uploading to Play Store:

- [ ] Version updated in `pubspec.yaml`
- [ ] Code tested locally
- [ ] Signing configured (`android/key.properties` exists)
- [ ] Build successful (`flutter build appbundle --release`)
- [ ] Tested on physical device
- [ ] Release notes prepared
- [ ] Screenshots updated (if needed)
- [ ] Privacy policy updated (if needed)
- [ ] Ready to upload to Play Console

---

## 🆘 Troubleshooting

### "Keystore file not found"
- Create `android/key.properties` (see `SETUP_SIGNING.md`)
- Make sure `upload-keystore.jks` is in `android/` directory

### "Version code already used"
- Increment version code in `pubspec.yaml`
- Use `update_version.bat` to do this automatically

### "Build failed"
- Run `flutter clean` first
- Check for compilation errors
- Verify all dependencies are installed

### "Can't upload to Play Store"
- Make sure version code is higher than current production
- Check if you're using the correct signing key
- Verify AAB file was built successfully

---

## 📞 Need Help?

1. **Quick questions:** See `QUICK_START.md`
2. **Signing issues:** See `SETUP_SIGNING.md`
3. **Testing tracks:** See `TESTING_TRACKS_GUIDE.md`
4. **Update process:** See `PLAY_STORE_UPDATE_GUIDE.md`
5. **Google Play Console:** https://play.google.com/console

---

## 🎯 Next Steps

1. ✅ **Set up signing** (if not already done)
   - Follow `SETUP_SIGNING.md`
   - Create `android/key.properties`

2. ✅ **Test the build process**
   - Run `build_release.bat`
   - Verify AAB is created

3. ✅ **Set up testing tracks**
   - Create Internal Testing track
   - Add your team as testers

4. ✅ **Make your first update**
   - Update version
   - Build release
   - Upload to Internal Testing
   - Test thoroughly
   - Promote to Production

---

## 📝 Notes

- Your current Play Store version: **1.0.0** (Nov 15, 2025)
- Next update should be: **1.0.1+2** (for patch) or **1.1.0+2** (for feature)
- Always test in Internal Testing before Production
- Use staged rollouts in Production (10% → 50% → 100%)

---

**Happy releasing! 🚀**
