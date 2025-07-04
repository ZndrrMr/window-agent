import Cocoa
import Foundation

// MARK: - Animation Testing and Verification
@MainActor
final class AnimationTester {
    
    static let shared = AnimationTester()
    
    private let windowManager = WindowManager.shared
    private let animationQueue = AnimationQueue.shared
    private let animationSelector = AnimationSelector.shared
    
    private init() {}
    
    // MARK: - Animation Verification
    
    /// Test if animations are actually working
    func testAnimationsWorking() -> AnimationTestResult {
        print("🧪 ANIMATION TESTING:")
        print("================")
        
        var results: [String] = []
        var issues: [String] = []
        
        // 1. Check user preferences
        let animationsEnabled = UserPreferences.shared.animateWindowMovement
        results.append("✓ Animation preference: \(animationsEnabled ? "ENABLED" : "DISABLED")")
        if !animationsEnabled {
            issues.append("❌ Animations disabled in user preferences")
        }
        
        // 2. Check accessibility settings
        let reduceMotion = UserDefaults.standard.bool(forKey: "accessibilityReduceMotion")
        results.append("✓ Reduce motion: \(reduceMotion ? "ON" : "OFF")")
        if reduceMotion {
            issues.append("❌ System reduce motion is enabled")
        }
        
        // 3. Check if we have windows to animate
        let windows = windowManager.getAllWindows()
        results.append("✓ Available windows: \(windows.count)")
        if windows.isEmpty {
            issues.append("❌ No windows available for testing")
        }
        
        // 4. Test animation queue status
        let queueStatus = animationQueue.getQueueStatus()
        results.append("✓ Animation queue - Active: \(queueStatus.activeAnimations), Queued: \(queueStatus.queuedAnimations)")
        
        // 5. Test preset selection
        let testPreset = animationSelector.selectPreset(
            for: .move,
            window: windows.first ?? WindowInfo(title: "Test", appName: "Test", bounds: .zero, windowRef: AXUIElementCreateApplication(0)),
            context: .default
        )
        results.append("✓ Selected preset: \(testPreset.name) (\(testPreset.duration)s)")
        if testPreset.duration == 0 {
            issues.append("❌ Selected preset has zero duration")
        }
        
        return AnimationTestResult(
            passed: issues.isEmpty,
            results: results,
            issues: issues,
            recommendations: generateRecommendations(issues: issues)
        )
    }
    
    /// Test a simple window animation with detailed logging
    func testSimpleAnimation() async -> Bool {
        print("\n🎬 TESTING SIMPLE ANIMATION:")
        print("============================")
        
        // Get a window to test with
        let windows = windowManager.getAllWindows()
        guard let testWindow = windows.first else {
            print("❌ No windows available for animation test")
            return false
        }
        
        print("🎯 Testing with window: '\(testWindow.title)' (\(testWindow.appName))")
        print("📍 Current position: \(testWindow.bounds.origin)")
        
        // Record initial position
        let initialBounds = testWindow.bounds
        let testPosition = CGPoint(
            x: initialBounds.origin.x + 50,
            y: initialBounds.origin.y + 50
        )
        
        print("🎯 Target position: \(testPosition)")
        print("📏 Movement distance: \(calculateDistance(from: initialBounds.origin, to: testPosition)) pixels")
        
        // Test with explicit animation call
        var animationCompleted = false
        
        print("🚀 Starting animation...")
        let startTime = Date()
        
        windowManager.moveWindowAnimated(testWindow, to: testPosition, preset: AnimationPresets.defaultSmooth) {
            animationCompleted = true
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Animation completed in \(String(format: "%.2f", duration))s")
        }
        
        // Wait for animation to complete (with timeout)
        let timeout = Date().addingTimeInterval(5.0)
        while !animationCompleted && Date() < timeout {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        if !animationCompleted {
            print("⏰ Animation timed out after 5 seconds")
            return false
        }
        
        // Check if window actually moved
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s for position to settle
        let finalWindows = windowManager.getAllWindows()
        if let finalWindow = finalWindows.first(where: { $0.appName == testWindow.appName }) {
            let finalPosition = finalWindow.bounds.origin
            let actualDistance = calculateDistance(from: initialBounds.origin, to: finalPosition)
            
            print("📍 Final position: \(finalPosition)")
            print("📏 Actual movement: \(String(format: "%.1f", actualDistance)) pixels")
            
            if actualDistance > 10 { // Allow some tolerance
                print("✅ Window successfully moved!")
                return true
            } else {
                print("❌ Window didn't move significantly")
                return false
            }
        } else {
            print("❌ Could not verify final window position")
            return false
        }
    }
    
    /// Test direct WindowAnimator functionality
    func testDirectAnimator() async -> Bool {
        print("\n🔧 TESTING DIRECT ANIMATOR:")
        print("==========================")
        
        let windows = windowManager.getAllWindows()
        guard let testWindow = windows.first else {
            print("❌ No windows available for direct animator test")
            return false
        }
        
        let animator = WindowAnimator.shared
        let initialBounds = testWindow.bounds
        let testPosition = CGPoint(
            x: initialBounds.origin.x + 30,
            y: initialBounds.origin.y + 30
        )
        
        print("🎯 Testing direct animator with window: '\(testWindow.title)'")
        print("📍 Moving from \(initialBounds.origin) to \(testPosition)")
        
        var completed = false
        let startTime = Date()
        
        animator.animateWindowMove(testWindow, to: testPosition, duration: 0.5) {
            completed = true
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Direct animator completed in \(String(format: "%.2f", duration))s")
        }
        
        // Wait for completion
        let timeout = Date().addingTimeInterval(3.0)
        while !completed && Date() < timeout {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return completed
    }
    
    /// Test animation with detailed step-by-step logging
    func testAnimationWithStepLogging() async -> Bool {
        print("\n📊 TESTING WITH STEP LOGGING:")
        print("=============================")
        
        let windows = windowManager.getAllWindows()
        guard let testWindow = windows.first else {
            print("❌ No windows available")
            return false
        }
        
        print("🎯 Target window: '\(testWindow.title)' (\(testWindow.appName))")
        
        // Enable detailed logging for this test
        let initialBounds = testWindow.bounds
        print("📍 Initial bounds: \(initialBounds)")
        
        // Create a simple animation task manually
        let targetPosition = CGPoint(
            x: initialBounds.origin.x + 100,
            y: initialBounds.origin.y
        )
        
        print("🎬 Starting manual step animation...")
        
        // Manual animation with logging
        let steps = 20
        let duration = 1.0
        let stepDelay = duration / Double(steps)
        
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let currentX = initialBounds.origin.x + (targetPosition.x - initialBounds.origin.x) * progress
            let currentPosition = CGPoint(x: currentX, y: initialBounds.origin.y)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(step)) { [weak self] in
                guard let self = self else { return }
                let success = self.windowManager.moveWindow(testWindow, to: currentPosition)
                print("📍 Step \(step)/\(steps): \(currentPosition) - \(success ? "✅" : "❌")")
            }
        }
        
        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: UInt64((duration + 0.5) * 1_000_000_000))
        
