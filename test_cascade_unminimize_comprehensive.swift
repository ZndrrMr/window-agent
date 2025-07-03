#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🧪 COMPREHENSIVE CASCADE UNMINIMIZE TEST")
print("=========================================")

// This test simulates the EXACT cascade flow that WindowAI uses
// It should FAIL and show where minimized windows get lost

func testCascadeUnminimizeFlow() {
    print("\n🔍 PHASE 1: Setup - Find and minimize Finder")
    print("============================================")
    
    // Get Finder app (same as WindowAI does)
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ FAIL: Finder app not found")
        return
    }
    
    print("✅ Found Finder app")
    
    // Get Finder windows
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let allWindows = windowsRef as? [AXUIElement], !allWindows.isEmpty else {
        print("❌ FAIL: No Finder windows found")
        return
    }
    
    print("✅ Found \(allWindows.count) Finder windows total")
    
    // Force minimize the first window
    let testWindow = allWindows[0]
    let minimizeResult = AXUIElementSetAttributeValue(testWindow, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    
    if minimizeResult != .success {
        print("❌ FAIL: Cannot minimize test window")
        return
    }
    
    print("✅ Minimized a Finder window for testing")
    Thread.sleep(forTimeInterval: 0.3)
    
    print("\n🔍 PHASE 2: Simulate WindowAI's window enumeration")
    print("==================================================")
    
    // Simulate WindowAI's getWindowsForApp method
    func simulateGetWindowsForApp(appName: String) -> [AXUIElement] {
        print("🔍 DEBUG: getWindowsForApp('\(appName)') called")
        
        // Find app by name (like WindowAI does)
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.localizedName?.lowercased() == appName.lowercased()
        }) else {
            print("❌ DEBUG: App not found by name")
            return []
        }
        
        print("✅ DEBUG: Found app by name")
        
        // Get windows
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsValue: CFTypeRef?
        let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        
        guard windowsResult == .success, let windows = windowsValue as? [AXUIElement] else {
            print("❌ DEBUG: Failed to get windows")
            return []
        }
        
        print("🔍 DEBUG: Raw window count: \(windows.count)")
        
        // Filter windows (like WindowAI might do)
        var validWindows: [AXUIElement] = []
        
        for (index, window) in windows.enumerated() {
            // Check if window has title (common filter)
            var titleValue: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
            
            // Check minimized status
            var minimizedValue: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
            let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
            
            print("🔍 DEBUG: Window \(index): title=\(titleResult == .success ? "✅" : "❌"), minimized=\(isMinimized)")
            
            // CRITICAL: Does WindowAI include minimized windows in the list?
            if titleResult == .success {
                validWindows.append(window)
                print("  ✅ Window \(index) INCLUDED in list")
            } else {
                print("  ❌ Window \(index) EXCLUDED from list")
            }
        }
        
        print("🔍 DEBUG: Final valid window count: \(validWindows.count)")
        return validWindows
    }
    
    let cascadeWindows = simulateGetWindowsForApp(appName: "Finder")
    print("📊 Windows available for cascade: \(cascadeWindows.count)")
    
    if cascadeWindows.isEmpty {
        print("❌ FAIL: No windows available for cascade")
        print("💡 PROBLEM: Window enumeration excludes minimized windows")
        return
    }
    
    print("\n🔍 PHASE 3: Check if minimized window is in cascade list")
    print("======================================================")
    
    var foundMinimizedWindow = false
    var minimizedWindowIndex = -1
    
    for (index, window) in cascadeWindows.enumerated() {
        var minimizedValue: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
        
        print("🔍 DEBUG: Cascade window \(index): minimized = \(isMinimized)")
        
        if isMinimized {
            foundMinimizedWindow = true
            minimizedWindowIndex = index
            print("✅ Found minimized window in cascade list at index \(index)")
        }
    }
    
    if !foundMinimizedWindow {
        print("❌ FAIL: Minimized window NOT found in cascade list")
        print("💡 PROBLEM: Window enumeration filters out minimized windows")
        return
    }
    
    print("\n🔍 PHASE 4: Simulate cascade positioning with unminimize")
    print("=======================================================")
    
    let minimizedWindow = cascadeWindows[minimizedWindowIndex]
    
    // Simulate WindowAI's isWindowMinimized check
    func simulateIsWindowMinimized(_ window: AXUIElement) -> Bool {
        var minimizedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        
        if result == .success, let minimized = minimizedValue as? Bool {
            print("🔍 DEBUG: isWindowMinimized() = \(minimized)")
            return minimized
        }
        print("🔍 DEBUG: isWindowMinimized() failed")
        return false
    }
    
    // Simulate WindowAI's restoreWindow
    func simulateRestoreWindow(_ window: AXUIElement) -> Bool {
        let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        print("🔍 DEBUG: restoreWindow() = \(result == .success)")
        return result == .success
    }
    
    print("🔄 Simulating cascade unminimize check...")
    
    if simulateIsWindowMinimized(minimizedWindow) {
        print("🔄 Window detected as minimized, attempting restore...")
        
        if simulateRestoreWindow(minimizedWindow) {
            print("✅ Restore call succeeded")
            Thread.sleep(forTimeInterval: 0.1)
            
            // Verify restoration
            if !simulateIsWindowMinimized(minimizedWindow) {
                print("✅ Window successfully unminimized")
            } else {
                print("❌ FAIL: Window still minimized after restore")
                return
            }
        } else {
            print("❌ FAIL: Restore call failed")
            return
        }
    } else {
        print("❌ FAIL: Window not detected as minimized")
        return
    }
    
    print("\n🔍 PHASE 5: Simulate actual positioning")
    print("======================================")
    
    // Simulate setting window bounds (what cascade actually does)
    let testBounds = CGRect(x: 100, y: 100, width: 400, height: 300)
    
    let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: testBounds.origin) { $0 })
    let sizeValue = AXValueCreate(.cgSize, withUnsafePointer(to: testBounds.size) { $0 })
    
    print("🔍 DEBUG: Setting position to \(testBounds.origin)")
    let posResult = AXUIElementSetAttributeValue(minimizedWindow, kAXPositionAttribute as CFString, positionValue!)
    print("🔍 DEBUG: Position result: \(posResult == .success ? "✅" : "❌")")
    
    print("🔍 DEBUG: Setting size to \(testBounds.size)")
    let sizeResult = AXUIElementSetAttributeValue(minimizedWindow, kAXSizeAttribute as CFString, sizeValue!)
    print("🔍 DEBUG: Size result: \(sizeResult == .success ? "✅" : "❌")")
    
    if posResult == .success && sizeResult == .success {
        print("✅ Window positioning succeeded")
        print("\n🎉 TEST RESULT: PASS")
        print("====================")
        print("✅ Complete cascade flow works with minimized windows")
        print("✅ Window enumeration includes minimized windows")
        print("✅ Unminimize detection and restoration works")
        print("✅ Window positioning works after unminimize")
    } else {
        print("❌ FAIL: Window positioning failed")
        return
    }
}

print("This comprehensive test simulates the COMPLETE cascade flow:")
print("1. Window enumeration (getWindowsForApp)")
print("2. Minimized window detection")
print("3. Unminimize logic")
print("4. Window positioning")
print("")
print("Expected result: FAIL at window enumeration or unminimize flow")
print("")

testCascadeUnminimizeFlow()

print("\n🔬 FAILURE ANALYSIS:")
print("====================")
print("If this test fails, it will show exactly where:")
print("- Window enumeration: Do minimized windows get included?")
print("- Detection timing: When is isWindowMinimized() called?")
print("- Restoration flow: Does the unminimize actually happen?")
print("- Positioning: Can we position windows after unminimize?")
print("")
print("This will pinpoint the exact failure point in the cascade flow.")