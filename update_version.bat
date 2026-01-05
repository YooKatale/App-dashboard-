@echo off
REM Windows batch script to help update app version for Play Store releases
REM Usage: update_version.bat [patch|minor|major]

setlocal enabledelayedexpansion

REM Read current version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set CURRENT_VERSION=%%a

echo Current version: %CURRENT_VERSION%

REM Parse version name and code
for /f "tokens=1 delims=+" %%a in ("%CURRENT_VERSION%") do set VERSION_NAME=%%a
for /f "tokens=2 delims=+" %%a in ("%CURRENT_VERSION%") do set VERSION_CODE=%%a

echo   Version Name: %VERSION_NAME%
echo   Version Code: %VERSION_CODE%

REM Get update type (default to patch)
set UPDATE_TYPE=%1
if "%UPDATE_TYPE%"=="" set UPDATE_TYPE=patch

REM Parse version name parts
for /f "tokens=1 delims=." %%a in ("%VERSION_NAME%") do set MAJOR=%%a
for /f "tokens=2 delims=." %%a in ("%VERSION_NAME%") do set MINOR=%%a
for /f "tokens=3 delims=." %%a in ("%VERSION_NAME%") do set PATCH=%%a

REM Calculate new version based on type
if "%UPDATE_TYPE%"=="patch" (
    set /a NEW_PATCH=%PATCH%+1
    set NEW_VERSION_NAME=%MAJOR%.%MINOR%.!NEW_PATCH!
) else if "%UPDATE_TYPE%"=="minor" (
    set /a NEW_MINOR=%MINOR%+1
    set NEW_VERSION_NAME=%MAJOR%.!NEW_MINOR!.0
) else if "%UPDATE_TYPE%"=="major" (
    set /a NEW_MAJOR=%MAJOR%+1
    set NEW_VERSION_NAME=!NEW_MAJOR!.0.0
) else (
    echo Invalid update type. Use: patch, minor, or major
    exit /b 1
)

set /a NEW_VERSION_CODE=%VERSION_CODE%+1
set NEW_VERSION=%NEW_VERSION_NAME%+%NEW_VERSION_CODE%

echo.
echo New version: %NEW_VERSION%
echo   Version Name: %NEW_VERSION_NAME%
echo   Version Code: %NEW_VERSION_CODE%
echo.

set /p CONFIRM="Update pubspec.yaml? (y/n) "
if /i "%CONFIRM%"=="y" (
    powershell -Command "(Get-Content pubspec.yaml) -replace '^version: .*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"
    echo.
    echo Updated pubspec.yaml to version %NEW_VERSION%
    echo.
    echo Next steps:
    echo 1. Test your changes
    echo 2. Build: flutter build appbundle --release
    echo 3. Upload to Google Play Console
) else (
    echo Cancelled. Version not updated.
)

endlocal
