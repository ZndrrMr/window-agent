#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 Debug X-Ray Coordinate Issues")
print("🎯 Let's figure out why windows are shifted to bottom of external monitor")
print("")

// Let's debug what's actually happening with real system data
func debugRealSystemCoordinates() {
    print("📊 Debug: Real System Coordinate Analysis")
    
    let screens = NSScreen.screens
    print("   Connected screens: \(screens.count)")
    
    for (index, screen) in screens.enumerated() {
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        let isMain = screen == NSScreen.main
        
        print("   Screen \(index): \(isMain ? "MAIN" : "EXTERNAL")")
        print("     frame: \(frame)")
        print("     visibleFrame: \(visibleFrame)")
        print("     backingScaleFactor: \(screen.backingScaleFactor)")
        
        let deviceDescription = screen.deviceDescription
        if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            print("     screenNumber: \(screenNumber)")
        }
        print("")
    }
}

// Test coordinate conversion with suspected issues
func testCoordinateConversionIssues() {
    print("📊 Debug: Coordinate Conversion Issues")
    
    // Simulate your external monitor setup based on the screenshot
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Simulate Terminal window position (upper area of external monitor)
    let terminalWindow = CGRect(x: 2800, y: -400, width: 800, height: 600)
    
    print("   External Display: \(externalDisplay)")
    print("   Terminal Window (upper area): \(terminalWindow)")
    print("")
    
    // Test different coordinate conversion approaches
    
    // Approach 1: Current implementation
    print("   🧪 Approach 1: Current Implementation")
    let localX1 = terminalWindow.origin.x - externalDisplay.origin.x
    let localY1 = terminalWindow.origin.y - externalDisplay.origin.y
    let convertedY1 = externalDisplay.height - localY1 - terminalWindow.height
    print("     localY = \(terminalWindow.origin.y) - (\(externalDisplay.origin.y)) = \(localY1)")
    print("     convertedY = \(externalDisplay.height) - \(localY1) - \(terminalWindow.height) = \(convertedY1)")
    print("     Result: (\(localX1), \(convertedY1)) - Window appears at \(convertedY1/externalDisplay.height * 100)% from bottom")
    print("")
    
    // Approach 2: Don't subtract window height
    print("   🧪 Approach 2: Don't Subtract Window Height")
    let localY2 = terminalWindow.origin.y - externalDisplay.origin.y
    let convertedY2 = externalDisplay.height - localY2
    print("     localY = \(terminalWindow.origin.y) - (\(externalDisplay.origin.y)) = \(localY2)")
    print("     convertedY = \(externalDisplay.height) - \(localY2) = \(convertedY2)")
    print("     Result: (\(localX1), \(convertedY2)) - Window appears at \(convertedY2/externalDisplay.height * 100)% from bottom")
    print("")
    
    // Approach 3: Use visibleFrame instead of frame
    print("   🧪 Approach 3: Account for Menu Bar/Dock (visibleFrame)")
    let visibleDisplay = CGRect(x: 1440, y: -540 + 25, width: 2560, height: 1440 - 50) // Approximate visible area
    let localY3 = terminalWindow.origin.y - visibleDisplay.origin.y
    let convertedY3 = visibleDisplay.height - localY3 - terminalWindow.height
    print("     visibleDisplay: \(visibleDisplay)")
    print("     localY = \(terminalWindow.origin.y) - (\(visibleDisplay.origin.y)) = \(localY3)")
    print("     convertedY = \(visibleDisplay.height) - \(localY3) - \(terminalWindow.height) = \(convertedY3)")
    print("     Result: (\(localX1), \(convertedY3)) - Window appears at \(convertedY3/visibleDisplay.height * 100)% from bottom")
    print("")
    
    // Approach 4: Simple relative positioning
    print("   🧪 Approach 4: Simple Relative Positioning")
    let relativeX = terminalWindow.origin.x - externalDisplay.origin.x
    let relativeY = terminalWindow.origin.y - externalDisplay.origin.y
    print("     Simply use relative position without coordinate system conversion")
    print("     Result: (\(relativeX), \(relativeY)) - Preserves original relative position")
    print("")
}

