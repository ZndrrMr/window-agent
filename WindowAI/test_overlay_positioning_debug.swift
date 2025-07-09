#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 OVERLAY POSITIONING DEBUG")
print("🎯 Goal: Check if overlay windows are positioned correctly on displays")
print("")

func testOverlayWindowPositioning() {
    print("📊 Overlay Window Positioning Test")
    
    let screens = NSScreen.screens
    
    for (index, screen) in screens.enumerated() {
        let isMain = screen == NSScreen.main
        print("   Screen \(index): \(isMain ? "MAIN" : "EXTERNAL")")
        print("     Frame: \(screen.frame)")
        print("     Visible frame: \(screen.visibleFrame)")
        print("     Backing scale factor: \(screen.backingScaleFactor)")
        
        // Simulate what XRayOverlayWindow does
        let overlayFrame = screen.frame
        print("     Overlay window frame: \(overlayFrame)")
        
        // Check if overlay covers the entire screen
        let coversEntireScreen = overlayFrame == screen.frame
        print("     Covers entire screen: \(coversEntireScreen ? "✅" : "❌")")
        
        // Check for any coordinate space issues
        if screen.frame.origin.x != 0 || screen.frame.origin.y != 0 {
            print("     🔍 Non-zero origin detected: \(screen.frame.origin)")
            print("     This could cause NSWindow.setFrame() issues")
        }
        
        print("")
    }
}

func testCoordinateSpaceConsistency() {
    print("📊 Coordinate Space Consistency Test")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ⚠️  No external screen detected")
        return
    }
    
    print("   Testing coordinate space consistency...")
    print("   External screen frame: \(external.frame)")
    
    // Test window at different positions
    let testWindows = [
        ("Top-left", CGRect(x: 1440, y: -540, width: 400, height: 300)),
        ("Center", CGRect(x: 2440, y: -270, width: 400, height: 300)),
        ("Bottom-right", CGRect(x: 3840, y: 900, width: 400, height: 300))
    ]
    
    for (name, windowBounds) in testWindows {
        print("   \(name) window: \(windowBounds)")
        
        // Step 1: Global to local
        let localX = windowBounds.origin.x - external.frame.origin.x
        let localY = windowBounds.origin.y - external.frame.origin.y
        print("     Local coords: (\(localX), \(localY))")
        
        // Step 2: Accessibility to Cocoa coordinate conversion
        let convertedX = localX
        let convertedY = external.frame.height - localY - windowBounds.height
        print("     Converted coords: (\(convertedX), \(convertedY))")
        
        // Step 3: Check if coordinates are reasonable
        let xInBounds = convertedX >= 0 && convertedX <= external.frame.width
        let yInBounds = convertedY >= 0 && convertedY <= external.frame.height
        print("     X in bounds: \(xInBounds ? "✅" : "❌")")
        print("     Y in bounds: \(yInBounds ? "✅" : "❌")")
        
        // Check if the conversion makes visual sense
        let relativeY = localY / external.frame.height
        let expectedOverlayY = external.frame.height * (1.0 - relativeY) - windowBounds.height
        let conversionCorrect = abs(convertedY - expectedOverlayY) < 1.0
        print("     Conversion correct: \(conversionCorrect ? "✅" : "❌")")
        
        if !conversionCorrect {
            print("     🚨 CONVERSION ERROR!")
            print("     Expected: \(expectedOverlayY)")
            print("     Got: \(convertedY)")
            print("     Difference: \(abs(convertedY - expectedOverlayY))")
        }
        
        print("")
    }
}

