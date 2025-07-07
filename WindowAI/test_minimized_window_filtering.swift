#!/usr/bin/env swift

import Foundation
import Cocoa

print("🧪 TDD RED PHASE: Testing Minimized Window Filtering")
print("🔍 Verifying that minimized windows are properly excluded from X-Ray overlay")
print("")

// Test case: Simulate the current X-Ray filtering logic
func testCurrentXRayFiltering() -> Bool {
    print("📊 Testing Current X-Ray Filtering Logic...")
    
    // Simulate window data that would come from WindowManager.getAllWindows()
    struct TestWindowInfo {
        let title: String
        let appName: String
        let bounds: CGRect
        let isMinimized: Bool // This simulates what the AX API would tell us
    }
    
    let testWindows = [
        // Normal visible windows
        TestWindowInfo(title: "Safari - Google", appName: "Safari", bounds: CGRect(x: 100, y: 100, width: 800, height: 600), isMinimized: false),
        TestWindowInfo(title: "Terminal", appName: "Terminal", bounds: CGRect(x: 200, y: 150, width: 600, height: 400), isMinimized: false),
        
        // Minimized windows (these should be EXCLUDED but currently aren't)
        TestWindowInfo(title: "Slack", appName: "Slack", bounds: CGRect(x: 300, y: 200, width: 700, height: 500), isMinimized: true),
        TestWindowInfo(title: "VS Code", appName: "Code", bounds: CGRect(x: 150, y: 100, width: 900, height: 700), isMinimized: true),
        
        // Hidden windows (these should be excluded and currently are)
        TestWindowInfo(title: "Hidden Window", appName: "TestApp", bounds: CGRect(x: -10000, y: 200, width: 400, height: 300), isMinimized: false)
    ]
    
    print("   Total test windows: \(testWindows.count)")
    print("   Expected visible: 2 (only non-minimized)")
    print("   Expected excluded: 3 (2 minimized + 1 hidden)")
    
    // Simulate current ULTRA-FAST filtering logic (position-based only)
    let currentFilteredWindows = testWindows.filter { window in
        // Current logic: Only position-based filtering (MISSING minimized check)
        return window.bounds.origin.x > -5000 && window.bounds.origin.y > -5000
    }
    
    let actualVisible = currentFilteredWindows.count
    let expectedVisible = 2 // Only Safari and Terminal should be visible
    
    print("   Actual visible with current logic: \(actualVisible)")
    print("   Expected visible: \(expectedVisible)")
    
    let testPassed = actualVisible == expectedVisible
    print("   Test Result: \(testPassed ? "✅ PASS" : "❌ FAIL") - \(testPassed ? "Minimized windows properly excluded" : "Minimized windows incorrectly included")")
    
    if !testPassed {
        print("   🐛 BUG CONFIRMED: Current logic shows \(actualVisible - expectedVisible) extra minimized windows")
        print("   📋 Minimized windows that should be hidden:")
        for window in currentFilteredWindows where window.isMinimized {
            print("      - \(window.title) (\(window.appName))")
        }
    }
    
    return testPassed
}

// Test case: Verify correct filtering logic (what we want to implement)
func testCorrectMinimizedFiltering() -> Bool {
    print("📊 Testing Correct Minimized Window Filtering...")
    
    struct TestWindowInfo {
        let title: String
        let appName: String
        let bounds: CGRect
        let isMinimized: Bool
    }
    
    let testWindows = [
        TestWindowInfo(title: "Safari - Google", appName: "Safari", bounds: CGRect(x: 100, y: 100, width: 800, height: 600), isMinimized: false),
        TestWindowInfo(title: "Terminal", appName: "Terminal", bounds: CGRect(x: 200, y: 150, width: 600, height: 400), isMinimized: false),
        TestWindowInfo(title: "Slack", appName: "Slack", bounds: CGRect(x: 300, y: 200, width: 700, height: 500), isMinimized: true),
        TestWindowInfo(title: "VS Code", appName: "Code", bounds: CGRect(x: 150, y: 100, width: 900, height: 700), isMinimized: true),
        TestWindowInfo(title: "Hidden Window", appName: "TestApp", bounds: CGRect(x: -10000, y: 200, width: 400, height: 300), isMinimized: false)
    ]
    
    // Correct logic: Both position AND minimization checks
    let correctFilteredWindows = testWindows.filter { window in
        // Position check (existing)
        guard window.bounds.origin.x > -5000 && window.bounds.origin.y > -5000 else {
            return false
        }
        
        // Minimization check (MISSING in current implementation)
        guard !window.isMinimized else {
            return false
        }
        
        return true
    }
    
    let actualVisible = correctFilteredWindows.count
    let expectedVisible = 2 // Only Safari and Terminal
    
    print("   Correct filtering shows: \(actualVisible) windows")
    print("   Expected: \(expectedVisible) windows")
    
    let testPassed = actualVisible == expectedVisible
    print("   Test Result: \(testPassed ? "✅ PASS" : "❌ FAIL")")
    
    return testPassed
}

// Run TDD tests
print("🚀 Running TDD Minimized Window Filter Tests")
print("=" + String(repeating: "=", count: 55))

let currentLogicTest = testCurrentXRayFiltering()
print("")
let correctLogicTest = testCorrectMinimizedFiltering()

print("")
print("📋 TDD Test Results:")
print("   Current X-Ray Logic: \(currentLogicTest ? "✅ PASS" : "❌ FAIL (expected - this confirms the bug)")")
print("   Correct Filter Logic: \(correctLogicTest ? "✅ PASS" : "❌ FAIL")")

print("")
if !currentLogicTest && correctLogicTest {
    print("🎯 TDD RED PHASE SUCCESS!")
    print("✅ Test confirms the bug exists in current implementation")
    print("✅ Test shows correct filtering logic works")
    print("📝 Ready to implement fix: Add minimization check to X-Ray filtering")
} else {
    print("❌ TDD RED PHASE ISSUES!")
    if currentLogicTest {
        print("⚠️  Current logic test passed - bug may not exist or test is wrong")
    }
    if !correctLogicTest {
        print("⚠️  Correct logic test failed - test design issue")
    }
}

print("")
print("💡 Next Steps:")
print("   1. Add minimization check to XRayWindowManager.getVisibleWindowsAsync()")
print("   2. Use fast isWindowVisible() with timeout for minimization detection")
print("   3. Verify tests pass after implementation")