#!/usr/bin/env swift

import Foundation
import Cocoa

/**
 * DEBUG SCRIPT - Test setWindowBounds behavior
 * This simulates what happens when Terminal gets full screen bounds
 */

print("🔍 DEBUG: setWindowBounds Behavior Analysis")
print("🎯 Goal: Understand why size portion fails for Terminal")
print("")

// Test the bounds calculations that should be used
func testBoundsCalculations() {
    print("📊 TEST: Bounds Calculations")
    
    guard let mainScreen = NSScreen.main else {
        print("❌ FAIL: Cannot get main screen")
        return
    }
    
    let visibleFrame = mainScreen.visibleFrame
    
    // These are the bounds that should be passed to setWindowBounds for full screen
    let fullScreenBounds = CGRect(
        x: 0,
        y: 0, 
        width: visibleFrame.width,
        height: visibleFrame.height
    )
    
    print("   Visible frame: \(visibleFrame)")
    print("   Full screen bounds: \(fullScreenBounds)")
    print("")
    
    // Test position and size components
    let position = fullScreenBounds.origin
    let size = fullScreenBounds.size
    
    print("   Position component: \(position)")
    print("   Size component: \(size)")
    print("")
    
    // Test that both are valid
    let positionValid = position.x >= 0 && position.y >= 0
    let sizeValid = size.width > 0 && size.height > 0
    let boundsValid = !fullScreenBounds.isEmpty
    
    print("   Position valid: \(positionValid)")
    print("   Size valid: \(sizeValid)")
    print("   Bounds valid: \(boundsValid)")
    print("")
    
    if positionValid && sizeValid && boundsValid {
        print("   ✅ All bounds components are valid")
        print("   Issue must be in AX API calls or validation")
    } else {
        print("   ❌ Invalid bounds detected")
    }
    print("")
}

// Test what the debug logging should show
func testExpectedDebugOutput() {
    print("📊 TEST: Expected Debug Output")
    
    guard let mainScreen = NSScreen.main else {
        print("❌ FAIL: Cannot get main screen")
        return
    }
    
    let visibleFrame = mainScreen.visibleFrame
    let fullScreenBounds = CGRect(x: 0, y: 0, width: visibleFrame.width, height: visibleFrame.height)
    
    print("   When setWindowBounds is called, debug should show:")
    print("   🔍 setWindowBounds DEBUG:")
    print("      App: Terminal")
    print("      Input bounds: \(fullScreenBounds)")
    print("      Validate: true")
    print("      Final bounds: \(fullScreenBounds)")
    print("      Bounds changed by validation: false")
    print("      Position result: SUCCESS")
    print("      Size result: SUCCESS  ← THIS SHOULD SUCCEED")
    print("      Overall success: true")
    print("")
    
    print("   If Size result shows FAILED, that's where the issue is!")
    print("")
}

// Test bounds validation impact
func testBoundsValidation() {
    print("📊 TEST: Bounds Validation Impact")
    
    guard let mainScreen = NSScreen.main else {
        print("❌ FAIL: Cannot get main screen")
        return
    }
    
    let visibleFrame = mainScreen.visibleFrame
    let fullScreenBounds = CGRect(x: 0, y: 0, width: visibleFrame.width, height: visibleFrame.height)
    
    print("   Original bounds: \(fullScreenBounds)")
    print("   If validation clips bounds, that could cause size issues")
    print("")
    
    // Check if bounds are within screen
    let withinScreen = fullScreenBounds.maxX <= visibleFrame.maxX && 
                      fullScreenBounds.maxY <= visibleFrame.maxY
    
    print("   Bounds within screen: \(withinScreen)")
    
    if withinScreen {
        print("   ✅ Bounds should pass validation unchanged")
        print("   If validation changes them, that's the bug")
    } else {
        print("   ❌ Bounds exceed screen, validation will clip them")
    }
    print("")
}

// Run all tests
print("🎯 Running setWindowBounds Debug Analysis...")
print("===========================================")

testBoundsCalculations()
testExpectedDebugOutput()
testBoundsValidation()

print("🎯 DEBUG ANALYSIS COMPLETE")
print("Next: Run the app with Terminal and check debug output")
print("Look for 'Size result: FAILED' in the logs")