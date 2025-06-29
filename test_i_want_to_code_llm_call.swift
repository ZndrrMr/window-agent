#!/usr/bin/env swift

import Foundation

print("🎯 TESTING 'I WANT TO CODE' LLM CALL")
print("===================================")
print("This will show exactly what the LLM decides for 'i want to code'")
print()

// The issue is Terminal is still focused despite our fixes
print("🚨 CURRENT PROBLEM:")
print("From debug output:")
print("  📝 Context: 'coding' ✅ (this works)")
print("  🎯 Focused: Terminal ❌ (this is WRONG - should be Xcode)")
print("  📱 Apps: Terminal, Arc, Xcode, Finder")
print()

print("🔍 ANALYSIS NEEDED:")
print("1. What does the LLM actually decide for sizes?")
print("2. Why is Terminal still focused instead of Xcode?")
print("3. Are Arc and Xcode getting same size as we intended?")
print()

// Expected vs Actual
print("📊 EXPECTED LLM DECISION:")
print("Arc and Xcode should get IDENTICAL sizes (55% width each)")
print("Terminal should get ≤30% width")
print("Xcode should be focused (highest layer)")
print()

print("📊 ACTUAL DEBUG OUTPUT:")
print("Xcode: Position (0.0, 0.0), Size (648.0, 743.75)")
print("Arc:   Position (576.0, 87.5), Size (504.0, 700.0)")  
print("Terminal: Position (1008.0, 0.0), Size (432.0, 875.0)")
print()

// Calculate percentages (assuming 1440x900 screen)
let screenWidth = 1440.0
let screenHeight = 900.0

print("🔢 SIZE ANALYSIS (assuming 1440x900 screen):")
let xcodeWidthPct = 648.0 / screenWidth * 100
let arcWidthPct = 504.0 / screenWidth * 100  
let terminalWidthPct = 432.0 / screenWidth * 100

print("Xcode:    \(Int(xcodeWidthPct))% width (\(648.0) / \(screenWidth))")
print("Arc:      \(Int(arcWidthPct))% width (\(504.0) / \(screenWidth))")  
print("Terminal: \(Int(terminalWidthPct))% width (\(432.0) / \(screenWidth))")
print()

if abs(xcodeWidthPct - arcWidthPct) <= 5 {
    print("✅ CASCADE SIZES: Xcode and Arc have similar widths")
} else {
    print("❌ CASCADE BROKEN: Xcode (\(Int(xcodeWidthPct))%) ≠ Arc (\(Int(arcWidthPct))%)")
    print("   Different sizes = side-by-side tiling instead of cascade overlap")
}

if terminalWidthPct <= 30 {
    print("✅ TERMINAL WIDTH: \(Int(terminalWidthPct))% ≤ 30%")
} else {
    print("❌ TERMINAL TOO WIDE: \(Int(terminalWidthPct))% > 30%")
}

print()
print("🚨 FOCUS ISSUE:")
print("The debug shows 'Focused: Terminal' but it should be 'Focused: Xcode'")
print("This suggests the priority-based focus resolution isn't working")
print()

print("💡 NEXT STEPS:")
print("1. Check if LLM is actually giving Xcode highest layer")
print("2. Verify focus resolution logic in FlexiblePositioning.swift")
print("3. Test if LLM prompt changes are being applied")
print("4. Fix whatever is still causing wrong focus selection")

print("\n🎯 TO DEBUG:")
print("Run 'i want to code' and capture the actual LLM tool call JSON")
print("Check if it has:")
print("- user_intent: 'i want to code'")
print("- Xcode with higher layer than Terminal")  
print("- Arc and Xcode with same sizes")
print("- Positions that create cascade overlap")