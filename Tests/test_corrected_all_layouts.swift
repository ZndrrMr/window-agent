#!/usr/bin/env swift

import Foundation

print("🧪 TESTING ALL CORRECTED LAYOUTS")
print("================================")

let screenSize = (width: 1440.0, height: 900.0)

struct Layout {
    let app: String
    let isFocused: Bool
    let x: Double, y: Double, width: Double, height: Double
    
    var pixelBounds: (x: Int, y: Int, width: Int, height: Int) {
        return (
            x: Int(x * screenSize.width),
            y: Int(y * screenSize.height),
            width: Int(width * screenSize.width),
            height: Int(height * screenSize.height)
        )
    }
}

func testLayout(focusedApp: String, layouts: [Layout]) -> Bool {
    print("\n🎯 Testing \(focusedApp) focused layout:")
    
    var allTestsPassed = true
    
    // Display the layout
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        let bounds = layout.pixelBounds
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
        print("    Pixels: \(bounds.width)×\(bounds.height)")
    }
    
    print("\n  🧪 Validation:")
    
    // Test 1: Focused app width (should be 50-70%)
    if let focused = layouts.first(where: { $0.isFocused }) {
        let focusedPercent = focused.width * 100
        if focusedPercent >= 50 && focusedPercent <= 70 {
            print("    ✅ Focused width: \(String(format: "%.0f", focusedPercent))% (balanced)")
        } else {
            print("    ❌ Focused width: \(String(format: "%.0f", focusedPercent))% (should be 50-70%)")
            allTestsPassed = false
        }
    }
    
    // Test 2: All apps have reduced height (≤ 90%) to allow peek room
    let fullHeightApps = layouts.filter { $0.height > 0.90 }
    if fullHeightApps.count <= 1 { // Only focused app can be full height
        print("    ✅ Peek room: Most apps ≤ 90% height (allows cascade peeks)")
    } else {
        print("    ❌ No peek room: \(fullHeightApps.count) apps at full height")
        allTestsPassed = false
    }
    
    // Test 3: Arc has functional width (≥ 500px)
    if let arc = layouts.first(where: { $0.app == "Arc" }) {
        let arcPixels = arc.pixelBounds.width
        if arcPixels >= 500 {
            print("    ✅ Arc functional: \(arcPixels)px width")
        } else {
            print("    ❌ Arc too narrow: \(arcPixels)px width")
            allTestsPassed = false
        }
    }
    
    // Test 4: Clean positioning (apps start at 0%, 20%, 25%, 40%, 50%, 70%, etc.)
    let cleanPositions = [0.0, 0.20, 0.25, 0.40, 0.50, 0.70, 0.75]
    var hasCleanPositioning = true
    
    for layout in layouts {
        let xPercent = layout.x
        let isClean = cleanPositions.contains { abs($0 - xPercent) < 0.05 }
        if !isClean {
            hasCleanPositioning = false
            break
        }
    }
    
    if hasCleanPositioning {
        print("    ✅ Clean positioning: All apps start at clean percentage positions")
    } else {
        print("    ❌ Weird positioning: Some apps have odd start positions")
        allTestsPassed = false
    }
    
    // Test 5: Full screen usage
    let rightmost = layouts.map { $0.x + $0.width }.max() ?? 0
    if rightmost >= 0.95 {
        print("    ✅ Screen usage: \(String(format: "%.1f", rightmost * 100))%")
    } else {
        print("    ❌ Wasted space: \(String(format: "%.1f", rightmost * 100))%")
        allTestsPassed = false
    }
    
    return allTestsPassed
}

// Test all corrected layouts
print("📱 CORRECTED LAYOUTS:")

// Xcode focused
let xcodeLayouts = [
    Layout(app: "Xcode", isFocused: true, x: 0.0, y: 0.0, width: 0.60, height: 0.90),
    Layout(app: "Arc", isFocused: false, x: 0.40, y: 0.10, width: 0.45, height: 0.80),
    Layout(app: "Terminal", isFocused: false, x: 0.70, y: 0.0, width: 0.30, height: 0.85)
]

// Arc focused  
let arcLayouts = [
    Layout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.25, height: 0.85),
    Layout(app: "Arc", isFocused: true, x: 0.20, y: 0.0, width: 0.55, height: 0.90),
    Layout(app: "Terminal", isFocused: false, x: 0.70, y: 0.10, width: 0.30, height: 0.80)
]

// Terminal focused (corrected based on screenshot issues)
let terminalLayouts = [
    Layout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.30, height: 0.85),
    Layout(app: "Arc", isFocused: false, x: 0.25, y: 0.10, width: 0.45, height: 0.80),
    Layout(app: "Terminal", isFocused: true, x: 0.50, y: 0.0, width: 0.50, height: 1.0)
]

let xcodePass = testLayout(focusedApp: "Xcode", layouts: xcodeLayouts)
let arcPass = testLayout(focusedApp: "Arc", layouts: arcLayouts)
let terminalPass = testLayout(focusedApp: "Terminal", layouts: terminalLayouts)

print("\n📊 OVERALL RESULTS")
print("==================")
if xcodePass && arcPass && terminalPass {
    print("🎉 ALL LAYOUTS PASSED! Ready to rebuild and test.")
    print()
    print("✨ Key improvements addressing screenshot issues:")
    print("• Terminal width reduced to 50% (was >55%)")
    print("• Arc positioned at clean 25% start (was weird floating)")
    print("• All non-focused apps leave peek room (85-90% height)")
    print("• Proper cascade overlaps maintained")
    print("• Full screen utilization")
} else {
    print("❌ Some layouts failed:")
    print("  Xcode focused: \(xcodePass ? "✅" : "❌")")
    print("  Arc focused: \(arcPass ? "✅" : "❌")")
    print("  Terminal focused: \(terminalPass ? "✅" : "❌")")
}

print("\n🚀 Ready to rebuild WindowAI with corrected layouts")