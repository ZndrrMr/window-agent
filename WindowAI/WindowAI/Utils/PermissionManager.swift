import Foundation
import ApplicationServices
import Cocoa

class PermissionManager: ObservableObject {
    
    // Store the active trust state of the app
    @Published var isTrusted: Bool = AXIsProcessTrusted()
    
    // MARK: - Accessibility Permissions
    static func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    // Poll the accessibility state every 1 second to check and update the trust status
    func pollAccessibilityPrivileges() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTrusted = AXIsProcessTrusted()
            
            if !self.isTrusted {
                self.pollAccessibilityPrivileges()
            }
        }
    }
    
    // Request accessibility permissions - this should prompt macOS to open
    // and present the required dialogue to the correct page for the user
    static func acquireAccessibilityPrivileges() {
        // First check if we already have permissions
        if AXIsProcessTrusted() {
            print("✅ Already have accessibility permissions")
            return
        }
        
        // Force the prompt to appear by trying to access something that requires permissions
        print("🔐 Triggering accessibility permission prompt...")
        
        // Method 1: Use the official API with correct types
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let enabled = AXIsProcessTrustedWithOptions(options)
        
        // Method 2: If that didn't work, try to access something that REQUIRES permissions
        if !enabled {
            // This will definitely trigger the prompt if Method 1 didn't
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let systemWideElement = AXUIElementCreateSystemWide()
                var focusedApp: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(
                    systemWideElement,
                    kAXFocusedApplicationAttribute as CFString,
                    &focusedApp
                )
                
                if result != .success {
                    print("⏳ Permission prompt should appear now!")
                }
            }
        }
        
        if enabled {
            print("✅ Accessibility permissions granted!")
        } else {
            print("⏳ Waiting for user to grant permissions...")
            print("📋 Please:")
            print("1. Look for the accessibility permission dialog")
            print("2. Click 'Open System Settings' when it appears")
            print("3. Enable WindowAI in the Accessibility list")
        }
    }
    
    static func requestAccessibilityPermissions() {
        acquireAccessibilityPrivileges()
    }
    
    static func openAccessibilitySettings() {
        // Try modern macOS 13+ format first
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension") {
            if NSWorkspace.shared.open(url) {
                return
            }
        }
        
        // Fall back to older format
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Screen Recording Permissions (if needed for screenshots)
    static func hasScreenRecordingPermissions() -> Bool {
        // TODO: Implement screen recording permission check
        // This would be needed if you want to take screenshots of windows
        return false
    }
    
    static func requestScreenRecordingPermissions() {
        // TODO: Implement screen recording permission request
    }
    
    // MARK: - Automation Permissions
    static func hasAutomationPermissions(for bundleIdentifier: String) -> Bool {
        // TODO: Check if we have permission to control specific apps
        return false
    }
    
    static func requestAutomationPermissions(for bundleIdentifier: String) {
        // TODO: Request permission to control specific apps
    }
    
    // MARK: - Helper Methods
    static func checkAllPermissions() -> PermissionStatus {
        var status = PermissionStatus()
        
        status.accessibility = hasAccessibilityPermissions()
        status.screenRecording = hasScreenRecordingPermissions()
        
        return status
    }
    
    static func requestAllNecessaryPermissions() {
        if !hasAccessibilityPermissions() {
            requestAccessibilityPermissions()
        }
    }
}

// MARK: - Permission Status
struct PermissionStatus {
    var accessibility: Bool = false
    var screenRecording: Bool = false
    var automation: [String: Bool] = [:]
    
    var allGranted: Bool {
        return accessibility // Add other permissions as needed
    }
    
    var hasMinimumPermissions: Bool {
        return accessibility // Accessibility is the minimum required
    }
}