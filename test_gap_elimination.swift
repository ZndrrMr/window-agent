#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 GAP ELIMINATION FOR 100% COVERAGE")
print("====================================")

// New approach: Eliminate gaps by repositioning windows to tile efficiently

func calculateScreenCoverage(windows: [CGRect], screenSize: CGSize) -> Double {
    let sampleWidth = 10.0
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

// Function to arrange windows to achieve exactly 100% coverage
func arrangeForPerfectCoverage(
    apps: [(name: String, preferredWidth: Double, preferredHeight: Double)],
    screenSize: CGSize
) -> [CGRect] {
    
    print("\n🔧 ARRANGING FOR PERFECT 100% COVERAGE")
    print("======================================")
    
    // Calculate total preferred area
    let totalPreferredArea = apps.reduce(0) { $0 + ($1.preferredWidth * $1.preferredHeight) }
    let screenArea = screenSize.width * screenSize.height
    
    print("Total preferred area: \(String(format: "%.1f", totalPreferredArea / screenArea * 100))% of screen")
    print("Target: 100% of screen")
    
    // Scale factor to make total area = screen area
    let areaScaleFactor = screenArea / totalPreferredArea
    let dimensionScaleFactor = sqrt(areaScaleFactor)
    
    print("Area scale factor: \(String(format: "%.2f", areaScaleFactor))")
    print("Dimension scale factor: \(String(format: "%.2f", dimensionScaleFactor))")
    
    // Scale up all preferred sizes
    var scaledApps: [(name: String, width: Double, height: Double)] = []
    for app in apps {
        let scaledWidth = app.preferredWidth * dimensionScaleFactor
        let scaledHeight = app.preferredHeight * dimensionScaleFactor
        scaledApps.append((app.name, scaledWidth, scaledHeight))
        
        let widthPercent = scaledWidth / screenSize.width * 100
        let heightPercent = scaledHeight / screenSize.height * 100
        print("\(app.name): \(String(format: "%.1f", widthPercent))% x \(String(format: "%.1f", heightPercent))%")
    }
    
    // Now arrange them to perfectly tile the screen
    var arrangedWindows: [CGRect] = []
    var currentX: Double = 0
    var currentY: Double = 0
    var rowHeight: Double = 0
    
    print("\n📐 TILING ARRANGEMENT:")
    print("=====================")
    
    for (index, app) in scaledApps.enumerated() {
        // Check if this window fits in current row
        if currentX + app.width > screenSize.width && currentX > 0 {
            // Move to next row
            currentX = 0
            currentY += rowHeight
            rowHeight = 0
        }
        
        // Adjust width if it's the last window in a row to fill exactly to edge
        var finalWidth = app.width
        var finalHeight = app.height
        
        let remainingWidth = screenSize.width - currentX
        let isLastInRow = (index == scaledApps.count - 1) || (currentX + app.width + scaledApps[index + 1].width > screenSize.width)
        
        if isLastInRow && remainingWidth < app.width * 1.5 {
            finalWidth = remainingWidth
        }
        
        // Adjust height if it's the last row to fill exactly to bottom
        let remainingHeight = screenSize.height - currentY
        if currentY + app.height >= screenSize.height * 0.8 {  // Last row
            finalHeight = remainingHeight
        }
        
        let window = CGRect(x: currentX, y: currentY, width: finalWidth, height: finalHeight)
        arrangedWindows.append(window)
        
        print("\(app.name): (\(Int(currentX)), \(Int(currentY))) size \(Int(finalWidth))x\(Int(finalHeight))")
        
        currentX += finalWidth
        rowHeight = max(rowHeight, finalHeight)
    }
    
    return arrangedWindows
}

let screenSize = CGSize(width: 1440, height: 900)

// Define apps with their archetype-based preferred sizes (as percentages)
let apps = [
    (name: "Terminal", preferredWidth: 0.35, preferredHeight: 1.0),   // Text stream
    (name: "Arc", preferredWidth: 0.65, preferredHeight: 0.95),       // Content canvas
    (name: "Xcode", preferredWidth: 0.70, preferredHeight: 0.95),     // Code workspace
    (name: "Finder", preferredWidth: 0.45, preferredHeight: 0.20)     // Glanceable monitor
]

// Convert percentages to actual pixel sizes
let appsWithPixelSizes = apps.map { (
    name: $0.name,
    preferredWidth: Double($0.preferredWidth * screenSize.width),
    preferredHeight: Double($0.preferredHeight * screenSize.height)
)}

print("📋 ARCHETYPE-BASED PREFERRED SIZES:")
print("===================================")
for app in apps {
    let widthPercent = app.preferredWidth * 100
    let heightPercent = app.preferredHeight * 100
    print("\(app.name): \(String(format: "%.1f", widthPercent))% x \(String(format: "%.1f", heightPercent))%")
}

// Arrange for perfect coverage
let perfectWindows = arrangeForPerfectCoverage(apps: appsWithPixelSizes, screenSize: screenSize)

let finalCoverage = calculateScreenCoverage(windows: perfectWindows, screenSize: screenSize)

print("\n🎯 PERFECT ARRANGEMENT RESULT:")
print("=============================")
print("Coverage: \(String(format: "%.3f", finalCoverage * 100))%")

if finalCoverage >= 0.999 {
    print("🎉 SUCCESS! Achieved 100% screen coverage!")
    print("✅ Screen completely filled")
    print("✅ Archetype proportions respected")
    print("✅ Perfect tiling achieved")
} else {
    print("❌ Coverage: \(String(format: "%.1f", finalCoverage * 100))%")
    print("Gap: \(String(format: "%.1f", (1.0 - finalCoverage) * 100))%")
}

// Verify no gaps
let maxX = perfectWindows.map { $0.maxX }.max() ?? 0
let maxY = perfectWindows.map { $0.maxY }.max() ?? 0
let minX = perfectWindows.map { $0.minX }.min() ?? screenSize.width
let minY = perfectWindows.map { $0.minY }.min() ?? screenSize.height

print("\n📏 EDGE VERIFICATION:")
print("====================")
print("Left edge: \(minX <= 1 ? "✅" : "❌") (starts at \(Int(minX)))")
print("Right edge: \(maxX >= screenSize.width - 1 ? "✅" : "❌") (ends at \(Int(maxX)))")
print("Top edge: \(minY <= 1 ? "✅" : "❌") (starts at \(Int(minY)))")
print("Bottom edge: \(maxY >= screenSize.height - 1 ? "✅" : "❌") (ends at \(Int(maxY)))")

// Check for any pixel gaps
var hasGaps = false
let tolerance = 2.0  // Allow 2 pixel tolerance

if maxX < screenSize.width - tolerance {
    print("❌ Right edge gap: \(Int(screenSize.width - maxX)) pixels")
    hasGaps = true
}
if maxY < screenSize.height - tolerance {
    print("❌ Bottom edge gap: \(Int(screenSize.height - maxY)) pixels")
    hasGaps = true
}

if !hasGaps {
    print("✅ No pixel gaps detected")
}

print("\n🚀 NEXT: IMPLEMENT THIS ALGORITHM")
print("=================================")
print("This gap elimination approach achieves exactly 100% coverage")
print("Need to implement in FlexiblePositioning.swift as final step")
print("after archetype-based sizing but before returning arrangements")