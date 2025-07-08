#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 X-Ray Negative Coordinate Issue Analysis")
print("==========================================")

// Test how NSView handles negative coordinates
func testNSViewNegativeCoordinates() {
    print("\n🖥️ TESTING NSView BEHAVIOR WITH NEGATIVE COORDINATES:")
    print("======================================================")
    
    // Simulate the external monitor scenario
    let externalScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let testWindow = CGRect(x: 2780, y: 209, width: 899, height: 707)
    
    print("External screen: \(externalScreen)")
    print("Test window: \(testWindow)")
    
    // Current conversion logic
    let convertedBounds = CGRect(
        x: testWindow.origin.x - externalScreen.origin.x,
        y: externalScreen.height - (testWindow.origin.y + testWindow.height - externalScreen.origin.y),
        width: testWindow.width,
        height: testWindow.height
    )
    
    print("Converted bounds: \(convertedBounds)")
    
    // The issue: Y coordinate is -16.0 (negative!)
    if convertedBounds.origin.y < 0 {
        print("🚨 PROBLEM IDENTIFIED: Y coordinate is negative (\(convertedBounds.origin.y))")
        print("   This causes the view to be positioned outside the visible area!")
        print("   NSView clips negative coordinates, so the view appears 'shifted down'")
        print("   because it's actually positioned above the visible area.")
    }
    
    // Let's check what the correct Y should be
    // The window is at y=209 in global coordinates
    // The external screen starts at y=-540 in global coordinates
    // So relative to the screen, the window should be at y=209-(-540) = 749
    
    let expectedScreenRelativeY = testWindow.origin.y - externalScreen.origin.y
    print("Expected screen-relative Y: \(expectedScreenRelativeY)")
    
    // For Cocoa coordinates (bottom-left origin), we need to flip it
    let expectedCocoaY = externalScreen.height - expectedScreenRelativeY - testWindow.height
    print("Expected Cocoa Y: \(expectedCocoaY)")
    
    // Compare with our calculation
    print("Our calculation: \(convertedBounds.origin.y)")
    print("Difference: \(expectedCocoaY - convertedBounds.origin.y)")
}

// Test the actual coordinate system understanding
func testCoordinateSystemUnderstanding() {
    print("\n🧠 COORDINATE SYSTEM UNDERSTANDING:")
    print("====================================")
    
    print("macOS has two coordinate systems:")
    print("1. GLOBAL (Accessibility): Top-left origin, Y increases downward")
    print("2. COCOA (NSView): Bottom-left origin, Y increases upward")
    print("")
    
    print("External monitor example:")
    print("- Global frame: (1440, -540, 2560, 1440)")
    print("- This means the monitor is positioned 1440 pixels right, 540 pixels UP from main display")
    print("- The TOP of the external monitor is at global Y = -540")
    print("- The BOTTOM of the external monitor is at global Y = -540 + 1440 = 900")
    print("")
    
    print("Window example:")
    print("- Window at global (2780, 209) means:")
    print("  - 2780 pixels from left edge of coordinate system")
    print("  - 209 pixels from top edge of coordinate system")
    print("- Since external monitor top is at Y=-540, window is at 209-(-540) = 749 pixels from monitor top")
    print("- For Cocoa coordinates, we need 1440 - 749 - 707 = -16 pixels from bottom")
    print("- NEGATIVE Y = window is above the visible area!")
}

// Test the correct fix
func testCorrectFix() {
    print("\n🛠️ TESTING CORRECT FIX:")
    print("=========================")
    
    let externalScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let testWindow = CGRect(x: 2780, y: 209, width: 899, height: 707)
    
    print("External screen: \(externalScreen)")
    print("Test window: \(testWindow)")
    
    // The issue is that we need to handle negative coordinates differently
    // Option 1: Clamp negative coordinates to 0
    let clampedConversion = CGRect(
        x: testWindow.origin.x - externalScreen.origin.x,
        y: max(0, externalScreen.height - (testWindow.origin.y + testWindow.height - externalScreen.origin.y)),
        width: testWindow.width,
        height: testWindow.height
    )
    
    print("Clamped conversion: \(clampedConversion)")
    
    // Option 2: Adjust the conversion to account for the global coordinate system properly
    // Actually, let's think about this differently...
    
    // The window is at global Y=209
    // The external screen spans from Y=-540 to Y=900 in global coordinates
    // So the window IS within the screen bounds (209 is between -540 and 900)
    
    // The issue is in our coordinate conversion!
    // We should convert like this:
    // 1. Get window position relative to screen top-left
    let windowRelativeToScreenTopLeft = CGPoint(
        x: testWindow.origin.x - externalScreen.origin.x,
        y: testWindow.origin.y - externalScreen.origin.y  // This handles negative screen origin
    )
    
    // 2. Convert from top-left origin to bottom-left origin
    let cocoaY = externalScreen.height - windowRelativeToScreenTopLeft.y - testWindow.height
    
    let correctedConversion = CGRect(
        x: windowRelativeToScreenTopLeft.x,
        y: cocoaY,
        width: testWindow.width,
        height: testWindow.height
    )
    
    print("Window relative to screen top-left: \(windowRelativeToScreenTopLeft)")
    print("Corrected conversion: \(correctedConversion)")
    
    // This should give us the same result as our current formula, which means the issue is NOT in the conversion
    // The issue might be that the window is legitimately positioned near the bottom of the external monitor
    // and the conversion is correct, but the user is seeing a visual shift for a different reason
}

// Main execution
testNSViewNegativeCoordinates()
testCoordinateSystemUnderstanding()
testCorrectFix()

print("\n🎯 CONCLUSION:")
print("===============")
print("The coordinate conversion math is CORRECT.")
print("The 'shifting down' issue is likely because:")
print("1. Windows near the bottom of external monitor get negative Cocoa Y coordinates")
print("2. This is mathematically correct given the coordinate system conversion")
print("3. The user's perception of 'shifting down' might be due to:")
print("   - Windows being clipped at the bottom of the screen")
print("   - Visual artifacts from negative coordinates")
print("   - Different window positioning on the external monitor")
print("")
print("The real fix might be to:")
print("1. Ensure the X-Ray overlay window bounds are properly set for each display")
print("2. Handle edge cases where converted coordinates are near screen bounds")
print("3. Investigate if the issue is in window filtering rather than coordinate conversion")