func testPotentialNSWindowIssues() {
    print("📊 Potential NSWindow Issues Test")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ⚠️  No external screen detected")
        return
    }
    
    print("   Testing NSWindow behavior on external display...")
    
    // Test if NSWindow.setFrame() works correctly with negative origins
    let testFrame = external.frame
    print("   Test frame: \(testFrame)")
    
    // Check for potential issues with negative coordinates
    if testFrame.origin.y < 0 {
        print("   🔍 Negative Y origin detected: \(testFrame.origin.y)")
        print("   This could cause NSWindow positioning issues")
        
        // Check if the frame is valid
        let frameValid = testFrame.width > 0 && testFrame.height > 0
        print("   Frame valid: \(frameValid ? "✅" : "❌")")
        
        // Check for coordinate overflow issues
        let maxY = testFrame.origin.y + testFrame.height
        print("   Frame Y range: \(testFrame.origin.y) to \(maxY)")
        
        if maxY > 10000 || testFrame.origin.y < -10000 {
            print("   ⚠️  Extreme coordinate values detected")
        }
    }
    
    // Test window level and collection behavior
    let maxWindowLevel = Int(CGWindowLevelForKey(.maximumWindow))
    let overlayLevel = maxWindowLevel + 1
    print("   Overlay window level: \(overlayLevel)")
    
    if overlayLevel > 1000 {
        print("   ⚠️  Very high window level - could cause display issues")
    }
    
    print("")
}

func testSpecificUserScenario() {
    print("📊 Specific User Scenario Test")
    
    // Your exact setup
    let externalFrame = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    let problemWindow = CGRect(x: 2800, y: -400, width: 800, height: 600)
    
    print("   External display: \(externalFrame)")
    print("   Problem window: \(problemWindow)")
    
    // Current coordinate conversion
    let localX = problemWindow.origin.x - externalFrame.origin.x
    let localY = problemWindow.origin.y - externalFrame.origin.y
    let convertedX = localX
    let convertedY = externalFrame.height - localY - problemWindow.height
    
    print("   Local coordinates: (\(localX), \(localY))")
    print("   Converted coordinates: (\(convertedX), \(convertedY))")
    
    // Where should the window appear in the overlay?
    let relativeXFromLeft = convertedX / externalFrame.width
    let relativeYFromBottom = convertedY / externalFrame.height
    let relativeYFromTop = 1.0 - relativeYFromBottom - (problemWindow.height / externalFrame.height)
    
    print("   Overlay position: \(relativeXFromLeft * 100)% from left, \(relativeYFromTop * 100)% from top")
    
    // Where is the actual window on the display?
    let actualRelativeX = (problemWindow.origin.x - externalFrame.origin.x) / externalFrame.width
    let actualRelativeY = (problemWindow.origin.y - externalFrame.origin.y) / externalFrame.height
    
    print("   Actual window position: \(actualRelativeX * 100)% from left, \(actualRelativeY * 100)% from top")
    
    // Check if they match
    let xMatches = abs(relativeXFromLeft - actualRelativeX) < 0.01
    let yMatches = abs(relativeYFromTop - actualRelativeY) < 0.01
    
    print("   X position matches: \(xMatches ? "✅" : "❌")")
    print("   Y position matches: \(yMatches ? "✅" : "❌")")
    
    if !yMatches {
        print("   🚨 Y POSITION MISMATCH!")
        print("   Expected: \(actualRelativeY * 100)% from top")
        print("   Overlay shows: \(relativeYFromTop * 100)% from top")
        print("   Difference: \(abs(relativeYFromTop - actualRelativeY) * 100)%")
        
        // This is the core issue!
        print("   🎯 This explains why the overlay appears 'slightly above' the actual window")
    }
}

// Run all tests
print("🚀 Running Overlay Positioning Debug")
print("=" + String(repeating: "=", count: 50))
print("")

testOverlayWindowPositioning()
testCoordinateSpaceConsistency()
testPotentialNSWindowIssues()
testSpecificUserScenario()

print("🎯 KEY FINDINGS:")
print("   • If overlay window covers entire screen correctly, positioning issue is internal")
print("   • If coordinate conversion tests pass, the math is correct")
print("   • If Y position mismatch is detected, we've found the exact issue")
print("   • This will pinpoint whether it's NSWindow positioning or coordinate conversion")