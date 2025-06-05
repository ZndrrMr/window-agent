#!/bin/bash

echo "🔧 Fixing Accessibility Toggle Issue"
echo "===================================="
echo ""

# Step 1: Kill the app
echo "1️⃣ Stopping WindowAI..."
killall WindowAI 2>/dev/null || echo "   App not running"

# Step 2: Reset permissions for the app
echo ""
echo "2️⃣ Resetting accessibility permissions..."
echo "   Enter your password when prompted:"
sudo tccutil reset Accessibility com.zandermodaress.WindowAI

# Step 3: Remove quarantine attributes
echo ""
echo "3️⃣ Removing quarantine attributes..."
xattr -dr com.apple.quarantine /Applications/WindowAI.app 2>/dev/null

# Step 4: Sign the app with ad-hoc signature
echo ""
echo "4️⃣ Signing app with stable signature..."
codesign --force --deep -s - /Applications/WindowAI.app

echo ""
echo "✅ Done! Now:"
echo ""
echo "1. Open System Settings > Privacy & Security > Accessibility"
echo "2. Look for WindowAI - it should be gone"
echo "3. Run the app again from Xcode"
echo "4. When prompted, grant accessibility permissions"
echo "5. The toggle should stay ON this time"
echo ""
echo "If it still flips back, try Solution 2 below:"
echo ""
echo "SOLUTION 2 - Direct Grant:"
echo "1. In Terminal, run:"
echo "   sudo sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.zandermodaress.WindowAI',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,1687876543);\""
echo ""
echo "2. Then restart the app"