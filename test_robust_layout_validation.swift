#!/usr/bin/env swift

import Foundation

print("🛡️ ROBUST LAYOUT VALIDATION TESTS")
print("==================================")
print("Creating tests to ensure layout issues NEVER happen")
print()

struct LayoutTest {
    let name: String
    let description: String
    let testFunction: ([(app: String, x: Double, y: Double, width: Double, height: Double, focused: Bool)]) -> (passed: Bool, message: String)
}

// Define screen dimensions
let SCREEN_WIDTH = 1440.0
let SCREEN_HEIGHT = 900.0

// Create comprehensive validation tests
let validationTests = [
    LayoutTest(
        name: "ZERO_WASTED_SPACE",
        description: "Screen must be ≥95% utilized horizontally - NO gaps allowed",
        testFunction: { layouts in
            let rightmostX = layouts.map { $0.x + $0.width }.max() ?? 0
            let screenUsage = rightmostX * 100
            
            if screenUsage >= 95.0 {
                return (true, "✅ Screen usage: \(String(format: "%.1f", screenUsage))%")
            } else {
                let wastedSpace = 100.0 - screenUsage
                return (false, "❌ WASTED SPACE: \(String(format: "%.1f", wastedSpace))% of screen unused (rightmost: \(String(format: "%.1f", rightmostX * 100))%)")
            }
        }
    ),
    
    LayoutTest(
        name: "TERMINAL_WIDTH_CONSTRAINT",
        description: "Terminal ≤30% focused, ≤25% unfocused - NEVER exceed",
        testFunction: { layouts in
            guard let terminal = layouts.first(where: { $0.app == "Terminal" }) else {
                return (true, "✅ No Terminal in layout")
            }
            
            let terminalWidthPercent = terminal.width * 100
            let maxAllowed = terminal.focused ? 30.0 : 25.0
            let focusStatus = terminal.focused ? "focused" : "unfocused"
            
            if terminalWidthPercent <= maxAllowed {
                return (true, "✅ Terminal: \(String(format: "%.1f", terminalWidthPercent))% (≤\(maxAllowed)% for \(focusStatus))")
            } else {
                let excess = terminalWidthPercent - maxAllowed
                return (false, "❌ TERMINAL TOO WIDE: \(String(format: "%.1f", terminalWidthPercent))% exceeds \(maxAllowed)% by \(String(format: "%.1f", excess))%")
            }
        }
    ),
    
    LayoutTest(
        name: "ARC_FUNCTIONAL_WIDTH",
        description: "Arc must have ≥500px width for functional browsing",
        testFunction: { layouts in
            guard let arc = layouts.first(where: { $0.app == "Arc" }) else {
                return (true, "✅ No Arc in layout")
            }
            
            let arcPixelWidth = Int(arc.width * SCREEN_WIDTH)
            
            if arcPixelWidth >= 500 {
                return (true, "✅ Arc functional: \(arcPixelWidth)px width")
            } else {
                let shortage = 500 - arcPixelWidth
                return (false, "❌ ARC TOO NARROW: \(arcPixelWidth)px (needs \(shortage)px more)")
            }
        }
    ),
    
    LayoutTest(
        name: "ARC_CASCADE_POSITIONING",
        description: "Arc must cascade from Xcode, not float independently",
        testFunction: { layouts in
            guard let arc = layouts.first(where: { $0.app == "Arc" }),
                  let xcode = layouts.first(where: { $0.app == "Xcode" }) else {
                return (true, "✅ Arc or Xcode not in layout")
            }
            
            let xcodeEnd = xcode.x + xcode.width
            let arcStart = arc.x
            
            // Arc should start within or slightly overlap Xcode's area for proper cascade
            if arcStart >= xcode.x && arcStart <= xcodeEnd {
                let overlapWidth = Int((xcodeEnd - arcStart) * SCREEN_WIDTH)
                return (true, "✅ Arc cascades from Xcode (overlap: \(overlapWidth)px)")
            } else {
                return (false, "❌ ARC NOT CASCADING: Arc at \(String(format: "%.1f", arcStart * 100))%, Xcode ends at \(String(format: "%.1f", xcodeEnd * 100))%")
            }
        }
    ),
    
    LayoutTest(
        name: "CODING_FOCUS_PRIORITY", 
        description: "'i want to code' should focus Xcode/coding app, not Terminal",
        testFunction: { layouts in
            let focusedApp = layouts.first { $0.focused }?.app ?? "None"
            let codingApps = ["Xcode", "Cursor", "VS Code", "Visual Studio Code"]
            
            if codingApps.contains(focusedApp) {
                return (true, "✅ Coding app focused: \(focusedApp)")
            } else if focusedApp == "Terminal" {
                return (false, "❌ WRONG FOCUS: Terminal focused for coding (should be Xcode/IDE)")
            } else {
                return (false, "❌ UNEXPECTED FOCUS: \(focusedApp) focused for coding")
            }
        }
    ),
    
    LayoutTest(
        name: "NO_OVERLAPPING_CHAOS",
        description: "Apps should have strategic overlaps, not chaotic positioning",
        testFunction: { layouts in
            var overlaps: [(String, String, Double)] = []
            
            for i in 0..<layouts.count {
                for j in (i+1)..<layouts.count {
                    let app1 = layouts[i]
                    let app2 = layouts[j]
                    
                    let app1End = app1.x + app1.width
                    let app2End = app2.x + app2.width
                    
                    // Check horizontal overlap
                    if app1.x < app2End && app2.x < app1End {
                        let overlapStart = max(app1.x, app2.x)
                        let overlapEnd = min(app1End, app2End)
                        let overlapPercent = (overlapEnd - overlapStart) * 100
                        overlaps.append((app1.app, app2.app, overlapPercent))
                    }
                }
            }
            
            if overlaps.count <= 2 && overlaps.allSatisfy({ $0.2 >= 5.0 && $0.2 <= 50.0 }) {
                return (true, "✅ Strategic overlaps: \(overlaps.count) meaningful cascades")
            } else if overlaps.isEmpty {
                return (false, "❌ NO CASCADE: Apps are side-by-side (no overlaps)")
            } else {
                return (false, "❌ CHAOTIC OVERLAPS: \(overlaps.count) overlaps detected")
            }
        }
    ),
    
    LayoutTest(
        name: "MINIMUM_VISIBILITY",
        description: "Each app must have meaningful visible area (≥15% width)",
        testFunction: { layouts in
            for layout in layouts {
                let widthPercent = layout.width * 100
                if widthPercent < 15.0 {
                    return (false, "❌ \(layout.app) TOO NARROW: \(String(format: "%.1f", widthPercent))% (needs ≥15%)")
                }
            }
            return (true, "✅ All apps have meaningful visibility (≥15% width)")
        }
    )
]

