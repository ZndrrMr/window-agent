#!/usr/bin/env swift

import Foundation
import Cocoa
import CoreGraphics

// Simulate the issue: LLM generates 100% width/height but only position is applied

print("🔍 DEBUGGING TERMINAL SIZE ISSUE")
print("==================================")

// 1. Simulate LLM response for 'make terminal take up the whole screen'
print("\n1. SIMULATED LLM RESPONSE:")
let llmResponse = """
{
  "tool_use": {
    "id": "test-001",
    "name": "flexible_position",
    "input": {
      "app_name": "Terminal",
      "x_position": "0",
      "y_position": "0", 
      "width": "100",
      "height": "100",
      "layer": 3,
      "focus": true
    }
  }
}
"""
print("  LLM Output: flexible_position(app_name: 'Terminal', x_position: '0', y_position: '0', width: '100', height: '100', layer: 3, focus: true)")

// 2. Simulate ToolToCommandConverter.convertFlexiblePosition()
print("\n2. TOOL TO COMMAND CONVERSION:")

struct SimulatedLLMToolUse {
    let name: String
    let input: [String: Any]
}

func simulateParsePercentageValue(_ value: String) -> Double {
    if value.hasSuffix("%") {
        let numberStr = String(value.dropLast(1))
        return Double(numberStr) ?? 0
    } else {
        return Double(value) ?? 0
    }
}

func simulateConvertFlexiblePosition(_ input: [String: Any]) -> (position: CGPoint, size: CGSize)? {
    guard let appName = input["app_name"] as? String,
          let xPos = input["x_position"] as? String,
          let yPos = input["y_position"] as? String,
          let width = input["width"] as? String,
          let height = input["height"] as? String else {
        return nil
    }
    
    print("  📝 Input parameters:")
    print("    app_name: \(appName)")
    print("    x_position: \(xPos)")
    print("    y_position: \(yPos)")
    print("    width: \(width)")
    print("    height: \(height)")
    
    // Get screen bounds (simulated)
    let screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    print("  📱 Screen bounds: \(screenBounds)")
    
    // Parse position values
    let x: Double
    let y: Double
    
    if xPos.hasSuffix("px") {
        x = Double(xPos.dropLast(2)) ?? 0
    } else {
        let percentage = simulateParsePercentageValue(xPos)
        x = screenBounds.width * (percentage / 100.0)
    }
    
    if yPos.hasSuffix("px") {
        y = Double(yPos.dropLast(2)) ?? 0
    } else {
        let percentage = simulateParsePercentageValue(yPos)
        y = screenBounds.height * (percentage / 100.0)
    }
    
    // Parse size values
    let w: Double
    let h: Double
    
    if width.hasSuffix("px") {
        w = Double(width.dropLast(2)) ?? 0
    } else {
        let percentage = simulateParsePercentageValue(width)
        w = screenBounds.width * (percentage / 100.0)
    }
    
    if height.hasSuffix("px") {
        h = Double(height.dropLast(2)) ?? 0
    } else {
        let percentage = simulateParsePercentageValue(height)
        h = screenBounds.height * (percentage / 100.0)
    }
    
    print("  📊 CALCULATED VALUES:")
    print("    x: \(x) (from \(xPos))")
    print("    y: \(y) (from \(yPos))")
    print("    w: \(w) (from \(width))")
    print("    h: \(h) (from \(height))")
    
    return (position: CGPoint(x: x, y: y), size: CGSize(width: w, height: h))
}

// Test the conversion
let testInput: [String: Any] = [
    "app_name": "Terminal",
    "x_position": "0",
    "y_position": "0",
    "width": "100",
    "height": "100",
    "layer": 3,
    "focus": true
]

if let result = simulateConvertFlexiblePosition(testInput) {
    print("  ✅ CONVERSION SUCCESSFUL:")
    print("    Position: \(result.position)")
    print("    Size: \(result.size)")
} else {
    print("  ❌ CONVERSION FAILED")
}

// 3. Simulate WindowCommand creation  
print("\n3. WINDOW COMMAND CREATION:")
if let result = simulateConvertFlexiblePosition(testInput) {
    print("  WindowCommand created with:")
    print("    action: .move")
    print("    target: Terminal")
    print("    position: .precise")
    print("    size: .precise")
    print("    customSize: \(result.size)")
    print("    customPosition: \(result.position)")
    print("    parameters: ['layer': '3', 'focus': 'true']")
}

// 4. Simulate WindowPositioner.moveWindow() execution
print("\n4. WINDOW POSITIONER EXECUTION:")
print("  moveWindow() called with command.position == .precise")
print("  Checking if customPosition and customSize are both present...")

if let result = simulateConvertFlexiblePosition(testInput) {
    let customPosition = result.position
    let customSize = result.size
    
    print("  customPosition: \(customPosition)")
    print("  customSize: \(customSize)")
    
    // This is the critical path in WindowPositioner.moveWindow()
    print("\n  🎯 CRITICAL PATH ANALYSIS:")
    print("  if command.position == .precise && customSize != nil {")
    print("    // Use flexible positioning (both position and size)")
    print("    let bounds = CGRect(origin: \(customPosition), size: \(customSize))")
    print("    windowManager.setWindowBounds(window, bounds: bounds)")
    print("  }")
    
    // Simulate the bounds validation
    let bounds = CGRect(origin: customPosition, size: customSize)
    print("\n  📐 BOUNDS VALIDATION:")
    print("    Original bounds: \(bounds)")
    
    // Check if validation might be clipping the size
    let screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    print("    Screen visible bounds: \(screenBounds)")
    
    if bounds.width > screenBounds.width {
        print("    ⚠️  Width (\(bounds.width)) exceeds screen width (\(screenBounds.width))")
    }
    if bounds.height > screenBounds.height {
        print("    ⚠️  Height (\(bounds.height)) exceeds screen height (\(screenBounds.height))")
    }
    
    // Check if position would cause clipping
    if bounds.origin.x + bounds.width > screenBounds.maxX {
        print("    ⚠️  Window would extend beyond right edge")
    }
    if bounds.origin.y + bounds.height > screenBounds.maxY {
        print("    ⚠️  Window would extend beyond bottom edge")
    }
}

// 5. Check for potential bugs in the code path
print("\n5. POTENTIAL ISSUES ANALYSIS:")
print("  🔍 Issue 1: Both position and size should be applied together")
print("  🔍 Issue 2: Check if validation is truncating the size")
print("  🔍 Issue 3: Check if AX API calls are failing silently")
print("  🔍 Issue 4: Check coordinate system conversion issues")

print("\n6. RECOMMENDED DEBUGGING STEPS:")
print("  1. Add debug logging to WindowPositioner.moveWindow()")
print("  2. Add debug logging to WindowManager.setWindowBounds()")
print("  3. Check if both position and size AX calls succeed")
print("  4. Verify that validation isn't clipping the size")
print("  5. Test with validate=false parameter")

// 7. Test the specific case that's failing
print("\n7. TESTING SPECIFIC FAILURE CASE:")
let screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
print("  Screen: \(screenBounds)")
print("  100% width: \(screenBounds.width)")
print("  100% height: \(screenBounds.height)")
print("  Expected terminal bounds: \(CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height))")

print("\nDEBUG COMPLETE ✅")