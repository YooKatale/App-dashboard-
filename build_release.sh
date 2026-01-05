#!/bin/bash

# Automated Build Script for Yookatale Android App
# This script automates the entire build and release process

set -e  # Exit on error

echo "========================================"
echo "  Yookatale App - Release Build Script"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"
echo ""

# Ask for update type
echo "What type of update is this?"
echo "1. Patch (bug fix) - e.g., 1.0.0 -> 1.0.1"
echo "2. Minor (new feature) - e.g., 1.0.0 -> 1.1.0"
echo "3. Major (major changes) - e.g., 1.0.0 -> 2.0.0"
echo "4. Skip version update (use current version)"
read -p "Enter choice (1-4): " choice

case $choice in
    1) UPDATE_TYPE="patch" ;;
    2) UPDATE_TYPE="minor" ;;
    3) UPDATE_TYPE="major" ;;
    4) UPDATE_TYPE="skip" ;;
    *) 
        echo "Invalid choice. Using patch update."
        UPDATE_TYPE="patch"
        ;;
esac

# Update version if needed
if [ "$UPDATE_TYPE" != "skip" ]; then
    echo ""
    echo "Updating version..."
    ./update_version.sh $UPDATE_TYPE
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to update version"
        exit 1
    fi
    
    # Read new version
    NEW_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    echo "Version updated to: $NEW_VERSION"
else
    NEW_VERSION=$CURRENT_VERSION
    echo "Using current version: $NEW_VERSION"
fi

echo ""
echo "========================================"
echo "  Step 1: Cleaning previous builds"
echo "========================================"
flutter clean

echo ""
echo "========================================"
echo "  Step 2: Getting dependencies"
echo "========================================"
flutter pub get

echo ""
echo "========================================"
echo "  Step 3: Analyzing code"
echo "========================================"
if ! flutter analyze; then
    echo "WARNING: Code analysis found issues"
    read -p "Continue anyway? (y/n): " continue_build
    if [ "$continue_build" != "y" ]; then
        echo "Build cancelled"
        exit 1
    fi
fi

echo ""
echo "========================================"
echo "  Step 4: Building release bundle"
echo "========================================"
echo "This may take several minutes..."
echo ""

# Check if key.properties exists
if [ -f "android/key.properties" ]; then
    echo "Using production signing configuration"
else
    echo "WARNING: key.properties not found"
    echo "Building with debug signing (NOT for production!)"
    echo ""
    echo "To set up production signing:"
    echo "1. See SETUP_SIGNING.md"
    echo "2. Create android/key.properties"
    echo "3. Run this script again"
    echo ""
    read -p "Continue with debug signing? (y/n): " continue_build
    if [ "$continue_build" != "y" ]; then
        echo "Build cancelled"
        exit 1
    fi
fi

flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "========================================"
echo "  Step 5: Building APK (optional)"
echo "========================================"
read -p "Also build APK? (y/n): " build_apk
if [ "$build_apk" == "y" ]; then
    flutter build apk --release
    if [ $? -ne 0 ]; then
        echo "WARNING: APK build failed, but AAB was successful"
    else
        echo "APK built successfully"
    fi
fi

echo ""
echo "========================================"
echo "  Build Complete!"
echo "========================================"
echo ""
echo "Version: $NEW_VERSION"
echo ""

# Check if files exist
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$AAB_PATH" ]; then
    echo "✓ AAB (App Bundle): $AAB_PATH"
    echo "  Size: $(du -h "$AAB_PATH" | cut -f1)"
else
    echo "✗ AAB not found!"
fi

if [ -f "$APK_PATH" ]; then
    echo "✓ APK: $APK_PATH"
    echo "  Size: $(du -h "$APK_PATH" | cut -f1)"
fi

echo ""
echo "========================================"
echo "  Next Steps"
echo "========================================"
echo ""
echo "1. Test the build on a device"
echo "2. Go to Google Play Console"
echo "3. Upload the AAB file to your testing track or production"
echo "4. Add release notes"
echo "5. Submit for review"
echo ""
echo "Testing Tracks Guide: See TESTING_TRACKS_GUIDE.md"
echo "Play Store Update Guide: See PLAY_STORE_UPDATE_GUIDE.md"
echo ""

# Ask if user wants to open the output folder
read -p "Open output folder? (y/n): " open_folder
if [ "$open_folder" == "y" ]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open build/app/outputs
    elif command -v open &> /dev/null; then
        open build/app/outputs
    else
        echo "Output folder: build/app/outputs"
    fi
fi

echo ""
echo "Build process completed!"
