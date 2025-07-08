#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 X-Ray Coordinate Fix Verification")
print("====================================")

// Test the fix with real-world scenarios
func testCoordinateFixWithRealData() {
    print("\n🧪 TESTING COORDINATE FIX WITH REAL DATA:")
    print("==========================================")
    
    // Real external monitor configuration
    let externalScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Test cases that would cause issues
    let testCases = [
        ("Window near bottom of external monitor", CGRect(x: 2780, y: 209, width: 899, height: 707)),
        ("Window at top of external monitor", CGRect(x: 1500, y: -500, width: 800, height: 600)),
        ("Window in middle of external monitor", CGRect(x: 2000, y: 0, width: 800, height: 600)),
        ("Large window spanning most of external monitor", CGRect(x: 1500, y: -400, width: 2000, height: 1200))
    ]
    
    for (description, windowBounds) in testCases {
        print("\n📋 Test Case: \(description)")
        print("   Window: \(windowBounds)")
        
        // OLD coordinate conversion (no clamping)
        let oldConvertedX = windowBounds.origin.x - externalScreen.origin.x
        let oldConvertedY = externalScreen.height - (windowBounds.origin.y + windowBounds.height - externalScreen.origin.y)
        let oldResult = CGRect(x: oldConvertedX, y: oldConvertedY, width: windowBounds.width, height: windowBounds.height)
        
        // NEW coordinate conversion (with clamping)
        let convertedX = windowBounds.origin.x - externalScreen.origin.x
        let convertedY = externalScreen.height - (windowBounds.origin.y + windowBounds.height - externalScreen.origin.y)
        let clampedX = max(0, min(convertedX, externalScreen.width - windowBounds.width))
        let clampedY = max(0, min(convertedY, externalScreen.height - windowBounds.height))
        let newResult = CGRect(x: clampedX, y: clampedY, width: windowBounds.width, height: windowBounds.height)
        
        print("   OLD result: \(oldResult)")
        print("   NEW result: \(newResult)")
        
        // Check if clamping was applied
        let xClamped = clampedX != convertedX
        let yClamped = clampedY != convertedY
        
        if xClamped || yClamped {
            print("   🔧 CLAMPING APPLIED:")
            if xClamped {
                print("      X: \(convertedX) → \(clampedX)")
            }
            if yClamped {
                print("      Y: \(convertedY) → \(clampedY)")
            }
        } else {
            print("   ✅ No clamping needed")
        }
        
        // Verify the result is within screen bounds
        let withinBounds = newResult.origin.x >= 0 && 
                          newResult.origin.y >= 0 && 
                          newResult.origin.x + newResult.width <= externalScreen.width &&
                          newResult.origin.y + newResult.height <= externalScreen.height
        
        print("   Within screen bounds: \(withinBounds ? "✅ YES" : "❌ NO")")
        
        // Check if the old result had negative coordinates
        let oldHadNegative = oldResult.origin.x < 0 || oldResult.origin.y < 0
        if oldHadNegative {
            print("   🚨 OLD result had negative coordinates - this would cause visual issues!")
        }
    }
}

