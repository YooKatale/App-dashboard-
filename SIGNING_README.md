Release signing and build instructions

1) Confirm `android/key.properties` contains your keystore credentials (do NOT commit secrets publicly).
   - `storeFile` should point to the keystore relative to `android/` (e.g. `keystore/upload-keystore.jks`).

2) If you don't have a keystore, generate one (run on your machine):

```powershell
keytool -genkeypair -v -keystore C:\path\to\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

3) Place the generated keystore at `App-dashboard-/android/upload-keystore.jks` (or update `key.properties` accordingly).

4) Ensure `android/app/build.gradle` has a signing config that reads `key.properties`. If not present, add under `android` > `signingConfigs` (example snippet):

```gradle
def keystorePropertiesFile = rootProject.file('key.properties')
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

5) Build the app bundle locally (needs Android SDK cmdline-tools and Java JDK installed):

```powershell
flutter pub get
flutter build appbundle --release
```

6) Output AAB path:

```
build\app\outputs\bundle\release\app-release.aab
```

7) Upload this `.aab` to Play Console > Release > Closed testing > Create release. Make sure the `applicationId` (package name) in `android/app/src/main/AndroidManifest.xml` matches the existing Play app.

Notes & troubleshooting
- `flutter doctor` must report no Android toolchain issues. If `cmdline-tools` are missing, install via Android Studio SDK Manager or download command-line tools from Android.
- If Play Console rejects the bundle for versionCode, bump the build number in `pubspec.yaml` and rebuild.
- I cannot upload to Play Console or access your Play account; you must upload the generated `.aab` and complete the rollout.
