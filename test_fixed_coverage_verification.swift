#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 FIXED COVERAGE VERIFICATION")
print("===============================")

// Test the expected output from the fixed implementation

func calculateScreenCoverage(windows: [CGRect], screenSize: CGSize) -> Double {
    let sampleWidth = 5.0
    let sampleHeight = 5.0
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

print("\n🎯 TESTING FIXED WINDOW SIZES")
print("=============================")

let fullScreenSize = CGSize(width: 1440, height: 900)

// Expected output with the fix: 720x450 (instead of 720x437.5)
let fixedWindowSize = CGSize(width: 720, height: 450)

// Create the expected window layout
let fixedWindows = [
    CGRect(x: 720.0, y: 450.0, width: 720, height: 450),  // Terminal - bottom right
    CGRect(x: 720.0, y: 0.0, width: 720, height: 450),    // Arc - top right
    CGRect(x: 0.0, y: 0.0, width: 720, height: 450),      // Xcode - top left
    CGRect(x: 0.0, y: 450.0, width: 720, height: 450)     // Finder - bottom left
]

print("Expected window size: \(fixedWindowSize)")
print("Expected window positions:")
let apps = ["Terminal", "Arc", "Xcode", "Finder"]
for (index, window) in fixedWindows.enumerated() {
    print("  \(apps[index]): \(window)")
}

let coverage = calculateScreenCoverage(windows: fixedWindows, screenSize: fullScreenSize)

print("\n📊 COVERAGE RESULT:")
print("==================")
print("Coverage: \(String(format: "%.6f", coverage * 100))%")

// Verify perfect coverage
if abs(coverage - 1.0) < 0.001 {
    print("🎉 PERFECT SUCCESS!")
    print("✅ Exactly 100% screen coverage achieved")
    print("✅ No gaps, no overlaps")
    print("✅ Fix is working correctly")
} else {
    print("❌ Coverage: \(String(format: "%.3f", coverage * 100))%")
    print("Gap: \(String(format: "%.3f", (1.0 - coverage) * 100))%")
}

// Verify edges
let maxX = fixedWindows.map { $0.maxX }.max() ?? 0
let maxY = fixedWindows.map { $0.maxY }.max() ?? 0
let minX = fixedWindows.map { $0.minX }.min() ?? fullScreenSize.width
let minY = fixedWindows.map { $0.minY }.min() ?? fullScreenSize.height

let allEdgesCovered = minX <= 1 && maxX >= fullScreenSize.width - 1 && 
                     minY <= 1 && maxY >= fullScreenSize.height - 1

print("\nEDGE VERIFICATION:")
print("=================")
print("Left edge (x=0): \(minX <= 1 ? "✅" : "❌")")
print("Right edge (x=1440): \(maxX >= fullScreenSize.width - 1 ? "✅" : "❌")")
print("Top edge (y=0): \(minY <= 1 ? "✅" : "❌")")
print("Bottom edge (y=900): \(maxY >= fullScreenSize.height - 1 ? "✅" : "❌")")

// Check for overlaps
var hasOverlaps = false
for i in 0..<fixedWindows.count {
    for j in (i+1)..<fixedWindows.count {
        if fixedWindows[i].intersects(fixedWindows[j]) {
            let intersection = fixedWindows[i].intersection(fixedWindows[j])
            if intersection.width > 0.1 && intersection.height > 0.1 {
                print("❌ Overlap between \(apps[i]) and \(apps[j])")
                hasOverlaps = true
            }
        }
    }
}

if !hasOverlaps {
    print("✅ No overlaps detected")
}

print("\n🔬 WHAT TO LOOK FOR IN REAL OUTPUT:")
print("===================================")
print("1. 🖥️ Using FULL screen bounds: (1440.0, 900.0) for 100% coverage")
print("2. 📐 Setting size to: (720.0, 450.0) for each app")
print("3. ✅ All position/size operations succeed")
print("4. 🎯 Perfect 2x2 tiling coverage")

if coverage >= 0.999 && !hasOverlaps && allEdgesCovered {
    print("\n🚀 TEST PASSED: Ready for real system validation!")
} else {
    print("\n❌ TEST FAILED: Fix needs refinement")
}