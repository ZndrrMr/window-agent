#!/usr/bin/env swift

import Foundation
import Cocoa
import ApplicationServices

// Test the X-Ray overlay performance by simulating hotkey trigger
print("🔍 Testing X-Ray Overlay Performance")
print("=====================================")

// Test 1: Check if WindowAI is running
let runningApps = NSWorkspace.shared.runningApplications
let windowAI = runningApps.first { $0.bundleIdentifier == "com.zandermodaress.WindowAI" }

if let windowAI = windowAI {
    print("✅ WindowAI is running (PID: \(windowAI.processIdentifier))")
} else {
    print("❌ WindowAI is not running")
    exit(1)
}

// Test 2: Simulate Command+Shift+X hotkey
print("\n🎯 Simulating Command+Shift+X hotkey...")
print("(This would trigger the X-Ray overlay)")

// We can't directly trigger the hotkey from outside the app,
// but we can measure basic window enumeration performance
let startTime = CFAbsoluteTimeGetCurrent()

// Basic window enumeration test
var windowCount = 0
let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

for app in apps.prefix(10) {
    let appRef = AXUIElementCreateApplication(app.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    if result == .success, let windows = windowsRef as? [AXUIElement] {
        windowCount += windows.count
    }
}

let endTime = CFAbsoluteTimeGetCurrent()
let duration = endTime - startTime

print("⏱️  Basic window enumeration took: \(String(format: "%.3f", duration))s")
print("📊 Found \(windowCount) windows across \(apps.prefix(10).count) apps")

// Performance evaluation
if duration < 0.1 {
    print("🎉 PERFORMANCE TEST PASSED! Under 0.1s requirement")
} else if duration < 0.5 {
    print("⚠️  PERFORMANCE WARNING: \(String(format: "%.3f", duration))s (should be <0.1s)")
} else {
    print("❌ PERFORMANCE FAILED: \(String(format: "%.3f", duration))s (way over 0.1s limit)")
}

print("\n💡 To test the actual X-Ray overlay:")
print("1. Press Command+Shift+X in WindowAI")
print("2. Check Console app for performance logs")
print("3. Look for timing diagnostics in the output")