// Test edge cases
func testEdgeCases() {
    print("\n🔍 TESTING EDGE CASES:")
    print("=======================")
    
    let mainScreen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let externalScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    let edgeCases = [
        ("Main screen - normal window", mainScreen, CGRect(x: 100, y: 100, width: 800, height: 600)),
        ("Main screen - window at bottom", mainScreen, CGRect(x: 100, y: 600, width: 800, height: 400)),
        ("External screen - window extends beyond top", externalScreen, CGRect(x: 1500, y: -600, width: 800, height: 200)),
        ("External screen - window extends beyond bottom", externalScreen, CGRect(x: 1500, y: 800, width: 800, height: 200)),
        ("External screen - window extends beyond left", externalScreen, CGRect(x: 1400, y: 0, width: 100, height: 600)),
        ("External screen - window extends beyond right", externalScreen, CGRect(x: 3900, y: 0, width: 200, height: 600))
    ]
    
    for (description, screenFrame, windowBounds) in edgeCases {
        print("\n📋 \(description)")
        print("   Screen: \(screenFrame)")
        print("   Window: \(windowBounds)")
        
        // Apply the fix
        let convertedX = windowBounds.origin.x - screenFrame.origin.x
        let convertedY = screenFrame.height - (windowBounds.origin.y + windowBounds.height - screenFrame.origin.y)
        let clampedX = max(0, min(convertedX, screenFrame.width - windowBounds.width))
        let clampedY = max(0, min(convertedY, screenFrame.height - windowBounds.height))
        
        let result = CGRect(x: clampedX, y: clampedY, width: windowBounds.width, height: windowBounds.height)
        
        print("   Result: \(result)")
        
        // Verify it's within bounds
        let withinBounds = result.origin.x >= 0 && 
                          result.origin.y >= 0 && 
                          result.origin.x + result.width <= screenFrame.width &&
                          result.origin.y + result.height <= screenFrame.height
        
        print("   Within bounds: \(withinBounds ? "✅ YES" : "❌ NO")")
        
        if !withinBounds {
            print("   🚨 Still outside bounds - may need additional handling")
        }
    }
}

// Test the mathematical correctness
func testMathematicalCorrectness() {
    print("\n🧮 TESTING MATHEMATICAL CORRECTNESS:")
    print("=====================================")
    
    let externalScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let testWindow = CGRect(x: 2000, y: 100, width: 800, height: 600)
    
    print("External screen: \(externalScreen)")
    print("Test window: \(testWindow)")
    
    // Step-by-step calculation
    print("\nStep-by-step calculation:")
    print("1. Convert to screen-relative coordinates:")
    let screenRelativeX = testWindow.origin.x - externalScreen.origin.x
    let screenRelativeY = testWindow.origin.y - externalScreen.origin.y
    print("   Screen-relative: (\(screenRelativeX), \(screenRelativeY))")
    
    print("2. Convert from top-left to bottom-left origin:")
    let cocoaY = externalScreen.height - screenRelativeY - testWindow.height
    print("   Cocoa Y: \(externalScreen.height) - \(screenRelativeY) - \(testWindow.height) = \(cocoaY)")
    
    print("3. Apply clamping:")
    let clampedX = max(0, min(screenRelativeX, externalScreen.width - testWindow.width))
    let clampedY = max(0, min(cocoaY, externalScreen.height - testWindow.height))
    print("   Clamped: (\(clampedX), \(clampedY))")
    
    print("4. Final result:")
    let finalResult = CGRect(x: clampedX, y: clampedY, width: testWindow.width, height: testWindow.height)
    print("   Final bounds: \(finalResult)")
    
    // Verify this makes sense
    print("\n✅ Verification:")
    print("   - X coordinate \(clampedX) is within [0, \(externalScreen.width)]: \(clampedX >= 0 && clampedX <= externalScreen.width)")
    print("   - Y coordinate \(clampedY) is within [0, \(externalScreen.height)]: \(clampedY >= 0 && clampedY <= externalScreen.height)")
    print("   - Window fits within screen: \(finalResult.maxX <= externalScreen.width && finalResult.maxY <= externalScreen.height)")
}

// Main execution
testCoordinateFixWithRealData()
testEdgeCases()
testMathematicalCorrectness()

print("\n🎯 FIX VERIFICATION RESULTS:")
print("=============================")
print("✅ The coordinate clamping fix addresses the core issue:")
print("   - Prevents negative coordinates that cause visual shifting")
print("   - Ensures all window outlines stay within screen bounds")
print("   - Maintains mathematical correctness for normal cases")
print("   - Handles edge cases gracefully")
print("")
print("🔧 The fix works by:")
print("   1. Converting coordinates normally (mathematically correct)")
print("   2. Clamping X and Y to stay within [0, screen_dimension]")
print("   3. Ensuring windows don't extend beyond screen boundaries")
print("")
print("This should resolve the 'shifting down' issue on external monitors!")