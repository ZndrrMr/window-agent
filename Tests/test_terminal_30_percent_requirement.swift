#!/usr/bin/env swift

import Foundation

print("🎯 TERMINAL 30% REQUIREMENT TEST")
print("===============================")
print("User requirement: Terminal should generally take up less than 30%")
print("Current implementation gives Terminal 50% when focused - TOO MUCH!")
print()

let screenSize = (width: 1440.0, height: 900.0)

struct TerminalRequirement {
    let scenario: String
    let terminalFocused: Bool
    let maxTerminalPercent: Double
    let reasoning: String
}

let requirements = [
    TerminalRequirement(
        scenario: "Terminal focused",
        terminalFocused: true,
        maxTerminalPercent: 30.0,
        reasoning: "Even when focused, Terminal should be ≤30% for balanced coding workspace"
    ),
    TerminalRequirement(
        scenario: "Terminal not focused",
        terminalFocused: false,
        maxTerminalPercent: 25.0,
        reasoning: "When not focused, Terminal should be even smaller (≤25%) as supporting tool"
    )
]

print("📋 TERMINAL WIDTH REQUIREMENTS:")
for req in requirements {
    let focusIcon = req.terminalFocused ? "🎯" : "👁️"
    print("  \(focusIcon) \(req.scenario): ≤\(req.maxTerminalPercent)%")
    print("    Reason: \(req.reasoning)")
}

print("\n🧪 TESTING CURRENT IMPLEMENTATION:")

// Current FlexiblePositioning.swift layouts
let currentLayouts = [
    (scenario: "Xcode focused", terminal: (width: 0.30, focused: false)),
    (scenario: "Arc focused", terminal: (width: 0.30, focused: false)),  
    (scenario: "Terminal focused", terminal: (width: 0.50, focused: true)) // PROBLEM!
]

var hasFailures = false

for layout in currentLayouts {
    let terminalPercent = layout.terminal.width * 100
    let focusIcon = layout.terminal.focused ? "🎯" : "👁️"
    let requirement = requirements.first { $0.terminalFocused == layout.terminal.focused }!
    
    print("\n  \(focusIcon) \(layout.scenario):")
    print("    Current Terminal width: \(String(format: "%.0f", terminalPercent))%")
    print("    Required: ≤\(requirement.maxTerminalPercent)%")
    
    if terminalPercent <= requirement.maxTerminalPercent {
        print("    ✅ PASSES requirement")
    } else {
        print("    ❌ FAILS requirement by \(String(format: "%.0f", terminalPercent - requirement.maxTerminalPercent))%")
        hasFailures = true
    }
}

print("\n📊 OVERALL RESULT:")
if hasFailures {
    print("❌ CURRENT IMPLEMENTATION FAILS TERMINAL WIDTH REQUIREMENTS")
    print("\n🔧 FIXES NEEDED:")
    print("• Reduce Terminal focused width from 50% to ≤30%")
    print("• Ensure Terminal unfocused stays at ≤25%")
    print("• Redistribute space to Xcode and Arc for better coding workspace")
} else {
    print("✅ All Terminal width requirements met")
}

print("\n🎯 PROPOSED CORRECTED LAYOUTS:")

// Corrected layouts that meet 30% requirement
let correctedLayouts = [
    (
        scenario: "Xcode focused (corrected)",
        apps: [
            (name: "Xcode", width: 0.60, height: 0.90, focused: true),
            (name: "Arc", width: 0.40, height: 0.85, focused: false),
            (name: "Terminal", width: 0.25, height: 0.80, focused: false) // ≤25%
        ]
    ),
    (
        scenario: "Arc focused (corrected)", 
        apps: [
            (name: "Xcode", width: 0.30, height: 0.85, focused: false),
            (name: "Arc", width: 0.50, height: 0.90, focused: true),
            (name: "Terminal", width: 0.25, height: 0.80, focused: false) // ≤25%
        ]
    ),
    (
        scenario: "Terminal focused (corrected)",
        apps: [
            (name: "Xcode", width: 0.45, height: 0.85, focused: false),
            (name: "Arc", width: 0.35, height: 0.80, focused: false), 
            (name: "Terminal", width: 0.30, height: 1.0, focused: true) // ≤30%
        ]
    )
]

for layout in correctedLayouts {
    print("\n📱 \(layout.scenario):")
    for app in layout.apps {
        let focusIcon = app.focused ? "🎯" : "👁️"
        let pixels = Int(app.width * screenSize.width)
        print("  \(focusIcon) \(app.name): \(Int(app.width * 100))% (\(pixels)px)")
    }
    
    // Validate corrected layout
    if let terminal = layout.apps.first(where: { $0.name == "Terminal" }) {
        let terminalPercent = terminal.width * 100
        let requirement = requirements.first { $0.terminalFocused == terminal.focused }!
        
        if terminalPercent <= requirement.maxTerminalPercent {
            print("  ✅ Terminal \(String(format: "%.0f", terminalPercent))% meets ≤\(requirement.maxTerminalPercent)% requirement")
        } else {
            print("  ❌ Terminal \(String(format: "%.0f", terminalPercent))% exceeds ≤\(requirement.maxTerminalPercent)% requirement")
        }
    }
    
    // Check screen usage
    let totalWidth = layout.apps.map { $0.width }.max() ?? 0
    if totalWidth >= 0.95 {
        print("  ✅ Screen usage: \(String(format: "%.0f", totalWidth * 100))%")
    } else {
        print("  ❌ Wasted space: only \(String(format: "%.0f", totalWidth * 100))% used")
    }
}

print("\n🚀 NEXT STEPS:")
print("1. Update FlexiblePositioning.swift with corrected Terminal widths")
print("2. Test the updated 'i want to code' command")
print("3. Verify all scenarios meet the ≤30% Terminal requirement")