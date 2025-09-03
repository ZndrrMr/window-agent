#!/usr/bin/env swift

import Foundation

print("🧮 ARCHETYPE MATH DEBUG")
print("========================")
print("Tracing the FlexibleLayoutEngine math that's creating uniform quarters")
print("")

// From the logs, archetype sizes:
let archetypeData = [
    ("Terminal", 0.35, 1.00, "Text Stream"),      // 35% area
    ("Arc", 0.65, 0.95, "Content Canvas"),        // 61% area  
    ("Xcode", 0.70, 0.95, "Code Workspace"),      // 66% area (largest)
    ("Finder", 0.45, 0.90, "Glanceable Monitor")  // 40% area
]

print("📊 ARCHETYPE SIZES:")
print("==================")
for (app, width, height, type) in archetypeData {
    let area = width * height
    print("📱 \(app): \(Int(width*100))%×\(Int(height*100))% = \(Int(area*10000)/100)% (\(type))")
}
print("")

// Sort by area (largest first) - this is what FlexibleLayoutEngine does
let sortedByArea = archetypeData.sorted { $0.1 * $0.2 > $1.1 * $1.2 }
print("📊 SORTED BY AREA (FlexibleLayoutEngine order):")
for (index, (app, width, height, _)) in sortedByArea.enumerated() {
    let area = width * height
    let position = ["Top-left", "Top-right", "Bottom-left", "Bottom-right"][index]
    print("  \(index + 1). \(app): \(Int(area*10000)/100)% → \(position)")
}
print("")

// Now trace the FlexibleLayoutEngine math (lines 565-574)
let app1 = sortedByArea[0] // Xcode (top-left)
let app2 = sortedByArea[1] // Arc (top-right)  
let app3 = sortedByArea[2] // Finder (bottom-left)
let app4 = sortedByArea[3] // Terminal (bottom-right)

print("🧮 FLEXIBLELAYOUTENGINE MATH:")
print("=============================")
print("app1 (Xcode): \(app1.1)×\(app1.2)")
print("app2 (Arc): \(app2.1)×\(app2.2)")
print("app3 (Finder): \(app3.1)×\(app3.2)")
print("app4 (Terminal): \(app4.1)×\(app4.2)")
print("")

// Calculate the splits exactly like FlexibleLayoutEngine
func normalizeToSum(_ values: [Double], target: Double) -> [Double] {
    let sum = values.reduce(0, +)
    return values.map { ($0 / sum) * target }
}

let topRowSplit = normalizeToSum([app1.1, app2.1], target: 1.0)      // [Xcode.width, Arc.width]
let bottomRowSplit = normalizeToSum([app3.1, app4.1], target: 1.0)   // [Finder.width, Terminal.width]
let leftColSplit = normalizeToSum([app1.2, app3.2], target: 1.0)     // [Xcode.height, Finder.height]
let rightColSplit = normalizeToSum([app2.2, app4.2], target: 1.0)    // [Arc.height, Terminal.height]

print("📐 ROW/COLUMN SPLITS:")
print("topRowSplit: [\(String(format: "%.3f", topRowSplit[0])), \(String(format: "%.3f", topRowSplit[1]))] (Xcode vs Arc widths)")
print("bottomRowSplit: [\(String(format: "%.3f", bottomRowSplit[0])), \(String(format: "%.3f", bottomRowSplit[1]))] (Finder vs Terminal widths)")
print("leftColSplit: [\(String(format: "%.3f", leftColSplit[0])), \(String(format: "%.3f", leftColSplit[1]))] (Xcode vs Finder heights)")
print("rightColSplit: [\(String(format: "%.3f", rightColSplit[0])), \(String(format: "%.3f", rightColSplit[1]))] (Arc vs Terminal heights)")
print("")

// THE PROBLEMATIC AVERAGING (lines 571-574)
let leftWidth = (topRowSplit[0] + bottomRowSplit[0]) / 2.0   // Average of Xcode and Finder width ratios
let rightWidth = 1.0 - leftWidth
let topHeight = (leftColSplit[0] + rightColSplit[0]) / 2.0   // Average of Xcode and Arc height ratios  
let bottomHeight = 1.0 - topHeight

print("❌ PROBLEMATIC AVERAGING:")
print("leftWidth = (topRowSplit[0] + bottomRowSplit[0]) / 2 = (\(String(format: "%.3f", topRowSplit[0])) + \(String(format: "%.3f", bottomRowSplit[0]))) / 2 = \(String(format: "%.3f", leftWidth))")
print("rightWidth = 1 - leftWidth = \(String(format: "%.3f", rightWidth))")
print("topHeight = (leftColSplit[0] + rightColSplit[0]) / 2 = (\(String(format: "%.3f", leftColSplit[0])) + \(String(format: "%.3f", rightColSplit[0]))) / 2 = \(String(format: "%.3f", topHeight))")
print("bottomHeight = 1 - topHeight = \(String(format: "%.3f", bottomHeight))")
print("")

print("📊 FINAL LAYOUT AREAS:")
print("======================")
let xcodeBounds = (width: leftWidth, height: topHeight)
let arcBounds = (width: rightWidth, height: topHeight)
let finderBounds = (width: leftWidth, height: bottomHeight)
let terminalBounds = (width: rightWidth, height: bottomHeight)

print("📱 Xcode: \(String(format: "%.1f", xcodeBounds.width*100))%×\(String(format: "%.1f", xcodeBounds.height*100))% = \(String(format: "%.1f", xcodeBounds.width * xcodeBounds.height * 100))% area")
print("📱 Arc: \(String(format: "%.1f", arcBounds.width*100))%×\(String(format: "%.1f", arcBounds.height*100))% = \(String(format: "%.1f", arcBounds.width * arcBounds.height * 100))% area")
print("📱 Finder: \(String(format: "%.1f", finderBounds.width*100))%×\(String(format: "%.1f", finderBounds.height*100))% = \(String(format: "%.1f", finderBounds.width * finderBounds.height * 100))% area")
print("📱 Terminal: \(String(format: "%.1f", terminalBounds.width*100))%×\(String(format: "%.1f", terminalBounds.height*100))% = \(String(format: "%.1f", terminalBounds.width * terminalBounds.height * 100))% area")
print("")

print("🎯 PROBLEM IDENTIFIED:")
print("======================")
print("The averaging in lines 571-574 flattens archetype differences!")
print("Even though archetypes have different sizes (35% to 66% area),")
print("the mathematical averaging creates near-uniform results.")
print("")
print("💡 FIX: Remove the averaging and use direct archetype proportions")
print("    without mathematical flattening.")