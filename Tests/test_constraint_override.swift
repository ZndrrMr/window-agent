#!/usr/bin/env swift

import Foundation

print("🔍 TESTING IF AppConstraints OVERRIDES AppArchetypes")
print("===================================================")

let screenSize = (width: 1440.0, height: 900.0)

// Step 1: AppArchetypes calculation
let optimalWidth = min(0.30, max(0.20, 600.0 / screenSize.width))
let archetypePixels = optimalWidth * screenSize.width

print("📊 STEP 1: AppArchetypes.getOptimalSizing")
print("  Result: \(String(format: "%.1f", optimalWidth * 100))% = \(Int(archetypePixels))px")

// Step 2: Check AppConstraints for Terminal
struct AppConstraints {
    let minWidth: Double
    let maxWidth: Double?
    
    func applyConstraints(to width: Double, screenWidth: Double) -> Double {
        let pixels = width * screenWidth
        let constrainedPixels = min(pixels, maxWidth ?? Double.infinity)
        let constrainedPixels2 = max(constrainedPixels, minWidth)
        return constrainedPixels2 / screenWidth
    }
}

let terminalConstraints = AppConstraints(minWidth: 480, maxWidth: 800)

print("\n📊 STEP 2: AppConstraints.applyConstraints")
print("  minWidth: \(Int(terminalConstraints.minWidth))px")
print("  maxWidth: \(Int(terminalConstraints.maxWidth!))px")
print("  Original: \(Int(archetypePixels))px")

let constrainedWidth = terminalConstraints.applyConstraints(to: optimalWidth, screenWidth: screenSize.width)
let constrainedPixels = constrainedWidth * screenSize.width

print("  Constrained: \(Int(constrainedPixels))px (\(String(format: "%.1f", constrainedWidth * 100))%)")

if constrainedPixels != archetypePixels {
    print("  ⚠️ CONSTRAINT APPLIED! Changed \(Int(archetypePixels))px → \(Int(constrainedPixels))px")
} else {
    print("  ✅ No constraint needed")
}

print("\n🎯 HYPOTHESIS TEST:")
print("If Terminal is getting 800px, it means:")
print("1. AppArchetypes gives \(Int(archetypePixels))px")  
print("2. AppConstraints might force it to \(Int(terminalConstraints.maxWidth!))px?")
print("3. But Terminal should NEVER be forced UP to maxWidth")
print("4. maxWidth should only CAP it, not SET it")

print("\n💡 ALTERNATIVE THEORY:")
print("Maybe Terminal is getting a DIFFERENT archetype/role combination...")

// Test what gives 800px
print("\n🔍 WHAT COMBINATION GIVES ~800PX?")

let targetPixels = 800.0
let targetPercentage = targetPixels / screenSize.width

print("Target: \(Int(targetPixels))px = \(String(format: "%.1f", targetPercentage * 100))%")

// Test contentCanvas calculation
let contentCanvasWidth = max(0.45, 800.0 / screenSize.width)
let contentCanvasPixels = contentCanvasWidth * screenSize.width

print("\ncontentCanvas calculation:")
print("  max(0.45, 800.0 / \(screenSize.width)) = \(String(format: "%.3f", contentCanvasWidth))")
print("  Result: \(Int(contentCanvasPixels))px (\(String(format: "%.1f", contentCanvasWidth * 100))%)")

if abs(contentCanvasPixels - 800.0) < 1 {
    print("  🎯 MATCH! Terminal is getting contentCanvas sizing!")
} else {
    print("  ❌ Not a match")
}

print("\n📝 CONCLUSION:")
if abs(contentCanvasPixels - 800.0) < 1 {
    print("Terminal is being sized as contentCanvas (800px), not textStream (432px)")
    print("This suggests either:")
    print("  1. Wrong archetype classification (should be fixed)")
    print("  2. Wrong role assignment (should be fixed)")  
    print("  3. contentCanvas logic is overriding textStream logic")
} else {
    print("Need to investigate further - 800px doesn't match expected calculations")
}