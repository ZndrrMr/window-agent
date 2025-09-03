#!/usr/bin/env swift

import Foundation

print("🧪 TESTING TERMINAL SIZING LIMITS")
print("=================================")

// Test the actual getOptimalSizing function behavior
func getOptimalSizing(for archetype: String, screenSize: (width: Double, height: Double), role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        // Text streams: dynamic based on screen size
        let optimalWidth = min(0.30, max(0.20, 600.0 / screenSize.width))
        return (width: optimalWidth, height: 1.0)
    default:
        return (width: 0.50, height: 0.70)
    }
}

// Test different screen sizes
let testScreens = [
    (name: "MacBook 13\"", width: 1280.0, height: 800.0),
    (name: "MacBook 15\"", width: 1440.0, height: 900.0),
    (name: "iMac 24\"", width: 1920.0, height: 1080.0),
    (name: "4K Display", width: 3840.0, height: 2160.0),
    (name: "Ultrawide", width: 2560.0, height: 1080.0)
]

print("\n📐 TERMINAL SIZING TESTS:")
for screen in testScreens {
    let terminalSize = getOptimalSizing(
        for: "textStream", 
        screenSize: (width: screen.width, height: screen.height), 
        role: "sideColumn", 
        windowCount: 3
    )
    
    let actualPixels = terminalSize.width * screen.width
    let percentage = terminalSize.width * 100
    
    let status = percentage <= 30.0 ? "✅" : "❌ TOO BIG"
    
    print("  🖥️ \(screen.name): \(Int(percentage))% (\(Int(actualPixels))px) \(status)")
}

print("\n🎯 TESTING 1440x900 DETAILED:")
let screen1440 = (width: 1440.0, height: 900.0)

// Test the exact calculation
let calculation = 600.0 / screen1440.width
let minResult = max(0.20, calculation)
let finalResult = min(0.30, minResult)

print("  📊 600 / 1440 = \(String(format: "%.3f", calculation))")
print("  📊 max(0.20, \(String(format: "%.3f", calculation))) = \(String(format: "%.3f", minResult))")
print("  📊 min(0.30, \(String(format: "%.3f", minResult))) = \(String(format: "%.3f", finalResult))")
print("  📊 Final percentage: \(String(format: "%.1f", finalResult * 100))%")
print("  📊 Final pixels: \(Int(finalResult * screen1440.width))px")

let isWithinLimit = finalResult <= 0.30
print("  🎯 Within 30% limit: \(isWithinLimit ? "✅" : "❌")")

if !isWithinLimit {
    print("\n❌ PROBLEM FOUND!")
    print("   The current formula allows Terminal to exceed 30%")
    print("   600px minimum on 1440px screen = \(String(format: "%.1f", calculation * 100))%")
    print("   This is more than our 30% target!")
    
    print("\n💡 PROPOSED FIX:")
    let maxPixelsFor30Percent = 0.30 * screen1440.width
    print("   30% of 1440px = \(Int(maxPixelsFor30Percent))px")
    print("   Should use: min(0.30, max(0.20, 432.0 / screenSize.width))")
    print("   New 432px limit = \(String(format: "%.1f", (432.0 / screen1440.width) * 100))%")
    
    // Test the fix
    let fixedCalculation = 432.0 / screen1440.width
    let fixedMinResult = max(0.20, fixedCalculation)
    let fixedFinalResult = min(0.30, fixedMinResult)
    print("   Fixed result: \(String(format: "%.1f", fixedFinalResult * 100))% (\(Int(fixedFinalResult * screen1440.width))px)")
}

print("\n🔍 CHECKING IF 600PX IS TOO AGGRESSIVE:")
for screen in testScreens {
    let thirtyPercent = 0.30 * screen.width
    let sixHundredPercent = (600.0 / screen.width) * 100
    
    if sixHundredPercent > 30.0 {
        print("  ❌ \(screen.name): 600px = \(String(format: "%.1f", sixHundredPercent))% (exceeds 30%)")
    } else {
        print("  ✅ \(screen.name): 600px = \(String(format: "%.1f", sixHundredPercent))% (within 30%)")
    }
}