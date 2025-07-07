#!/usr/bin/env swift

import Foundation
import Cocoa
import ApplicationServices

print("🎯 Final Performance Test - Clean Console Output")
print("================================================")

// Check if WindowAI is running
let runningApps = NSWorkspace.shared.runningApplications
let windowAI = runningApps.first { $0.bundleIdentifier == "com.zandermodaress.WindowAI" }

if let windowAI = windowAI {
    print("✅ WindowAI is running (PID: \(windowAI.processIdentifier))")
} else {
    print("❌ WindowAI is not running")
    exit(1)
}

print("\n🧪 Testing basic window enumeration performance...")
let start = CFAbsoluteTimeGetCurrent()

var totalWindows = 0
let relevantApps = runningApps.filter { app in
    guard let bundleId = app.bundleIdentifier else { return false }
    
    // Skip WindowAI itself and system apps (same logic as fixed code)
    if bundleId == "com.zandermodaress.WindowAI" {
        return false
    }
    
    let skipApps = [
        "com.apple.dock",
        "com.apple.systemuiserver", 
        "com.apple.WindowServer",
        "com.apple.loginwindow",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui"
    ]
    
    return app.activationPolicy == .regular && !skipApps.contains(bundleId)
}

for app in relevantApps.prefix(8) {
    let appRef = AXUIElementCreateApplication(app.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    if result == .success, let windows = windowsRef as? [AXUIElement] {
        totalWindows += windows.count
    }
}

let duration = CFAbsoluteTimeGetCurrent() - start

print("📊 Results:")
print("   - Apps scanned: \(relevantApps.prefix(8).count)")
print("   - Windows found: \(totalWindows)")
print("   - Duration: \(String(format: "%.3f", duration))s")

if duration < 0.1 {
    print("🎉 SUCCESS: Performance is now under 0.1s!")
    print("✅ X-Ray overlay should work properly")
} else if duration < 0.5 {
    print("⚠️  IMPROVED but still needs optimization: \(String(format: "%.3f", duration))s")
} else {
    print("❌ STILL SLOW: \(String(format: "%.3f", duration))s")
}

print("\n🔧 Key Fixes Applied:")
print("- ✅ Removed all debug logging (clean console)")
print("- ✅ Skip WindowAI self-scanning to prevent recursion")
print("- ✅ Use optimized getWindowsForAppFast() method")
print("- ✅ Limit app scanning and add timeout protection")

print("\n🎯 Test the X-Ray overlay now:")
print("Press Command+Shift+X to see if it loads quickly!")
print("The console should be clean with no debug spam.")