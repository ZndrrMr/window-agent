#!/bin/bash

echo "🔍 Finding WindowAI.app in DerivedData..."

# Find the most recent WindowAI.app build
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "WindowAI.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find WindowAI.app in DerivedData"
    echo "Please build the app in Xcode first"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""
echo "📋 Next steps:"
echo "1. Open System Settings > Privacy & Security > Accessibility"
echo "2. Click the lock to make changes"
echo "3. Click the + button"
echo "4. Press Cmd+Shift+G and paste this path:"
echo ""
echo "$APP_PATH"
echo ""
echo "5. Click 'Open' to add WindowAI"
echo "6. Make sure the checkbox next to WindowAI is checked"
echo "7. You may need to restart the app"
echo ""
echo "🎯 Alternative: Copy to Applications folder"
echo "Run: cp -R \"$APP_PATH\" /Applications/"
echo "Then add /Applications/WindowAI.app to Accessibility"