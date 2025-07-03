#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🔍 DEBUG MINIMIZED STATE")
print("========================")

func debugMinimizedState() {
    guard let finderApp = NSWorkspace.shared.runningApplications.first(where: { 
        $0.bundleIdentifier == "com.apple.finder" 
    }) else {
        print("❌ Finder not found")
        return
    }
    
    let appRef = AXUIElementCreateApplication(finderApp.processIdentifier)
    var windowsRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
    
    guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
        print("❌ No windows found")
        return
    }
    
    let window = windows[0]
    
    print("🔍 BEFORE MINIMIZE:")
    var beforeMinimizedValue: CFTypeRef?
    let beforeResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &beforeMinimizedValue)
    let beforeMinimized = (beforeResult == .success && (beforeMinimizedValue as? Bool) == true)
    print("  Minimized: \(beforeMinimized) (query result: \(beforeResult == .success ? "SUCCESS" : "FAILED"))")
    
    print("\n🔧 MINIMIZING WINDOW...")
    let minimizeResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    print("  Minimize result: \(minimizeResult == .success ? "SUCCESS" : "FAILED (\(minimizeResult.rawValue))")")
    
    if minimizeResult != .success {
        print("❌ Cannot test - minimize failed")
        return
    }
    
    print("\n⏳ WAITING 0.5 seconds...")
    Thread.sleep(forTimeInterval: 0.5)
    
    print("\n🔍 AFTER MINIMIZE:")
    var afterMinimizedValue: CFTypeRef?
    let afterResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &afterMinimizedValue)
    let afterMinimized = (afterResult == .success && (afterMinimizedValue as? Bool) == true)
    print("  Minimized: \(afterMinimized) (query result: \(afterResult == .success ? "SUCCESS" : "FAILED"))")
    
    // Also test title accessibility
    var titleValue: CFTypeRef?
    let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
    print("  Title query: \(titleResult == .success ? "SUCCESS" : "FAILED")")
    if titleResult == .success, let title = titleValue as? String {
        print("    Title: '\(title)'")
    }
    
    if afterMinimized {
        print("\n✅ MINIMIZED STATE DETECTED CORRECTLY")
        
        print("\n🔧 TESTING RESTORE...")
        let restoreResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        print("  Restore result: \(restoreResult == .success ? "SUCCESS" : "FAILED (\(restoreResult.rawValue))")")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        var finalMinimizedValue: CFTypeRef?
        let finalResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &finalMinimizedValue)
        let finalMinimized = (finalResult == .success && (finalMinimizedValue as? Bool) == true)
        print("  Final minimized: \(finalMinimized) (should be false)")
        
        if !finalMinimized {
            print("✅ RESTORE WORKED")
        } else {
            print("❌ RESTORE FAILED")
        }
    } else {
        print("❌ MINIMIZED STATE NOT DETECTED - THIS IS THE BUG!")
    }
}

debugMinimizedState()