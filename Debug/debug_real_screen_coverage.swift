#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🔍 REAL SCREEN COVERAGE DIAGNOSTIC")
print("===================================")

// From the actual output, we know the system set:
// Height: 437.5 instead of expected 450 (for 50% of 900)
// This suggests screen height might be 875 instead of 900?

print("\n📐 ANALYZING ACTUAL WINDOW SIZES:")
print("================================")

let reportedSizes = [
    ("Terminal", CGSize(width: 720.0, height: 437.5)),
    ("Arc", CGSize(width: 720.0, height: 437.5)),
    ("Xcode", CGSize(width: 720.0, height: 437.5)),
    ("Finder", CGSize(width: 720.0, height: 437.5))
]

// If these are supposed to be 50% each, what would be the implied screen size?
let impliedScreenWidth = reportedSizes[0].1.width * 2
let impliedScreenHeight = reportedSizes[0].1.height * 2

print("  Reported window size: \(reportedSizes[0].1)")
print("  Implied screen size: \(impliedScreenWidth) x \(impliedScreenHeight)")
print("  Expected screen size: 1440 x 900")

let heightDifference = 900 - impliedScreenHeight
print("  Height difference: \(heightDifference) pixels")

print("\n🎯 COVERAGE CALCULATION:")
print("======================")

// Calculate actual coverage with the reported sizes
let actualScreenWidth = 1440.0
let actualScreenHeight = 900.0

func calculateActualCoverage(windows: [(name: String, size: CGSize)], screenSize: CGSize) -> Double {
    // Using the positions from the log:
    // Terminal: (720.0, 437.5) - bottom right
    // Arc: (720.0, 0.0) - top right  
    // Xcode: (0.0, 0.0) - top left
    // Finder: (0.0, 437.5) - bottom left
    
    let positions = [
        CGPoint(x: 720.0, y: 437.5),  // Terminal - bottom right
        CGPoint(x: 720.0, y: 0.0),    // Arc - top right
        CGPoint(x: 0.0, y: 0.0),      // Xcode - top left
        CGPoint(x: 0.0, y: 437.5)     // Finder - bottom left
    ]
    
    var windowRects: [CGRect] = []
    for (index, window) in windows.enumerated() {
        let rect = CGRect(origin: positions[index], size: window.size)
        windowRects.append(rect)
        print("  \(window.name): \(rect)")
    }
    
    // Sample-based coverage calculation
    let sampleSize = 5.0
    let cols = Int(screenSize.width / sampleSize)
    let rows = Int(screenSize.height / sampleSize)
    
    var coveredSamples = 0
    
    for row in 0..<rows {
        for col in 0..<cols {
            let sampleX = Double(col) * sampleSize + sampleSize/2
            let sampleY = Double(row) * sampleSize + sampleSize/2
            let samplePoint = CGPoint(x: sampleX, y: sampleY)
            
            for rect in windowRects {
                if rect.contains(samplePoint) {
                    coveredSamples += 1
                    break
                }
            }
        }
    }
    
    let totalSamples = rows * cols
    return Double(coveredSamples) / Double(totalSamples)
}

let actualCoverage = calculateActualCoverage(
    windows: reportedSizes,
    screenSize: CGSize(width: actualScreenWidth, height: actualScreenHeight)
)

print("\n📊 ACTUAL COVERAGE RESULT:")
print("=========================")
print("  Coverage: \(String(format: "%.1f", actualCoverage * 100))%")

if actualCoverage < 0.999 {
    print("  ❌ FAILED: Not 100% coverage!")
    print("  Gap: \(String(format: "%.1f", (1.0 - actualCoverage) * 100))%")
    
    // Analyze where the gap is
    let maxY = max(437.5 + 437.5, 437.5 + 437.5)  // Bottom edge of bottom windows
    let screenBottom = actualScreenHeight
    
    if maxY < screenBottom {
        let bottomGap = screenBottom - maxY
        print("  🔍 Bottom gap identified: \(bottomGap) pixels")
        print("  🔧 FIX: Increase height from 437.5 to \(actualScreenHeight / 2)")
    }
} else {
    print("  ✅ SUCCESS: 100% coverage achieved")
}

print("\n💡 DIAGNOSIS:")
print("=============")
print("The issue is that windows are sized to 437.5 height instead of 450.")
print("This creates a gap of \(450 - 437.5) = 12.5 pixels at the bottom.")
print("Total gap: \(12.5 * 2) = 25 pixels vertical gap.")
print("")
print("CAUSE: Something is modifying our perfect 50% sizing.")
print("NEED: Debug why .percentage(0.5) becomes 437.5 instead of 450.")

print("\n🔧 REQUIRED FIXES:")
print("=================")
print("1. Ensure screen height detection is correct (should be 900)")
print("2. Verify .toPixels() calculation: 0.5 * 900 = 450 (not 437.5)")
print("3. Check for any constraints/adjustments after our perfect coverage")
print("4. Force exact pixel values if percentage calculations fail")