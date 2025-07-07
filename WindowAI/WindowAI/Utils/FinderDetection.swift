import Cocoa
import Foundation

/// Smart detection for Finder windows to avoid showing default/system positions
struct FinderDetection {
    
    /// Default Finder window positions that should be ignored
    /// These are common default positions where Finder appears on macOS
    private static let defaultFinderPositions: [DefaultPosition] = [
        // Common default positions on various screen sizes
        DefaultPosition(x: 100, y: 100, width: 800, height: 600, tolerance: 50),  // Classic default
        DefaultPosition(x: 0, y: 0, width: 800, height: 600, tolerance: 50),     // Top-left default
        DefaultPosition(x: 200, y: 200, width: 800, height: 600, tolerance: 50), // Slightly offset
        DefaultPosition(x: 50, y: 50, width: 900, height: 700, tolerance: 50),   // Common variant
        DefaultPosition(x: 150, y: 150, width: 750, height: 550, tolerance: 50), // Another variant
    ]
    
    /// Minimum time a Finder window should exist before being considered "user-positioned"
    private static let minimumFinderAge: TimeInterval = 2.0
    
    /// Track when Finder windows are first seen
    private static var finderWindowFirstSeen: [String: Date] = [:]
    
    /// Represents a default Finder position with tolerance
    private struct DefaultPosition {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let tolerance: CGFloat
        
        func matches(_ bounds: CGRect) -> Bool {
            return abs(bounds.origin.x - x) <= tolerance &&
                   abs(bounds.origin.y - y) <= tolerance &&
                   abs(bounds.width - width) <= tolerance &&
                   abs(bounds.height - height) <= tolerance
        }
    }
    
    /// Fast version: Simple heuristic for X-Ray overlay performance
    /// Returns true if window should be shown, false if it should be hidden
    static func shouldShowFinderWindowFast(_ window: WindowInfo) -> Bool {
        // Only apply this logic to Finder
        guard window.appName.lowercased().contains("finder") else {
            return true // Not Finder, show normally
        }
        
        // Simple heuristics for performance:
        // 1. Hide if window has empty/generic title
        let title = window.title.lowercased()
        if title.isEmpty || title == "untitled" || title == "desktop" || title == "finder" {
            return false
        }
        
        // 2. Hide if window is very small (likely not meaningful)
        if window.bounds.width < 200 || window.bounds.height < 150 {
            return false
        }
        
        // 3. Hide if window covers most of screen (likely desktop)
        if let screen = NSScreen.main {
            let screenArea = screen.frame.width * screen.frame.height
            let windowArea = window.bounds.width * window.bounds.height
            if (windowArea / screenArea) > 0.8 {
                return false
            }
        }
        
        // Otherwise, show the window
        return true
    }
    
    /// Original comprehensive version (kept for compatibility)
    /// Determines if a Finder window should be shown in X-Ray overlay
    /// Returns true if the window appears to be user-positioned, false if it's in default position
    static func shouldShowFinderWindow(_ window: WindowInfo) -> Bool {
        // Only apply this logic to Finder
        guard window.appName.lowercased().contains("finder") else {
            return true // Not Finder, show normally
        }
        
        print("🔍 FinderDetection: Analyzing Finder window at \(window.bounds)")
        
        // Test 1: Check if it's in a default position
        let isInDefaultPosition = isFinderInDefaultPosition(window)
        if isInDefaultPosition {
            print("🔍 FinderDetection: Window is in default position - HIDING")
            return false
        }
        
        // Test 2: Check if it's a desktop window (very large, covering most of screen)
        let isDesktopWindow = isFinderDesktopWindow(window)
        if isDesktopWindow {
            print("🔍 FinderDetection: Window is desktop window - HIDING")
            return false
        }
        
        // Test 3: Check if it's been around long enough (prevents showing transient windows)
        let hasExistedLongEnough = hasFinderWindowExistedLongEnough(window)
        if !hasExistedLongEnough {
            print("🔍 FinderDetection: Window too new, waiting - HIDING")
            return false
        }
        
        // Test 4: Check if it has meaningful content (not just an empty folder view)
        let hasMeaningfulContent = finderWindowHasMeaningfulContent(window)
        if !hasMeaningfulContent {
            print("🔍 FinderDetection: Window has no meaningful content - HIDING")
            return false
        }
        
        print("🔍 FinderDetection: Window passes all tests - SHOWING")
        return true
    }
    
