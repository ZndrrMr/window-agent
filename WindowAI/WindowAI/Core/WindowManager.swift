import Cocoa
import ApplicationServices

struct WindowInfo {
    let title: String
    let appName: String
    let bounds: CGRect
    let windowRef: AXUIElement
}

class WindowManager {
    static let shared = WindowManager()
    
    private init() {
        _ = checkAccessibilityPermissions()
    }
    
    // MARK: - Permission Management
    func checkAccessibilityPermissions() -> Bool {
        let isTrusted = AXIsProcessTrusted()
        // Removed verbose logging
        return isTrusted
    }
    
    func requestAccessibilityPermissions() {
        print("🔐 WindowManager: Requesting accessibility permissions...")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let result = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("🔐 WindowManager: Request result = \(result)")
    }
    
    // MARK: - Window Discovery
    func getAllWindows() -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        var windows: [WindowInfo] = []
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let bundleIdentifier = app.bundleIdentifier,
               !bundleIdentifier.contains("com.apple.dock"),
               !bundleIdentifier.contains("com.apple.systemuiserver") {
                let appWindows = getWindowsForApp(pid: app.processIdentifier)
                windows.append(contentsOf: appWindows)
            }
        }
        
        return windows
    }
    
    func getWindowsForApp(named appName: String) -> [WindowInfo] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.localizedName?.lowercased() == appName.lowercased() 
        }) else {
            return []
        }
        
        return getWindowsForApp(pid: app.processIdentifier)
    }
    
    private func getWindowsForApp(pid: pid_t) -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        let appRef = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success {
            return []
        }
        
        guard let windows = windowsRef as? [AXUIElement] else {
            return []
        }
        
        var windowInfos: [WindowInfo] = []
        
        for window in windows {
            if let windowInfo = createWindowInfo(from: window, appPID: pid) {
                windowInfos.append(windowInfo)
            }
        }
        
        return windowInfos
    }
    
    private func createWindowInfo(from window: AXUIElement, appPID: pid_t) -> WindowInfo? {
        var titleRef: CFTypeRef?
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        // Get window title
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String ?? "Untitled"
        
        // Get window position
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        var position = CGPoint.zero
        if let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        
        // Get window size
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var size = CGSize.zero
        if let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        // Get app name
        let appName = NSRunningApplication(processIdentifier: appPID)?.localizedName ?? "Unknown App"
        
        let bounds = CGRect(origin: position, size: size)
        return WindowInfo(title: title, appName: appName, bounds: bounds, windowRef: window)
    }
    
    func getFrontmostWindow() -> WindowInfo? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let windows = getWindowsForApp(pid: frontmostApp.processIdentifier)
        return windows.first // Usually the first window is the frontmost
    }
    
    // MARK: - Window Manipulation
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        guard checkAccessibilityPermissions() else { 
            print("❌ moveWindow: No accessibility permissions")
            return false 
        }
        
        print("🚀 moveWindow: Moving '\(windowInfo.title)' to position \(position)")
        let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: position) { $0 })
        let result = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXPositionAttribute as CFString, positionValue!)
        
        if result == .success {
            print("✅ moveWindow: Successfully moved window")
        } else {
            print("❌ moveWindow: Failed with error code: \(result.rawValue)")
        }
        
        return result == .success
    }
    
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Validate size against app constraints
        let bundleID = getBundleID(for: windowInfo.appName) ?? ""
        let validatedSize = AppConstraintsManager.shared.validateWindowSize(size, for: bundleID)
        
        let sizeValue = AXValueCreate(.cgSize, withUnsafePointer(to: validatedSize) { $0 })
        let result = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXSizeAttribute as CFString, sizeValue!)
        return result == .success
    }
    
    func setWindowBounds(_ windowInfo: WindowInfo, bounds: CGRect, validate: Bool = true) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Validate bounds against app constraints and screen bounds (unless disabled)
        let finalBounds = validate ? validateWindowBounds(bounds, for: windowInfo.appName) : bounds
        
        let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: finalBounds.origin) { $0 })
        let sizeValue = AXValueCreate(.cgSize, withUnsafePointer(to: finalBounds.size) { $0 })
        
        let positionResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXPositionAttribute as CFString, positionValue!)
        let sizeResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXSizeAttribute as CFString, sizeValue!)
        
        return positionResult == .success && sizeResult == .success
    }
    
    func focusWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // First make the window the main window
        let mainResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXMainAttribute as CFString, kCFBooleanTrue)
        
        // Then raise the window
        let raiseResult = AXUIElementPerformAction(windowInfo.windowRef, kAXRaiseAction as CFString)
        
        // Also bring the app to front
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: getBundleID(for: windowInfo.appName) ?? "").first {
            app.activate()
        }
        
        return mainResult == .success && raiseResult == .success
    }
    
    func minimizeWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        let result = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        return result == .success
    }
    
    func maximizeWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Get screen bounds for the display this window is on
        let screenBounds = getScreenBounds(for: windowInfo.bounds.origin)
        
        // Apply some padding for menu bar and dock
        let menuBarHeight: CGFloat = 25
        let dockHeight: CGFloat = 80
        let padding: CGFloat = 10
        
        let maxBounds = CGRect(
            x: screenBounds.origin.x + padding,
            y: screenBounds.origin.y + menuBarHeight,
            width: screenBounds.width - (padding * 2),
            height: screenBounds.height - menuBarHeight - dockHeight - padding
        )
        
        return setWindowBounds(windowInfo, bounds: maxBounds)
    }
    
    func closeWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Try to close the window using the close button action
        let closeResult = AXUIElementPerformAction(windowInfo.windowRef, kAXPressAction as CFString)
        
        if closeResult != .success {
            // If that fails, try to close via the close button subelement
            var closeButtonRef: CFTypeRef?
            let buttonResult = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXCloseButtonAttribute as CFString, &closeButtonRef)
            
            if buttonResult == .success, let closeButton = closeButtonRef as! AXUIElement? {
                let pressResult = AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
                return pressResult == .success
            }
        }
        
        return closeResult == .success
    }
    
    func quitApp(_ appName: String) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Find the app and quit it
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: getBundleID(for: appName) ?? "").first {
            return app.terminate()
        }
        
        // Try by localized name if bundle ID didn't work
        if let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.localizedName?.lowercased() == appName.lowercased() 
        }) {
            return app.terminate()
        }
        
        return false
    }
    
    func restoreWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Check if window is minimized
        var isMinimized: CFTypeRef?
        let minResult = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &isMinimized)
        
        if minResult == .success, let minimized = isMinimized as? Bool, minimized {
            // Unminimize the window
            let result = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            return result == .success
        }
        
        // If not minimized, bring it to front
        return focusWindow(windowInfo)
    }
    
    // MARK: - Screen Information
    func getScreenBounds() -> CGRect {
        guard let mainScreen = NSScreen.main else {
            return .zero
        }
        return mainScreen.frame
    }
    
    func getAllScreenBounds() -> [CGRect] {
        return NSScreen.screens.map { $0.frame }
    }
    
    func getScreenBounds(for point: CGPoint) -> CGRect {
        // Find which screen contains this point
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen.frame
            }
        }
        // Default to main screen if point not found
        return getScreenBounds()
    }
    
    func getVisibleScreenBounds(for point: CGPoint) -> CGRect {
        // Get screen bounds minus menu bar and dock
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen.visibleFrame
            }
        }
        return NSScreen.main?.visibleFrame ?? .zero
    }
    
    // MARK: - Display Information
    func getDisplayCount() -> Int {
        return NSScreen.screens.count
    }
    
    func getDisplayInfo(at index: Int) -> DisplayInfo? {
        let screens = NSScreen.screens
        guard index >= 0 && index < screens.count else { return nil }
        
        let screen = screens[index]
        let isMain = screen == NSScreen.main
        
        return DisplayInfo(
            index: index,
            name: screen.localizedName,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            isMain: isMain,
            backingScaleFactor: screen.backingScaleFactor
        )
    }
    
    func getAllDisplayInfo() -> [DisplayInfo] {
        return NSScreen.screens.enumerated().map { index, screen in
            DisplayInfo(
                index: index,
                name: screen.localizedName,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                isMain: screen == NSScreen.main,
                backingScaleFactor: screen.backingScaleFactor
            )
        }
    }
    
    func getDisplayForWindow(_ windowInfo: WindowInfo) -> Int {
        let windowCenter = CGPoint(
            x: windowInfo.bounds.midX,
            y: windowInfo.bounds.midY
        )
        
        for (index, screen) in NSScreen.screens.enumerated() {
            if screen.frame.contains(windowCenter) {
                return index
            }
        }
        
        // Default to main display if not found
        return 0
    }
    
    func getWindowsOnDisplay(_ displayIndex: Int) -> [WindowInfo] {
        let allWindows = getAllWindows()
        guard displayIndex >= 0 && displayIndex < NSScreen.screens.count else {
            return []
        }
        
        let displayBounds = NSScreen.screens[displayIndex].frame
        
        return allWindows.filter { window in
            let windowCenter = CGPoint(
                x: window.bounds.midX,
                y: window.bounds.midY
            )
            return displayBounds.contains(windowCenter)
        }
    }
}

