#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🔍 MANUAL MINIMIZE TEST")
print("=======================")
print("")
print("1. Please MANUALLY minimize a Finder window now")
print("2. Press ENTER when done")

let _ = readLine()

func testManuallyMinimizedWindow() {
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ Finder not found")
        return
    }
    
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement] else {
        print("❌ No windows found")
        return
    }
    
    print("Found \(windows.count) Finder windows")
    
    var foundMinimized = false
    
    for (index, window) in windows.enumerated() {
        var minimizedValue: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        let isMinimized = (minimizedResult == .success && (minimizedValue as? Bool) == true)
        
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        let title = titleValue as? String ?? "No Title"
        
        print("Window \(index): minimized=\(isMinimized), title_accessible=\(titleResult == .success), title='\(title)'")
        
        if isMinimized {
            foundMinimized = true
            print("\n✅ Found manually minimized window!")
            
            print("Testing WindowAI's restore logic...")
            let restoreResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            print("Restore call result: \(restoreResult == .success ? "SUCCESS" : "FAILED")")
            
            if restoreResult == .success {
                Thread.sleep(forTimeInterval: 0.2)
                
                var afterRestoreValue: CFTypeRef?
                let afterRestoreResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &afterRestoreValue)
                let afterRestore = (afterRestoreResult == .success && (afterRestoreValue as? Bool) == true)
                
                print("After restore: minimized=\(afterRestore)")
                
                if !afterRestore {
                    print("✅ RESTORE WORKED! Window should now be visible")
                } else {
                    print("❌ RESTORE FAILED - window still minimized")
                }
            }
            break
        }
    }
    
    if !foundMinimized {
        print("❌ No minimized windows found. Please minimize a Finder window and try again.")
    }
}

testManuallyMinimizedWindow()