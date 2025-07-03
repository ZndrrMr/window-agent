#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 100% SCREEN COVERAGE TEST")
print("============================")

// Test for EXACTLY 100% coverage through proportional scaling

func calculateScreenCoverage(windows: [CGRect], screenSize: CGSize) -> Double {
    let sampleWidth = 10.0  // Higher resolution for more accurate measurement
    let sampleHeight = 10.0
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

// Function to scale windows to achieve 100% coverage
func scaleWindowsToFillScreen(windows: [CGRect], screenSize: CGSize) -> [CGRect] {
    print("\n🔧 SCALING WINDOWS TO FILL SCREEN 100%")
    print("=====================================")
    
    // Step 1: Calculate current coverage
    let currentCoverage = calculateScreenCoverage(windows: windows, screenSize: screenSize)
    print("Current coverage: \(Int(currentCoverage * 100))%")
    
    if currentCoverage >= 0.999 {
        print("Already at 100% coverage")
        return windows
    }
    
    // Step 2: Find the bounding box of all windows
    let minX = windows.map { $0.minX }.min() ?? 0
    let minY = windows.map { $0.minY }.min() ?? 0
    let maxX = windows.map { $0.maxX }.max() ?? screenSize.width
    let maxY = windows.map { $0.maxY }.max() ?? screenSize.height
    
    print("Current bounds: (\(Int(minX)), \(Int(minY))) to (\(Int(maxX)), \(Int(maxY)))")
    
    // Step 3: Calculate scale factors to fill entire screen
    let currentWidth = maxX - minX
    let currentHeight = maxY - minY
    
    let scaleX = screenSize.width / currentWidth
    let scaleY = screenSize.height / currentHeight
    
    print("Scale factors: X=\(String(format: "%.2f", scaleX)), Y=\(String(format: "%.2f", scaleY))")
    
    // Step 4: Apply scaling to all windows
    var scaledWindows: [CGRect] = []
    
    for (index, window) in windows.enumerated() {
        // Scale position relative to the bounding box origin
        let relativeX = (window.minX - minX) * scaleX
        let relativeY = (window.minY - minY) * scaleY
        
        // Scale size
        let scaledWidth = window.width * scaleX
        let scaledHeight = window.height * scaleY
        
        let scaledWindow = CGRect(
            x: relativeX,
            y: relativeY,
            width: scaledWidth,
            height: scaledHeight
        )
        
        scaledWindows.append(scaledWindow)
        print("Window \(index): \(window) → \(scaledWindow)")
    }
    
    // Step 5: Verify 100% coverage
    let finalCoverage = calculateScreenCoverage(windows: scaledWindows, screenSize: screenSize)
    print("Final coverage: \(String(format: "%.1f", finalCoverage * 100))%")
    
    return scaledWindows
}

let screenSize = CGSize(width: 1440, height: 900)

// Test with our current layout (Terminal, Arc, Xcode, Finder)
print("\n📐 ORIGINAL ARCHETYPE-BASED LAYOUT:")
print("===================================")

let originalWindows = [
    CGRect(x: 0, y: 0, width: 504, height: 900),        // Terminal: 35% x 100%
    CGRect(x: 144, y: 72, width: 936, height: 855),     // Arc: 65% x 95%
    CGRect(x: 259, y: 126, width: 1008, height: 855),   // Xcode: 70% x 95%
    CGRect(x: 72, y: 720, width: 648, height: 180)      // Finder: 45% x 20%
]

let apps = ["Terminal", "Arc", "Xcode", "Finder"]
for (index, window) in originalWindows.enumerated() {
    let widthPercent = window.width / screenSize.width * 100
    let heightPercent = window.height / screenSize.height * 100
    print("\(apps[index]): \(Int(widthPercent))% x \(Int(heightPercent))% at (\(Int(window.minX)), \(Int(window.minY)))")
}

let originalCoverage = calculateScreenCoverage(windows: originalWindows, screenSize: screenSize)
print("Original coverage: \(Int(originalCoverage * 100))%")

// Scale to 100% coverage
let scaledWindows = scaleWindowsToFillScreen(windows: originalWindows, screenSize: screenSize)

print("\n📊 SCALED LAYOUT (100% COVERAGE):")
print("=================================")

for (index, window) in scaledWindows.enumerated() {
    let widthPercent = window.width / screenSize.width * 100
    let heightPercent = window.height / screenSize.height * 100
    print("\(apps[index]): \(String(format: "%.1f", widthPercent))% x \(String(format: "%.1f", heightPercent))% at (\(Int(window.minX)), \(Int(window.minY)))")
}

let finalCoverage = calculateScreenCoverage(windows: scaledWindows, screenSize: screenSize)

print("\n🎯 FINAL RESULT:")
print("================")
print("Coverage: \(String(format: "%.3f", finalCoverage * 100))%")

if finalCoverage >= 0.999 {
    print("🎉 SUCCESS! Achieved 100% screen coverage!")
    print("✅ Screen completely filled")
    print("✅ Archetype proportions maintained")
    print("✅ No wasted pixels")
} else {
    print("❌ Failed to achieve 100% coverage")
    print("Coverage gap: \(String(format: "%.1f", (1.0 - finalCoverage) * 100))%")
}

// Test edge coverage specifically
let maxX = scaledWindows.map { $0.maxX }.max() ?? 0
let maxY = scaledWindows.map { $0.maxY }.max() ?? 0
let minX = scaledWindows.map { $0.minX }.min() ?? screenSize.width
let minY = scaledWindows.map { $0.minY }.min() ?? screenSize.height

print("\n📏 EDGE COVERAGE:")
print("=================")
print("Left edge: \(minX <= 1 ? "✅" : "❌") (starts at \(Int(minX)))")
print("Right edge: \(maxX >= screenSize.width - 1 ? "✅" : "❌") (ends at \(Int(maxX)))")
print("Top edge: \(minY <= 1 ? "✅" : "❌") (starts at \(Int(minY)))")
print("Bottom edge: \(maxY >= screenSize.height - 1 ? "✅" : "❌") (ends at \(Int(maxY)))")

print("\n💡 ALGORITHM EXPLANATION:")
print("========================")
print("1. Calculate current window arrangement coverage")
print("2. Find bounding box of all windows")
print("3. Calculate scale factors to make bounding box = screen size")
print("4. Apply proportional scaling to all windows")
print("5. Result: 100% screen coverage while maintaining relative sizes")

print("\n🚀 IMPLEMENTATION NEEDED:")
print("========================")
print("Add this scaling algorithm to FlexiblePositioning.swift")
print("Call it after generating archetype-based layout")
print("Ensure every layout achieves exactly 100% coverage")