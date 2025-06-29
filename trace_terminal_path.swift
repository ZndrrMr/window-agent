#!/usr/bin/env swift

import Foundation

print("🔍 TRACING TERMINAL SIZE CALCULATION PATH")
print("==========================================")

// Simulate the actual cascade process
let screenSize = (width: 1440.0, height: 900.0)
let windowCount = 4

print("📊 STEP 1: AppArchetypes.getOptimalSizing")
func getOptimalSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        let optimalWidth = min(0.30, max(0.20, 600.0 / screenSize.width))
        print("  textStream + sideColumn:")
        print("    600.0 / \(screenSize.width) = \(600.0 / screenSize.width)")
        print("    max(0.20, \(600.0 / screenSize.width)) = \(max(0.20, 600.0 / screenSize.width))")
        print("    min(0.30, \(max(0.20, 600.0 / screenSize.width))) = \(optimalWidth)")
        return (width: optimalWidth, height: 1.0)
    default:
        return (width: 0.50, height: 0.70)
    }
}

let terminalOptimal = getOptimalSizing(for: "textStream", screenSize: screenSize, role: "sideColumn", windowCount: windowCount)
print("  → Terminal optimalWidth: \(terminalOptimal.width) (\(Int(terminalOptimal.width * screenSize.width))px)")

print("\n📊 STEP 2: FlexiblePositioning calculation")
let rightX = 1.0 - terminalOptimal.width
print("  rightX = 1.0 - \(terminalOptimal.width) = \(rightX)")
print("  Position: x=\(rightX * 100)%, y=0%")
print("  Size: width=\(terminalOptimal.width * 100)%, height=100%")
print("  Pixels: \(Int(terminalOptimal.width * screenSize.width))px × \(Int(screenSize.height))px")

print("\n📊 STEP 3: BUT WHAT IF... the context is wrong?")
print("From the log: Context: 'general' (not 'coding')")
print("This might mean Terminal isn't getting textStream + sideColumn role!")

print("\n🤔 CHECKING OTHER POSSIBLE PATHS:")

// What if Terminal gets a different role?
print("\n❓ If Terminal gets 'primary' role instead:")
let terminalPrimary = getOptimalSizing(for: "textStream", screenSize: screenSize, role: "primary", windowCount: windowCount)
print("  → Would be: \(terminalPrimary.width) (\(Int(terminalPrimary.width * screenSize.width))px)")

print("\n❓ If Terminal gets 'contentCanvas' archetype (wrong classification):")
func getContentCanvasSize() -> (width: Double, height: Double) {
    let minFunctionalWidth = max(0.45, 800.0 / screenSize.width)
    print("  contentCanvas calculation:")
    print("    800.0 / \(screenSize.width) = \(800.0 / screenSize.width)")
    print("    max(0.45, \(800.0 / screenSize.width)) = \(minFunctionalWidth)")
    return (width: minFunctionalWidth, height: 0.45)
}

let contentCanvasSize = getContentCanvasSize()
print("  → Would be: \(contentCanvasSize.width) (\(Int(contentCanvasSize.width * screenSize.width))px)")

print("\n🎯 HYPOTHESIS:")
print("The log shows Terminal getting ~65% width (\(Int(0.65 * screenSize.width))px)")
print("This matches contentCanvas calculation: \(Int(contentCanvasSize.width * screenSize.width))px")
print("So Terminal might be misclassified as contentCanvas instead of textStream!")

print("\n💡 OR... there's a default case being hit:")
let defaultWidth = 0.60 // From default case
print("Default role width: \(defaultWidth) (\(Int(defaultWidth * screenSize.width))px)")

print("\n🔍 NEED TO CHECK:")
print("1. Is Terminal being classified as textStream?")
print("2. Is Terminal getting sideColumn role?") 
print("3. Are we hitting the right switch case in getOptimalSizing?")
print("4. Is there some override happening after AppArchetypes?")