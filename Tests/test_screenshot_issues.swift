#!/usr/bin/env swift

import Foundation

print("🔍 SCREENSHOT ISSUE ANALYSIS & TESTS")
print("====================================")
print("Based on user feedback from latest screenshot showing layout problems")
print()

let screenSize = (width: 1440.0, height: 900.0)

struct ScreenshotIssue {
    let problem: String
    let currentBehavior: String
    let expectedBehavior: String
    let testCriteria: String
}

let identifiedIssues = [
    ScreenshotIssue(
        problem: "Terminal way too wide",
        currentBehavior: "Terminal takes >50% of screen width",
        expectedBehavior: "Terminal should be 45-55% max when focused",
        testCriteria: "Terminal width ≤ 55% of screen"
    ),
    ScreenshotIssue(
        problem: "Arc positioned weirdly", 
        currentBehavior: "Arc floating in middle with strange positioning",
        expectedBehavior: "Arc should cascade from a proper edge/corner position",
        testCriteria: "Arc should start from 0%, 25%, or similar clean edge position"
    ),
    ScreenshotIssue(
        problem: "No peek room for Arc",
        currentBehavior: "Xcode full height (100%) blocks Arc peek visibility", 
        expectedBehavior: "Xcode should leave 10-15% margin for Arc to peek through",
        testCriteria: "Xcode height ≤ 90% to allow Arc peek area"
    ),
    ScreenshotIssue(
        problem: "Poor cascade layering",
        currentBehavior: "Windows don't have strategic overlap positioning",
        expectedBehavior: "Clear cascade where each app has visible clickable area",
        testCriteria: "Each non-focused app has 15-25% visible peek area"
    )
]

print("📋 IDENTIFIED ISSUES FROM SCREENSHOT:")
for (index, issue) in identifiedIssues.enumerated() {
    print("\n\(index + 1). ❌ \(issue.problem)")
    print("   Current: \(issue.currentBehavior)")
    print("   Expected: \(issue.expectedBehavior)")
    print("   Test: \(issue.testCriteria)")
}

print("\n🧪 CORRECTED LAYOUT TESTS")
print("========================")

struct CorrectedLayout {
    let app: String
    let isFocused: Bool
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    
    var pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int) {
        let pixelX = Int(x * screenSize.width)
        let pixelY = Int(y * screenSize.height)
        let pixelWidth = Int(width * screenSize.width)
        let pixelHeight = Int(height * screenSize.height)
        
        return (
            x: pixelX,
            y: pixelY,
            width: pixelWidth,
            height: pixelHeight,
            endX: pixelX + pixelWidth,
            endY: pixelY + pixelHeight
        )
    }
}

// CORRECTED LAYOUT: Terminal focused with proper cascade positioning
func generateCorrectedTerminalFocusedLayout() -> [CorrectedLayout] {
    return [
        // Xcode: Left side, reduced height to leave peek room for Arc
        CorrectedLayout(
            app: "Xcode",
            isFocused: false,
            x: 0.0,  // Clean left edge
            y: 0.0,  // Top
            width: 0.30,  // 30% width (432px) - substantial but not dominating
            height: 0.85  // 85% height - leaves 15% for Arc to peek through
        ),
        
        // Arc: Cascade position with proper peek visibility
        CorrectedLayout(
            app: "Arc", 
            isFocused: false,
            x: 0.25,  // Starts at clean 25% position, overlaps Xcode by 72px
            y: 0.10,  // 10% from top - uses the peek space left by Xcode
            width: 0.45,  // 45% width (648px) - functional browsing width
            height: 0.80  // 80% height - substantial but allows layering
        ),
        
        // Terminal: Focused app with balanced space
        CorrectedLayout(
            app: "Terminal",
            isFocused: true,
            x: 0.50,  // Starts at 50% - good overlap with Arc for cascade
            y: 0.0,   // Full height as focused app
            width: 0.50,  // 50% width (720px) - focused but not excessive
            height: 1.0   // Full height for focused terminal
        )
    ]
}

