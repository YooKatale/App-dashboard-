# Quick Command Reference

## Correct Directory Structure

```
Yookatle Interview/
├── yookatale-app/          ← You were here
├── yookatale-server/
└── App-dashboard-/         ← You need to go here
```

## Correct Navigation

From your current location (`yookatale-app`), navigate like this:

```powershell
# Go up one level
cd ..

# Then go into App-dashboard-
cd App-dashboard-

# Or do it in one command:
cd ..\App-dashboard-
```

## Full Command Sequence

```powershell
# 1. Navigate to App-dashboard- directory
cd "C:\Users\mujun\Desktop\Yookatle Interview\App-dashboard-"

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# Or build for specific platform:
flutter build apk          # Android
flutter build ios          # iOS
```

## Flutter Not Found Error

If you see `flutter : The term 'flutter' is not recognized`, you need to:

1. **Install Flutter** (if not installed):
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Extract to a location like `C:\src\flutter`

2. **Add Flutter to PATH**:
   - Open System Properties → Environment Variables
   - Edit "Path" variable
   - Add: `C:\src\flutter\bin` (or wherever you installed Flutter)
   - Restart PowerShell/Terminal

3. **Verify Installation**:
   ```powershell
   flutter --version
   flutter doctor
   ```

## Alternative: Use Flutter Full Path

If Flutter is installed but not in PATH, use the full path:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run
```

Replace `C:\src\flutter` with your actual Flutter installation path.

