#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 EXTERNAL DISPLAY DEBUG: Ultra-precise coordinate analysis")
print("🎯 Goal: Create a test that reliably fails and shows exactly what's wrong")
print("")

// Simulate the EXACT scenario the user is experiencing
func testExternalDisplayCoordinateConversion() {
    print("📊 Test: External Display Coordinate Conversion (RELIABLE FAILURE)")
    
    // User's EXACT external display configuration
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Let's test windows at different positions on the external display
    let testWindows = [
        // Window at the VERY TOP of external display
        (name: "Top Window", global: CGRect(x: 2000, y: -540, width: 800, height: 400)),
        
        // Window at the MIDDLE of external display  
        (name: "Middle Window", global: CGRect(x: 2000, y: -270, width: 800, height: 400)),
        
        // Window at the BOTTOM of external display (near main display)
        (name: "Bottom Window", global: CGRect(x: 2000, y: 100, width: 800, height: 400)),
        
        // Window that user specifically mentioned as problematic
        (name: "User's Problem Window", global: CGRect(x: 2800, y: -400, width: 800, height: 600))
    ]
    
    for testWindow in testWindows {
        print("   🔍 Testing: \(testWindow.name)")
        print("     Global window: \(testWindow.global)")
        print("     Display frame: \(externalDisplay)")
        
        // Step 1: Convert to local coordinates
        let localX = testWindow.global.origin.x - externalDisplay.origin.x
        let localY = testWindow.global.origin.y - externalDisplay.origin.y
        print("     Local coords: (\(localX), \(localY))")
        
        // Step 2: Current conversion formula
        let convertedX = localX
        let convertedY = externalDisplay.height - localY - testWindow.global.height
        print("     Converted coords: (\(convertedX), \(convertedY))")
        
        // Step 3: Clamping
        let clampedX = max(0, min(convertedX, externalDisplay.width - testWindow.global.width))
        let clampedY = max(0, min(convertedY, externalDisplay.height - testWindow.global.height))
        print("     Clamped coords: (\(clampedX), \(clampedY))")
        
        // CRITICAL: What SHOULD the overlay coordinates be?
        let expectedOverlayY = calculateExpectedOverlayY(
            globalWindow: testWindow.global,
            display: externalDisplay
        )
        print("     Expected overlay Y: \(expectedOverlayY)")
        
        // Check if conversion matches expectation
        let yDifference = abs(clampedY - expectedOverlayY)
        let isCorrect = yDifference < 10 // Allow 10px tolerance
        
        print("     Y difference: \(yDifference)px")
        print("     Result: \(isCorrect ? "✅ CORRECT" : "❌ WRONG")")
        
        if !isCorrect {
            print("     🚨 FAILURE DETECTED!")
            print("     🔍 Expected: Window should appear at Y=\(expectedOverlayY)")
            print("     🔍 Actual: Window appears at Y=\(clampedY)")
            print("     🔍 This is \(clampedY > expectedOverlayY ? "BELOW" : "ABOVE") where it should be")
        }
        
        print("")
    }
}

// Calculate what the overlay Y coordinate SHOULD be based on visual positioning
func calculateExpectedOverlayY(globalWindow: CGRect, display: CGRect) -> CGFloat {
    print("       🧮 Calculating expected overlay Y...")
    
    // For external display with negative origin, let's think about this:
    // 1. A window at the TOP of the external display (globalY = -540) 
    //    should appear at the TOP of the overlay (overlayY ≈ 1440 - windowHeight)
    // 2. A window at the BOTTOM of the external display (globalY ≈ 900)
    //    should appear at the BOTTOM of the overlay (overlayY ≈ 0)
    
    // Calculate relative position within the display (0.0 = top, 1.0 = bottom)
    let relativeY = (globalWindow.origin.y - display.origin.y) / display.height
    print("       Relative Y position: \(relativeY) (0.0=top, 1.0=bottom)")
    
    // In Cocoa coordinates (bottom-left origin), convert relative position to overlay Y
    // For Cocoa: Y=0 is bottom, Y=displayHeight is top
    // So: overlayY = displayHeight * (1.0 - relativeY) - windowHeight
    let expectedY = display.height * (1.0 - relativeY) - globalWindow.height
    print("       Expected calculation: \(display.height) * (1.0 - \(relativeY)) - \(globalWindow.height) = \(expectedY)")
    
    return expectedY
}

