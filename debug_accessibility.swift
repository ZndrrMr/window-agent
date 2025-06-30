#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🔍 DEBUGGING ACCESSIBILITY TEST")

let cursorBounds = CGRect(x: 0, y: 0, width: 792, height: 765)
let arcBounds = CGRect(x: 504, y: 135, width: 648, height: 630)
let terminalBounds = CGRect(x: 1080, y: 0, width: 360, height: 900)

print("Window positions:")
print("- Cursor: \(cursorBounds)")  
print("- Arc: \(arcBounds)")
print("- Terminal: \(terminalBounds)")

// Test Arc title bar visibility
let arcTitleBar = CGRect(x: arcBounds.minX, y: arcBounds.minY, width: arcBounds.width, height: 30)
let intersection = cursorBounds.intersection(arcTitleBar)

print("\nArc title bar analysis:")
print("- Title bar area: \(arcTitleBar)")
print("- Intersection with Cursor: \(intersection)")
print("- Title bar width: \(arcTitleBar.width)")
print("- Intersection width: \(intersection.width)")

let titleBarVisibleWidth = arcTitleBar.width - intersection.width
let titleBarVisiblePercent = titleBarVisibleWidth / arcTitleBar.width

print("- Visible title bar width: \(titleBarVisibleWidth)")
print("- Visible percent: \(titleBarVisiblePercent * 100)%")
print("- Required: 20%")
print("- Title bar test: \(titleBarVisiblePercent >= 0.2 ? "PASS" : "FAIL")")

// Test Terminal intersections
print("\nTerminal intersection tests:")
print("- Cursor intersects Terminal: \(cursorBounds.intersects(terminalBounds))")
print("- Arc intersects Terminal: \(arcBounds.intersects(terminalBounds))")

// Test Arc overall visibility
let arcVisibleArea = arcBounds.width * arcBounds.height - intersection.width * intersection.height
let arcTotalArea = arcBounds.width * arcBounds.height
let arcVisiblePercent = arcVisibleArea / arcTotalArea

print("\nArc overall visibility:")
print("- Total area: \(arcTotalArea)")
print("- Blocked area: \(intersection.width * intersection.height)")
print("- Visible area: \(arcVisibleArea)")
print("- Visible percent: \(arcVisiblePercent * 100)%")
print("- Required: 30%")
print("- Overall visibility test: \(arcVisiblePercent >= 0.3 ? "PASS" : "FAIL")")

print("\n🎯 ISSUE IDENTIFICATION:")
if titleBarVisiblePercent < 0.2 {
    print("❌ Arc title bar not visible enough - need to adjust positioning")
}
if arcVisiblePercent < 0.3 {
    print("❌ Arc not visible enough overall - too much overlap with Cursor")
}
if cursorBounds.intersects(terminalBounds) {
    print("❌ Cursor blocks Terminal")
}
if arcBounds.intersects(terminalBounds) {
    print("❌ Arc blocks Terminal")
}