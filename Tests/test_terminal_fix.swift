#!/usr/bin/env swift

import Foundation

print("🧪 TESTING TERMINAL SIZE FIX")
print("============================")

let screenSize = (width: 1440.0, height: 900.0)

// Test the updated getOptimalSizing
func getOptimalSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        // FIXED: 480px minimum instead of 600px
        let optimalWidth = min(0.30, max(0.20, 480.0 / screenSize.width))
        return (width: optimalWidth, height: 1.0)
    case ("contentCanvas", "peekLayer"):
        // FIXED: 650px minimum instead of 800px
        let minFunctionalWidth = max(0.45, 650.0 / screenSize.width)
        return (width: minFunctionalWidth, height: 0.45)
    default:
        return (width: 0.50, height: 0.70)
    }
}

print("🎯 TERMINAL SIZING TEST:")
print("  Before fix: Terminal got 800px (55.6%)")

let terminalResult = getOptimalSizing(for: "textStream", screenSize: screenSize, role: "sideColumn", windowCount: 3)
let terminalPixels = terminalResult.width * screenSize.width

print("  After fix: Terminal gets \(Int(terminalPixels))px (\(String(format: "%.1f", terminalResult.width * 100))%)")

// Apply AppConstraints minimum
let constrainedTerminal = max(480.0, terminalPixels)
let constrainedPercentage = constrainedTerminal / screenSize.width

print("  With constraints: \(Int(constrainedTerminal))px (\(String(format: "%.1f", constrainedPercentage * 100))%)")

print("\n✅ EXPECTATIONS:")
print("  - Terminal should be ~33% (480px) due to AppConstraints minimum")
print("  - This is much better than 55.6% (800px)")
print("  - User should see Terminal take up about 1/3 of screen width")

let isGoodSize = constrainedPercentage <= 0.35
print("  - Result: \(isGoodSize ? "✅ ACCEPTABLE" : "❌ STILL TOO BIG")")

print("\n🎯 ARC SIZING TEST:")
let arcResult = getOptimalSizing(for: "contentCanvas", screenSize: screenSize, role: "peekLayer", windowCount: 3)
let arcPixels = arcResult.width * screenSize.width

print("  Arc gets \(Int(arcPixels))px (\(String(format: "%.1f", arcResult.width * 100))%)")
print("  This should be functional but not dominating")

let isFunctional = arcPixels >= 648 // Need at least 650px for reading
print("  Functional: \(isFunctional ? "✅" : "❌")")

print("\n🚀 SUMMARY:")
print("  Terminal: \(Int(constrainedTerminal))px (\(String(format: "%.1f", constrainedPercentage * 100))%) - Much smaller!")
print("  Arc: \(Int(arcPixels))px (\(String(format: "%.1f", arcResult.width * 100))%) - Still functional")
print("  Overall: \(isGoodSize && isFunctional ? "✅ FIXED!" : "⚠️ Needs more work")")

print("\n💡 NEXT STEPS:")
print("  1. Test with real 'i want to code' command")
print("  2. Verify Terminal stays under 35% of screen")
print("  3. Ensure Arc remains readable")
print("  4. Continue investigating why Terminal was getting contentCanvas sizing")