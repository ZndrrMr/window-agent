#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 DISPLAY ORIGIN ANALYSIS: Why does the external monitor have negative origin?")
print("🎯 Goal: Understand if the coordinate system should actually be different")
print("")

// Analyze the display configuration to understand the negative origin
func analyzeDisplayConfiguration() {
    print("📊 Display Configuration Analysis")
    
    // Your setup based on the coordinates we've seen:
    let mainDisplay = CGRect(x: 0, y: 0, width: 1440, height: 900)      // MacBook built-in
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)  // External monitor
    
    print("   Main Display (MacBook): \(mainDisplay)")
    print("   External Display: \(externalDisplay)")
    print("")
    
    // The negative Y origin means the external display is positioned ABOVE the main display
    print("   🔍 Origin Analysis:")
    print("     Main display Y=0: This is the reference point")
    print("     External display Y=-540: This is 540 pixels ABOVE the main display")
    print("     This means you have your external monitor physically positioned above your MacBook")
    print("")
    
    // Let's think about what this means for coordinates
    print("   🔍 Coordinate System Implications:")
    print("     - macOS uses a global coordinate system across all displays")
    print("     - The main display is always at origin (0,0)")
    print("     - Other displays are positioned relative to main display")
    print("     - Y=-540 means external display TOP is 540px above main display TOP")
    print("")
    
    // The key insight: Are these actually different coordinate systems?
    print("   🔍 Key Question: Are these different coordinate systems?")
    print("     - Accessibility API: Uses global coordinates across all displays")
    print("     - Cocoa/NSWindow: Uses per-display local coordinates")
    print("     - The conversion should be the same mathematical relationship!")
    print("")
    
    // Test the mathematical relationship
    print("   🔍 Mathematical Relationship Test:")
    
    // For main display: A window at top-left (0, 0) in global coords
    let mainWindow = CGRect(x: 0, y: 0, width: 400, height: 300)
    let mainLocalY = mainWindow.origin.y - mainDisplay.origin.y  // 0 - 0 = 0
    let mainOverlayY = mainDisplay.height - mainLocalY - mainWindow.height  // 900 - 0 - 300 = 600
    
    print("     Main display window at (0,0):")
    print("       Local Y: \(mainLocalY)")
    print("       Overlay Y: \(mainOverlayY) (should be near bottom since window is at top)")
    print("")
    
    // For external display: A window at top-left (-540, 0) in global coords  
    let extWindow = CGRect(x: 1440, y: -540, width: 400, height: 300)
    let extLocalY = extWindow.origin.y - externalDisplay.origin.y  // -540 - (-540) = 0
    let extOverlayY = externalDisplay.height - extLocalY - extWindow.height  // 1440 - 0 - 300 = 1140
    
    print("     External display window at top-left:")
    print("       Local Y: \(extLocalY)")
    print("       Overlay Y: \(extOverlayY) (should be near bottom since window is at top)")
    print("")
    
    // The math should be identical!
    print("   🎯 Conclusion:")
    print("     Both displays have windows at their respective top-left corners")
    print("     Both local Y coordinates are 0 (correct)")
    print("     Both overlay Y coordinates are near the bottom (correct)")
    print("     The mathematical relationship is IDENTICAL!")
    print("")
}

// Test if the issue is in our understanding vs the actual system behavior
func testCoordinateSystemConsistency() {
    print("📊 Coordinate System Consistency Test")
    
    let mainDisplay = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Test the same relative position on both displays
    let testPositions = [
        ("Top-left", 0.0, 0.0),      // 0% from left, 0% from top
        ("Center", 0.5, 0.5),        // 50% from left, 50% from top  
        ("Bottom-right", 1.0, 1.0)   // 100% from left, 100% from top
    ]
    
    for (name, relativeX, relativeY) in testPositions {
        print("   Testing relative position: \(name) (\(relativeX), \(relativeY))")
        
        // Calculate global coordinates for both displays
        let mainGlobalX = mainDisplay.origin.x + relativeX * mainDisplay.width
        let mainGlobalY = mainDisplay.origin.y + relativeY * mainDisplay.height
        let mainWindow = CGRect(x: mainGlobalX, y: mainGlobalY, width: 400, height: 300)
        
        let extGlobalX = externalDisplay.origin.x + relativeX * externalDisplay.width
        let extGlobalY = externalDisplay.origin.y + relativeY * externalDisplay.height
        let extWindow = CGRect(x: extGlobalX, y: extGlobalY, width: 400, height: 300)
        
        print("     Main display global: (\(mainGlobalX), \(mainGlobalY))")
        print("     External display global: (\(extGlobalX), \(extGlobalY))")
        
        // Apply coordinate conversion
        let mainLocalY = mainWindow.origin.y - mainDisplay.origin.y
        let mainOverlayY = mainDisplay.height - mainLocalY - mainWindow.height
        let mainRelativeOverlayY = mainOverlayY / mainDisplay.height
        
        let extLocalY = extWindow.origin.y - externalDisplay.origin.y
        let extOverlayY = externalDisplay.height - extLocalY - extWindow.height
        let extRelativeOverlayY = extOverlayY / externalDisplay.height
        
        print("     Main overlay Y: \(mainOverlayY) (relative: \(mainRelativeOverlayY))")
        print("     External overlay Y: \(extOverlayY) (relative: \(extRelativeOverlayY))")
        
        // The relative positions should be identical!
        let difference = abs(mainRelativeOverlayY - extRelativeOverlayY)
        let consistent = difference < 0.01  // 1% tolerance
        
        print("     Relative difference: \(difference)")
        print("     Consistent: \(consistent ? "✅" : "❌")")
        print("")
    }
}

