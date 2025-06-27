#!/usr/bin/env swift

import Foundation

print("🎯 TESTING CORRECT FOCUS-AWARE LAYOUT")
print("=====================================")
print("Based on user feedback from screenshot - fixing the layout issues")
print()

let screenSize = (width: 1440.0, height: 900.0)
let apps = ["Xcode", "Arc", "Terminal"]

struct CorrectLayout {
    let app: String
    let isFocused: Bool
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    let pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int)
    let isOverlapping: Bool // Should this window overlap with others?
    let peekArea: Double // How much of this window should be visible when not focused
    
    init(app: String, isFocused: Bool, x: Double, y: Double, width: Double, height: Double, screenSize: (width: Double, height: Double)) {
        self.app = app
        self.isFocused = isFocused
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        
        let pixelX = Int(x * screenSize.width)
        let pixelY = Int(y * screenSize.height)
        let pixelWidth = Int(width * screenSize.width)
        let pixelHeight = Int(height * screenSize.height)
        
        self.pixelBounds = (
            x: pixelX,
            y: pixelY,
            width: pixelWidth,
            height: pixelHeight,
            endX: pixelX + pixelWidth,
            endY: pixelY + pixelHeight
        )
        
        // Check if this is overlapping with other windows (cascade behavior)
        self.isOverlapping = !isFocused // Non-focused apps should peek from behind
        
        // Calculate how much of this window should be visible as peek area
        if isFocused {
            self.peekArea = 1.0 // Focused app is fully visible
        } else {
            // Non-focused apps should have substantial peek areas (25-40% visible)
            self.peekArea = min(0.4, max(0.25, width * 0.6))
        }
    }
}

// CRITICAL TESTS based on user feedback from screenshot
func testCorrectFocusAwareLayout(focusedApp: String) -> [CorrectLayout] {
    print("🎯 Testing CORRECT layout with \(focusedApp) focused:")
    
    switch focusedApp {
    case "Xcode":
        // Xcode focused: Should be primary (60-70% width) with Arc cascading behind/above for peek access
        return [
            CorrectLayout(app: "Xcode", isFocused: true, x: 0.0, y: 0.0, width: 0.65, height: 1.0, screenSize: screenSize),
            CorrectLayout(app: "Arc", isFocused: false, x: 0.45, y: 0.05, width: 0.50, height: 0.85, screenSize: screenSize), // Overlaps Xcode for cascade peek
            CorrectLayout(app: "Terminal", isFocused: false, x: 0.70, y: 0.0, width: 0.30, height: 1.0, screenSize: screenSize)
        ]
        
    case "Arc":
        // Arc focused: Should get substantial space (55-65% width) with Xcode and Terminal as side columns
        return [
            CorrectLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.25, height: 1.0, screenSize: screenSize),
            CorrectLayout(app: "Arc", isFocused: true, x: 0.20, y: 0.0, width: 0.60, height: 1.0, screenSize: screenSize), // Overlaps slightly for cascade
            CorrectLayout(app: "Terminal", isFocused: false, x: 0.75, y: 0.0, width: 0.25, height: 1.0, screenSize: screenSize)
        ]
        
    case "Terminal":
        // Terminal focused: Should get good space (45-55% width) with others cascading
        return [
            CorrectLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.30, height: 1.0, screenSize: screenSize),
            CorrectLayout(app: "Arc", isFocused: false, x: 0.25, y: 0.05, width: 0.45, height: 0.9, screenSize: screenSize), // Cascade peek
            CorrectLayout(app: "Terminal", isFocused: true, x: 0.45, y: 0.0, width: 0.55, height: 1.0, screenSize: screenSize)
        ]
        
    default:
        return []
    }
}

