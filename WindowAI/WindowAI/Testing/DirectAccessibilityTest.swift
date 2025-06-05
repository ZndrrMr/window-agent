import Foundation
import Cocoa
import ApplicationServices

class DirectAccessibilityTest {
    
    static func runDetailedTest() {
        print("\n🔬 DIRECT ACCESSIBILITY API TEST")
        print("=====================================")
        
        // Test 1: Basic trust check
        let trusted = AXIsProcessTrusted()
        print("✅ AXIsProcessTrusted: \(trusted)")
        
        if !trusted {
            print("❌ Not trusted! Requesting permissions...")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        // Test 2: Get system-wide element
        print("\n🔍 Testing System-Wide Element...")
        let systemWide = AXUIElementCreateSystemWide()
        var focusedAppRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppRef)
        
        if focusResult == .success, let focusedApp = focusedAppRef {
            print("✅ Got focused application")
            
            // Get app name
            var appNameRef: CFTypeRef?
            AXUIElementCopyAttributeValue(focusedApp as! AXUIElement, kAXTitleAttribute as CFString, &appNameRef)
            if let appName = appNameRef as? String {
                print("   App name: \(appName)")
            }
        } else {
            print("❌ Failed to get focused application: \(describeError(focusResult))")
        }
        
        // Test 3: Try to find and move a specific app window
        print("\n🎯 Looking for moveable windows...")
        
        // Get all running apps
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            app.activationPolicy == .regular && app.processIdentifier != -1
        }
        
        print("📱 Found \(runningApps.count) regular apps")
        
        // Try each app until we find one with windows
        for app in runningApps {
            guard let appName = app.localizedName else { continue }
            
            // Skip system apps
            if ["Dock", "Finder", "WindowServer"].contains(appName) { continue }
            
            print("\n🔍 Checking \(appName) (PID: \(app.processIdentifier))...")
            
            // Create AX element for this app
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            
            // Get windows attribute
            var windowsRef: CFTypeRef?
            let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
            
            if windowsResult == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty {
                print("✅ Found \(windows.count) window(s) for \(appName)")
                
                // Try to move the first window
                if let firstWindow = windows.first {
                    print("🎯 Attempting to move first window...")
                    
                    // Get current position
                    var positionRef: CFTypeRef?
                    var sizeRef: CFTypeRef?
                    
                    AXUIElementCopyAttributeValue(firstWindow, kAXPositionAttribute as CFString, &positionRef)
                    AXUIElementCopyAttributeValue(firstWindow, kAXSizeAttribute as CFString, &sizeRef)
                    
                    var currentPosition = CGPoint.zero
                    var currentSize = CGSize.zero
                    
                    if let posValue = positionRef {
                        AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPosition)
                    }
                    if let sizeValue = sizeRef {
                        AXValueGetValue(sizeValue as! AXValue, .cgSize, &currentSize)
                    }
                    
                    print("📍 Current position: \(currentPosition)")
                    print("📐 Current size: \(currentSize)")
                    
                    // Try to move to left half of screen
                    let screen = NSScreen.main!
                    let newPosition = CGPoint(x: screen.frame.minX, y: screen.frame.minY + 25) // Account for menu bar
                    let newSize = CGSize(width: screen.frame.width / 2, height: screen.frame.height - 100)
                    
                    print("🎯 Moving to: \(newPosition) with size: \(newSize)")
                    
                    // Create new values
                    var targetPosition = newPosition
                    var targetSize = newSize
                    let posValue = AXValueCreate(.cgPoint, &targetPosition)!
                    let sizeValue = AXValueCreate(.cgSize, &targetSize)!
                    
                    // Set position
                    let posResult = AXUIElementSetAttributeValue(firstWindow, kAXPositionAttribute as CFString, posValue)
                    print("📍 Position set result: \(describeError(posResult))")
                    
                    // Set size
                    let sizeResult = AXUIElementSetAttributeValue(firstWindow, kAXSizeAttribute as CFString, sizeValue)
                    print("📐 Size set result: \(describeError(sizeResult))")
                    
                    if posResult == .success && sizeResult == .success {
                        print("✅ Successfully moved \(appName) window!")
                        
                        // Verify the move
                        Thread.sleep(forTimeInterval: 0.5)
                        
                        var newPosRef: CFTypeRef?
                        AXUIElementCopyAttributeValue(firstWindow, kAXPositionAttribute as CFString, &newPosRef)
                        
                        var verifiedPosition = CGPoint.zero
                        if let verifyPos = newPosRef {
                            AXValueGetValue(verifyPos as! AXValue, .cgPoint, &verifiedPosition)
                            print("✅ Verified new position: \(verifiedPosition)")
                        }
                        
                        return // Success! Exit the test
                    }
                }
            } else if windowsResult != .success {
                print("❌ Failed to get windows: \(describeError(windowsResult))")
            } else {
                print("⚠️ No windows found for \(appName)")
            }
        }
        
        print("\n❌ Could not find any moveable windows!")
        print("💡 Make sure you have at least one app window open")
    }
    
    private static func describeError(_ error: AXError) -> String {
        switch error {
        case .success: return "Success"
        case .actionUnsupported: return "Action Unsupported"
        case .apiDisabled: return "API Disabled"
        case .attributeUnsupported: return "Attribute Unsupported"
        case .cannotComplete: return "Cannot Complete"
        case .failure: return "Failure"
        case .illegalArgument: return "Illegal Argument"
        case .invalidUIElement: return "Invalid UI Element"
        case .invalidUIElementObserver: return "Invalid UI Element Observer"
        case .noValue: return "No Value"
        case .notEnoughPrecision: return "Not Enough Precision"
        case .notImplemented: return "Not Implemented"
        case .notificationAlreadyRegistered: return "Notification Already Registered"
        case .notificationNotRegistered: return "Notification Not Registered"
        case .notificationUnsupported: return "Notification Unsupported"
        case .parameterizedAttributeUnsupported: return "Parameterized Attribute Unsupported"
        @unknown default: return "Unknown Error (\(error.rawValue))"
        }
    }
}