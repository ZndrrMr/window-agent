import Foundation
import ApplicationServices
import Cocoa

class PermissionManager {
    
    // MARK: - Accessibility Permissions
    static func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermissions() {
        // This will prompt the user if permissions aren't granted
        let _ = AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary)
    }
    
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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