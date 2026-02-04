#!/bin/bash

# Configuration
APP_NAME="BanglaBar"
SCHEME_NAME="BanglaBar"
BUILD_DIR="./build"
APP_OUTPUT="$BUILD_DIR/Release"

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$APP_OUTPUT"

echo "🚀 Building $APP_NAME for Release..."

# Build (instead of Archive, to bypass strict signing checks)
xcodebuild build \
  -project BanglaBar.xcodeproj \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  CONFIGURATION_BUILD_DIR="$APP_OUTPUT" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "📦 Packaging..."

# Create a ZIP file for distribution
cd "$APP_OUTPUT"
# In case the app name in project settings is lowercase 'BanglaBar', check both
if [ -d "$APP_NAME.app" ]; then
    zip -r "$APP_NAME.zip" "$APP_NAME.app"
elif [ -d "$SCHEME_NAME.app" ]; then
    # Rename for distribution if needed
    mv "$SCHEME_NAME.app" "$APP_NAME.app"
    zip -r "$APP_NAME.zip" "$APP_NAME.app"
else 
    echo "⚠️ Could not find .app file to zip."
    ls -l
    exit 1
fi

echo "✅ Done! Release package ready:"
echo "   $PWD/$APP_NAME.zip"
open .
