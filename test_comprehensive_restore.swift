#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🧪 COMPREHENSIVE RESTORE TEST")
print("=============================")
print("This test does EXACTLY what WindowAI should do")
print("")

func testComprehensiveRestore() {
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ FAIL: Finder app not found")
        return
    }
    
    print("✅ Found Finder app (PID: \(finderApp.processIdentifier))")
    
    // Simulate exactly what WindowAI does: getWindowsForApp
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement] else {
        print("❌ FAIL: Cannot get windows")
        return
    }
    
    print("✅ Found \(windows.count) Finder windows")
    
    // Find minimized windows
    var minimizedWindows: [(index: Int, window: AXUIElement)] = []
    
    for (index, window) in windows.enumerated() {
        var minimizedValue: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
        
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        let title = titleValue as? String ?? "No Title"
        
        print("  Window \(index): '\(title)' - minimized: \(isMinimized)")
        
        if isMinimized {
            minimizedWindows.append((index: index, window: window))
        }
    }
    
    if minimizedWindows.isEmpty {
        print("⚠️ No minimized windows found - please minimize a Finder window first")
        return
    }
    
    print("\n🔧 RESTORING \(minimizedWindows.count) MINIMIZED WINDOW(S)")
    print("=============================================")
    
    for (_, minimizedWindow) in minimizedWindows {
        print("\n🔄 Processing minimized window...")
        
        // Step 1: Check current state
        func getWindowState(_ window: AXUIElement) -> (minimized: Bool, bounds: CGRect, title: String) {
            var minimizedValue: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
            let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
            
            var positionValue: CFTypeRef?
            var sizeValue: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
            
            var bounds = CGRect.zero
            if let pos = positionValue, let size = sizeValue {
                var position = CGPoint.zero
                var windowSize = CGSize.zero
                AXValueGetValue(pos as! AXValue, .cgPoint, &position)
                AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
                bounds = CGRect(origin: position, size: windowSize)
            }
            
            var titleValue: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
            let title = titleValue as? String ?? "Untitled"
            
            return (minimized: isMinimized, bounds: bounds, title: title)
        }
        
        let beforeState = getWindowState(minimizedWindow)
        print("  Before: minimized=\(beforeState.minimized), bounds=\(beforeState.bounds)")
        
        // Step 2: WindowAI's exact restore logic
        print("  🔄 Calling restoreWindow() equivalent...")
        let restoreResult = AXUIElementSetAttributeValue(minimizedWindow, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        print("  Restore API result: \(restoreResult == .success ? "✅ SUCCESS" : "❌ FAILED")")
        
        // Step 3: Add app activation (missing from WindowAI?)
        print("  🎯 Activating Finder app...")
        finderApp.activate()
        
        // Step 4: Add window focus (missing from WindowAI?)
        print("  🎯 Focusing window...")
        let focusResult = AXUIElementPerformAction(minimizedWindow, kAXRaiseAction as CFString)
        print("  Focus API result: \(focusResult == .success ? "✅ SUCCESS" : "❌ FAILED")")
        
        // Step 5: Wait for changes to take effect
        print("  ⏳ Waiting 1 second for changes...")
        Thread.sleep(forTimeInterval: 1.0)
        
        // Step 6: Verify final state
        let afterState = getWindowState(minimizedWindow)
        print("  After: minimized=\(afterState.minimized), bounds=\(afterState.bounds)")
        
        let isActuallyVisible = !afterState.minimized && 
                               afterState.bounds.width > 10 && 
                               afterState.bounds.height > 10
        
        print("  📊 RESULT: \(isActuallyVisible ? "✅ VISIBLE" : "❌ STILL HIDDEN")")
        
        if isActuallyVisible {
            print("  🎉 SUCCESS: Window '\(afterState.title)' is now visible!")
            
            // Test positioning to confirm it works
            print("  🧪 Testing positioning...")
            let testBounds = CGRect(x: 100, y: 100, width: 600, height: 400)
            
            let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: testBounds.origin) { $0 })
            let sizeValue = AXValueCreate(.cgSize, withUnsafePointer(to: testBounds.size) { $0 })
            
            let posResult = AXUIElementSetAttributeValue(minimizedWindow, kAXPositionAttribute as CFString, positionValue!)
            let sizeResult = AXUIElementSetAttributeValue(minimizedWindow, kAXSizeAttribute as CFString, sizeValue!)
            
            print("  Position result: \(posResult == .success ? "✅" : "❌")")
            print("  Size result: \(sizeResult == .success ? "✅" : "❌")")
            
            Thread.sleep(forTimeInterval: 0.5)
            
            let finalState = getWindowState(minimizedWindow)
            print("  Final bounds: \(finalState.bounds)")
            
            let correctPosition = abs(finalState.bounds.origin.x - 100) < 10 && 
                                 abs(finalState.bounds.origin.y - 100) < 10
            
            if correctPosition {
                print("  ✅ POSITIONING WORKS!")
                return
            } else {
                print("  ❌ POSITIONING FAILED")
            }
        } else {
            print("  ❌ FAILED: Window is still not visible")
        }
    }
    
    print("\n🔬 ANALYSIS:")
    print("============")
    print("If this test fails, WindowAI needs to:")
    print("1. ✅ Activate the app after restoring windows")
    print("2. ✅ Focus/raise the window after restoring")
    print("3. ✅ Add proper delays for macOS to process changes")
    print("4. ✅ Verify actual visibility, not just API success")
}

testComprehensiveRestore()