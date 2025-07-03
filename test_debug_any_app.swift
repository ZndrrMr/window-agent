#!/usr/bin/env swift

import Foundation
import ApplicationServices
import AppKit

print("🔍 DEBUG ANY APP MINIMIZE")
print("=========================")

func debugAnyAppMinimize() {
    print("Getting all running apps with windows...")
    
    let runningApps = NSWorkspace.shared.runningApplications.filter { app in
        guard let bundleId = app.bundleIdentifier else { return false }
        // Skip system apps that might have weird behavior
        return !bundleId.hasPrefix("com.apple.") || bundleId == "com.apple.finder"
    }
    
    for app in runningApps.prefix(5) { // Test first 5 apps
        guard let appName = app.localizedName else { continue }
        
        print("\n🔍 Testing app: \(appName)")
        
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            print("  ❌ No accessible windows")
            continue
        }
        
        print("  ✅ Found \(windows.count) windows")
        
        let window = windows[0]
        
        // Check current state
        var currentMinimizedValue: CFTypeRef?
        let currentResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &currentMinimizedValue)
        let currentMinimized = (currentResult == .success && (currentMinimizedValue as? Bool) == true)
        
        print("    Current minimized: \(currentMinimized)")
        
        if currentMinimized {
            print("    Already minimized, testing restore...")
            let restoreResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            print("    Restore result: \(restoreResult == .success ? "SUCCESS" : "FAILED")")
            Thread.sleep(forTimeInterval: 0.3)
            
            var afterRestoreValue: CFTypeRef?
            let afterRestoreResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &afterRestoreValue)
            let afterRestore = (afterRestoreResult == .success && (afterRestoreValue as? Bool) == true)
            print("    After restore: minimized=\(afterRestore)")
            
            if !afterRestore {
                print("    ✅ RESTORE WORKED for \(appName)")
                return
            }
        } else {
            print("    Testing minimize...")
            let minimizeResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
            print("    Minimize result: \(minimizeResult == .success ? "SUCCESS" : "FAILED")")
            
            if minimizeResult == .success {
                Thread.sleep(forTimeInterval: 0.3)
                
                var afterMinimizeValue: CFTypeRef?
                let afterMinimizeResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &afterMinimizeValue)
                let afterMinimize = (afterMinimizeResult == .success && (afterMinimizeValue as? Bool) == true)
                print("    After minimize: minimized=\(afterMinimize)")
                
                if afterMinimize {
                    print("    ✅ MINIMIZE WORKED for \(appName)")
                    
                    // Test restore
                    let restoreResult = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                    print("    Restore result: \(restoreResult == .success ? "SUCCESS" : "FAILED")")
                    Thread.sleep(forTimeInterval: 0.2)
                    
                    var finalValue: CFTypeRef?
                    let finalResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &finalValue)
                    let finalMinimized = (finalResult == .success && (finalValue as? Bool) == true)
                    print("    Final state: minimized=\(finalMinimized)")
                    
                    if !finalMinimized {
                        print("    ✅ FULL CYCLE WORKED for \(appName)")
                    }
                    return
                }
            }
        }
    }
    
    print("\n❌ No apps worked for minimize/restore cycle")
}

debugAnyAppMinimize()