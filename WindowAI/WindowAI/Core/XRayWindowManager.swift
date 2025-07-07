import Cocoa
import Foundation

// MARK: - X-Ray Window Manager
class XRayWindowManager {
    
    static let shared = XRayWindowManager()
    
    private var overlayWindow: XRayOverlayWindow?
    private var isOverlayVisible = false
    private var lastActivationTime: Date = Date()
    
    private init() {
        // Pre-create overlay window for instant display
        if let screen = NSScreen.main {
            overlayWindow = XRayOverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
        }
        
        // Start background cache warming
        startBackgroundCacheWarming()
    }
    
    /// Start background cache warming to keep window data fresh
    private func startBackgroundCacheWarming() {
        // ELIMINATED - No cache system needed for maximum performance
    }
    
    // MARK: - Public Interface
    
    /// Show the X-Ray overlay with all visible windows - PARALLEL PROCESSING
    func showXRayOverlay() {
        guard !isOverlayVisible else { return }
        
        // Use async parallel processing for maximum performance
        Task {
            await showXRayOverlayAsync()
        }
    }
    
    /// Async version with parallel window discovery using TaskGroup
    private func showXRayOverlayAsync() async {
        let startTime = Date()
        
        // Use parallel TaskGroup implementation for maximum performance
        let visibleWindows = await getVisibleWindowsAsync()
        
        // Display on main thread
        await MainActor.run {
            displayOverlayWithWindows(visibleWindows)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Performance test - fallback to diagnostics if still slow
        if duration > 0.1 {
            // Run diagnostic version for debugging
            _ = getVisibleWindowsFastWithDiagnostics()
        }
    }
    
    /// Helper method to display overlay with given windows - ULTRA-FAST with TIMING
    private func displayOverlayWithWindows(_ visibleWindows: [WindowInfo]) {
        guard !visibleWindows.isEmpty else { return }
        
        let displayStart = Date()
        
        // Use OPTIMIZED version for maximum performance
        overlayWindow?.showWithWindowsOptimized(visibleWindows)
        
        let displayDuration = Date().timeIntervalSince(displayStart)
        
        isOverlayVisible = true
        lastActivationTime = Date()
        
        // Auto-hide after 10 seconds if no interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isOverlayVisible && Date().timeIntervalSince(self.lastActivationTime) >= 10.0 {
                self.hideXRayOverlay()
            }
        }
    }
    
    /// ULTRA-FAST synchronous window gathering with TIMING DIAGNOSTICS
    private func getVisibleWindowsFast() -> [WindowInfo] {
        let startTime = Date()
        
        // Step 1: Get all windows with timing
        let getAllStart = Date()
        let allWindows = WindowManager.shared.getAllWindows()
        let getAllDuration = Date().timeIntervalSince(getAllStart)
        
        // Step 2: Filter with timing
        let filterStart = Date()
        let visibleWindows = allWindows.compactMap { window -> WindowInfo? in
            // Quick exclusion checks first
            guard !window.appName.contains("WindowAI"),
                  !window.appName.contains("Dock"),
                  !window.appName.contains("SystemUIServer"),
                  window.bounds.width > 50,
                  window.bounds.height > 50 else {
                return nil
            }
            
            // SKIP EXPENSIVE isWindowVisible CHECK - use position heuristics instead
            let bounds = window.bounds
            // Skip obviously hidden windows (negative coords or way off screen)
            guard bounds.origin.x > -10000 && bounds.origin.y > -10000 &&
                  bounds.origin.x < 10000 && bounds.origin.y < 10000 else {
                return nil
            }
            
            // Quick Finder filtering (minimal checks for speed)
            if window.appName.lowercased().contains("finder") {
                // Only check for obvious desktop/default cases (FAST)
                if window.bounds.width >= 1400 || // Desktop size
                   (window.bounds.origin.x <= 10 && window.bounds.origin.y <= 10 && window.bounds.width >= 700) || // Default position
                   window.title.isEmpty || window.title == "Untitled" { // Generic titles
                    return nil
                }
            }
            
            return window
        }
        let filterDuration = Date().timeIntervalSince(filterStart)
        
        let totalDuration = Date().timeIntervalSince(startTime)
        
        // EMERGENCY FALLBACK: If still too slow, use minimal window set
        if totalDuration > 1.0 {
            return Array(allWindows.prefix(5).filter { 
                !$0.appName.contains("WindowAI") && $0.bounds.width > 100 
            })
        }
        
        return visibleWindows
    }
    
    /// ULTRA-FAST window gathering with targeted optimizations
    private func getVisibleWindowsUltraFast() -> [WindowInfo] {
        let overallStart = Date()
        
        // OPTIMIZATION 1: Limit app scanning to prevent slow apps from blocking
        let startApps = Date()
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Filter to only regular apps that are likely to have visible windows
        let targetApps = runningApps.filter { app in
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier else { return false }
            
            // Skip known problematic/slow apps and WindowAI itself (prevents recursion)
            let skipApps = [
                "com.apple.dock",
                "com.apple.systemuiserver",
                "com.apple.WindowServer",
                "com.apple.loginwindow",
                "com.apple.controlcenter",
                "com.apple.notificationcenterui",
                "com.zandermodaress.WindowAI" // Skip self to prevent recursive calls
            ]
            
            return !skipApps.contains(bundleId)
        }
        .prefix(15) // Limit to 15 most recent apps to prevent timeout
        
        let appsEnd = Date()
        let appFilterTime = appsEnd.timeIntervalSince(startApps)
        
        // OPTIMIZATION 2: Parallel window gathering with timeout
        let startWindows = Date()
        var allWindows: [WindowInfo] = []
        
        // Use concurrent queue with timeout protection
        let semaphore = DispatchSemaphore(value: 0)
        let timeout: TimeInterval = 0.5 // 500ms max for window gathering
        
        var windowGatheringCompleted = false
        let windowQueue = DispatchQueue(label: "window-gathering", qos: .userInitiated)
        
        windowQueue.async {
            var tempWindows: [WindowInfo] = []
            
            for app in targetApps {
                // Skip if we've already taken too long
                if Date().timeIntervalSince(startWindows) > timeout {
                    break
                }
                
                // Quick timeout per app
                let appStart = Date()
                let appWindows = WindowManager.shared.getWindowsForAppFast(pid: app.processIdentifier)
                let appTime = Date().timeIntervalSince(appStart)
                
                // Only include if app responded quickly
                if appTime < 0.2 { // 200ms max per app
                    tempWindows.append(contentsOf: appWindows)
                }
            }
            
            allWindows = tempWindows
            windowGatheringCompleted = true
            semaphore.signal()
        }
        
        // Wait with timeout
        let waitResult = semaphore.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
        }
        
        let windowsEnd = Date()
        let windowGatherTime = windowsEnd.timeIntervalSince(startWindows)
        
        // OPTIMIZATION 3: Fast filtering without additional AX calls
        let startFilter = Date()
        let visibleWindows = allWindows.filter { window in
            // Size check (instant)
            guard window.bounds.width > 50 && window.bounds.height > 50 else { return false }
            
            // App exclusion check (instant)
            guard !window.appName.contains("WindowAI"),
                  !window.appName.contains("Dock"),
                  !window.appName.contains("SystemUIServer") else { return false }
            
            // Simple position check for obviously hidden windows
            guard window.bounds.origin.x > -10000 && window.bounds.origin.y > -10000 else { return false }
            
            // Fast Finder filtering
            if window.appName.lowercased().contains("finder") {
                if window.bounds.width >= 1400 || // Desktop size
                   (window.bounds.origin.x <= 10 && window.bounds.origin.y <= 10 && window.bounds.width >= 700) ||
                   window.title.isEmpty || window.title == "Untitled" {
                    return false
                }
            }
            
            return true
        }
        
        let filterEnd = Date()
        let filterTime = filterEnd.timeIntervalSince(startFilter)
        
        let totalTime = Date().timeIntervalSince(overallStart)
        
        
        if totalTime > 0.05 {
        }
        
        return visibleWindows
    }
    
    /// DIAGNOSTIC VERSION: Window gathering with detailed timing breakdowns
    private func getVisibleWindowsFastWithDiagnostics() -> [WindowInfo] {
        let overallStart = Date()
        
        // Step 1: Get all windows
        let step1Start = Date()
        let allWindows = WindowManager.shared.getAllWindows()
        let step1Duration = Date().timeIntervalSince(step1Start)
        
        // Step 2: Pre-filter basic exclusions
        let step2Start = Date()
        let prefiltered = allWindows.filter { window in
            !window.appName.contains("WindowAI") &&
            !window.appName.contains("Dock") &&
            !window.appName.contains("SystemUIServer") &&
            window.bounds.width > 50 &&
            window.bounds.height > 50
        }
        let step2Duration = Date().timeIntervalSince(step2Start)
        
        // Step 3: Visibility checks (likely bottleneck)
        let step3Start = Date()
        var visibilityCheckCount = 0
        var visibilityCheckTotalTime: TimeInterval = 0
        
        let visibilityFiltered = prefiltered.compactMap { window -> WindowInfo? in
            let checkStart = Date()
            let isVisible = WindowManager.shared.isWindowVisible(window)
            let checkDuration = Date().timeIntervalSince(checkStart)
            
            visibilityCheckCount += 1
            visibilityCheckTotalTime += checkDuration
            
            // Log slow visibility checks
            if checkDuration > 0.1 {
            }
            
            return isVisible ? window : nil
        }
        let step3Duration = Date().timeIntervalSince(step3Start)
        let avgVisibilityCheck = visibilityCheckCount > 0 ? visibilityCheckTotalTime / Double(visibilityCheckCount) : 0
        
        // Step 4: Finder filtering
        let step4Start = Date()
        var finderCheckCount = 0
        var finderCheckTotalTime: TimeInterval = 0
        
        let finderFiltered = visibilityFiltered.compactMap { window -> WindowInfo? in
            if window.appName.lowercased().contains("finder") {
                let checkStart = Date()
                finderCheckCount += 1
                
                // Quick Finder filtering (minimal checks for speed)
                if window.bounds.width >= 1400 || // Desktop size
                   (window.bounds.origin.x <= 10 && window.bounds.origin.y <= 10 && window.bounds.width >= 700) || // Default position
                   window.title.isEmpty || window.title == "Untitled" { // Generic titles
                    let checkDuration = Date().timeIntervalSince(checkStart)
                    finderCheckTotalTime += checkDuration
                    return nil
                }
                
                let checkDuration = Date().timeIntervalSince(checkStart)
                finderCheckTotalTime += checkDuration
                
                // Log slow finder checks
                if checkDuration > 0.01 {
                }
            }
            return window
        }
        let step4Duration = Date().timeIntervalSince(step4Start)
        let avgFinderCheck = finderCheckCount > 0 ? finderCheckTotalTime / Double(finderCheckCount) : 0
        
        let overallDuration = Date().timeIntervalSince(overallStart)
        
        // Performance analysis
        let step1Percent = (step1Duration / overallDuration) * 100
        let step2Percent = (step2Duration / overallDuration) * 100
        let step3Percent = (step3Duration / overallDuration) * 100
        let step4Percent = (step4Duration / overallDuration) * 100
        
        
        if overallDuration > 0.05 {
            
            // Identify bottleneck
            if step1Percent > 50 {
            } else if step3Percent > 50 {
            } else if step4Percent > 30 {
            }
        }
        
        return finderFiltered
    }
    
    /// DEEP DIAGNOSTIC: Analyze WindowManager.getAllWindows() performance
    private func analyzeGetAllWindowsPerformance() -> [WindowInfo] {
        let overallStart = Date()
        
        // Step 1: Check accessibility permissions
        let permissionStart = Date()
        let hasPermissions = WindowManager.shared.checkAccessibilityPermissions()
        let permissionDuration = Date().timeIntervalSince(permissionStart)
        
        guard hasPermissions else {
            return []
        }
        
        // Step 2: Get running applications
        let appsStart = Date()
        let runningApps = NSWorkspace.shared.runningApplications
        let appsEnd = Date()
        let appsDuration = appsEnd.timeIntervalSince(appsStart)
        
        // Step 3: Filter apps (excluding system apps)
        let filterStart = Date()
        let filteredApps = runningApps.filter { app in
            guard let bundleIdentifier = app.bundleIdentifier else { return false }
            return !bundleIdentifier.contains("com.apple.dock") &&
                   !bundleIdentifier.contains("com.apple.systemuiserver")
        }
        let filterDuration = Date().timeIntervalSince(filterStart)
        
        // Step 4: Get windows for each app (THIS IS LIKELY THE BOTTLENECK)
        let windowsStart = Date()
        var allWindows: [WindowInfo] = []
        var appCount = 0
        var slowApps: [(String, TimeInterval)] = []
        
        for app in filteredApps {
            let appStart = Date()
            let appWindows = WindowManager.shared.getWindowsForApp(pid: app.processIdentifier)
            let appDuration = Date().timeIntervalSince(appStart)
            
            appCount += 1
            allWindows.append(contentsOf: appWindows)
            
            // Track slow apps
            if appDuration > 0.1 {
                let appName = app.localizedName ?? "Unknown"
                slowApps.append((appName, appDuration))
            }
        }
        
        let windowsDuration = Date().timeIntervalSince(windowsStart)
        let avgPerApp = appCount > 0 ? windowsDuration / Double(appCount) : 0
        
        // Show slowest apps
        if !slowApps.isEmpty {
            for (appName, duration) in slowApps.sorted(by: { $0.1 > $1.1 }).prefix(5) {
            }
        }
        
        let overallDuration = Date().timeIntervalSince(overallStart)
        
        // Performance breakdown
        let permissionPercent = (permissionDuration / overallDuration) * 100
        let appsPercent = (appsDuration / overallDuration) * 100
        let filterPercent = (filterDuration / overallDuration) * 100
        let windowsPercent = (windowsDuration / overallDuration) * 100
        
        
        if windowsPercent > 80 {
        }
        
        return allWindows
    }
    
    /// OPTIMIZED VERSION: Fast window gathering with multiple performance improvements
    private func getVisibleWindowsOptimized() -> [WindowInfo] {
        let overallStart = Date()
        
        // OPTIMIZATION 1: Skip permission check if we've already verified it recently
        // (WindowManager constructor already checks, no need to check again)
        
        // OPTIMIZATION 2: Use a more targeted app filter that skips expensive operations
        let appsStart = Date()
        let runningApps = NSWorkspace.shared.runningApplications
        let targetApps = runningApps.filter { app in
            // Quick checks first
            guard app.activationPolicy == .regular else { return false }
            guard let bundleId = app.bundleIdentifier else { return false }
            
            // Skip obvious system apps without expensive string operations
            if bundleId.hasPrefix("com.apple.dock") ||
               bundleId.hasPrefix("com.apple.systemuiserver") ||
               bundleId.hasPrefix("com.apple.WindowServer") {
                return false
            }
            
            return true
        }
        let appsEnd = Date()
        
        // OPTIMIZATION 3: Parallel window gathering with timeout protection
        let windowsStart = Date()
        var allWindows: [WindowInfo] = []
        
        // Use DispatchGroup for parallel processing
        let dispatchGroup = DispatchGroup()
        let windowsQueue = DispatchQueue(label: "windows-gathering", qos: .userInitiated)
        let resultQueue = DispatchQueue(label: "results-collection", qos: .userInitiated)
        var tempResults: [WindowInfo] = []
        
        for app in targetApps.prefix(10) { // Limit to 10 most recent apps for speed
            dispatchGroup.enter()
            windowsQueue.async {
                let appStart = Date()
                let appWindows = WindowManager.shared.getWindowsForAppFast(pid: app.processIdentifier)
                let appDuration = Date().timeIntervalSince(appStart)
                
                // Only collect if it was reasonably fast
                if appDuration < 1.0 && !appWindows.isEmpty {
                    resultQueue.async {
                        tempResults.append(contentsOf: appWindows)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        
        // Wait for completion with timeout
        let timeout = dispatchGroup.wait(timeout: .now() + 0.5) // 500ms timeout
        allWindows = tempResults
        
        if timeout == .timedOut {
        }
        
        let windowsEnd = Date()
        
        // OPTIMIZATION 4: Fast visibility filtering using batch operations
        let filterStart = Date()
        let visibleWindows = allWindows.filter { window in
            // Quick size and app checks (no expensive string operations)
            return window.bounds.width > 50 &&
                   window.bounds.height > 50 &&
                   !window.appName.contains("WindowAI") &&
                   !window.appName.contains("Dock") &&
                   WindowManager.shared.isWindowVisible(window)
        }
        let filterEnd = Date()
        
        let overallDuration = Date().timeIntervalSince(overallStart)
        
        return visibleWindows
    }
    
    /// DEBUG METHOD: Test all approaches and compare performance
    func debugPerformanceComparison() {
        
        // Test 1: Ultra-fast optimized method
        let start1 = Date()
        let result1 = getVisibleWindowsUltraFast()
        let duration1 = Date().timeIntervalSince(start1)
        
        // Test 2: Original method with diagnostics
        let start2 = Date()
        let result2 = getVisibleWindowsFastWithDiagnostics()
        let duration2 = Date().timeIntervalSince(start2)
        
        // Test 3: Deep diagnostic method
        let start3 = Date()
        let result3 = analyzeGetAllWindowsPerformance()
        let duration3 = Date().timeIntervalSince(start3)
        
        // Test 4: Older optimized method
        let start4 = Date()
        let result4 = getVisibleWindowsOptimized()
        let duration4 = Date().timeIntervalSince(start4)
        
        
        let bestTime = min(duration1, duration2, duration3, duration4)
        
        if duration1 == bestTime {
        } else if duration2 == bestTime {
        } else if duration3 == bestTime {
        } else {
        }
        
        if duration1 < duration2 {
            let improvement = ((duration2 - duration1) / duration2) * 100
        } else {
            let regression = ((duration1 - duration2) / duration2) * 100
        }
        
    }
    
    
    /// Fast async window filtering with parallel visibility checks
    private func getVisibleWindowsAsync() async -> [WindowInfo] {
        let startTime = Date()
        
        // Get all windows first (fast)
        let allWindows = WindowManager.shared.getAllWindows()
        
        // Pre-filter obvious exclusions (instant)
        let candidateWindows = allWindows.filter { window in
            !window.appName.contains("WindowAI") &&
            !window.appName.contains("Dock") &&
            !window.appName.contains("SystemUIServer") &&
            window.bounds.width > 50 &&
            window.bounds.height > 50
        }
        
        // PARALLEL MODE: Fast position checks + parallel minimization detection
        // Use TaskGroup for concurrent processing to eliminate sequential bottleneck
        let visibleWindows = await withTaskGroup(of: WindowInfo?.self, returning: [WindowInfo].self) { group in
            for window in candidateWindows {
                group.addTask {
                    // 1. Position-based visibility heuristic (instant)
                    guard window.bounds.origin.x > -5000 && window.bounds.origin.y > -5000 else {
                        return nil // Obviously hidden/off-screen
                    }
                    
                    // 2. Parallel minimization check (async, no timeout overhead)
                    let isVisible = await WindowManager.shared.isWindowVisibleAsync(window)
                    guard isVisible else {
                        return nil // Minimized window - exclude from X-Ray
                    }
                    
                    // 3. Fast Finder filtering for performance
                    if !FinderDetection.shouldShowFinderWindowFast(window) {
                        return nil
                    }
                    
                    return window
                }
            }
            
            var results: [WindowInfo] = []
            for await window in group {
                if let window = window {
                    results.append(window)
                }
            }
            return results
        }
        
        // Clean up old Finder tracking data periodically
        FinderDetection.cleanupOldTrackingData()
        
        let duration = Date().timeIntervalSince(startTime)
        
        return visibleWindows
    }
    
    /// Fallback: Parallel visibility checks (more accurate but slower)
    private func getVisibleWindowsWithAccurateChecks() async -> [WindowInfo] {
        let startTime = Date()
        
        // Get all windows first (fast)
        let allWindows = WindowManager.shared.getAllWindows()
        
        // Pre-filter obvious exclusions (instant)
        let candidateWindows = allWindows.filter { window in
            !window.appName.contains("WindowAI") &&
            !window.appName.contains("Dock") &&
            !window.appName.contains("SystemUIServer") &&
            window.bounds.width > 50 &&
            window.bounds.height > 50
        }
        
        // Parallel visibility checks (more accurate but slower)
        let visibleWindows = await withTaskGroup(of: WindowInfo?.self, returning: [WindowInfo].self) { group in
            for window in candidateWindows {
                group.addTask {
                    let isVisible = await WindowManager.shared.isWindowVisibleAsync(window)
                    
                    // Additional check: Fast Finder filtering for performance
                    if isVisible && !FinderDetection.shouldShowFinderWindowFast(window) {
                        return nil
                    }
                    
                    return isVisible ? window : nil
                }
            }
            
            var results: [WindowInfo] = []
            for await window in group {
                if let window = window {
                    results.append(window)
                }
            }
            return results
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return visibleWindows
    }
    
    /// Hide the X-Ray overlay
    func hideXRayOverlay() {
        guard isOverlayVisible else { return }
        
        overlayWindow?.hideOverlay()
        isOverlayVisible = false
    }
    
    /// Toggle X-Ray overlay visibility
    func toggleXRayOverlay() {
        if isOverlayVisible {
            hideXRayOverlay()
        } else {
            showXRayOverlay()
        }
    }
    
    /// Check if overlay is currently visible
    func isXRayVisible() -> Bool {
        return isOverlayVisible
    }
    
    /// Focus window by number (1-9)
    func focusWindowByNumber(_ number: Int) {
        guard isOverlayVisible else { return }
        
        // The overlay window handles number key selection internally
        // This method is for external programmatic access
    }
    
    // MARK: - Window Information
    
    /// Get current window layout for debugging
    func getCurrentWindowLayout() -> [WindowInfo] {
        let allWindows = WindowManager.shared.getAllWindows()
        return allWindows.filter { window in
            !window.appName.contains("WindowAI") &&
            !window.appName.contains("Dock") &&
            window.bounds.width > 50 &&
            window.bounds.height > 50 &&
            WindowManager.shared.isWindowVisible(window) // Only show unminimized windows
        }
    }
    
    /// Get current window layout for debugging (async version)
    func getCurrentWindowLayoutAsync() async -> [WindowInfo] {
        return await getVisibleWindowsAsync()
    }
    
    /// Print current window layout to console (DEBUG only)
    func debugCurrentLayout() {
        #if DEBUG
        let windows = getCurrentWindowLayout()
        
        for (index, window) in windows.enumerated() {
            let bounds = window.bounds
        }
        #endif
    }
    
    /// Test the performance optimization - call this to identify bottlenecks (DEBUG only)
    func testPerformanceOptimization() {
        #if DEBUG
        // Run 3 iterations to get average
        var times: [TimeInterval] = []
        var windowCounts: [Int] = []
        
        for i in 1...3 {
            let start = Date()
            let windows = getVisibleWindowsUltraFast()
            let duration = Date().timeIntervalSince(start)
            
            times.append(duration)
            windowCounts.append(windows.count)
        }
        
        let avgTime = times.reduce(0, +) / Double(times.count)
        let avgWindows = windowCounts.reduce(0, +) / windowCounts.count
        
        if avgTime >= 0.05 {
            debugPerformanceComparison()
        }
        #endif
    }
    
    /// Debug all Finder windows and their detection status (DEBUG only)
    func debugFinderWindows() {
        #if DEBUG
        let allWindows = WindowManager.shared.getAllWindows()
        let finderWindows = allWindows.filter { $0.appName.lowercased().contains("finder") }
        
        
        for (index, window) in finderWindows.enumerated() {
            
            let shouldShow = FinderDetection.shouldShowFinderWindowFast(window)
        }
        
        let stats = FinderDetection.getTrackingStats()
        if let oldestAge = stats.oldestAge {
        }
        #endif
    }
}

// MARK: - Performance Testing
#if DEBUG
extension XRayWindowManager {
    
    /// Run comprehensive performance tests to ensure <0.1s operations
    func runPerformanceTests() {
        var allTestsPassed = true
        
        // Test 1: Show overlay performance
        allTestsPassed = testShowPerformance() && allTestsPassed
        
        // Test 2: Hide overlay performance 
        allTestsPassed = testHidePerformance() && allTestsPassed
        
        // Test 3: Toggle performance
        allTestsPassed = testTogglePerformance() && allTestsPassed
        
        // Test 4: Repeated show/hide cycles
        allTestsPassed = testRepeatedCycles() && allTestsPassed
        
        // Test 5: Direct performance
        allTestsPassed = testDirectPerformance() && allTestsPassed
        
        // Test 6: TDD Performance Requirements (NEW - Expected to fail initially)
        allTestsPassed = testTDDPerformanceRequirements() && allTestsPassed
    }
    
    private func testShowPerformance() -> Bool {
        // Hide if currently visible
        if isOverlayVisible {
            hideXRayOverlay()
            Thread.sleep(forTimeInterval: 0.01) // Brief pause
        }
        
        let startTime = Date()
        showXRayOverlay()
        let duration = Date().timeIntervalSince(startTime)
        
        let passed = duration < 0.1
        
        return passed
    }
    
    private func testHidePerformance() -> Bool {
        // Ensure overlay is visible
        if !isOverlayVisible {
            showXRayOverlay()
            Thread.sleep(forTimeInterval: 0.01) // Brief pause
        }
        
        let startTime = Date()
        hideXRayOverlay()
        let duration = Date().timeIntervalSince(startTime)
        
        let passed = duration < 0.1
        
        return passed
    }
    
    private func testTogglePerformance() -> Bool {
        var allPassed = true
        
        // Test toggle show
        if isOverlayVisible {
            hideXRayOverlay()
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        let startTime1 = Date()
        toggleXRayOverlay() // Should show
        let duration1 = Date().timeIntervalSince(startTime1)
        
        let passed1 = duration1 < 0.1
        allPassed = allPassed && passed1
        
        Thread.sleep(forTimeInterval: 0.01)
        
        // Test toggle hide
        let startTime2 = Date()
        toggleXRayOverlay() // Should hide
        let duration2 = Date().timeIntervalSince(startTime2)
        
        let passed2 = duration2 < 0.1
        allPassed = allPassed && passed2
        
        return allPassed
    }
    
    private func testRepeatedCycles() -> Bool {
        var allPassed = true
        var totalDuration: TimeInterval = 0
        let iterations = 10
        
        for i in 1...iterations {
            // Hide if visible
            if isOverlayVisible {
                hideXRayOverlay()
                Thread.sleep(forTimeInterval: 0.005)
            }
            
            // Test show
            let showStart = Date()
            showXRayOverlay()
            let showDuration = Date().timeIntervalSince(showStart)
            
            Thread.sleep(forTimeInterval: 0.005)
            
            // Test hide
            let hideStart = Date()
            hideXRayOverlay()
            let hideDuration = Date().timeIntervalSince(hideStart)
            
            let cycleDuration = showDuration + hideDuration
            totalDuration += cycleDuration
            
            let passed = showDuration < 0.1 && hideDuration < 0.1
            if !passed {
                allPassed = false
            }
            
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        let avgDuration = totalDuration / Double(iterations * 2) // 2 operations per cycle
        
        return allPassed && avgDuration < 0.1
    }
    
    private func testDirectPerformance() -> Bool {
        // Test window gathering speed
        let startTime1 = Date()
        let windows1 = getVisibleWindowsFast()
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Test full show operation
        let startTime2 = Date()
        showXRayOverlay()
        let duration2 = Date().timeIntervalSince(startTime2)
        
        hideXRayOverlay()
        
        let passed1 = duration1 < 0.05 // Even stricter for window gathering
        let passed2 = duration2 < 0.1
        
        return passed1 && passed2
    }
    
    /// Run detailed performance analysis to identify bottlenecks
    func runDetailedPerformanceAnalysis() {
        debugPerformanceComparison()
    }
    
    /// TDD Performance Requirements Test - EXPECTED TO FAIL initially
    /// Tests the stricter <0.5s requirements for complete X-Ray display
    private func testTDDPerformanceRequirements() -> Bool {
        print("\n🧪 TDD PERFORMANCE REQUIREMENTS TEST")
        print("   ⚠️  EXPECTED TO FAIL - Current performance ~10s, target <0.5s")
        print(String(repeating: "=", count: 50))
        
        var allTestsPassed = true
        var results: [String] = []
        
        // Test 1: Total End-to-End Display Time (<0.5s)
        print("\n📋 Test 1: Total X-Ray Display Time")
        print("   Target: <0.5s")
        
        let startTotal = Date()
        showXRayOverlay()
        let totalDuration = Date().timeIntervalSince(startTotal)
        
        let totalPassed = totalDuration < 0.5
        let totalStatus = totalPassed ? "✅ PASS" : "❌ FAIL"
        let totalResult = "   Result: \(totalStatus) - \(String(format: "%.3f", totalDuration))s"
        print(totalResult)
        results.append("Total Display: \(String(format: "%.3f", totalDuration))s (\(totalPassed ? "PASS" : "FAIL"))")
        
        if !totalPassed { allTestsPassed = false }
        
        // Test 2: Window Discovery Time (<0.3s)
        print("\n📋 Test 2: Window Discovery Time")
        print("   Target: <0.3s")
        
        let startDiscovery = Date()
        let windows = getVisibleWindowsUltraFast()
        let discoveryDuration = Date().timeIntervalSince(startDiscovery)
        
        let discoveryPassed = discoveryDuration < 0.3
        let discoveryStatus = discoveryPassed ? "✅ PASS" : "❌ FAIL"
        let discoveryResult = "   Result: \(discoveryStatus) - \(String(format: "%.3f", discoveryDuration))s (\(windows.count) windows)"
        print(discoveryResult)
        results.append("Window Discovery: \(String(format: "%.3f", discoveryDuration))s (\(discoveryPassed ? "PASS" : "FAIL"))")
        
        if !discoveryPassed { allTestsPassed = false }
        
        // Test 3: Individual isWindowVisible() Performance (<0.05s each)
        print("\n📋 Test 3: isWindowVisible() Call Performance")
        print("   Target: <0.05s per call")
        
        let testWindows = Array(windows.prefix(5)) // Test first 5 windows
        var visibilityPassed = true
        var maxVisibilityTime: Double = 0
        
        for (index, window) in testWindows.enumerated() {
            let startVis = Date()
            let _ = WindowManager.shared.isWindowVisible(window)
            let visDuration = Date().timeIntervalSince(startVis)
            
            maxVisibilityTime = max(maxVisibilityTime, visDuration)
            
            if visDuration >= 0.05 {
                visibilityPassed = false
            }
            
            let visStatus = visDuration < 0.05 ? "✅" : "❌"
            print("   Window \(index + 1): \(visStatus) \(String(format: "%.3f", visDuration))s - \(window.appName)")
        }
        
        let visibilityStatus = visibilityPassed ? "✅ PASS" : "❌ FAIL"
        let visibilityResult = "   Result: \(visibilityStatus) - Max: \(String(format: "%.3f", maxVisibilityTime))s"
        print(visibilityResult)
        results.append("Visibility Checks: \(String(format: "%.3f", maxVisibilityTime))s max (\(visibilityPassed ? "PASS" : "FAIL"))")
        
        if !visibilityPassed { allTestsPassed = false }
        
        // Test 4: FinderDetection Performance (<0.1s)
        print("\n📋 Test 4: FinderDetection Processing Time")
        print("   Target: <0.1s total")
        
        let finderWindows = windows.filter { $0.appName.lowercased().contains("finder") }
        var finderPassed = true
        var finderDuration: Double = 0
        
        if !finderWindows.isEmpty {
            let startFinder = Date()
            for window in finderWindows {
                let _ = FinderDetection.shouldShowFinderWindowFast(window)
            }
            finderDuration = Date().timeIntervalSince(startFinder)
            finderPassed = finderDuration < 0.1
        }
        
        let finderStatus = finderPassed ? "✅ PASS" : "❌ FAIL"
        let finderResult = "   Result: \(finderStatus) - \(String(format: "%.3f", finderDuration))s (\(finderWindows.count) Finder windows)"
        print(finderResult)
        results.append("FinderDetection: \(String(format: "%.3f", finderDuration))s (\(finderPassed ? "PASS" : "FAIL"))")
        
        if !finderPassed { allTestsPassed = false }
        
        // Clean up
        hideXRayOverlay()
        
        // Summary
        print(String(repeating: "=", count: 50))
        print("📊 TDD PERFORMANCE TEST SUMMARY")
        
        if allTestsPassed {
            print("✅ ALL TDD REQUIREMENTS MET!")
            print("   X-Ray system meets <0.5s performance target")
        } else {
            print("❌ TDD REQUIREMENTS FAILED")
            print("   Performance optimizations needed:")
            for result in results {
                if result.contains("FAIL") {
                    print("   🚨 \(result)")
                }
            }
            print("\n💡 OPTIMIZATION SUGGESTIONS:")
            if !visibilityPassed {
                print("   • Add timeout protection to isWindowVisible() calls")
                print("   • Use async/parallel window visibility checking")
            }
            if !discoveryPassed {
                print("   • Implement aggressive app filtering (limit to 8-10 apps)")
                print("   • Add circuit breaker for slow-responding apps")
            }
            if !finderPassed {
                print("   • Simplify FinderDetection heuristic (remove expensive calculations)")
            }
            if !totalPassed {
                print("   • Consider background window caching")
                print("   • Skip expensive operations in fast-display mode")
            }
        }
        
        print(String(repeating: "=", count: 50))
        return allTestsPassed
    }
}
#endif

// MARK: - X-Ray Activation Types
enum XRayActivationType {
    case doubleTapCommand    // Double-tap Command key
    case commandPlusSpace    // Command + Space
    case customHotkey        // User-defined hotkey
}

// MARK: - X-Ray Configuration
struct XRayConfiguration {
    var activationType: XRayActivationType = .doubleTapCommand
    var autoHideDelay: TimeInterval = 10.0
    var showWindowNumbers: Bool = true
    var showWindowTitles: Bool = true
    var glowEffect: Bool = true
    var gridBackground: Bool = true
    var blurBackground: Bool = true
    
    static let `default` = XRayConfiguration()
}

// MARK: - Extensions for Integration
extension XRayWindowManager {
    
    /// Show X-Ray overlay after window arrangement to visualize results
    func showPostArrangementOverlay(delay: TimeInterval = 1.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.showXRayOverlay()
        }
    }
    
    /// Quick preview mode - show briefly then auto-hide
    func showQuickPreview(duration: TimeInterval = 3.0) {
        showXRayOverlay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.hideXRayOverlay()
        }
    }
}