#!/bin/bash

# Script to help update app version for Play Store releases
# Usage: ./update_version.sh [patch|minor|major]

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
VERSION_CODE=$(echo $CURRENT_VERSION | cut -d'+' -f2)

echo "Current version: $CURRENT_VERSION"
echo "  Version Name: $VERSION_NAME"
echo "  Version Code: $VERSION_CODE"

UPDATE_TYPE=${1:-patch}

case $UPDATE_TYPE in
  patch)
    # Increment patch version: 1.0.0 -> 1.0.1
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    MINOR=$(echo $VERSION_NAME | cut -d'.' -f2)
    PATCH=$(echo $VERSION_NAME | cut -d'.' -f3)
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION_NAME="$MAJOR.$MINOR.$NEW_PATCH"
    ;;
  minor)
    # Increment minor version: 1.0.0 -> 1.1.0
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    MINOR=$(echo $VERSION_NAME | cut -d'.' -f2)
    NEW_MINOR=$((MINOR + 1))
    NEW_VERSION_NAME="$MAJOR.$NEW_MINOR.0"
    ;;
  major)
    # Increment major version: 1.0.0 -> 2.0.0
    MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
    NEW_MAJOR=$((MAJOR + 1))
    NEW_VERSION_NAME="$NEW_MAJOR.0.0"
    ;;
  *)
    echo "Invalid update type. Use: patch, minor, or major"
    exit 1
    ;;
esac

NEW_VERSION_CODE=$((VERSION_CODE + 1))
NEW_VERSION="$NEW_VERSION_NAME+$NEW_VERSION_CODE"

echo ""
echo "New version: $NEW_VERSION"
echo "  Version Name: $NEW_VERSION_NAME"
echo "  Version Code: $NEW_VERSION_CODE"
echo ""

read -p "Update pubspec.yaml? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Update pubspec.yaml (works on both Linux/Mac and Windows with Git Bash)
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
  else
    # Linux/Mac
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
  fi
  echo "✅ Updated pubspec.yaml to version $NEW_VERSION"
  echo ""
  echo "Next steps:"
  echo "1. Test your changes"
  echo "2. Build: flutter build appbundle --release"
  echo "3. Upload to Google Play Console"
else
  echo "Cancelled. Version not updated."
fi