// MARK: - Display Info Structure
struct DisplayInfo {
    let index: Int
    let name: String
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let backingScaleFactor: CGFloat
}

// MARK: - Helper Extensions
extension WindowManager {
    func getWindowAtPosition(_ position: CGPoint) -> WindowInfo? {
        let allWindows = getAllWindows()
        
        // Find the topmost window at this position
        for window in allWindows {
            if window.bounds.contains(position) {
                return window
            }
        }
        
        return nil
    }
    
    func isWindowVisible(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        var isMinimized: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &isMinimized)
        
        if result == .success, let minimized = isMinimized as? Bool {
            return !minimized
        }
        
        return true // Assume visible if we can't determine
    }
    
    private func getBundleID(for appName: String) -> String? {
        return NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.lowercased() == appName.lowercased()
        }?.bundleIdentifier
    }
    
    private func validateWindowBounds(_ bounds: CGRect, for appName: String) -> CGRect {
        let bundleID = getBundleID(for: appName) ?? ""
        let validatedSize = AppConstraintsManager.shared.validateWindowSize(bounds.size, for: bundleID)
        
        // Ensure window stays within screen bounds
        let screenBounds = getVisibleScreenBounds(for: bounds.origin)
        
        var validatedBounds = bounds
        validatedBounds.size = validatedSize
        
        // Clamp position to screen bounds
        validatedBounds.origin.x = max(screenBounds.minX, min(screenBounds.maxX - validatedBounds.width, validatedBounds.origin.x))
        validatedBounds.origin.y = max(screenBounds.minY, min(screenBounds.maxY - validatedBounds.height, validatedBounds.origin.y))
        
        return validatedBounds
    }
}