func runValidationTests(on layouts: [(app: String, x: Double, y: Double, width: Double, height: Double, focused: Bool)], scenario: String) -> (passed: Bool, results: [String]) {
    print("\n🧪 TESTING SCENARIO: \(scenario)")
    print("Layout: \(layouts.map { $0.app }.joined(separator: ", "))")
    print("Focused: \(layouts.first { $0.focused }?.app ?? "None")")
    
    var allPassed = true
    var results: [String] = []
    
    for test in validationTests {
        let result = test.testFunction(layouts)
        results.append("[\(test.name)] \(result.message)")
        
        if !result.passed {
            allPassed = false
        }
    }
    
    return (allPassed, results)
}

print("📋 VALIDATION TEST DEFINITIONS:")
for (index, test) in validationTests.enumerated() {
    print("\(index + 1). \(test.name)")
    print("   \(test.description)")
}

print("\n🧪 TESTING ACTUAL COMMAND OUTPUT:")

// Test the actual problematic layout from user's command
let actualProblematicLayout = [
    (app: "Xcode", x: 0.0, y: 0.0, width: 0.45, height: 0.827, focused: false),
    (app: "Arc", x: 0.40, y: 0.097, width: 0.35, height: 0.778, focused: false),
    (app: "Terminal", x: 0.70, y: 0.0, width: 0.30, height: 0.972, focused: true)
]

let (actualPassed, actualResults) = runValidationTests(on: actualProblematicLayout, scenario: "ACTUAL COMMAND OUTPUT")

for result in actualResults {
    print("  \(result)")
}

if !actualPassed {
    print("\n❌ ACTUAL LAYOUT FAILED VALIDATION")
} else {
    print("\n✅ Actual layout passed all tests")
}

print("\n🎯 TESTING EXPECTED CORRECTED LAYOUT:")

// Test the expected corrected layout
let expectedCorrectedLayout = [
    (app: "Xcode", x: 0.0, y: 0.0, width: 0.60, height: 0.90, focused: true),
    (app: "Arc", x: 0.40, y: 0.10, width: 0.45, height: 0.80, focused: false),
    (app: "Terminal", x: 0.75, y: 0.0, width: 0.25, height: 0.85, focused: false)
]

let (expectedPassed, expectedResults) = runValidationTests(on: expectedCorrectedLayout, scenario: "EXPECTED CORRECTED LAYOUT")

for result in expectedResults {
    print("  \(result)")
}

if expectedPassed {
    print("\n✅ EXPECTED LAYOUT PASSES ALL TESTS")
} else {
    print("\n❌ Expected layout still has issues")
}

print("\n📊 VALIDATION SUMMARY:")
print("Actual layout passed: \(actualPassed ? "✅" : "❌")")
print("Expected layout passed: \(expectedPassed ? "✅" : "❌")")

if !actualPassed && expectedPassed {
    print("\n🔧 FIXES CONFIRMED NEEDED:")
    print("1. Change focus from Terminal to Xcode for 'i want to code'")
    print("2. Ensure proper cascade positioning")
    print("3. Maintain screen utilization")
    print("4. Keep Terminal within width constraints")
}

print("\n🚀 NEXT: Implement these validation tests in WindowAI")