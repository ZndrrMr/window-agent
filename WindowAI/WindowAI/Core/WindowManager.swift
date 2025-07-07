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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let result = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Window Discovery
    func getAllWindows() -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        var windows: [WindowInfo] = []
        
        // Known problematic apps that should be skipped or have shorter timeouts
        let problematicApps = [
            "com.apple.dock",
            "com.apple.systemuiserver", 
            "com.apple.windowserver",
            "com.apple.loginwindow",
            "com.apple.CoreSimulator.SimulatorTrampoline",
            "com.docker.docker",
            "com.apple.ActivityMonitor"
        ]
        
        let relevantApps = runningApps.filter { app in
            guard let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName else { return false }
            
            return !problematicApps.contains(bundleId) && 
                   app.activationPolicy == .regular
        }
        
        
        for app in relevantApps {
            // Use timeout for each app to prevent hanging
            let appWindows = getWindowsForAppWithTimeout(pid: app.processIdentifier, timeout: 2.0)
            windows.append(contentsOf: appWindows)
        }
        
        return windows
    }
    
    // MARK: - Fast Window Discovery (Optimized Performance)
    func getAllWindowsFast() -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Aggressive filtering - only include apps likely to have manageable windows
        let fastFilteredApps = runningApps.filter { app in
            guard let bundleId = app.bundleIdentifier,
                  app.activationPolicy == .regular else { return false }
            
            // Skip known problematic apps
            let skipApps = [
                "com.apple.dock", "com.apple.systemuiserver", "com.apple.windowserver",
                "com.apple.loginwindow", "com.apple.ActivityMonitor", "com.docker.docker",
                "com.apple.CoreSimulator.SimulatorTrampoline", "com.apple.screensaver.engine"
            ]
            
            if skipApps.contains(bundleId) { return false }
            
            // Skip apps without localized names (likely system processes)
            guard app.localizedName != nil else { return false }
            
            return true
        }
        
        var windows: [WindowInfo] = []
        var processedApps = 0
        
        // Process with aggressive timeout per app
        for app in fastFilteredApps.prefix(15) { // Limit to 15 apps max
            let appWindows = getWindowsForAppFast(pid: app.processIdentifier)
            windows.append(contentsOf: appWindows)
            processedApps += 1
            
            // Break early if we already have lots of windows
            if windows.count > 50 {
                break
            }
        }
        
        return windows
    }
    
    func getWindowsForAppFast(pid: pid_t) -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { return [] }
        
        let appRef = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        
        // Very short timeout for getting windows list
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success { return [] }
        
        guard let windows = windowsRef as? [AXUIElement] else { return [] }
        
        var windowInfos: [WindowInfo] = []
        
        // Process only first 10 windows per app to avoid hanging
        for window in windows.prefix(10) {
            if let windowInfo = createWindowInfoFast(from: window, appPID: pid) {
                windowInfos.append(windowInfo)
            }
        }
        
        return windowInfos
    }
    
    private func createWindowInfoFast(from window: AXUIElement, appPID: pid_t) -> WindowInfo? {
        var titleRef: CFTypeRef?
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        // Get only essential properties, skip slow ones
        _ = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String ?? "Untitled"
        
        // Try to get position/size but don't wait long
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        var position = CGPoint.zero
        if let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var size = CGSize.zero
        if let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        // Cache app name lookup
        let appName = NSRunningApplication(processIdentifier: appPID)?.localizedName ?? "Unknown App"
        
        let bounds = CGRect(origin: position, size: size)
        
        return WindowInfo(title: title, appName: appName, bounds: bounds, windowRef: window)
    }
    
    // MARK: - Async Parallel Window Discovery
    func getAllWindowsAsync() async -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        let relevantApps = getRelevantApps()
        
        // Parallel app scanning with concurrency limits
        return await withTaskGroup(of: [WindowInfo].self, returning: [WindowInfo].self) { group in
            for app in relevantApps {
                group.addTask { 
                    await self.getWindowsForAppAsync(pid: app.processIdentifier)
                }
            }
            
            // Collect all results
            var allWindows: [WindowInfo] = []
            for await windows in group {
                allWindows.append(contentsOf: windows)
            }
            return allWindows
        }
    }
    
    private func getRelevantApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter { app in
            guard let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName else { return false }
            
            // Skip WindowAI itself to prevent recursion and performance issues
            if bundleId == "com.zandermodaress.WindowAI" {
                return false
            }
            
            // Skip true system apps, but allow user-manageable Apple apps
            let allowedAppleApps = [
                "com.apple.Terminal",
                "com.apple.TextEdit", 
                "com.apple.Preview",
                "com.apple.QuickTimePlayerX",
                "com.apple.Calculator",
                "com.apple.Notes",
                "com.apple.Music",
                "com.apple.TV",
                "com.apple.Photos",
                "com.apple.Maps",
                "com.apple.Calendar",
                "com.apple.Contacts",
                "com.apple.Mail",
                "com.apple.FaceTime",
                "com.apple.Messages"
            ]
            
            let isSystemApp = bundleId.hasPrefix("com.apple.") && !allowedAppleApps.contains(bundleId)
            let isBackgroundProcess = !["Dock", "Finder", "SystemUIServer", "WindowServer"].contains(appName) &&
                                    !bundleId.contains("com.apple.dock") &&
                                    !bundleId.contains("com.apple.systemuiserver")
            
            return app.activationPolicy == .regular &&
                   !isSystemApp &&
                   isBackgroundProcess
        }
        .prefix(20) // Increased limit to accommodate more Apple apps
        .map { $0 }
    }
    
    private func getWindowsForAppAsync(pid: pid_t) async -> [WindowInfo] {
        // Add timeout per app to prevent hanging
        return await withTimeout(seconds: 2.0) {
            await self.getWindowsForAppUnsafe(pid: pid)
        } ?? []
    }
    
    private func getWindowsForAppUnsafe(pid: pid_t) async -> [WindowInfo] {
        guard checkAccessibilityPermissions() else { 
            return [] 
        }
        
        // Get window references first (sequential for AX app reference)
        let windowRefs = getWindowReferences(pid: pid)
        
        // Parallel property gathering for all windows in this app
        return await withTaskGroup(of: WindowInfo?.self, returning: [WindowInfo].self) { group in
            for windowRef in windowRefs {
                group.addTask {
                    await self.createWindowInfoAsync(from: windowRef, appPID: pid)
                }
            }
            
            var windows: [WindowInfo] = []
            for await window in group {
                if let window = window {
                    windows.append(window)
                }
            }
            return windows
        }
    }
    
    private func getWindowReferences(pid: pid_t) -> [AXUIElement] {
        let appRef = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success {
            return []
        }
        
        return (windowsRef as? [AXUIElement]) ?? []
    }
    
    private func createWindowInfoAsync(from window: AXUIElement, appPID: pid_t) async -> WindowInfo? {
        // Gather all properties in parallel
        async let title = getWindowTitleAsync(window)
        async let position = getWindowPositionAsync(window) 
        async let size = getWindowSizeAsync(window)
        async let isMinimized = getWindowMinimizedAsync(window)
        async let appName = getAppNameAsync(appPID)
        
        // Wait for all to complete
        let (finalTitle, finalPosition, finalSize, minimized, finalAppName) = await (title, position, size, isMinimized, appName)
        
        let bounds = CGRect(
            origin: finalPosition ?? CGPoint.zero, 
            size: finalSize ?? CGSize.zero
        )
        
        return WindowInfo(
            title: finalTitle ?? (minimized ? "Minimized Window" : "Untitled"),
            appName: finalAppName ?? "Unknown App",
            bounds: bounds,
            windowRef: window
        )
    }
    
    // MARK: - Async Property Getters
    private func getWindowTitleAsync(_ window: AXUIElement) async -> String? {
        return await withCheckedContinuation { continuation in
            var titleRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            let title = (result == .success) ? (titleRef as? String) : nil
            continuation.resume(returning: title)
        }
    }
    
    private func getWindowPositionAsync(_ window: AXUIElement) async -> CGPoint? {
        return await withCheckedContinuation { continuation in
            var positionRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
            
            if result == .success, let positionValue = positionRef {
                var position = CGPoint.zero
                AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
                continuation.resume(returning: position)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func getWindowSizeAsync(_ window: AXUIElement) async -> CGSize? {
        return await withCheckedContinuation { continuation in
            var sizeRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
            
            if result == .success, let sizeValue = sizeRef {
                var size = CGSize.zero
                AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                continuation.resume(returning: size)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func getWindowMinimizedAsync(_ window: AXUIElement) async -> Bool {
        return await withCheckedContinuation { continuation in
            var minimizedRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
            let isMinimized = (result == .success && (minimizedRef as? Bool) == true)
            continuation.resume(returning: isMinimized)
        }
    }
    
    private func getAppNameAsync(_ appPID: pid_t) async -> String? {
        return await withCheckedContinuation { continuation in
            let appName = NSRunningApplication(processIdentifier: appPID)?.localizedName
            continuation.resume(returning: appName)
        }
    }
    
    // MARK: - Timeout Utility
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    func getWindowsForApp(named appName: String) -> [WindowInfo] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.localizedName?.lowercased() == appName.lowercased() 
        }) else {
            return []
        }
        
        return getWindowsForApp(pid: app.processIdentifier)
    }
    
    // MARK: - Timeout Wrapper for Per-App Window Discovery
    func getWindowsForAppWithTimeout(pid: pid_t, timeout: TimeInterval) -> [WindowInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: [WindowInfo] = []
        var completed = false
        
        let workQueue = DispatchQueue.global(qos: .userInitiated)
        let timeoutQueue = DispatchQueue.global(qos: .utility)
        
        let group = DispatchGroup()
        
        // Start the actual work
        group.enter()
        workQueue.async {
            defer { group.leave() }
            if !completed {
                result = self.getWindowsForApp(pid: pid)
                completed = true
            }
        }
        
        // Start timeout timer
        timeoutQueue.asyncAfter(deadline: .now() + timeout) {
            if !completed {
                completed = true
                // Timeout occurred
            }
        }
        
        // Wait for completion or timeout
        _ = group.wait(timeout: .now() + timeout + 0.1)
        
        
        return result
    }
    
    func getWindowsForApp(pid: pid_t) -> [WindowInfo] {
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
        
        // Check if this is a minimized window first
        var minimizedRef: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = (minimizedResult == .success && (minimizedRef as? Bool) == true)
        
        // Get window title (minimized windows may have accessibility issues)
        _ = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String ?? (isMinimized ? "Minimized Window" : "Untitled")
        
        // Get window position (may be inaccessible for minimized windows)
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        var position = CGPoint.zero
        if let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        
        // Get window size (may be inaccessible for minimized windows)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var size = CGSize.zero
        if let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        // Get app name
        let appName = NSRunningApplication(processIdentifier: appPID)?.localizedName ?? "Unknown App"
        
        let bounds = CGRect(origin: position, size: size)
        
        // CRITICAL: Always include windows, even minimized ones with accessibility issues
        
        return WindowInfo(title: title, appName: appName, bounds: bounds, windowRef: window)
    }
    
    func getFrontmostWindow() -> WindowInfo? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let windows = getWindowsForApp(pid: frontmostApp.processIdentifier)
        return windows.first // Usually the first window is the frontmost
    }
    
    // MARK: - Animated Window Operations
    
    /// Move window with animation
    func moveWindowAnimated(_ windowInfo: WindowInfo, to position: CGPoint, preset: AnimationPreset = AnimationPresets.defaultSmooth, completion: (() -> Void)? = nil) {
        AnimationQueue.shared.queueAnimation(
            id: "move_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .move(position),
            preset: preset,
            completion: completion
        )
    }
    
    /// Resize window with animation
    func resizeWindowAnimated(_ windowInfo: WindowInfo, to size: CGSize, preset: AnimationPreset = AnimationPresets.defaultSmooth, completion: (() -> Void)? = nil) {
        AnimationQueue.shared.queueAnimation(
            id: "resize_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .resize(size),
            preset: preset,
            completion: completion
        )
    }
    
    /// Set window bounds with animation
    func setWindowBoundsAnimated(_ windowInfo: WindowInfo, bounds: CGRect, preset: AnimationPreset = AnimationPresets.defaultSmooth, completion: (() -> Void)? = nil) {
        AnimationQueue.shared.queueAnimation(
            id: "bounds_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .bounds(bounds),
            preset: preset,
            completion: completion
        )
    }
    
    /// Maximize window with animation
    func maximizeWindowAnimated(_ windowInfo: WindowInfo, completion: (() -> Void)? = nil) {
        // Calculate maximize bounds
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(windowInfo.bounds.origin) }) ?? NSScreen.main else {
            completion?()
            return
        }
        
        let maximizeBounds = CGRect(
            x: screen.frame.origin.x,
            y: screen.visibleFrame.origin.y,
            width: screen.frame.width,
            height: screen.visibleFrame.height
        )
        
        AnimationQueue.shared.queueAnimation(
            id: "maximize_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .bounds(maximizeBounds),
            preset: AnimationPresets.maximize,
            completion: completion
        )
    }
    
    /// Restore window with animation
    func restoreWindowAnimated(_ windowInfo: WindowInfo, to bounds: CGRect? = nil, completion: (() -> Void)? = nil) {
        let targetBounds = bounds ?? CGRect(
            x: windowInfo.bounds.origin.x,
            y: windowInfo.bounds.origin.y,
            width: 800,
            height: 600
        )
        
        // First handle unminimizing if needed
        if isWindowMinimized(windowInfo) {
            let restoreResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            if restoreResult == .success {
                // Activate the app
                if let bundleID = getBundleID(for: windowInfo.appName),
                   let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                    app.activate()
                }
                
                // Small delay then animate to target bounds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    AnimationQueue.shared.queueRestoreAnimation(for: windowInfo, to: targetBounds)
                    completion?()
                }
            } else {
                completion?()
            }
        } else {
            AnimationQueue.shared.queueRestoreAnimation(for: windowInfo, to: targetBounds)
            completion?()
        }
    }
    
    /// Focus window with subtle animation
    func focusWindowAnimated(_ windowInfo: WindowInfo, completion: (() -> Void)? = nil) {
        // Focus immediately, then add subtle animation
        let focusSuccess = focusWindow(windowInfo)
        
        if focusSuccess {
            AnimationQueue.shared.queueFocusAnimation(for: windowInfo)
        }
        
        completion?()
    }
    
    /// Snap window to position with quick animation
    func snapWindowAnimated(_ windowInfo: WindowInfo, to bounds: CGRect, completion: (() -> Void)? = nil) {
        // Check if animations are enabled
        guard UserPreferences.shared.animateWindowMovement else {
            _ = setWindowBounds(windowInfo, bounds: bounds)
            completion?()
            return
        }
        
        AnimationQueue.shared.queueAnimation(
            id: "snap_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .bounds(bounds),
            preset: AnimationPresets.snap,
            completion: completion
        )
    }
    
    // MARK: - Batch Animated Operations
    
    /// Animate multiple windows in coordinated fashion
    func animateWindowsCoordinated(_ operations: [(WindowInfo, CGRect)], configuration: AnimationConfiguration = .default, completion: (() -> Void)? = nil) {
        let windowOperations = operations.map { (windowInfo, bounds) in
            (windowInfo, AnimationOperation.bounds(bounds))
        }
        
        AnimationQueue.shared.queueCoordinatedAnimations(
            windowOperations,
            preset: configuration.preset,
            staggerDelay: configuration.staggerDelay,
            completion: completion
        )
    }
    
    /// Cascade multiple windows with staggered animation
    func cascadeWindowsAnimated(_ windows: [WindowInfo], startingAt origin: CGPoint, cascade: CascadeConfiguration, completion: (() -> Void)? = nil) {
        var operations: [(WindowInfo, CGRect)] = []
        
        for (index, window) in windows.enumerated() {
            let offset = CGPoint(
                x: origin.x + (CGFloat(index) * CGFloat(cascade.offset.horizontal)),
                y: origin.y + (CGFloat(index) * CGFloat(cascade.offset.vertical))
            )
            
            let bounds = CGRect(origin: offset, size: window.bounds.size)
            operations.append((window, bounds))
        }
        
        AnimationQueue.shared.queueCoordinatedAnimations(
            operations.map { ($0.0, .bounds($0.1)) },
            preset: AnimationPresets.cascade,
            staggerDelay: 0.1,
            completion: completion
        )
    }
    
    /// Arrange workspace with smooth transitions
    func arrangeWorkspaceAnimated(_ windows: [WindowInfo], layout: [(CGRect)], completion: (() -> Void)? = nil) {
        guard windows.count == layout.count else {
            // Window count doesn't match layout count
            completion?()
            return
        }
        
        AnimationQueue.shared.queueWorkspaceTransition(
            windows: windows,
            targetBounds: layout,
            configuration: AnimationConfiguration.fromSystemPreferences(),
            completion: completion
        )
    }

    // MARK: - Window Manipulation
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        guard checkAccessibilityPermissions() else { 
            return false 
        }
        
        let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: position) { $0 })
        let result = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXPositionAttribute as CFString, positionValue!)
        
        return result == .success
    }
    
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // DYNAMIC SYSTEM: No constraint validation - use size as calculated
        let validatedSize = size
        
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
    
    func isWindowMinimized(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        var minimizedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &minimizedValue)
        
        if result == .success, let minimized = minimizedValue as? Bool {
            return minimized
        }
        return false
    }
    
    func zoomWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Try to click the zoom button (green button)
        var zoomButton: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXZoomButtonAttribute as CFString, &zoomButton)
        
        if result == .success, let button = zoomButton as! AXUIElement? {
            let clickResult = AXUIElementPerformAction(button, kAXPressAction as CFString)
            return clickResult == .success
        }
        
        return false
    }
    
    func maximizeWindow(_ windowInfo: WindowInfo) -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        // Manual maximize only - never use zoom button
        // Get the screen that contains this window
        var targetScreen: NSScreen?
        for screen in NSScreen.screens {
            if screen.frame.contains(windowInfo.bounds.origin) {
                targetScreen = screen
                break
            }
        }
        
        guard let screen = targetScreen ?? NSScreen.main else {
            return false
        }
        
        // Get the full frame and visible frame
        let fullFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Calculate the actual maximize bounds
        // The visible frame should already exclude menu bar and dock, but let's be explicit
        let maximizeBounds = CGRect(
            x: fullFrame.origin.x,
            y: visibleFrame.origin.y,
            width: fullFrame.width,
            height: visibleFrame.height
        )
        
        // Try setting position and size separately for better compatibility
        let positionValue = AXValueCreate(.cgPoint, withUnsafePointer(to: maximizeBounds.origin) { $0 })
        let sizeValue = AXValueCreate(.cgSize, withUnsafePointer(to: maximizeBounds.size) { $0 })
        
        // First set the position
        let posResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXPositionAttribute as CFString, positionValue!)
        
        // Then set the size
        let sizeResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXSizeAttribute as CFString, sizeValue!)
        
        // Verify the final bounds
        if posResult == .success && sizeResult == .success {
            Thread.sleep(forTimeInterval: 0.1) // Give it a moment to apply
            
            // Read back the actual bounds
            var actualPosition: CFTypeRef?
            var actualSize: CFTypeRef?
            
            if AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXPositionAttribute as CFString, &actualPosition) == .success,
               AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXSizeAttribute as CFString, &actualSize) == .success {
                
                var finalOrigin = CGPoint.zero
                var finalSize = CGSize.zero
                
                if let posValue = actualPosition {
                    AXValueGetValue(posValue as! AXValue, .cgPoint, &finalOrigin)
                }
                if let sizeVal = actualSize {
                    AXValueGetValue(sizeVal as! AXValue, .cgSize, &finalSize)
                }
                
                // Window bounds updated
            }
        }
        
        return posResult == .success && sizeResult == .success
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
            // Step 1: Unminimize the window
            let restoreResult = AXUIElementSetAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            
            if restoreResult != .success {
                return false
            }
            
            // Step 2: Activate the app (critical for visibility)
            if let bundleID = getBundleID(for: windowInfo.appName),
               let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                app.activate()
                Thread.sleep(forTimeInterval: 0.2)
            }
            
            // Step 3: Focus/raise the window
            let focusResult = AXUIElementPerformAction(windowInfo.windowRef, kAXRaiseAction as CFString)
            
            // Step 4: Verify the window is actually restored
            var verifyMinimized: CFTypeRef?
            let verifyResult = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &verifyMinimized)
            let stillMinimized = (verifyResult == .success && (verifyMinimized as? Bool) == true)
            
            if stillMinimized {
                return false
            }
            
            return true
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

