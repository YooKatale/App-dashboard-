# build_android_aab.ps1

Purpose: helper script to generate a keystore, create `android/key.properties`, build a signed Android App Bundle (AAB) and perform a basic signature validation.

Prerequisites:
- Java JDK installed (keytool & jarsigner on PATH)
- Flutter installed and on PATH
- Android SDK with cmdline-tools installed; accept licenses (`flutter doctor --android-licenses`)

Usage:
1. Open PowerShell and change to the project root:

```powershell
cd "c:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"
powershell -ExecutionPolicy Bypass -File .\scripts\build_android_aab.ps1
```

2. If a keystore does not exist, the script will prompt to create one and ask for passwords.
3. The script will create `android/key.properties` in the `android/` folder. This file contains sensitive values — add it to `.gitignore`.
4. After building, the script locates the produced `.aab` under `build/` and attempts a `jarsigner -verify` check.

CI / Non-interactive usage:
- Set `CI_MODE=1` or pass `-NonInteractive` to the script.
- Provide keystore via `CI_KEYSTORE_BASE64` (base64-encoded keystore bytes) or `CI_KEYSTORE_PATH` (path accessible on runner).
- Provide keystore passwords via `CI_KEYSTORE_PASSWORD` and `CI_KEY_PASSWORD`.

Example CI environment variables (GitHub Actions):

```yaml
env:
	CI_MODE: '1'
	CI_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
	CI_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
	CI_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
	CI_KEY_ALIAS: upload
```

Security notes:
- The script writes `android/key.properties` containing plaintext passwords. Keep this file out of source control.
- For CI, store keystore and passwords in pipeline secrets and avoid committing `key.properties`.

If you hit errors about missing Android SDK components, install Android cmdline-tools via Android Studio SDK Manager or follow official docs.
