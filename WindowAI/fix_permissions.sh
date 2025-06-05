#!/bin/bash

echo "🔧 WindowAI Permission Fix Script"
echo "================================="
echo ""
echo "This script will help fix accessibility permissions for WindowAI"
echo ""

# Step 1: Kill any running instances
echo "1️⃣ Killing any running WindowAI instances..."
killall WindowAI 2>/dev/null || echo "   No running instances found"

# Step 2: Reset permissions
echo ""
echo "2️⃣ Resetting accessibility permissions..."
echo "   You'll need to enter your password:"
sudo tccutil reset Accessibility com.zandermodaress.WindowAI

# Step 3: Remove from accessibility database
echo ""
echo "3️⃣ Cleaning up accessibility database..."
sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "DELETE FROM access WHERE client='com.zandermodaress.WindowAI';" 2>/dev/null || echo "   Database cleanup skipped"

# Step 4: Instructions
echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📋 Now follow these steps:"
echo ""
echo "1. Open System Settings > Privacy & Security > Accessibility"
echo "2. If WindowAI is still in the list, remove it (click - button)"
echo "3. Click the lock to make changes if needed"
echo "4. Click the + button"
echo "5. Navigate to /Applications and add WindowAI.app"
echo "6. Make sure the checkbox is CHECKED ✓"
echo "7. Close System Settings"
echo ""
echo "🚀 Then run WindowAI using ONE of these methods:"
echo ""
echo "Option A: From Terminal (recommended for testing):"
echo "   /Applications/WindowAI.app/Contents/MacOS/WindowAI"
echo ""
echo "Option B: From Finder:"
echo "   Double-click /Applications/WindowAI.app"
echo ""
echo "Option C: From Xcode:"
echo "   Clean build folder (Shift+Cmd+K)"
echo "   Run again from Xcode"
echo ""
echo "⚠️  IMPORTANT: The app MUST be restarted after granting permissions!"