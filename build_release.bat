@echo off
REM Automated Build Script for Yookatale Android App
REM This script automates the entire build and release process

setlocal enabledelayedexpansion

echo ========================================
echo   Yookatale App - Release Build Script
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

REM Get current version
for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set CURRENT_VERSION=%%a
echo Current version: %CURRENT_VERSION%
echo.

REM Ask for update type
echo What type of update is this?
echo 1. Patch (bug fix) - e.g., 1.0.0 -^> 1.0.1
echo 2. Minor (new feature) - e.g., 1.0.0 -^> 1.1.0
echo 3. Major (major changes) - e.g., 1.0.0 -^> 2.0.0
echo 4. Skip version update (use current version)
set /p UPDATE_TYPE="Enter choice (1-4): "

if "%UPDATE_TYPE%"=="1" (
    set UPDATE_TYPE=patch
) else if "%UPDATE_TYPE%"=="2" (
    set UPDATE_TYPE=minor
) else if "%UPDATE_TYPE%"=="3" (
    set UPDATE_TYPE=major
) else if "%UPDATE_TYPE%"=="4" (
    set UPDATE_TYPE=skip
) else (
    echo Invalid choice. Using patch update.
    set UPDATE_TYPE=patch
)

REM Update version if needed
if not "%UPDATE_TYPE%"=="skip" (
    echo.
    echo Updating version...
    call update_version.bat %UPDATE_TYPE%
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to update version
        pause
        exit /b 1
    )
    
    REM Read new version
    for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set NEW_VERSION=%%a
    echo Version updated to: !NEW_VERSION!
) else (
    set NEW_VERSION=%CURRENT_VERSION%
    echo Using current version: %NEW_VERSION%
)

echo.
echo ========================================
echo   Step 1: Cleaning previous builds
echo ========================================
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Step 2: Getting dependencies
echo ========================================
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Step 3: Analyzing code
echo ========================================
flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Code analysis found issues
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "!CONTINUE!"=="y" (
        echo Build cancelled
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   Step 4: Building release bundle
echo ========================================
echo This may take several minutes...
echo.

REM Check if key.properties exists
if exist "android\key.properties" (
    echo Using production signing configuration
) else (
    echo WARNING: key.properties not found
    echo Building with debug signing (NOT for production!)
    echo.
    echo To set up production signing:
    echo 1. See SETUP_SIGNING.md
    echo 2. Create android\key.properties
    echo 3. Run this script again
    echo.
    set /p CONTINUE="Continue with debug signing? (y/n): "
    if /i not "!CONTINUE!"=="y" (
        echo Build cancelled
        pause
        exit /b 1
    )
)

flutter build appbundle --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Step 5: Building APK (optional)
echo ========================================
set /p BUILD_APK="Also build APK? (y/n): "
if /i "!BUILD_APK!"=="y" (
    flutter build apk --release
    if %ERRORLEVEL% NEQ 0 (
        echo WARNING: APK build failed, but AAB was successful
    ) else (
        echo APK built successfully
    )
)

echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo Version: %NEW_VERSION%
echo.

REM Check if files exist
set AAB_PATH=build\app\outputs\bundle\release\app-release.aab
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%AAB_PATH%" (
    echo ✓ AAB (App Bundle): %AAB_PATH%
    for %%A in ("%AAB_PATH%") do echo   Size: %%~zA bytes
) else (
    echo ✗ AAB not found!
)

if exist "%APK_PATH%" (
    echo ✓ APK: %APK_PATH%
    for %%A in ("%APK_PATH%") do echo   Size: %%~zA bytes
)

echo.
echo ========================================
echo   Next Steps
echo ========================================
echo.
echo 1. Test the build on a device
echo 2. Go to Google Play Console
echo 3. Upload the AAB file to your testing track or production
echo 4. Add release notes
echo 5. Submit for review
echo.
echo Testing Tracks Guide: See TESTING_TRACKS_GUIDE.md
echo Play Store Update Guide: See PLAY_STORE_UPDATE_GUIDE.md
echo.

REM Ask if user wants to open the output folder
set /p OPEN_FOLDER="Open output folder? (y/n): "
if /i "!OPEN_FOLDER!"=="y" (
    explorer build\app\outputs
)

echo.
echo Build process completed!
pause
