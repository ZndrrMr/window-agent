#!/usr/bin/env swift

import Foundation

print("🔍 DEBUGGING TERMINAL WIDTH ISSUE")
print("=================================")

let screenSize = (width: 1440.0, height: 900.0)

// Test the AppArchetypes calculation
func getOptimalSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        let optimalWidth = min(0.30, max(0.20, 600.0 / screenSize.width))
        return (width: optimalWidth, height: 1.0)
    default:
        return (width: 0.50, height: 0.70)
    }
}

print("📊 EXPECTED TERMINAL SIZE FROM AppArchetypes:")
let terminalSize = getOptimalSizing(for: "textStream", screenSize: screenSize, role: "sideColumn", windowCount: 3)
let expectedPixels = terminalSize.width * screenSize.width
print("  Width: \(String(format: "%.1f", terminalSize.width * 100))% = \(Int(expectedPixels))px")

print("\n❌ ACTUAL OUTPUT FROM LOG:")
print("  Width: 800px = \(String(format: "%.1f", (800.0 / screenSize.width) * 100))%")

print("\n🔍 DIFFERENCE:")
let difference = 800.0 - expectedPixels
print("  Expected: \(Int(expectedPixels))px")
print("  Actual: 800px") 
print("  Difference: +\(Int(difference))px (\(String(format: "%.1f", (difference / screenSize.width) * 100))% extra)")

print("\n💡 POSSIBLE CAUSES:")
print("1. FlexiblePositioning.swift might have hardcoded 800px somewhere")
print("2. Window bounds adjustment might be overriding the size")
print("3. AppConstraints might be setting minimum size to 800px")
print("4. The cascade system might not be using AppArchetypes properly")

print("\n🧪 TESTING IF 432PX IS BETTER MINIMUM:")
func getBetterSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        // Use 432px as max 30% of 1440px screen
        let optimalWidth = min(0.30, max(0.20, 432.0 / screenSize.width))
        return (width: optimalWidth, height: 1.0)
    default:
        return (width: 0.50, height: 0.70)
    }
}

let betterSize = getBetterSizing(for: "textStream", screenSize: screenSize, role: "sideColumn", windowCount: 3)
let betterPixels = betterSize.width * screenSize.width
print("  Better result: \(String(format: "%.1f", betterSize.width * 100))% = \(Int(betterPixels))px")

print("\n✅ TEST ON DIFFERENT SCREENS:")
let screens = [
    (name: "1280x800", width: 1280.0),
    (name: "1440x900", width: 1440.0), 
    (name: "1920x1080", width: 1920.0)
]

for screen in screens {
    let size432 = min(0.30, max(0.20, 432.0 / screen.width))
    let size600 = min(0.30, max(0.20, 600.0 / screen.width))
    
    print("  \(screen.name):")
    print("    432px min: \(String(format: "%.1f", size432 * 100))% (\(Int(size432 * screen.width))px)")
    print("    600px min: \(String(format: "%.1f", size600 * 100))% (\(Int(size600 * screen.width))px)")
}