# Fixing Xcode Accessibility Permissions for WindowAI

## The Problem

When running WindowAI from Xcode, the app doesn't appear in System Settings > Privacy & Security > Accessibility because:
1. It runs as a subprocess of Xcode, not as an independent app
2. The bundle identifier and process differ from the built app
3. macOS tracks accessibility permissions by bundle ID and code signature

## Solutions

### Solution 1: Grant Xcode Accessibility Permissions (Quick Fix)
1. Open System Settings > Privacy & Security > Accessibility
2. Click the lock to make changes
3. Add Xcode.app to the list (if not already there)
4. Enable the checkbox next to Xcode
5. Restart Xcode completely
6. Run WindowAI from Xcode - it will inherit Xcode's permissions

**Pros:** Quick and easy for development
**Cons:** Gives Xcode broad accessibility permissions

### Solution 2: Run the Built App with Console Logs
1. Build the app in Xcode (⌘+B)
2. Find the built app: Product menu > Show Build Folder in Finder
3. Copy WindowAI.app to Applications folder
4. Grant it accessibility permissions in System Settings
5. Launch from Terminal to see logs:
   ```bash
   /Applications/WindowAI.app/Contents/MacOS/WindowAI
   ```

### Solution 3: Use a Development Script
1. Create a script that builds and runs the app outside Xcode:
   ```bash
   #!/bin/bash
   # build_and_run.sh
   
   # Build the app
   xcodebuild -project WindowAI/WindowAI.xcodeproj -scheme WindowAI -configuration Debug build
   
   # Find the built app
   BUILD_PATH=$(xcodebuild -project WindowAI/WindowAI.xcodeproj -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | grep -oE "/.*")
   APP_PATH="$BUILD_PATH/WindowAI.app"
   
   # Copy to a known location
   cp -R "$APP_PATH" /tmp/WindowAI.app
   
   # Run it
   /tmp/WindowAI.app/Contents/MacOS/WindowAI
   ```

### Solution 4: Attach Debugger to Running App
1. Build and run the app normally (outside Xcode)
2. In Xcode: Debug menu > Attach to Process > WindowAI
3. Now you can debug while the app has proper permissions

## Testing Accessibility

Use the menu bar options we added:
- **Run Accessibility Diagnostics**: Shows detailed permission status
- **Test Direct Accessibility**: Tests low-level API access
- **Test Window Movement**: Runs comprehensive window tests

## Verification Steps

1. Run the app (using any method above)
2. Click the brain icon in menu bar
3. Select "Run Accessibility Diagnostics"
4. Check the console output for:
   - ✅ AXIsProcessTrusted: true
   - ✅ Window count > 0
   - ✅ Successful system-wide element access

## Common Issues

### "WindowAI" is in the list but still doesn't work
- Toggle the checkbox off and on
- Restart the app
- Check if multiple versions are in the list

### App doesn't appear in accessibility list
- Make sure you're running the built app, not from Xcode
- Try using `tccutil reset Accessibility com.zandermodaress.WindowAI`
- Build a signed version with your Developer ID

### Xcode debugging doesn't work even with Xcode permitted
- Completely quit and restart Xcode
- Clean build folder (⇧⌘K)
- Delete derived data
- Make sure Xcode itself is code-signed properly

## Development Workflow

For active development with debugging:
1. Grant Xcode accessibility permissions (one-time setup)
2. Use the diagnostic menu items to verify permissions
3. Use console logging extensively
4. For production testing, always test the built app directly