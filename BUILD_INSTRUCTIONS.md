# Building AAB File for Play Store

## Quick Start

### Option 1: Simple Build Script (Recommended)
```powershell
.\build_aab.ps1
```
This will:
- Stop any running builds
- Clean previous builds
- Get dependencies
- Build the AAB file
- Show the result and file location

### Option 2: Build with Automatic Monitoring
```powershell
.\build_aab_with_monitor.ps1
```
This will:
- Clean previous builds
- Get dependencies
- Start the build in the background
- Open a monitoring window to track progress

### Option 3: Build Manually and Monitor Separately

**Terminal 1 - Start the build:**
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

**Terminal 2 - Monitor progress:**
```powershell
.\monitor_build.ps1
```

### Option 4: Use Existing Batch Script
```powershell
.\build_release.bat
```

## Monitor Script Usage

The `monitor_build.ps1` script provides real-time monitoring:

```powershell
.\monitor_build.ps1                # Monitor with default 5-second intervals
.\monitor_build.ps1 -AutoOpen      # Auto-open file explorer when done
```

**Features:**
- Real-time build progress tracking
- Shows completed build stages
- Detects stuck builds (no activity for 2+ minutes)
- Displays Java process status
- Automatically detects when AAB file is created

## Output Location

The AAB file will be created at:
```
build\app\outputs\bundle\release\app-release.aab
```

## Build Time

- Typical build time: 5-15 minutes (depending on system)
- First build: May take longer (downloading dependencies)
- Subsequent builds: Usually faster (cached dependencies)

## Troubleshooting

### Build Stuck/No Progress
1. Check if Java processes are running: `Get-Process java`
2. Kill stuck processes: `Get-Process java | Stop-Process -Force`
3. Clean and rebuild: `flutter clean && flutter pub get && flutter build appbundle --release`

### Build Fails
1. Check for errors in the build output
2. Verify signing configuration in `android/key.properties`
3. Ensure all dependencies are installed: `flutter pub get`
4. Check Flutter doctor: `flutter doctor`

### Monitor Script Not Working
- Ensure PowerShell execution policy allows scripts:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Uploading to Play Store

1. Go to Google Play Console
2. Select your app
3. Go to Production (or Internal/Alpha/Beta testing)
4. Click "Create new release"
5. Upload `app-release.aab` file
6. Add release notes
7. Review and publish