func validateCorrectLayout(_ layouts: [CorrectLayout], focusedApp: String) -> Bool {
    print("\n🧪 CRITICAL VALIDATION (Based on User Feedback):")
    var allTestsPassed = true
    
    // TEST 1: NO WASTED SCREEN SPACE
    let rightmostX = layouts.map { $0.x + $0.width }.max() ?? 0
    if rightmostX < 0.95 { // Should use at least 95% of screen width
        print("  ❌ WASTED SPACE: Only using \(String(format: "%.1f", rightmostX * 100))% of screen width")
        print("     User complaint: \"there should not be blank screen on the right side\"")
        allTestsPassed = false
    } else {
        print("  ✅ FULL SCREEN USAGE: Using \(String(format: "%.1f", rightmostX * 100))% of screen width")
    }
    
    // TEST 2: ARC BROWSER MUST BE FUNCTIONALLY WIDE
    if let arcLayout = layouts.first(where: { $0.app == "Arc" }) {
        let arcWidthPixels = arcLayout.pixelBounds.width
        if arcWidthPixels < 500 { // Arc needs at least 500px to be functional
            print("  ❌ ARC TOO SKINNY: Arc only \(arcWidthPixels)px wide (needs 500px minimum)")
            print("     User complaint: \"arc browser is skinny and not correct\"")
            allTestsPassed = false
        } else {
            print("  ✅ ARC FUNCTIONAL WIDTH: Arc is \(arcWidthPixels)px wide (adequate for browsing)")
        }
    }
    
    // TEST 3: MUST HAVE CASCADE OVERLAPS
    let focusedLayout = layouts.first { $0.isFocused }!
    let nonFocusedLayouts = layouts.filter { !$0.isFocused }
    
    var hasProperCascade = false
    for nonFocused in nonFocusedLayouts {
        // Check if non-focused app overlaps with focused app (cascade behavior)
        let focusedEnd = focusedLayout.x + focusedLayout.width
        let nonFocusedStart = nonFocused.x
        let nonFocusedEnd = nonFocused.x + nonFocused.width
        
        if (nonFocusedStart < focusedEnd && nonFocusedEnd > focusedLayout.x) {
            hasProperCascade = true
            let overlapStart = max(focusedLayout.x, nonFocusedStart)
            let overlapEnd = min(focusedEnd, nonFocusedEnd)
            let overlapWidth = (overlapEnd - overlapStart) * screenSize.width
            print("  ✅ CASCADE OVERLAP: \(nonFocused.app) overlaps \(focusedLayout.app) by \(Int(overlapWidth))px")
        }
    }
    
    if !hasProperCascade {
        print("  ❌ NO CASCADE: Windows are side-by-side instead of overlapping")
        print("     User complaint: \"it still needed cascade area so we could see arc underneath or above it\"")
        allTestsPassed = false
    }
    
    // TEST 4: FOCUSED APP GETS PRIMARY SPACE BUT NOT EVERYTHING
    let focusedPercent = focusedLayout.width * 100
    if focusedPercent < 45 {
        print("  ❌ FOCUSED APP TOO SMALL: \(focusedLayout.app) only gets \(String(format: "%.1f", focusedPercent))%")
        allTestsPassed = false
    } else if focusedPercent > 75 {
        print("  ❌ FOCUSED APP TOO LARGE: \(focusedLayout.app) gets \(String(format: "%.1f", focusedPercent))% (leaves no room for peek areas)")
        allTestsPassed = false
    } else {
        print("  ✅ FOCUSED APP BALANCED: \(focusedLayout.app) gets \(String(format: "%.1f", focusedPercent))% (good balance)")
    }
    
    // TEST 5: ALL APPS REMAIN SUBSTANTIALLY VISIBLE
    for layout in nonFocusedLayouts {
        let visiblePercent = layout.width * 100
        if visiblePercent < 20 {
            print("  ❌ \(layout.app) TOO NARROW: Only \(String(format: "%.1f", visiblePercent))% width")
            allTestsPassed = false
        } else {
            print("  ✅ \(layout.app) SUBSTANTIAL: \(String(format: "%.1f", visiblePercent))% width (good peek area)")
        }
    }
    
    return allTestsPassed
}

// Test all focus scenarios with the correct expectations
print("📋 TESTING ALL FOCUS SCENARIOS:")
print("===============================")

var allScenariosPass = true

for focusedApp in apps {
    print("\n" + "🎯 SCENARIO: \(focusedApp.uppercased()) FOCUSED")
    print(String(repeating: "=", count: 50))
    
    let layouts = testCorrectFocusAwareLayout(focusedApp: focusedApp)
    
    print("📱 Generated Layout:")
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        let overlapIndicator = layout.isOverlapping ? "🔄" : "📐"
        print("  \(focusIndicator)\(overlapIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
        print("    Pixels: \(layout.pixelBounds.width)×\(layout.pixelBounds.height) at (\(layout.pixelBounds.x), \(layout.pixelBounds.y))")
        if layout.isOverlapping {
            print("    Cascade peek area: \(String(format: "%.1f", layout.peekArea * 100))% visible")
        }
    }
    
    let scenarioPass = validateCorrectLayout(layouts, focusedApp: focusedApp)
    if !scenarioPass {
        allScenariosPass = false
        print("\n❌ SCENARIO FAILED: \(focusedApp) layout doesn't meet requirements")
    } else {
        print("\n✅ SCENARIO PASSED: \(focusedApp) layout meets all requirements")
    }
}

print("\n" + "📊 FINAL TEST RESULTS")
print(String(repeating: "=", count: 25))
if allScenariosPass {
    print("🎉 ALL TESTS PASSED! Layout system meets user requirements.")
    print("\n✨ Key Success Factors:")
    print("• Full screen utilization (no wasted space)")
    print("• Arc browser gets functional width (500px+)")  
    print("• Proper cascade overlaps for peek access")
    print("• Focused app gets primary space but leaves room for others")
    print("• All apps remain substantially visible")
} else {
    print("❌ TESTS FAILED! Need to fix the focus-aware layout implementation.")
    print("\n🔧 Issues to address:")
    print("• Eliminate wasted screen space")
    print("• Make Arc browser functionally wide")
    print("• Implement proper cascade overlapping")
    print("• Balance focused app space with peek requirements")
}

print("\n🚀 Next: Update FlexiblePositioning.swift to implement this correct behavior")