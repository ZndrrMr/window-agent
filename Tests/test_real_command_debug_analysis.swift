#!/usr/bin/env swift

import Foundation

print("🔍 ANALYZING REAL 'i want to code' COMMAND OUTPUT")
print("===============================================")
print("User reported: Arc didn't cascade correctly, was smallish, not underneath Xcode")
print("Also: Need clearer debug output showing which app gets which position/size")
print()

// Parse the actual debug output from the command
struct ActualLayout {
    let app: String
    let position: (x: Double, y: Double)
    let size: (width: Double, height: Double)
    let pixelPosition: (x: Int, y: Int)
    let pixelSize: (width: Int, height: Int)
}

print("📋 PARSING ACTUAL COMMAND OUTPUT:")
print("Context: 'general', Focused: Terminal, Apps: Terminal, Arc, Xcode, Finder")
print()

// From the debug output, reconstruct what actually happened
let actualLayouts = [
    ActualLayout(
        app: "Xcode", // First position/size pair
        position: (x: 0.0, y: 0.0),
        size: (width: 648.0, height: 743.75),
        pixelPosition: (x: 0, y: 0),
        pixelSize: (width: 648, height: 744)
    ),
    ActualLayout(
        app: "Arc", // Second position/size pair  
        position: (x: 576.0, y: 87.5),
        size: (width: 504.0, height: 700.0),
        pixelPosition: (x: 576, y: 88),
        pixelSize: (width: 504, height: 700)
    ),
    ActualLayout(
        app: "Terminal", // Third position/size pair (focused)
        position: (x: 1008.0, y: 0.0),
        size: (width: 432.0, height: 875.0),
        pixelPosition: (x: 1008, y: 0),
        pixelSize: (width: 432, height: 875)
    )
]

print("🎯 ACTUAL LAYOUT ANALYSIS:")
for (index, layout) in actualLayouts.enumerated() {
    let focusIcon = layout.app == "Terminal" ? "🎯" : "👁️"
    print("\n\(index + 1). \(focusIcon) \(layout.app):")
    print("   Position: (\(Int(layout.position.x)), \(Int(layout.position.y)))")
    print("   Size: \(layout.pixelSize.width)×\(layout.pixelSize.height)")
    print("   End: (\(layout.pixelPosition.x + layout.pixelSize.width), \(layout.pixelPosition.y + layout.pixelSize.height))")
    
    // Calculate percentages (assuming 1440×900 screen)
    let widthPercent = (Double(layout.pixelSize.width) / 1440.0) * 100
    let heightPercent = (Double(layout.pixelSize.height) / 900.0) * 100
    let xPercent = (layout.position.x / 1440.0) * 100
    let yPercent = (layout.position.y / 900.0) * 100
    
    print("   Percentage: \(String(format: "%.1f", widthPercent))%×\(String(format: "%.1f", heightPercent))% at (\(String(format: "%.1f", xPercent))%, \(String(format: "%.1f", yPercent))%)")
}

print("\n🚨 IDENTIFIED PROBLEMS:")

// Problem 1: Terminal too wide
if let terminal = actualLayouts.first(where: { $0.app == "Terminal" }) {
    let terminalWidthPercent = (Double(terminal.pixelSize.width) / 1440.0) * 100
    if terminalWidthPercent > 30.0 {
        print("❌ TERMINAL TOO WIDE: \(String(format: "%.1f", terminalWidthPercent))% (should be ≤30%)")
    }
}

// Problem 2: Screen coverage
let rightmostX = actualLayouts.map { $0.pixelPosition.x + $0.pixelSize.width }.max() ?? 0
let screenCoverage = (Double(rightmostX) / 1440.0) * 100
if screenCoverage < 95.0 {
    print("❌ WASTED SCREEN SPACE: Only using \(String(format: "%.1f", screenCoverage))% of screen width")
}

// Problem 3: Arc positioning
if let arc = actualLayouts.first(where: { $0.app == "Arc" }),
   let xcode = actualLayouts.first(where: { $0.app == "Xcode" }) {
    let arcWidthPercent = (Double(arc.pixelSize.width) / 1440.0) * 100
    
    print("❌ ARC POSITIONING ISSUES:")
    print("   • Arc width: \(String(format: "%.1f", arcWidthPercent))% (\(arc.pixelSize.width)px)")
    print("   • Arc position: (\(arc.pixelPosition.x), \(arc.pixelPosition.y))")
    print("   • Expected: Arc should cascade from Xcode, not float in middle")
    
    // Check if Arc is actually underneath/overlapping Xcode
    let xcodeEnd = xcode.pixelPosition.x + xcode.pixelSize.width
    let arcStart = arc.pixelPosition.x
    
    if arcStart >= xcodeEnd {
        print("   • Arc is BESIDE Xcode, not cascading underneath")
    } else {
        print("   • Arc overlaps Xcode by \(xcodeEnd - arcStart)px")
    }
}

// Problem 4: Wrong focused app
print("❌ FOCUS ISSUE: Terminal is focused but user wants coding setup")
print("   • Expected: Xcode should be focused for 'i want to code'")
print("   • Actual: Terminal is focused (wrong primary app)")

print("\n🧪 CRITICAL TEST CASES NEEDED:")

print("\n1. ZERO WASTED SPACE TEST:")
print("   • Screen must be ≥95% utilized horizontally")
print("   • No gaps between rightmost window and screen edge")
print("   • Test: rightmost_x ≥ screen_width * 0.95")

print("\n2. TERMINAL WIDTH CONSTRAINT TEST:")
print("   • Terminal focused: ≤30% width")
print("   • Terminal unfocused: ≤25% width") 
print("   • Test: terminal_width ≤ max_allowed_percent")

print("\n3. ARC CASCADE POSITIONING TEST:")
print("   • Arc must cascade from Xcode, not float independently")
print("   • Arc must have functional width (≥500px)")
print("   • Test: arc_x > xcode_x AND arc_x < (xcode_x + xcode_width)")

print("\n4. CORRECT FOCUS FOR CODING TEST:")
print("   • 'i want to code' should focus Xcode or primary coding app")
print("   • Not Terminal (Terminal is supporting tool)")
print("   • Test: focused_app in ['Xcode', 'Cursor', 'VS Code']")

print("\n5. CLEAR DEBUG OUTPUT TEST:")
print("   • Each position/size operation must show app name")
print("   • Format: 'Setting Xcode position to: (x, y)'")
print("   • Test: debug_output contains app names for each operation")

print("\n🔧 FIXES NEEDED:")
print("1. Fix FlexiblePositioning.swift Terminal-focused layout")
print("2. Ensure 'i want to code' focuses Xcode, not Terminal")
print("3. Improve debug output clarity with app names")
print("4. Add comprehensive layout validation tests")
print("5. Ensure Arc cascades properly from Xcode")

print("\n🎯 EXPECTED CORRECTED LAYOUT:")
print("For 'i want to code' with Xcode focused:")
print("• Xcode: 60%×90% at (0%, 0%) - Primary coding space")
print("• Arc: 45%×80% at (40%, 10%) - Cascades from Xcode for docs")
print("• Terminal: 25%×85% at (75%, 0%) - Supporting tool, compact")
print("• Screen usage: 100% (no wasted space)")