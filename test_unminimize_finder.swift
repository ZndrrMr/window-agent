#!/usr/bin/env swift

import Foundation
import ApplicationServices

print("🔍 TESTING UNMINIMIZE FUNCTIONALITY")
print("===================================")

// Test if we can detect and unminimize Finder
func testUnminimizeFunction() {
    print("\n1. Getting list of all windows...")
    
    // Get Finder app
    let runningApps = NSWorkspace.shared.runningApplications
    guard let finderApp = runningApps.first(where: { $0.bundleIdentifier == "com.apple.finder" }) else {
        print("❌ Finder app not found")
        return
    }
    
    print("✅ Found Finder app: \(finderApp.localizedName ?? "Finder")")
    
    // Get Finder windows
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement] else {
        print("❌ Could not get Finder windows (error: \(result.rawValue))")
        return
    }
    
    print("✅ Found \(windows.count) Finder windows")
    
    for (index, window) in windows.enumerated() {
        print("\n--- Window \(index + 1) ---")
        
        // Check if minimized
        var minimizedValue: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        
        let isMinimized: Bool
        if minimizedResult == .success, let minimized = minimizedValue as? Bool {
            isMinimized = minimized
            print("Minimized status: \(isMinimized ? "🟡 MINIMIZED" : "✅ Visible")")
        } else {
            print("❌ Could not check minimized status (error: \(minimizedResult.rawValue))")
            continue
        }
        
        if isMinimized {
            print("🔄 Attempting to unminimize...")
            let restoreResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            
            if restoreResult == .success {
                print("✅ Successfully unminimized window!")
                
                // Verify it's now unminimized
                Thread.sleep(forTimeInterval: 0.2)
                var newMinimizedValue: CFTypeRef?
                let newMinimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &newMinimizedValue)
                
                if newMinimizedResult == .success, let newMinimized = newMinimizedValue as? Bool {
                    print("Verification: \(newMinimized ? "❌ Still minimized" : "✅ Now visible")")
                } else {
                    print("⚠️ Could not verify unminimize result")
                }
            } else {
                print("❌ Failed to unminimize (error: \(restoreResult.rawValue))")
            }
        }
        
        // Get window title for identification
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        if titleResult == .success, let title = titleValue as? String {
            print("Window title: '\(title)'")
        }
        
        // Get window bounds
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        if posResult == .success && sizeResult == .success {
            if let position = positionValue, let size = sizeValue {
                var pos = CGPoint.zero
                var sz = CGSize.zero
                AXValueGetValue(position as! AXValue, .cgPoint, &pos)
                AXValueGetValue(size as! AXValue, .cgSize, &sz)
                print("Current bounds: \(pos) size: \(sz)")
            }
        }
    }
}

print("Testing Finder unminimize functionality...")
testUnminimizeFunction()

print("\n🔧 RECOMMENDATIONS:")
print("===================")
print("1. If Finder windows are found but minimized, the unminimize should work")
print("2. If no Finder windows found, open a Finder window first")
print("3. Check that the app has accessibility permissions")
print("4. The WindowAI app should now auto-unminimize before positioning")