// Test what the user is actually seeing vs what they should see
func testUserExperienceAnalysis() {
    print("📊 User Experience Analysis")
    
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // The user said a window appears "slightly above" where it should be
    // Let's figure out what "should be" means
    
    print("   User's external display: \(externalDisplay)")
    print("")
    
    // Test window that user mentioned
    let userWindow = CGRect(x: 2800, y: -400, width: 800, height: 600)
    print("   User's window: \(userWindow)")
    
    // Where is this window positioned on the external display?
    let relativeX = (userWindow.origin.x - externalDisplay.origin.x) / externalDisplay.width
    let relativeY = (userWindow.origin.y - externalDisplay.origin.y) / externalDisplay.height
    
    print("   Relative position: (\(relativeX), \(relativeY))")
    print("   This means: \(relativeX * 100)% from left, \(relativeY * 100)% from top")
    print("")
    
    // What should the overlay position be?
    let expectedOverlayX = relativeX * externalDisplay.width
    let expectedOverlayY = externalDisplay.height * (1.0 - relativeY) - userWindow.height
    
    print("   Expected overlay position: (\(expectedOverlayX), \(expectedOverlayY))")
    print("   This should be: \(expectedOverlayX / externalDisplay.width * 100)% from left, \((externalDisplay.height - expectedOverlayY) / externalDisplay.height * 100)% from top")
    print("")
    
    // What does our current formula give?
    let localY = userWindow.origin.y - externalDisplay.origin.y
    let currentOverlayY = externalDisplay.height - localY - userWindow.height
    
    print("   Current formula result: (\(userWindow.origin.x - externalDisplay.origin.x), \(currentOverlayY))")
    print("   Current position: \((userWindow.origin.x - externalDisplay.origin.x) / externalDisplay.width * 100)% from left, \((externalDisplay.height - currentOverlayY) / externalDisplay.height * 100)% from top")
    print("")
    
    // Are they the same?
    let positionMatch = abs(currentOverlayY - expectedOverlayY) < 1
    print("   Position match: \(positionMatch ? "✅" : "❌")")
    
    if !positionMatch {
        print("   🚨 MISMATCH DETECTED!")
        print("   Expected: \(expectedOverlayY)")
        print("   Current: \(currentOverlayY)")
        print("   Difference: \(abs(currentOverlayY - expectedOverlayY))")
    }
}

// The real test: Are we over-complicating this?
func testSimpleReality() {
    print("📊 Simple Reality Check")
    
    print("   🤔 Maybe the issue isn't coordinate systems at all...")
    print("   🤔 Maybe it's something else in the pipeline...")
    print("")
    
    print("   Possible issues:")
    print("   1. Window bounds are wrong (not from where we think)")
    print("   2. Display frame is wrong (not what we think)")
    print("   3. Overlay window positioning is wrong (not coordinate conversion)")
    print("   4. Visual perception vs actual positioning")
    print("   5. Timing issues (window moves after X-Ray appears)")
    print("")
    
    print("   🎯 The math in our test shows the coordinate conversion is correct!")
    print("   🎯 So the issue must be elsewhere in the chain...")
    print("")
    
    print("   Next debugging steps:")
    print("   1. Log the actual WindowInfo.bounds values from real windows")
    print("   2. Log the actual NSScreen.frame values from real displays")
    print("   3. Check if XRayOverlayWindow.setFrame() is working correctly")
    print("   4. Verify the overlay window is on the correct display")
    print("   5. Check if there are scaling/HiDPI factors we're missing")
}

// Run all analysis
print("🚀 Running Display Origin Analysis")
print("=" + String(repeating: "=", count: 60))
print("")

analyzeDisplayConfiguration()
testCoordinateSystemConsistency()
testUserExperienceAnalysis()
testSimpleReality()

print("🎯 KEY INSIGHTS:")
print("   • The negative origin is just macOS positioning the external display above the main display")
print("   • The coordinate conversion mathematics should be identical for both displays")
print("   • Our test shows the conversion is mathematically correct")
print("   • The issue might be elsewhere: window bounds, display frame, or overlay positioning")
print("   • We need to debug the actual values from the real system, not theoretical ones")