        // Verify final position
        let finalWindows = windowManager.getAllWindows()
        if let finalWindow = finalWindows.first(where: { $0.appName == testWindow.appName }) {
            let finalPosition = finalWindow.bounds.origin
            let distance = calculateDistance(from: initialBounds.origin, to: finalPosition)
            print("📍 Final position: \(finalPosition)")
            print("📏 Total movement: \(String(format: "%.1f", distance)) pixels")
            return distance > 50
        }
        
        return false
    }
    
    /// Check what's blocking animations
    func diagnoseAnimationIssues() -> [String] {
        print("\n🔍 DIAGNOSING ANIMATION ISSUES:")
        print("==============================")
        
        var issues: [String] = []
        
        // Check permissions
        if !windowManager.checkAccessibilityPermissions() {
            issues.append("❌ Missing accessibility permissions")
        }
        
        // Check user preferences
        if !UserPreferences.shared.animateWindowMovement {
            issues.append("❌ Animations disabled in UserPreferences")
        }
        
        // Check system accessibility
        if UserDefaults.standard.bool(forKey: "accessibilityReduceMotion") {
            issues.append("❌ System reduce motion enabled")
        }
        
        // Check animation queue
        let queueStatus = animationQueue.getQueueStatus()
        if !queueStatus.isProcessing && queueStatus.queuedAnimations > 0 {
            issues.append("⚠️ Animation queue has items but not processing")
        }
        
        // Check available windows
        let windows = windowManager.getAllWindows()
        if windows.isEmpty {
            issues.append("❌ No windows available for animation")
        }
        
        // Check if animations are being called correctly
        let testPreset = AnimationPresets.defaultSmooth
        if testPreset.duration == 0 {
            issues.append("❌ Default animation preset has zero duration")
        }
        
        if issues.isEmpty {
            issues.append("✅ No obvious issues found - animations should work")
        }
        
        return issues
    }
    
    // MARK: - Helper Methods
    
    private func calculateDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func generateRecommendations(issues: [String]) -> [String] {
        var recommendations: [String] = []
        
        for issue in issues {
            if issue.contains("disabled in user preferences") {
                recommendations.append("💡 Enable animations in UserPreferences.shared.animateWindowMovement")
            } else if issue.contains("reduce motion") {
                recommendations.append("💡 Disable 'Reduce Motion' in System Preferences > Accessibility > Display")
            } else if issue.contains("No windows") {
                recommendations.append("💡 Open some applications to test window animations")
            } else if issue.contains("zero duration") {
                recommendations.append("💡 Check animation preset selection logic")
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("💡 Try the testSimpleAnimation() method for detailed testing")
        }
        
        return recommendations
    }
}

// MARK: - Test Result Structure
struct AnimationTestResult {
    let passed: Bool
    let results: [String]
    let issues: [String]
    let recommendations: [String]
    
    func printSummary() {
        print("\n📋 ANIMATION TEST SUMMARY:")
        print("=========================")
        print("Status: \(passed ? "✅ PASSED" : "❌ FAILED")")
        print("")
        
        print("Results:")
        for result in results {
            print("  \(result)")
        }
        print("")
        
        if !issues.isEmpty {
            print("Issues:")
            for issue in issues {
                print("  \(issue)")
            }
            print("")
        }
        
        if !recommendations.isEmpty {
            print("Recommendations:")
            for rec in recommendations {
                print("  \(rec)")
            }
        }
    }
}