#!/bin/bash

echo "🔐 Signing WindowAI for Accessibility"
echo "===================================="

# Find the app
APP_PATH="/Applications/WindowAI.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ WindowAI.app not found in /Applications"
    exit 1
fi

# Remove any extended attributes that might interfere
echo "1️⃣ Removing extended attributes..."
xattr -cr "$APP_PATH"

# Sign with ad-hoc signature (for local testing)
echo "2️⃣ Signing app with ad-hoc signature..."
codesign --force --deep --sign - "$APP_PATH"

# Verify signature
echo "3️⃣ Verifying signature..."
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E "(Signature|Identifier)" || echo "Signature info not found"

# Check signature validity
if codesign --verify "$APP_PATH" 2>&1; then
    echo "✅ App signed successfully!"
else
    echo "❌ Signature verification failed"
fi

echo ""
echo "📋 Next steps:"
echo "1. Remove WindowAI from Accessibility list if present"
echo "2. Restart your Mac (yes, really - this often helps with TCC)"
echo "3. After restart, run: /Applications/WindowAI.app/Contents/MacOS/WindowAI"
echo "4. When prompted, add to Accessibility"
echo ""
echo "Alternative: Try running as sudo once to establish trust:"
echo "  sudo /Applications/WindowAI.app/Contents/MacOS/WindowAI"