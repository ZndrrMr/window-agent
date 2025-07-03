#!/usr/bin/env swift

import Foundation

print("🧮 NEW ALGORITHM TEST")
print("=====================")
print("Testing the fixed direct archetype proportions algorithm")
print("")

// Same archetype data as before
let archetypeData = [
    ("Terminal", 0.35, 1.00, "Text Stream"),      // 35% area
    ("Arc", 0.65, 0.95, "Content Canvas"),        // 61% area  
    ("Xcode", 0.70, 0.95, "Code Workspace"),      // 66% area (largest)
    ("Finder", 0.45, 0.90, "Glanceable Monitor")  // 40% area
]

// Sort by area (FlexibleLayoutEngine order)
let sortedByArea = archetypeData.sorted { $0.1 * $0.2 > $1.1 * $1.2 }
let app1 = sortedByArea[0] // Xcode (top-left)
let app2 = sortedByArea[1] // Arc (top-right)  
let app3 = sortedByArea[2] // Finder (bottom-left)
let app4 = sortedByArea[3] // Terminal (bottom-right)

print("📊 APP ASSIGNMENTS:")
print("==================")
print("app1 (top-left): \(app1.0) - \(app1.1)×\(app1.2) = \(Int((app1.1 * app1.2)*10000)/100)% area")
print("app2 (top-right): \(app2.0) - \(app2.1)×\(app2.2) = \(Int((app2.1 * app2.2)*10000)/100)% area")
print("app3 (bottom-left): \(app3.0) - \(app3.1)×\(app3.2) = \(Int((app3.1 * app3.2)*10000)/100)% area")
print("app4 (bottom-right): \(app4.0) - \(app4.1)×\(app4.2) = \(Int((app4.1 * app4.2)*10000)/100)% area")
print("")

// NEW ALGORITHM: Direct archetype proportions
print("🎯 NEW ALGORITHM - DIRECT PROPORTIONS:")
print("======================================")

let totalArea = (app1.1 * app1.2) + (app2.1 * app2.2) + (app3.1 * app3.2) + (app4.1 * app4.2)
let app1AreaRatio = (app1.1 * app1.2) / totalArea
let app2AreaRatio = (app2.1 * app2.2) / totalArea
let app3AreaRatio = (app3.1 * app3.2) / totalArea
let app4AreaRatio = (app4.1 * app4.2) / totalArea

print("Area ratios:")
print("  app1 (\(app1.0)): \(String(format: "%.3f", app1AreaRatio)) (\(String(format: "%.1f", app1AreaRatio * 100))%)")
print("  app2 (\(app2.0)): \(String(format: "%.3f", app2AreaRatio)) (\(String(format: "%.1f", app2AreaRatio * 100))%)")
print("  app3 (\(app3.0)): \(String(format: "%.3f", app3AreaRatio)) (\(String(format: "%.1f", app3AreaRatio * 100))%)")
print("  app4 (\(app4.0)): \(String(format: "%.3f", app4AreaRatio)) (\(String(format: "%.1f", app4AreaRatio * 100))%)")
print("")

// Calculate proportional widths and heights
let app1WidthRatio = sqrt(app1AreaRatio * app1.1 / app1.2)
let app2WidthRatio = sqrt(app2AreaRatio * app2.1 / app2.2)
let app3WidthRatio = sqrt(app3AreaRatio * app3.1 / app3.2)
let app4WidthRatio = sqrt(app4AreaRatio * app4.1 / app4.2)

print("Width ratios (square root scaling):")
print("  app1: \(String(format: "%.3f", app1WidthRatio))")
print("  app2: \(String(format: "%.3f", app2WidthRatio))")
print("  app3: \(String(format: "%.3f", app3WidthRatio))")
print("  app4: \(String(format: "%.3f", app4WidthRatio))")
print("")

// Normalize to ensure screen coverage
let totalTopWidth = app1WidthRatio + app2WidthRatio
let totalBottomWidth = app3WidthRatio + app4WidthRatio
let maxTotalWidth = max(totalTopWidth, totalBottomWidth)

let leftWidth = max(app1WidthRatio, app3WidthRatio) / maxTotalWidth
let rightWidth = 1.0 - leftWidth