// Test the coordinate conversion step by step to find where it breaks
func testStepByStepDebugging() {
    print("📊 Test: Step-by-Step Debugging")
    
    let display = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let window = CGRect(x: 2000, y: -400, width: 800, height: 600) // User's problem window
    
    print("   Display: \(display)")
    print("   Window: \(window)")
    print("")
    
    // Step 1: Global to local conversion
    print("   Step 1: Global → Local conversion")
    let localX = window.origin.x - display.origin.x
    let localY = window.origin.y - display.origin.y
    print("     localX = \(window.origin.x) - \(display.origin.x) = \(localX)")
    print("     localY = \(window.origin.y) - \(display.origin.y) = \(localY)")
    
    // Verify: localY should be positive and within display bounds
    let localYValid = localY >= 0 && localY <= display.height
    print("     Local Y valid (0 to \(display.height)): \(localYValid ? "✅" : "❌")")
    print("")
    
    // Step 2: Coordinate system conversion
    print("   Step 2: Accessibility → Cocoa coordinate conversion")
    let convertedX = localX
    let convertedY = display.height - localY - window.height
    print("     convertedX = \(localX) (unchanged)")
    print("     convertedY = \(display.height) - \(localY) - \(window.height) = \(convertedY)")
    
    // Verify: convertedY should be positive and within display bounds
    let convertedYValid = convertedY >= 0 && convertedY <= display.height
    print("     Converted Y valid (0 to \(display.height)): \(convertedYValid ? "✅" : "❌")")
    print("")
    
    // Step 3: Clamping
    print("   Step 3: Bounds clamping")
    let clampedX = max(0, min(convertedX, display.width - window.width))
    let clampedY = max(0, min(convertedY, display.height - window.height))
    print("     clampedX = max(0, min(\(convertedX), \(display.width - window.width))) = \(clampedX)")
    print("     clampedY = max(0, min(\(convertedY), \(display.height - window.height))) = \(clampedY)")
    
    let clampingChanged = clampedX != convertedX || clampedY != convertedY
    print("     Clamping changed values: \(clampingChanged ? "⚠️ YES" : "✅ NO")")
    print("")
    
    // Final verification: Where does the window actually appear?
    print("   Final Result Analysis:")
    let percentFromBottom = clampedY / display.height * 100
    let percentFromTop = (display.height - clampedY) / display.height * 100
    print("     Window appears at \(percentFromBottom)% from BOTTOM of overlay")
    print("     Window appears at \(percentFromTop)% from TOP of overlay")
    
    // For this specific window at globalY=-400:
    // - It's at -400 on a display that goes from -540 to 900
    // - That's ((-400) - (-540)) / 1440 = 140/1440 = 9.7% from the top
    // - So it SHOULD appear at ~90% from the bottom of the overlay
    let expectedPercentFromTop = ((window.origin.y - display.origin.y) / display.height) * 100
    print("     Expected: \(expectedPercentFromTop)% from TOP (based on global position)")
    print("     Expected: \(100 - expectedPercentFromTop)% from BOTTOM")
    
    let positioningCorrect = abs(percentFromTop - expectedPercentFromTop) < 5
    print("     Positioning correct: \(positioningCorrect ? "✅" : "❌")")
    
    if !positioningCorrect {
        print("     🚨 POSITIONING ERROR DETECTED!")
        print("     🔍 Expected \(expectedPercentFromTop)% from top, got \(percentFromTop)% from top")
        print("     🔍 Difference: \(abs(percentFromTop - expectedPercentFromTop))%")
    }
}

// Test what happens with different coordinate conversion approaches
func testAlternativeApproaches() {
    print("📊 Test: Alternative Coordinate Conversion Approaches")
    
    let display = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let window = CGRect(x: 2000, y: -400, width: 800, height: 600)
    
    // Current approach
    let localY1 = window.origin.y - display.origin.y
    let converted1 = display.height - localY1 - window.height
    
    // Alternative 1: Don't subtract window height
    let converted2 = display.height - localY1
    
    // Alternative 2: Use absolute positioning
    let converted3 = abs(window.origin.y - display.origin.y)
    
    // Alternative 3: Direct relative positioning
    let relativeY = (window.origin.y - display.origin.y) / display.height
    let converted4 = display.height * (1.0 - relativeY) - window.height
    
    print("   Window: \(window)")
    print("   Display: \(display)")
    print("   Local Y: \(localY1)")
    print("")
    print("   Approach 1 (current): \(display.height) - \(localY1) - \(window.height) = \(converted1)")
    print("   Approach 2 (no height): \(display.height) - \(localY1) = \(converted2)")
    print("   Approach 3 (absolute): abs(\(window.origin.y) - \(display.origin.y)) = \(converted3)")
    print("   Approach 4 (relative): \(display.height) * (1.0 - \(relativeY)) - \(window.height) = \(converted4)")
    print("")
    
    // Which approach gives the most sensible result?
    let approaches = [
        ("Current", converted1),
        ("No Height", converted2),
        ("Absolute", converted3),
        ("Relative", converted4)
    ]
    
    for (name, result) in approaches {
        let percentFromBottom = result / display.height * 100
        let withinBounds = result >= 0 && result <= display.height
        print("   \(name): Y=\(result) (\(percentFromBottom)% from bottom) \(withinBounds ? "✅" : "❌")")
    }
}

// Run all debugging tests
print("🚀 Running External Display Debug Tests")
print("=" + String(repeating: "=", count: 60))
print("")

testExternalDisplayCoordinateConversion()
print("")
testStepByStepDebugging()
print("")
testAlternativeApproaches()

print("")
print("🎯 DEBUG SUMMARY:")
print("   This test suite should reveal exactly where the coordinate conversion fails")
print("   for external displays with negative origins. Look for ❌ WRONG results.")
print("   The test validates both the mathematical correctness and visual positioning.")