// Analyze what the user expects vs what they're getting
func analyzeUserIssue() {
    print("📊 Debug: User Issue Analysis")
    
    print("   🎯 What User Sees:")
    print("     - Terminal window in UPPER area of external monitor")
    print("     - X-Ray shows Terminal outline at BOTTOM of external monitor")
    print("     - This indicates Y coordinate is being flipped incorrectly")
    print("")
    
    print("   🤔 Possible Root Causes:")
    print("     1. Wrong frame reference (frame vs visibleFrame)")
    print("     2. Incorrect coordinate system conversion")
    print("     3. Window bounds in wrong coordinate system")
    print("     4. Display scaling/DPI issues")
    print("     5. External monitor coordinate mapping issues")
    print("")
    
    print("   🔍 Key Questions:")
    print("     - Are we getting window bounds in Accessibility coordinates?")
    print("     - Are we using the correct display frame?")
    print("     - Is the coordinate system conversion formula correct?")
    print("     - Are there scaling factors we're missing?")
    print("")
}

// Test what happens with a known good position
func testKnownGoodPosition() {
    print("📊 Debug: Test Known Good Position")
    
    let display = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Test a window that SHOULD appear at the top of the overlay
    let topWindow = CGRect(x: 2000, y: -520, width: 400, height: 200) // Near top of external display
    
    print("   Display: \(display)")
    print("   Window near top: \(topWindow)")
    print("")
    
    // Current conversion
    let localY = topWindow.origin.y - display.origin.y
    let convertedY = display.height - localY - topWindow.height
    
    print("   Current conversion:")
    print("     localY = \(topWindow.origin.y) - (\(display.origin.y)) = \(localY)")
    print("     convertedY = \(display.height) - \(localY) - \(topWindow.height) = \(convertedY)")
    print("     Expected: Window should appear near TOP of overlay (Y ≈ 1200-1400)")
    print("     Actual: Window appears at Y = \(convertedY) (\((1440-convertedY)/1440*100)% from top)")
    print("")
    
    if convertedY < 200 {
        print("   🚨 PROBLEM: Window that should be at TOP appears at BOTTOM!")
        print("   This confirms the coordinate conversion is inverted.")
    } else if convertedY > 1200 {
        print("   ✅ GOOD: Window appears near top as expected.")
    } else {
        print("   ⚠️ UNCLEAR: Window appears in middle area.")
    }
    print("")
}

// Suggest debugging steps for the actual implementation
func suggestDebuggingSteps() {
    print("📊 Debug: Suggested Debugging Steps")
    
    print("   🔧 Step 1: Add Coordinate Logging")
    print("     Add detailed logging to XRayOverlayWindow.swift:")
    print("     print(\"🔍 Window: \\(windowInfo.appName) at \\(windowInfo.bounds)\")")
    print("     print(\"🔍 Display: \\(screenFrame)\")")
    print("     print(\"🔍 Local: (\\(localX), \\(localY))\")")
    print("     print(\"🔍 Converted: (\\(convertedX), \\(convertedY))\")")
    print("     print(\"🔍 Final: (\\(clampedX), \\(clampedY))\")")
    print("")
    
    print("   🔧 Step 2: Test Frame vs VisibleFrame")
    print("     Try using targetScreen.visibleFrame instead of targetScreen.frame")
    print("")
    
    print("   🔧 Step 3: Test Without Height Subtraction")
    print("     Try: convertedY = screenFrame.height - localY (without - windowInfo.bounds.height)")
    print("")
    
    print("   🔧 Step 4: Verify Window Bounds Source")
    print("     Check if windowInfo.bounds are in the expected coordinate system")
    print("")
    
    print("   🔧 Step 5: Test Simple Relative Positioning")
    print("     Try: overlayX = globalX - displayX, overlayY = globalY - displayY")
    print("     This would preserve the original positioning without coordinate conversion")
    print("")
}

// Run all debugging tests
debugRealSystemCoordinates()
testCoordinateConversionIssues()
analyzeUserIssue()
testKnownGoodPosition()
suggestDebuggingSteps()

print("🎯 Next Steps:")
print("   1. Run this debug script to understand your system setup")
print("   2. Add coordinate logging to the actual X-Ray implementation") 
print("   3. Test the suggested coordinate conversion fixes")
print("   4. Compare expected vs actual overlay positions")

print("")
print("💡 Most Likely Issue:")
print("   The coordinate system conversion is probably incorrect.")
print("   We may need to use visibleFrame, remove height subtraction,")
print("   or completely change the conversion approach.")