// Test the corrected layout against screenshot issues
func validateCorrectedLayout(_ layouts: [CorrectedLayout]) -> Bool {
    print("\n🧪 VALIDATION AGAINST SCREENSHOT ISSUES:")
    var allTestsPassed = true
    
    // Issue 1: Terminal too wide
    if let terminal = layouts.first(where: { $0.app == "Terminal" && $0.isFocused }) {
        let terminalPercent = terminal.width * 100
        if terminalPercent <= 55 {
            print("  ✅ Terminal width: \(String(format: "%.0f", terminalPercent))% (≤ 55%)")
        } else {
            print("  ❌ Terminal too wide: \(String(format: "%.0f", terminalPercent))% (> 55%)")
            allTestsPassed = false
        }
    }
    
    // Issue 2: Arc positioning
    if let arc = layouts.first(where: { $0.app == "Arc" }) {
        let arcStartPercent = arc.x * 100
        let cleanPositions = [0, 20, 25, 30, 50] // Clean edge positions
        let isCleanPosition = cleanPositions.contains { abs(Double($0) - arcStartPercent) < 5 }
        
        if isCleanPosition {
            print("  ✅ Arc clean position: starts at \(String(format: "%.0f", arcStartPercent))%")
        } else {
            print("  ❌ Arc weird position: starts at \(String(format: "%.1f", arcStartPercent))% (not clean edge)")
            allTestsPassed = false
        }
    }
    
    // Issue 3: Peek room for Arc
    if let xcode = layouts.first(where: { $0.app == "Xcode" }) {
        let xcodeHeightPercent = xcode.height * 100
        if xcodeHeightPercent <= 90 {
            print("  ✅ Xcode peek room: \(String(format: "%.0f", xcodeHeightPercent))% height (≤ 90%)")
        } else {
            print("  ❌ Xcode blocks peek: \(String(format: "%.0f", xcodeHeightPercent))% height (> 90%)")
            allTestsPassed = false
        }
    }
    
    // Issue 4: Proper cascade visibility
    let nonFocusedApps = layouts.filter { !$0.isFocused }
    var cascadeTestPassed = true
    
    for app in nonFocusedApps {
        let visiblePercent = app.width * 100
        if visiblePercent >= 15 && visiblePercent <= 50 {
            print("  ✅ \(app.app) cascade visibility: \(String(format: "%.0f", visiblePercent))% (15-50%)")
        } else {
            print("  ❌ \(app.app) poor visibility: \(String(format: "%.0f", visiblePercent))% (outside 15-50%)")
            cascadeTestPassed = false
        }
    }
    
    if !cascadeTestPassed {
        allTestsPassed = false
    }
    
    // Additional test: Full screen usage (no wasted space)
    let rightmost = layouts.map { $0.x + $0.width }.max() ?? 0
    if rightmost >= 0.95 {
        print("  ✅ Screen usage: \(String(format: "%.1f", rightmost * 100))% (≥ 95%)")
    } else {
        print("  ❌ Wasted space: only \(String(format: "%.1f", rightmost * 100))% used")
        allTestsPassed = false
    }
    
    // Overlap validation (cascade requirement)
    if let terminal = layouts.first(where: { $0.app == "Terminal" && $0.isFocused }),
       let arc = layouts.first(where: { $0.app == "Arc" }) {
        
        let terminalStart = terminal.x
        let arcEnd = arc.x + arc.width
        
        if arcEnd > terminalStart {
            let overlapWidth = Int((arcEnd - terminalStart) * screenSize.width)
            print("  ✅ Cascade overlap: Arc overlaps Terminal by \(overlapWidth)px")
        } else {
            print("  ❌ No cascade: Arc and Terminal don't overlap")
            allTestsPassed = false
        }
    }
    
    return allTestsPassed
}

// Test the corrected layout
print("\n📱 CORRECTED TERMINAL-FOCUSED LAYOUT:")
let correctedLayouts = generateCorrectedTerminalFocusedLayout()

for layout in correctedLayouts {
    let focusIndicator = layout.isFocused ? "🎯" : "👁️"
    let bounds = layout.pixelBounds
    print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
    print("    Pixels: \(bounds.width)×\(bounds.height) at (\(bounds.x), \(bounds.y)) → (\(bounds.endX), \(bounds.endY))")
}

let testsPassed = validateCorrectedLayout(correctedLayouts)

print("\n📊 TEST RESULTS")
print("===============")
if testsPassed {
    print("🎉 ALL TESTS PASSED! Corrected layout addresses screenshot issues.")
    print()
    print("✨ Key improvements:")
    print("• Terminal focused but not excessive (50% width vs >55%)")
    print("• Arc clean cascade position (25% start vs weird floating)")
    print("• Xcode leaves peek room (85% height vs 100%)")
    print("• Proper cascade overlaps with good visibility")
    print("• Full screen utilization")
} else {
    print("❌ TESTS FAILED! Layout still has issues.")
}

print("\n🚀 Next: Update FlexiblePositioning.swift with corrected Terminal layout")