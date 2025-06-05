#!/bin/bash

echo "🔨 Building WindowAI with Stable Signature"
echo "=========================================="
echo ""

# Clean build
echo "1️⃣ Cleaning previous builds..."
xcodebuild -project WindowAI.xcodeproj -scheme WindowAI clean

# Build in Release mode (more stable)
echo ""
echo "2️⃣ Building in Release mode..."
xcodebuild -project WindowAI.xcodeproj -scheme WindowAI -configuration Release build

# Find the built app
BUILD_DIR=$(xcodebuild -project WindowAI.xcodeproj -showBuildSettings -configuration Release | grep "BUILT_PRODUCTS_DIR" | grep -oE "/.*" | head -1)
APP_PATH="$BUILD_DIR/WindowAI.app"

echo ""
echo "3️⃣ Built app at: $APP_PATH"

# Copy to Applications
echo ""
echo "4️⃣ Installing to Applications..."
rm -rf /Applications/WindowAI.app
cp -R "$APP_PATH" /Applications/

# Sign with ad-hoc certificate for consistency
echo ""
echo "5️⃣ Signing with stable certificate..."
codesign --force --deep -s - /Applications/WindowAI.app

echo ""
echo "✅ Build complete!"
echo ""
echo "To run:"
echo "  /Applications/WindowAI.app/Contents/MacOS/WindowAI"
echo ""
echo "Or double-click WindowAI in Applications folder"
echo ""
echo "The app should now maintain consistent permissions!"