print("Screen division:")
print("  totalTopWidth: \(String(format: "%.3f", totalTopWidth))")
print("  totalBottomWidth: \(String(format: "%.3f", totalBottomWidth))")
print("  maxTotalWidth: \(String(format: "%.3f", maxTotalWidth))")
print("  leftWidth: \(String(format: "%.3f", leftWidth)) (\(String(format: "%.1f", leftWidth * 100))%)")
print("  rightWidth: \(String(format: "%.3f", rightWidth)) (\(String(format: "%.1f", rightWidth * 100))%)")
print("")

// Calculate heights
let app1HeightRatio = sqrt(app1AreaRatio * app1.2 / app1.1)
let app3HeightRatio = sqrt(app3AreaRatio * app3.2 / app3.1)
let totalLeftHeight = app1HeightRatio + app3HeightRatio

let topHeight = app1HeightRatio / totalLeftHeight
let bottomHeight = 1.0 - topHeight

print("Height division:")
print("  app1HeightRatio: \(String(format: "%.3f", app1HeightRatio))")
print("  app3HeightRatio: \(String(format: "%.3f", app3HeightRatio))")
print("  totalLeftHeight: \(String(format: "%.3f", totalLeftHeight))")
print("  topHeight: \(String(format: "%.3f", topHeight)) (\(String(format: "%.1f", topHeight * 100))%)")
print("  bottomHeight: \(String(format: "%.3f", bottomHeight)) (\(String(format: "%.1f", bottomHeight * 100))%)")
print("")

print("📊 FINAL INTELLIGENT LAYOUT:")
print("============================")
let xcodeBounds = (width: leftWidth, height: topHeight)
let arcBounds = (width: rightWidth, height: topHeight)
let finderBounds = (width: leftWidth, height: bottomHeight)
let terminalBounds = (width: rightWidth, height: bottomHeight)

print("📱 \(app1.0): \(String(format: "%.1f", xcodeBounds.width*100))%×\(String(format: "%.1f", xcodeBounds.height*100))% = \(String(format: "%.1f", xcodeBounds.width * xcodeBounds.height * 100))% area")
print("📱 \(app2.0): \(String(format: "%.1f", arcBounds.width*100))%×\(String(format: "%.1f", arcBounds.height*100))% = \(String(format: "%.1f", arcBounds.width * arcBounds.height * 100))% area")
print("📱 \(app3.0): \(String(format: "%.1f", finderBounds.width*100))%×\(String(format: "%.1f", finderBounds.height*100))% = \(String(format: "%.1f", finderBounds.width * finderBounds.height * 100))% area")
print("📱 \(app4.0): \(String(format: "%.1f", terminalBounds.width*100))%×\(String(format: "%.1f", terminalBounds.height*100))% = \(String(format: "%.1f", terminalBounds.width * terminalBounds.height * 100))% area")
print("")

// Test for quarters detection
let areas = [
    xcodeBounds.width * xcodeBounds.height,
    arcBounds.width * arcBounds.height,
    finderBounds.width * finderBounds.height,
    terminalBounds.width * terminalBounds.height
]

let avgArea = areas.reduce(0, +) / Double(areas.count)
let maxDeviation = areas.map { abs($0 - avgArea) }.max() ?? 0

print("🔍 QUARTERS TEST:")
print("================")
print("Average area: \(String(format: "%.1f", avgArea * 100))%")
print("Max deviation: \(String(format: "%.1f", maxDeviation * 100))%")

let isUniformQuarters = maxDeviation < 0.05 && abs(avgArea - 0.25) < 0.05

if isUniformQuarters {
    print("❌ STILL UNIFORM QUARTERS! Algorithm needs more work.")
} else {
    print("✅ SUCCESS! Non-uniform intelligent proportional layout!")
    print("   Different apps have meaningfully different areas")
}

print("")
print("🎯 EXPECTED IMPROVEMENT:")
print("========================")
print("The largest app (Xcode) should get significantly more area than smallest (Terminal)")
print("Current largest: \(String(format: "%.1f", areas.max()! * 100))%")
print("Current smallest: \(String(format: "%.1f", areas.min()! * 100))%")
print("Difference: \(String(format: "%.1f", (areas.max()! - areas.min()!) * 100))%")

if (areas.max()! - areas.min()!) > 0.10 {
    print("✅ Good: More than 10% difference between largest and smallest")
} else {
    print("❌ Still too uniform: Less than 10% difference")
}