// MARK: - Performance Testing Utilities
extension WindowManager {
    /// Compare performance between different window discovery methods
    func performanceTest() {
        // Test 1: Standard getAllWindows() with timing
        let standardWindows = getAllWindows()
        
        // Test 2: Fast getAllWindows()
        let fastWindows = getAllWindowsFast()
        
        // Test 3: Async version
        Task {
            let asyncStartTime = CFAbsoluteTimeGetCurrent()
            let asyncWindows = await getAllWindowsAsync()
            let asyncTime = CFAbsoluteTimeGetCurrent() - asyncStartTime
        }
        
        // App breakdown
        let standardApps = Set(standardWindows.map { $0.appName })
        let fastApps = Set(fastWindows.map { $0.appName })
        
        // Missing apps
        let missingInFast = standardApps.subtracting(fastApps)
        let extraInFast = fastApps.subtracting(standardApps)
    }
    
    /// Test specific app performance
    func testAppPerformance(appName: String) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.localizedName?.lowercased() == appName.lowercased() 
        }) else {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let windows = getWindowsForApp(pid: app.processIdentifier)
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
    }
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
        
        // Add timeout protection to prevent hanging on slow apps
        return withTimeout(0.05) { // 50ms max per window
            var isMinimized: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &isMinimized)
            
            if result == .success, let minimized = isMinimized as? Bool {
                return !minimized
            }
            
            return true // Assume visible if we can't determine
        } ?? true // Default to visible on timeout
    }
    
    /// Timeout wrapper for Accessibility API calls to prevent hanging
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () -> T) -> T? {
        var result: T?
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global(qos: .userInitiated).async {
            result = operation()
            semaphore.signal()
        }
        
        let timeoutResult = semaphore.wait(timeout: .now() + timeout)
        
        if timeoutResult == .timedOut {
            // Operation timed out - return nil to indicate failure
            return nil
        }
        
        return result
    }
    
    func isWindowVisibleAsync(_ windowInfo: WindowInfo) async -> Bool {
        guard checkAccessibilityPermissions() else { return false }
        
        return await withCheckedContinuation { continuation in
            var isMinimized: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(windowInfo.windowRef, kAXMinimizedAttribute as CFString, &isMinimized)
            
            if result == .success, let minimized = isMinimized as? Bool {
                continuation.resume(returning: !minimized)
            } else {
                continuation.resume(returning: true) // Assume visible if we can't determine
            }
        }
    }
    
    private func getBundleID(for appName: String) -> String? {
        return NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.lowercased() == appName.lowercased()
        }?.bundleIdentifier
    }
    
    private func validateWindowBounds(_ bounds: CGRect, for appName: String) -> CGRect {
        // DYNAMIC SYSTEM: No constraint validation - use bounds as calculated
        let validatedSize = bounds.size
        
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

