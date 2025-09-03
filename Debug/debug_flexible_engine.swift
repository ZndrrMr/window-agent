#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🔍 DEBUGGING FLEXIBLE LAYOUT ENGINE")
print("==================================")

// Test what FlexibleLayoutEngine.generateFocusAwareLayout actually returns
// This will reveal if our fixes are being used

print("\n📋 SIMULATING CURRENT SCENARIO:")
print("===============================")
print("Apps: Terminal, Arc, Xcode, Finder")
print("Focused: Terminal (textStream)")
print("Screen: 1440x900")

// Mock the FlexibleLayoutEngine based on our updated code
// This simulates what it SHOULD return after our fixes

struct MockFlexiblePosition {
    let x: Double
    let y: Double
    
    func toPixels(for dimension: Double, current: Double = 0) -> Double {
        return x * dimension / 100.0  // Convert percentage to pixels
    }
}

struct MockFlexibleSize {
    let width: Double
    let height: Double
    
    func toPixels(for dimension: Double, otherDimension: Double? = nil) -> Double? {
        return width * dimension / 100.0  // Convert percentage to pixels
    }
}

struct MockArrangement {
    let window: String
    let position: MockFlexiblePosition
    let size: MockFlexibleSize
}

func simulateFixedFlexibleLayoutEngine(
    windowNames: [String],
    screenSize: CGSize,
    focusedApp: String
) -> [MockArrangement] {
    
    print("\n🔧 FIXED FlexibleLayoutEngine simulation:")
    print("========================================")
    
    var arrangements: [MockArrangement] = []
    
    for (index, appName) in windowNames.enumerated() {
        let isFocused = (appName == focusedApp)
        
        if isFocused {
            // Primary position and size from our fixed getPrimaryPosition/getPrimarySize
            print("  📱 \(appName) (FOCUSED):")
            
            // Fixed: getPrimaryPosition for textStream returns x: 0.0 (was 0.70!)
            let position = MockFlexiblePosition(x: 0.0, y: 0.0)
            
            // Fixed: getPrimarySize for textStream with 4 apps
            let size = MockFlexibleSize(width: 35.0, height: 100.0)  // Our improved sizes
            
            print("    - Position: \(position.x)%, \(position.y)%")
            print("    - Size: \(size.width)%, \(size.height)%")
            
            arrangements.append(MockArrangement(window: appName, position: position, size: size))
            
        } else {
            // Cascade position and size from our fixed getCascadePosition/getCascadeSize
            print("  📱 \(appName) (cascade):")
            
            // Fixed cascade positioning - starts from edges
            let baseX = 2.0  // Changed from 35%!
            let baseY = 2.0  // Changed from 10%
            let offsetX = Double(index) * 8.0  // Changed from 15%
            let offsetY = Double(index) * 6.0  // Changed from 15%
            
            let position = MockFlexiblePosition(
                x: min(baseX + offsetX, 95.0),  // Changed max from 60% to 95%
                y: min(baseY + offsetY, 25.0)   // Changed max from 50% to 25%
            )
            
            // Fixed cascade sizes - much larger
            let size: MockFlexibleSize
            switch appName {
            case "Arc":
                size = MockFlexibleSize(width: 65.0, height: 95.0)  // Was 35%, 80%
            case "Xcode":
                size = MockFlexibleSize(width: 70.0, height: 95.0)  // Was 40%, 80%
            case "Finder":
                size = MockFlexibleSize(width: 45.0, height: 90.0)  // Was tiny!
            default:
                size = MockFlexibleSize(width: 60.0, height: 90.0)
            }
            
            print("    - Position: \(position.x)%, \(position.y)%")
            print("    - Size: \(size.width)%, \(size.height)%")
            
            arrangements.append(MockArrangement(window: appName, position: position, size: size))
        }
    }
    
    return arrangements
}

// Test with our scenario
let windowNames = ["Terminal", "Arc", "Xcode", "Finder"]
let screenSize = CGSize(width: 1440, height: 900)
let focusedApp = "Terminal"

let arrangements = simulateFixedFlexibleLayoutEngine(
    windowNames: windowNames,
    screenSize: screenSize,
    focusedApp: focusedApp
)

print("\n📐 PIXEL CONVERSION RESULTS:")
print("===========================")

var actualBounds: [CGRect] = []

for arrangement in arrangements {
    let pixelX = arrangement.position.x * screenSize.width / 100.0
    let pixelY = arrangement.position.y * screenSize.height / 100.0
    let pixelWidth = arrangement.size.width * screenSize.width / 100.0
    let pixelHeight = arrangement.size.height * screenSize.height / 100.0
    
    let bounds = CGRect(x: pixelX, y: pixelY, width: pixelWidth, height: pixelHeight)
    actualBounds.append(bounds)
    
    print("  📱 \(arrangement.window): \(bounds)")
    print("    - Pixels: \(Int(pixelWidth)) x \(Int(pixelHeight))")
}

// Calculate coverage
func calculateScreenCoverage(windows: [CGRect], screenSize: CGSize) -> Double {
    let sampleWidth = 20.0
    let sampleHeight = 20.0
    let cols = Int(screenSize.width / sampleWidth)
    let rows = Int(screenSize.height / sampleHeight)
    
    var coveredSamples = 0
    
    for row in 0..<rows {
        for col in 0..<cols {
            let sampleX = Double(col) * sampleWidth + sampleWidth/2
            let sampleY = Double(row) * sampleHeight + sampleHeight/2
            let samplePoint = CGPoint(x: sampleX, y: sampleY)
            
            for window in windows {
                if window.contains(samplePoint) {
                    coveredSamples += 1
                    break
                }
            }
        }
    }
    
    let totalSamples = rows * cols
    return Double(coveredSamples) / Double(totalSamples)
}

let coverage = calculateScreenCoverage(windows: actualBounds, screenSize: screenSize)

print("\n📊 FIXED ENGINE RESULTS:")
print("========================")
print("Screen coverage: \(Int(coverage * 100))%")
print("Finder size: \(Int(actualBounds[3].width)) x \(Int(actualBounds[3].height)) (should be ~648x810, not 216x131!)")

print("\n🔍 COMPARISON WITH ACTUAL RESULTS:")
print("==================================")
print("ACTUAL (broken): Finder at 216x131 pixels")
print("EXPECTED (fixed): Finder at ~648x810 pixels")
print("DIFFERENCE: \(Int((actualBounds[3].width - 216) / 216 * 100))% wider, \(Int((actualBounds[3].height - 131) / 131 * 100))% taller")

if coverage >= 0.85 {
    print("✅ Fixed engine achieves good coverage (\(Int(coverage * 100))%)")
} else {
    print("❌ Even fixed engine has poor coverage (\(Int(coverage * 100))%)")
}

print("\n💡 DEBUGGING CONCLUSIONS:")
print("=========================")
if actualBounds[3].width < 400 {
    print("❌ Something is still wrong - Finder should be much larger")
    print("🔍 Need to check if FlexibleLayoutEngine is actually using our updated functions")
} else {
    print("✅ Fixed engine produces correct sizes")
    print("🔍 The issue is likely that our fixes aren't being applied in the real FlexibleLayoutEngine")
}

print("\n🎯 NEXT STEPS:")
print("==============")
print("1. Verify FlexibleLayoutEngine.generateFocusAwareLayout is using our updated functions")
print("2. Check if there's a different code path for glanceable_monitor archetype")
print("3. Look for any hardcoded size overrides after FlexibleLayoutEngine returns")
print("4. Test the real FlexibleLayoutEngine with debug output")