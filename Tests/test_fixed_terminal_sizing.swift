#!/usr/bin/env swift

import Foundation

print("🧪 TESTING FIXED TERMINAL SIZING")
print("================================")

let screenSize = (width: 1440.0, height: 900.0)

// Updated calculations
func getOptimalSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        // Fixed: 480px minimum instead of 600px
        let optimalWidth = min(0.30, max(0.20, 480.0 / screenSize.width))
        return (width: optimalWidth, height: 1.0)
    case ("contentCanvas", "peekLayer"):
        // Fixed: 650px minimum instead of 800px  
        let minFunctionalWidth = max(0.45, 650.0 / screenSize.width)
        return (width: minFunctionalWidth, height: 0.45)
    default:
        return (width: 0.50, height: 0.70)
    }
}

print("📊 TERMINAL (textStream + sideColumn):")
let terminalSize = getOptimalSizing(for: "textStream", screenSize: screenSize, role: "sideColumn", windowCount: 3)
let terminalPixels = terminalSize.width * screenSize.width
print("  Calculation: min(0.30, max(0.20, 480.0 / \(screenSize.width)))")
print("  Result: \(String(format: "%.1f", terminalSize.width * 100))% = \(Int(terminalPixels))px")
print("  Status: \(terminalPixels <= 432 ? "✅ Within 30%" : "❌ Too big")")

print("\n📊 ARC (contentCanvas + peekLayer):")
let arcSize = getOptimalSizing(for: "contentCanvas", screenSize: screenSize, role: "peekLayer", windowCount: 3)
let arcPixels = arcSize.width * screenSize.width
print("  Calculation: max(0.45, 650.0 / \(screenSize.width))")
print("  Result: \(String(format: "%.1f", arcSize.width * 100))% = \(Int(arcPixels))px")
print("  Status: \(arcPixels >= 648 ? "✅ Functional width" : "❌ Too narrow")")

print("\n🎯 COMPARISON:")
print("Before fixes:")
print("  Terminal: 800px (55.6%) ❌ Too big")
print("  Arc: 800px (55.6%) ✅ Functional")
print("\nAfter fixes:")
print("  Terminal: \(Int(terminalPixels))px (\(String(format: "%.1f", terminalSize.width * 100))%) \(terminalPixels <= 432 ? "✅" : "❌")")
print("  Arc: \(Int(arcPixels))px (\(String(format: "%.1f", arcSize.width * 100))%) \(arcPixels >= 648 ? "✅" : "❌")")

// Test AppConstraints effect
print("\n📊 WITH AppConstraints applied:")
let terminalConstrained = max(480.0, terminalPixels) // Terminal minWidth: 480
let arcConstrained = arcPixels // Arc has no constraints in this range

print("  Terminal: \(Int(terminalPixels))px → \(Int(terminalConstrained))px (after 480px minimum)")
print("  Arc: \(Int(arcPixels))px (no constraint)")

let terminalFinalPercentage = terminalConstrained / screenSize.width
print("  Terminal final: \(String(format: "%.1f", terminalFinalPercentage * 100))% = \(Int(terminalConstrained))px")

let isTerminalAcceptable = terminalFinalPercentage <= 0.35 // Allow up to 35% for constraints
print("  Terminal acceptable: \(isTerminalAcceptable ? "✅" : "❌")")

print("\n💡 KEY INSIGHT:")
print("Even with AppConstraints 480px minimum, Terminal should be ~33.3% (480px)")
print("But actual Terminal is getting 800px (55.6%)")
print("This confirms Terminal is being sized as contentCanvas, not textStream!")