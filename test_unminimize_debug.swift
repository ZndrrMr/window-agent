#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🧪 UNMINIMIZE DEBUG TEST")
print("========================")

// This test will programmatically minimize a Finder window, then test our unminimize logic
// It should FAIL with current implementation to show what's broken

func testUnminimizeLogic() {
    print("\n🔍 STEP 1: Finding Finder windows...")
    
    // Get Finder app
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ FAIL: Finder app not found")
        return
    }
    
    print("✅ Found Finder app (PID: \(finderApp.processIdentifier))")
    
    // Get Finder windows using same method as WindowAI
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
        print("❌ FAIL: No Finder windows found (error: \(result.rawValue))")
        print("💡 Open a Finder window first")
        return
    }
    
    print("✅ Found \(windows.count) Finder window(s)")
    
    // Use first window for test
    let testWindow = windows[0]
    
    print("\n🔍 STEP 2: Getting initial window state...")
    
    // Check initial minimized state
    var initialMinimizedValue: CFTypeRef?
    let initialResult = AXUIElementCopyAttributeValue(testWindow, kAXMinimizedAttribute as CFString, &initialMinimizedValue)
    
    guard initialResult == .success, let initialMinimized = initialMinimizedValue as? Bool else {
        print("❌ FAIL: Cannot read minimized attribute (error: \(initialResult.rawValue))")
        return
    }
    
    print("📊 Initial state: minimized = \(initialMinimized)")
    
    print("\n🔍 STEP 3: Force minimizing the window...")
    
    // Force minimize the window
    let minimizeResult = AXUIElementSetAttributeValue(testWindow, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    
    if minimizeResult != .success {
        print("❌ FAIL: Cannot minimize window (error: \(minimizeResult.rawValue))")
        return
    }
    
    print("✅ Forced window to minimized state")
    
    // Brief delay for state change
    Thread.sleep(forTimeInterval: 0.2)
    
    print("\n🔍 STEP 4: Verify window is now minimized...")
    
    // Verify it's minimized
    var postMinimizeValue: CFTypeRef?
    let postMinimizeResult = AXUIElementCopyAttributeValue(testWindow, kAXMinimizedAttribute as CFString, &postMinimizeValue)
    
    guard postMinimizeResult == .success, let postMinimized = postMinimizeValue as? Bool else {
        print("❌ FAIL: Cannot verify minimized state (error: \(postMinimizeResult.rawValue))")
        return
    }
    
    print("📊 After minimize: minimized = \(postMinimized)")
    
    if !postMinimized {
        print("❌ FAIL: Window was not actually minimized")
        return
    }
    
    print("✅ Window is confirmed minimized")
    
    print("\n🔍 STEP 5: Testing WindowAI's isWindowMinimized logic...")
    
    // Simulate WindowAI's isWindowMinimized method
    func testIsWindowMinimized(_ window: AXUIElement) -> Bool {
        var minimizedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        
        if result == .success, let minimized = minimizedValue as? Bool {
            print("🔍 DEBUG: isWindowMinimized() - AX call success, minimized = \(minimized)")
            return minimized
        }
        print("🔍 DEBUG: isWindowMinimized() - AX call failed (error: \(result.rawValue))")
        return false
    }
    
    let detectedMinimized = testIsWindowMinimized(testWindow)
    print("📊 WindowAI detection result: \(detectedMinimized)")
    
    if !detectedMinimized {
        print("❌ FAIL: WindowAI's isWindowMinimized() does not detect minimized window")
        return
    }
    
    print("✅ WindowAI correctly detects minimized window")
    
    print("\n🔍 STEP 6: Testing WindowAI's restoreWindow logic...")
    
    // Simulate WindowAI's restoreWindow method
    func testRestoreWindow(_ window: AXUIElement) -> Bool {
        let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        print("🔍 DEBUG: restoreWindow() - AX call result: \(result == .success ? "SUCCESS" : "FAILED (\(result.rawValue))")")
        return result == .success
    }
    
    let restoreSuccess = testRestoreWindow(testWindow)
    print("📊 WindowAI restore result: \(restoreSuccess)")
    
    if !restoreSuccess {
        print("❌ FAIL: WindowAI's restoreWindow() failed")
        return
    }
    
    print("✅ WindowAI restore call succeeded")
    
    print("\n🔍 STEP 7: Verifying window is actually restored...")
    
    // Wait for restore to take effect
    Thread.sleep(forTimeInterval: 0.2)
    
    // Check final state
    var finalMinimizedValue: CFTypeRef?
    let finalResult = AXUIElementCopyAttributeValue(testWindow, kAXMinimizedAttribute as CFString, &finalMinimizedValue)
    
    guard finalResult == .success, let finalMinimized = finalMinimizedValue as? Bool else {
        print("❌ FAIL: Cannot verify final state (error: \(finalResult.rawValue))")
        return
    }
    
    print("📊 Final state: minimized = \(finalMinimized)")
    
    if finalMinimized {
        print("❌ FAIL: Window is still minimized after restore attempt")
        return
    }
    
    print("✅ Window is now restored")
    
    print("\n🎉 TEST RESULT: PASS")
    print("====================")
    print("✅ WindowAI's unminimize logic works correctly")
    print("✅ Detection works: isWindowMinimized() = true")
    print("✅ Restoration works: restoreWindow() = true") 
    print("✅ Verification works: final minimized = false")
}

print("This test will:")
print("1. Find a Finder window")
print("2. Force it to minimized state")
print("3. Test WindowAI's isWindowMinimized() detection")
print("4. Test WindowAI's restoreWindow() restoration")
print("5. Verify the window is actually unminimized")
print("")
print("Expected result with current broken implementation: FAIL")
print("Expected result after fixing: PASS")
print("")

testUnminimizeLogic()

print("\n🔬 ANALYSIS:")
print("============")
print("If this test FAILS, it will show exactly where the unminimize logic breaks:")
print("- Detection failure: isWindowMinimized() returns false for minimized window")
print("- Restoration failure: restoreWindow() returns false or doesn't actually restore")
print("- Timing failure: restore call succeeds but window stays minimized")
print("")
print("If this test PASSES, then the issue is elsewhere (window enumeration, cascade logic, etc.)")