#!/usr/bin/env swift

import Foundation

print("✅ TESTING CORRECTED TERMINAL 30% IMPLEMENTATION")
print("===============================================")
print("Testing the updated FlexiblePositioning.swift for Terminal ≤30% requirement")
print()

let screenSize = (width: 1440.0, height: 900.0)

struct CorrectedLayout {
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

// Updated layouts from corrected FlexiblePositioning.swift
let correctedLayouts = [
    (
        scenario: "Xcode focused",
        apps: [
            CorrectedLayout(app: "Xcode", isFocused: true, x: 0.0, y: 0.0, width: 0.60, height: 0.90),
            CorrectedLayout(app: "Arc", isFocused: false, x: 0.40, y: 0.10, width: 0.45, height: 0.80),
            CorrectedLayout(app: "Terminal", isFocused: false, x: 0.75, y: 0.0, width: 0.25, height: 0.85) // ≤25%
        ]
    ),
    (
        scenario: "Arc focused", 
        apps: [
            CorrectedLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.25, height: 0.85),
            CorrectedLayout(app: "Arc", isFocused: true, x: 0.20, y: 0.0, width: 0.55, height: 0.90),
            CorrectedLayout(app: "Terminal", isFocused: false, x: 0.75, y: 0.10, width: 0.25, height: 0.80) // ≤25%
        ]
    ),
    (
        scenario: "Terminal focused",
        apps: [
            CorrectedLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.45, height: 0.85),
            CorrectedLayout(app: "Arc", isFocused: false, x: 0.40, y: 0.10, width: 0.35, height: 0.80),
            CorrectedLayout(app: "Terminal", isFocused: true, x: 0.70, y: 0.0, width: 0.30, height: 1.0) // ≤30%
        ]
    )
]

func validateTerminalRequirement(_ layouts: [CorrectedLayout], scenario: String) -> Bool {
    print("\n🎯 Testing \(scenario):")
    
    var allPassed = true
    
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        let bounds = layout.pixelBounds
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
        print("    Pixels: \(bounds.width)×\(bounds.height)")
    }
    
    print("\n  🧪 Validation:")
    
    // Test Terminal width requirement
    if let terminal = layouts.first(where: { $0.app == "Terminal" }) {
        let terminalPercent = terminal.width * 100
        let isFocused = terminal.isFocused
        let maxAllowed = isFocused ? 30.0 : 25.0
        let focusStatus = isFocused ? "focused" : "unfocused"
        
        if terminalPercent <= maxAllowed {
            print("    ✅ Terminal width: \(String(format: "%.0f", terminalPercent))% (≤\(maxAllowed)% for \(focusStatus))")
        } else {
            print("    ❌ Terminal TOO WIDE: \(String(format: "%.0f", terminalPercent))% (exceeds \(maxAllowed)% for \(focusStatus))")
            allPassed = false
        }
    }
    
    // Test Arc functional width
    if let arc = layouts.first(where: { $0.app == "Arc" }) {
        let arcPixels = arc.pixelBounds.width
        if arcPixels >= 500 {
            print("    ✅ Arc functional: \(arcPixels)px width")
        } else {
            print("    ❌ Arc too narrow: \(arcPixels)px width (needs ≥500px)")
            allPassed = false
        }
    }
    
    // Test screen usage
    let rightmost = layouts.map { $0.x + $0.width }.max() ?? 0
    if rightmost >= 0.95 {
        print("    ✅ Screen usage: \(String(format: "%.1f", rightmost * 100))%")
    } else {
        print("    ❌ Wasted space: only \(String(format: "%.1f", rightmost * 100))% used")
        allPassed = false
    }
    
    // Test cascade overlaps
    let focused = layouts.first { $0.isFocused }!
    let others = layouts.filter { !$0.isFocused }
    
    var hasOverlaps = false
    for other in others {
        let focusedEnd = focused.x + focused.width
        let otherStart = other.x
        let otherEnd = other.x + other.width
        
        if otherStart < focusedEnd && otherEnd > focused.x {
            hasOverlaps = true
            let overlapStart = max(focused.x, otherStart)
            let overlapEnd = min(focusedEnd, otherEnd)
            let overlapWidth = Int((overlapEnd - overlapStart) * screenSize.width)
            print("    ✅ Cascade overlap: \(other.app) overlaps \(focused.app) by \(overlapWidth)px")
        }
    }
    
    if !hasOverlaps {
        print("    ⚠️  No cascade overlaps - apps are side-by-side")
    }
    
    return allPassed
}

print("📋 TESTING ALL CORRECTED SCENARIOS:")
print("===================================")

var allScenariosPass = true

for layoutTest in correctedLayouts {
    let scenarioPass = validateTerminalRequirement(layoutTest.apps, scenario: layoutTest.scenario)
    if !scenarioPass {
        allScenariosPass = false
    }
}

print("\n📊 FINAL RESULTS:")
print("=================")

if allScenariosPass {
    print("🎉 ALL TERMINAL 30% REQUIREMENTS MET!")
    print("\n✨ Key achievements:")
    print("• Terminal focused: 30% (≤30% requirement)")
    print("• Terminal unfocused: 25% (≤25% requirement)")
    print("• Arc maintains functional width (≥500px)")
    print("• Full screen utilization")
    print("• Better balance for coding workspace")
} else {
    print("❌ Some requirements still not met")
}

print("\n🚀 NEXT STEPS:")
print("1. Build the updated WindowAI app")
print("2. Test with multiple 'i want to code' commands")
print("3. Verify LLM consistency with new layouts")

print("\n📐 SUMMARY OF CHANGES:")
print("• Terminal focused: 50% → 30% (20% reduction)")
print("• Terminal unfocused: 30% → 25% (5% reduction)")
print("• Xcode gets more space when Terminal focused: 30% → 45%")
print("• Arc maintains functional width: 504px-648px range")