    /// Test 1: Check if Finder is in a known default position
    private static func isFinderInDefaultPosition(_ window: WindowInfo) -> Bool {
        let bounds = window.bounds
        
        for defaultPos in defaultFinderPositions {
            if defaultPos.matches(bounds) {
                print("🔍 Test 1: Matches default position (\(defaultPos.x), \(defaultPos.y))")
                return true
            }
        }
        
        // Additional check: is it at screen edges (common for default positioning)
        if let screen = NSScreen.main {
            let screenBounds = screen.visibleFrame
            
            // Check if positioned at common screen edge positions
            let isAtLeftEdge = abs(bounds.origin.x - screenBounds.origin.x) < 10
            let isAtTopEdge = abs(bounds.origin.y - screenBounds.origin.y) < 10
            let isAtRightEdge = abs((bounds.origin.x + bounds.width) - (screenBounds.origin.x + screenBounds.width)) < 10
            
            if (isAtLeftEdge || isAtTopEdge || isAtRightEdge) && bounds.width >= 700 && bounds.height >= 500 {
                print("🔍 Test 1: At screen edge with default size")
                return true
            }
        }
        
        print("🔍 Test 1: Not in default position")
        return false
    }
    
    /// Test 2: Check if this is a desktop window (covers most of the screen)
    private static func isFinderDesktopWindow(_ window: WindowInfo) -> Bool {
        guard let screen = NSScreen.main else { return false }
        
        let screenArea = screen.frame.width * screen.frame.height
        let windowArea = window.bounds.width * window.bounds.height
        let coverage = windowArea / screenArea
        
        // If the window covers more than 80% of the screen, it's likely the desktop
        if coverage > 0.8 {
            print("🔍 Test 2: Desktop window (covers \(Int(coverage * 100))% of screen)")
            return true
        }
        
        print("🔍 Test 2: Not desktop window (covers \(Int(coverage * 100))% of screen)")
        return false
    }
    
    /// Test 3: Check if the Finder window has existed long enough
    private static func hasFinderWindowExistedLongEnough(_ window: WindowInfo) -> Bool {
        let windowKey = "\(window.bounds.origin.x)_\(window.bounds.origin.y)_\(window.bounds.width)_\(window.bounds.height)"
        let now = Date()
        
        // Record first time we see this window
        if finderWindowFirstSeen[windowKey] == nil {
            finderWindowFirstSeen[windowKey] = now
            print("🔍 Test 3: First time seeing this window, starting timer")
            return false
        }
        
        // Check if enough time has passed
        let firstSeen = finderWindowFirstSeen[windowKey]!
        let age = now.timeIntervalSince(firstSeen)
        
        if age >= minimumFinderAge {
            print("🔍 Test 3: Window has existed for \(String(format: "%.1f", age))s - old enough")
            return true
        } else {
            print("🔍 Test 3: Window only existed for \(String(format: "%.1f", age))s - too new")
            return false
        }
    }
    
    /// Test 4: Check if Finder window has meaningful content (heuristic)
    private static func finderWindowHasMeaningfulContent(_ window: WindowInfo) -> Bool {
        // Heuristic: Check window title for meaningful content
        let title = window.title.lowercased()
        
        // Empty or generic titles suggest default/empty Finder windows
        let genericTitles = ["", "untitled", "new folder", "desktop", "finder"]
        
        for genericTitle in genericTitles {
            if title == genericTitle {
                print("🔍 Test 4: Generic title '\(window.title)' suggests no meaningful content")
                return false
            }
        }
        
        // Very small windows are likely not meaningful
        if window.bounds.width < 300 || window.bounds.height < 200 {
            print("🔍 Test 4: Window too small (\(Int(window.bounds.width))x\(Int(window.bounds.height)))")
            return false
        }
        
        print("🔍 Test 4: Title '\(window.title)' and size suggest meaningful content")
        return true
    }
    
    /// Clean up old tracking data to prevent memory leaks
    static func cleanupOldTrackingData() {
        let cutoff = Date().addingTimeInterval(-300) // Remove data older than 5 minutes
        finderWindowFirstSeen = finderWindowFirstSeen.filter { $0.value > cutoff }
    }
    
    /// Reset all tracking data (useful for testing)
    static func resetTrackingData() {
        finderWindowFirstSeen.removeAll()
        print("🔍 FinderDetection: Reset all tracking data")
    }
    
    /// Get current tracking statistics (for debugging)
    static func getTrackingStats() -> (trackedWindows: Int, oldestAge: TimeInterval?) {
        let count = finderWindowFirstSeen.count
        let oldestAge = finderWindowFirstSeen.values.map { Date().timeIntervalSince($0) }.max()
        return (count, oldestAge)
    }
}

// MARK: - Test Suite
#if DEBUG
extension FinderDetection {
    
    /// Comprehensive test suite for Finder detection
    static func runTests() {
        print("🧪 Starting FinderDetection test suite...")
        
        testDefaultPositionDetection()
        testDesktopWindowDetection()
        testWindowAgeTracking()
        testMeaningfulContentDetection()
        testEdgeCases()
        
        print("🧪 FinderDetection test suite completed!")
    }
    
