#!/usr/bin/env swift

// Standalone script to test accessibility permissions
// Run with: swift test_accessibility_standalone.swift

import Cocoa
import ApplicationServices

print("🧪 Standalone Accessibility Test")
print("================================")
print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "com.apple.swift")")
print("Process: \(ProcessInfo.processInfo.processName)")
print("PID: \(ProcessInfo.processInfo.processIdentifier)")

// Test 1: Basic permission check
print("\n1️⃣ Basic Permission Check:")
let isTrusted = AXIsProcessTrusted()
print("   AXIsProcessTrusted: \(isTrusted ? "✅ YES" : "❌ NO")")

if !isTrusted {
    print("\n⚠️  No accessibility permissions!")
    print("   To grant permissions:")
    print("   1. Open System Settings > Privacy & Security > Accessibility")
    print("   2. Add Terminal.app (or wherever you're running this from)")
    print("   3. Enable the checkbox")
    print("   4. Run this script again")
    
    // Optionally prompt for permissions
    print("\n   Prompting for permissions...")
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
    AXIsProcessTrustedWithOptions(options as CFDictionary)
    exit(1)
}

// Test 2: System-wide access
print("\n2️⃣ System-wide Access Test:")
let systemWide = AXUIElementCreateSystemWide()
var focusedApp: CFTypeRef?
let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
print("   Get focused app: \(result == .success ? "✅ Success" : "❌ Failed (Error: \(result.rawValue))")")

// Test 3: Find windows
print("\n3️⃣ Window Discovery Test:")
let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
print("   Found \(apps.count) regular apps")

var windowCount = 0
for app in apps.prefix(5) { // Test first 5 apps
    guard let bundleID = app.bundleIdentifier else { continue }
    print("\n   Testing \(app.localizedName ?? "Unknown") [\(bundleID)]:")
    
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windowsRef: CFTypeRef?
    let windowResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
    
    if windowResult == .success, let windows = windowsRef as? [AXUIElement] {
        print("      ✅ Found \(windows.count) windows")
        windowCount += windows.count
        
        // Try to get first window title
        if let firstWindow = windows.first {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(firstWindow, kAXTitleAttribute as CFString, &titleRef)
            if let title = titleRef as? String {
                print("      📄 First window: '\(title)'")
            }
        }
    } else {
        print("      ❌ Failed to get windows (Error: \(windowResult.rawValue))")
    }
}

print("\n📊 Summary: Found \(windowCount) total windows")

// Test 4: Try to move a window
print("\n4️⃣ Window Manipulation Test:")
if windowCount > 0 {
    // Find first moveable window
    for app in apps {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement],
           let window = windows.first {
            
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleRef as? String) ?? "Untitled"
            
            print("   Attempting to move '\(title)' from \(app.localizedName ?? "Unknown")")
            
            // Get current position
            var posRef: CFTypeRef?
            var currentPos = CGPoint.zero
            if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
               let posValue = posRef {
                AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
                print("   Current position: \(currentPos)")
            }
            
            // Try to move it
            var newPos = CGPoint(x: currentPos.x + 50, y: currentPos.y + 50)
            let newPosValue = AXValueCreate(.cgPoint, &newPos)!
            let moveResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPosValue)
            
            if moveResult == .success {
                print("   ✅ Successfully moved window!")
            } else {
                print("   ❌ Failed to move window (Error: \(moveResult.rawValue))")
            }
            
            break
        }
    }
} else {
    print("   ⚠️  No windows found to test movement")
}

print("\n✅ Test complete!")
print("================================\n")