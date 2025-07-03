#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🧪 ACTUAL VISIBILITY TEST")
print("=========================")
print("This test verifies windows are ACTUALLY visible, not just API success")
print("")

func testActualVisibility() {
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ FAIL: Finder app not found")
        return
    }
    
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
        print("❌ FAIL: No Finder windows found")
        return
    }
    
    let window = windows[0]
    
    print("🔍 PHASE 1: Check initial state")
    print("===============================")
    
    func checkWindowVisibility(_ window: AXUIElement) -> (minimized: Bool, onScreen: Bool, bounds: CGRect) {
        // Check minimized attribute
        var minimizedValue: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
        
        // Check actual bounds
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        var bounds = CGRect.zero
        if posResult == .success && sizeResult == .success {
            var position = CGPoint.zero
            var size = CGSize.zero
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
            bounds = CGRect(origin: position, size: size)
        }
        
        // Check if bounds are reasonable (not at weird coordinates)
        let onScreen = bounds.width > 10 && bounds.height > 10 && 
                      bounds.origin.x >= -100 && bounds.origin.y >= -100 &&
                      bounds.origin.x < 3000 && bounds.origin.y < 3000
        
        return (minimized: isMinimized, onScreen: onScreen, bounds: bounds)
    }
    
    let initialState = checkWindowVisibility(window)
    print("Initial state:")
    print("  Minimized attribute: \(initialState.minimized)")
    print("  Bounds: \(initialState.bounds)")
    print("  Appears on screen: \(initialState.onScreen)")
    
    if !initialState.minimized {
        print("\n🔧 PHASE 2: Force minimize to test restore")
        print("==========================================")
        
        let minimizeResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        print("Minimize API result: \(minimizeResult == .success ? "SUCCESS" : "FAILED")")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        let afterMinimize = checkWindowVisibility(window)
        print("After minimize:")
        print("  Minimized attribute: \(afterMinimize.minimized)")
        print("  Bounds: \(afterMinimize.bounds)")
        print("  Appears on screen: \(afterMinimize.onScreen)")
        
        if !afterMinimize.minimized {
            print("❌ FAIL: Window was not actually minimized")
            return
        }
    }
    
    print("\n🔧 PHASE 3: Test restore methods")
    print("=================================")
    
    // Method 1: Set minimized to false
    print("Method 1: AXMinimizedAttribute = false")
    let restoreResult1 = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
    print("  API result: \(restoreResult1 == .success ? "SUCCESS" : "FAILED")")
    
    Thread.sleep(forTimeInterval: 0.5)
    
    let afterRestore1 = checkWindowVisibility(window)
    print("  After restore:")
    print("    Minimized attribute: \(afterRestore1.minimized)")
    print("    Bounds: \(afterRestore1.bounds)")
    print("    Actually visible: \(afterRestore1.onScreen && !afterRestore1.minimized)")
    
    if afterRestore1.onScreen && !afterRestore1.minimized {
        print("✅ SUCCESS: Method 1 worked!")
        return
    }
    
    // Method 2: Try AXRaiseAction
    print("\nMethod 2: AXRaiseAction")
    let raiseResult = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    print("  API result: \(raiseResult == .success ? "SUCCESS" : "FAILED")")
    
    Thread.sleep(forTimeInterval: 0.5)
    
    let afterRaise = checkWindowVisibility(window)
    print("  After raise:")
    print("    Minimized attribute: \(afterRaise.minimized)")
    print("    Bounds: \(afterRaise.bounds)")
    print("    Actually visible: \(afterRaise.onScreen && !afterRaise.minimized)")
    
    if afterRaise.onScreen && !afterRaise.minimized {
        print("✅ SUCCESS: Method 2 worked!")
        return
    }
    
    // Method 3: Try focus + unminimize
    print("\nMethod 3: Focus app + unminimize")
    finderApp.activate()
    Thread.sleep(forTimeInterval: 0.2)
    
    let restoreResult3 = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
    print("  API result: \(restoreResult3 == .success ? "SUCCESS" : "FAILED")")
    
    Thread.sleep(forTimeInterval: 0.5)
    
    let afterRestore3 = checkWindowVisibility(window)
    print("  After focus + restore:")
    print("    Minimized attribute: \(afterRestore3.minimized)")
    print("    Bounds: \(afterRestore3.bounds)")
    print("    Actually visible: \(afterRestore3.onScreen && !afterRestore3.minimized)")
    
    if afterRestore3.onScreen && !afterRestore3.minimized {
        print("✅ SUCCESS: Method 3 worked!")
        return
    }
    
    print("\n❌ ALL METHODS FAILED")
    print("===================")
    print("The window API calls succeed but window remains invisible")
    print("This suggests:")
    print("1. macOS doesn't allow programmatic unminimize for Finder")
    print("2. Need different approach (app activation, dock click simulation, etc.)")
    print("3. May need to use AppleScript or other higher-level APIs")
}

testActualVisibility()

print("\n🔬 CONCLUSION:")
print("==============")
print("This test reveals whether the issue is:")
print("1. ✅ API calls fail - need different approach")
print("2. ❌ API calls succeed but window stays hidden - macOS restriction")
print("3. ⚠️ Need app activation or other steps first")