    private static func testDefaultPositionDetection() {
        print("🧪 Test: Default Position Detection")
        
        // Test known default positions
        let defaultWindow = WindowInfo(
            title: "Untitled",
            appName: "Finder",
            bounds: CGRect(x: 100, y: 100, width: 800, height: 600),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        assert(!shouldShowFinderWindow(defaultWindow), "Should hide default position window")
        
        // Test non-default position
        let customWindow = WindowInfo(
            title: "My Documents",
            appName: "Finder",
            bounds: CGRect(x: 500, y: 300, width: 600, height: 400),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        resetTrackingData()
        // First call should return false (too new)
        assert(!shouldShowFinderWindow(customWindow), "Should hide new custom window initially")
        
        // Simulate aging
        let windowKey = "500.0_300.0_600.0_400.0"
        finderWindowFirstSeen[windowKey] = Date().addingTimeInterval(-3.0)
        assert(shouldShowFinderWindow(customWindow), "Should show aged custom window")
        
        print("✅ Default Position Detection tests passed")
    }
    
    private static func testDesktopWindowDetection() {
        print("🧪 Test: Desktop Window Detection")
        
        guard let screen = NSScreen.main else { return }
        
        // Test desktop-sized window
        let desktopWindow = WindowInfo(
            title: "Desktop",
            appName: "Finder",
            bounds: CGRect(x: 0, y: 0, width: screen.frame.width * 0.9, height: screen.frame.height * 0.9),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        assert(!shouldShowFinderWindow(desktopWindow), "Should hide desktop window")
        
        // Test normal-sized window
        let normalWindow = WindowInfo(
            title: "Documents",
            appName: "Finder",
            bounds: CGRect(x: 200, y: 200, width: 400, height: 300),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        resetTrackingData()
        let windowKey = "200.0_200.0_400.0_300.0"
        finderWindowFirstSeen[windowKey] = Date().addingTimeInterval(-3.0)
        assert(shouldShowFinderWindow(normalWindow), "Should show normal-sized window")
        
        print("✅ Desktop Window Detection tests passed")
    }
    
    private static func testWindowAgeTracking() {
        print("🧪 Test: Window Age Tracking")
        
        resetTrackingData()
        
        let testWindow = WindowInfo(
            title: "Test Folder",
            appName: "Finder",
            bounds: CGRect(x: 300, y: 300, width: 500, height: 400),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        // First check should return false (too new)
        assert(!shouldShowFinderWindow(testWindow), "New window should be hidden")
        
        // Manually age the window
        let windowKey = "300.0_300.0_500.0_400.0"
        finderWindowFirstSeen[windowKey] = Date().addingTimeInterval(-3.0)
        
        // Now it should be shown
        assert(shouldShowFinderWindow(testWindow), "Aged window should be shown")
        
        print("✅ Window Age Tracking tests passed")
    }
    
    private static func testMeaningfulContentDetection() {
        print("🧪 Test: Meaningful Content Detection")
        
        resetTrackingData()
        
        // Test generic title
        let genericWindow = WindowInfo(
            title: "",
            appName: "Finder",
            bounds: CGRect(x: 400, y: 400, width: 600, height: 500),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        let windowKey1 = "400.0_400.0_600.0_500.0"
        finderWindowFirstSeen[windowKey1] = Date().addingTimeInterval(-3.0)
        assert(!shouldShowFinderWindow(genericWindow), "Window with empty title should be hidden")
        
        // Test meaningful title
        let meaningfulWindow = WindowInfo(
            title: "My Project Files",
            appName: "Finder",
            bounds: CGRect(x: 400, y: 400, width: 600, height: 500),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        let windowKey2 = "400.0_400.0_600.0_500.0"
        finderWindowFirstSeen[windowKey2] = Date().addingTimeInterval(-3.0)
        assert(shouldShowFinderWindow(meaningfulWindow), "Window with meaningful title should be shown")
        
        print("✅ Meaningful Content Detection tests passed")
    }
    
    private static func testEdgeCases() {
        print("🧪 Test: Edge Cases")
        
        resetTrackingData()
        
        // Test non-Finder window (should always pass)
        let nonFinderWindow = WindowInfo(
            title: "Safari",
            appName: "Safari",
            bounds: CGRect(x: 100, y: 100, width: 800, height: 600),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        assert(shouldShowFinderWindow(nonFinderWindow), "Non-Finder windows should always be shown")
        
        // Test very small Finder window
        let tinyWindow = WindowInfo(
            title: "Folder",
            appName: "Finder",
            bounds: CGRect(x: 500, y: 500, width: 100, height: 100),
            windowRef: AXUIElementCreateSystemWide()
        )
        
        let windowKey = "500.0_500.0_100.0_100.0"
        finderWindowFirstSeen[windowKey] = Date().addingTimeInterval(-3.0)
        assert(!shouldShowFinderWindow(tinyWindow), "Very small windows should be hidden")
        
        print("✅ Edge Cases tests passed")
    }
}
#endif