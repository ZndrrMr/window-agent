#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 COMPREHENSIVE X-RAY DIAGNOSTIC")
print("🎯 Goal: Capture ALL information needed to diagnose why X-Ray shows windows at bottom")
print("")

// DIAGNOSTIC 1: Complete Display Configuration
func captureDisplayConfiguration() {
    print("📊 1. COMPLETE DISPLAY CONFIGURATION")
    
    let screens = NSScreen.screens
    print("   Total screens: \(screens.count)")
    
    for (index, screen) in screens.enumerated() {
        let isMain = screen == NSScreen.main
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        let backingScaleFactor = screen.backingScaleFactor
        
        print("   Screen \(index) (\(isMain ? "MAIN" : "EXTERNAL")):")
        print("     Frame: \(frame)")
        print("     Visible frame: \(visibleFrame)")
        print("     Backing scale factor: \(backingScaleFactor)")
        print("     Max FPS: \(screen.maximumFramesPerSecond)")
        print("     Display update granularity: \(screen.displayUpdateGranularity)")
        
        let deviceDescription = screen.deviceDescription
        for (key, value) in deviceDescription {
            print("     \(key): \(value)")
        }
        
        // Check if this is the external display
        if !isMain {
            print("     🖥️  EXTERNAL DISPLAY ANALYSIS:")
            print("       Origin Y is negative: \(frame.origin.y < 0)")
            print("       Total height span: \(frame.origin.y) to \(frame.origin.y + frame.height)")
            print("       Coordinate system: Global macOS coordinates")
            print("       Expected overlay coverage: Entire external display")
        }
        
        print("")
    }
}

// DIAGNOSTIC 2: Simulate Real Window Data
func simulateRealWindowAnalysis() {
    print("📊 2. REAL WINDOW POSITIONING ANALYSIS")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ❌ No external screen found")
        return
    }
    
    print("   External screen frame: \(external.frame)")
    print("   Testing window positions that would appear in different screen areas...")
    
    // Test windows at different visual positions
    let testScenarios = [
        // Windows that should appear at TOP of external display
        ("TOP area window", CGRect(x: 2000, y: -520, width: 600, height: 400)),
        ("TOP-LEFT corner", CGRect(x: 1500, y: -530, width: 500, height: 300)),
        ("TOP-RIGHT corner", CGRect(x: 3500, y: -530, width: 500, height: 300)),
        
        // Windows that should appear at MIDDLE of external display
        ("MIDDLE area window", CGRect(x: 2500, y: -200, width: 600, height: 400)),
        ("CENTER window", CGRect(x: 2200, y: -270, width: 800, height: 300)),
        
        // Windows that should appear at BOTTOM of external display  
        ("BOTTOM area window", CGRect(x: 2000, y: 300, width: 600, height: 400)),
        ("BOTTOM-LEFT corner", CGRect(x: 1500, y: 500, width: 500, height: 300)),
        ("BOTTOM-RIGHT corner", CGRect(x: 3500, y: 500, width: 500, height: 300)),
    ]
    
    for (name, windowBounds) in testScenarios {
        print("   \(name): \(windowBounds)")
        
        // Apply the current X-Ray coordinate conversion
        let localX = windowBounds.origin.x - external.frame.origin.x
        let localY = windowBounds.origin.y - external.frame.origin.y
        let convertedX = localX
        let convertedY = external.frame.height - localY - windowBounds.height
        
        // Apply clamping (this might be the issue!)
        let clampedX = max(0, min(convertedX, external.frame.width - windowBounds.width))
        let clampedY = max(0, min(convertedY, external.frame.height - windowBounds.height))
        
        print("     Local: (\(localX), \(localY))")
        print("     Converted: (\(convertedX), \(convertedY))")
        print("     Clamped: (\(clampedX), \(clampedY))")
        
        // Where does this appear in the overlay?
        let overlayPercentFromTop = (external.frame.height - clampedY) / external.frame.height * 100
        let overlayPercentFromBottom = clampedY / external.frame.height * 100
        
        print("     Overlay position: \(overlayPercentFromTop)% from TOP, \(overlayPercentFromBottom)% from BOTTOM")
        
        // Where SHOULD it appear based on the original window position?
        let originalPercentFromTop = (windowBounds.origin.y - external.frame.origin.y) / external.frame.height * 100
        
        print("     Expected position: \(originalPercentFromTop)% from TOP")
        
        // Check if they match
        let positionError = abs(overlayPercentFromTop - originalPercentFromTop)
        print("     Position error: \(positionError)%")
        
        if positionError > 10 {
            print("     🚨 MAJOR POSITIONING ERROR!")
        }
        
        // Check if clamping caused the issue
        if clampedY != convertedY {
            print("     ⚠️  CLAMPING CHANGED Y POSITION!")
            print("       Before clamping: \(convertedY)")
            print("       After clamping: \(clampedY)")
            print("       🎯 This could be why windows appear at bottom!")
        }
        
        print("")
    }
}

// DIAGNOSTIC 3: Check for coordinate system bugs
func checkCoordinateSystemBugs() {
    print("📊 3. COORDINATE SYSTEM BUG DETECTION")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ❌ No external screen found")
        return
    }
    
    print("   External screen: \(external.frame)")
    
    // Test the coordinate conversion step by step
    let testWindow = CGRect(x: 2000, y: -400, width: 800, height: 600)
    print("   Test window: \(testWindow)")
    
    // Step 1: Global to local
    let globalX = testWindow.origin.x
    let globalY = testWindow.origin.y
    let displayOriginX = external.frame.origin.x
    let displayOriginY = external.frame.origin.y
    
    print("   Step 1: Global to Local")
    print("     Global: (\(globalX), \(globalY))")
    print("     Display origin: (\(displayOriginX), \(displayOriginY))")
    
    let localX = globalX - displayOriginX
    let localY = globalY - displayOriginY
    print("     Local: (\(localX), \(localY))")
    
    // Check if local coordinates make sense
    let localXValid = localX >= 0 && localX < external.frame.width
    let localYValid = localY >= 0 && localY < external.frame.height
    print("     Local X valid: \(localXValid)")
    print("     Local Y valid: \(localYValid)")
    
    // Step 2: Accessibility to Cocoa coordinate conversion
    print("   Step 2: Accessibility → Cocoa")
    print("     Accessibility uses TOP-LEFT origin")
    print("     Cocoa uses BOTTOM-LEFT origin")
    print("     Display height: \(external.frame.height)")
    
    let convertedX = localX
    let convertedY = external.frame.height - localY - testWindow.height
    print("     Converted: (\(convertedX), \(convertedY))")
    
    // Check if conversion makes sense
    let convertedXValid = convertedX >= 0 && convertedX < external.frame.width
    let convertedYValid = convertedY >= 0 && convertedY < external.frame.height
    print("     Converted X valid: \(convertedXValid)")
    print("     Converted Y valid: \(convertedYValid)")
    
    // Step 3: Check what clamping does
    print("   Step 3: Clamping")
    let maxX = external.frame.width - testWindow.width
    let maxY = external.frame.height - testWindow.height
    print("     Max X: \(maxX)")
    print("     Max Y: \(maxY)")
    
    let clampedX = max(0, min(convertedX, maxX))
    let clampedY = max(0, min(convertedY, maxY))
    print("     Clamped: (\(clampedX), \(clampedY))")
    
    if clampedY != convertedY {
        print("     🚨 CLAMPING CHANGED Y COORDINATE!")
        print("     This could be forcing windows to bottom of screen!")
    }
}

// DIAGNOSTIC 4: Test the actual X-Ray overlay window setup
func testXRayOverlayWindowSetup() {
    print("📊 4. X-RAY OVERLAY WINDOW SETUP TEST")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ❌ No external screen found")
        return
    }
    
    print("   Testing XRayOverlayWindow configuration...")
    print("   Target screen: \(external.frame)")
    
    // Test what happens when we create an overlay window
    let overlayFrame = external.frame
    print("   Overlay window frame: \(overlayFrame)")
    
    // Check if frame has issues
    let frameValid = overlayFrame.width > 0 && overlayFrame.height > 0
    print("   Frame valid: \(frameValid)")
    
    // Check window level
    let windowLevel = Int(CGWindowLevelForKey(.maximumWindow)) + 1
    print("   Window level: \(windowLevel)")
    
    // Check if window level is too high
    if windowLevel > 1000000000 {
        print("   ⚠️  Extremely high window level - could cause display issues")
    }
    
    // Check collection behavior
    print("   Collection behavior: [.canJoinAllSpaces, .fullScreenAuxiliary]")
    
    // Test if negative origin causes issues
    if overlayFrame.origin.y < 0 {
        print("   🔍 Negative Y origin: \(overlayFrame.origin.y)")
        print("   This could cause NSWindow positioning issues")
        
        // Check if the coordinate system is being interpreted incorrectly
        let bottomY = overlayFrame.origin.y + overlayFrame.height
        print("   Y coordinate range: \(overlayFrame.origin.y) to \(bottomY)")
        
        if bottomY < 0 {
            print("   🚨 ENTIRE DISPLAY IS ABOVE Y=0!")
            print("   This could cause major coordinate issues")
        }
    }
}

// DIAGNOSTIC 5: Test BetterDisplay impact
func testBetterDisplayImpact() {
    print("📊 5. BETTERDISPLAY IMPACT ANALYSIS")
    
    let externalScreen = NSScreen.screens.first { $0 != NSScreen.main }
    guard let external = externalScreen else {
        print("   ❌ No external screen found")
        return
    }
    
    print("   Current external display configuration:")
    print("   Frame: \(external.frame)")
    print("   Backing scale factor: \(external.backingScaleFactor)")
    
    // Check if BetterDisplay changed anything
    let isHiDPI = external.backingScaleFactor > 1.0
    print("   Currently HiDPI: \(isHiDPI)")
    
    if isHiDPI {
        print("   ✅ BetterDisplay successfully enabled HiDPI")
        print("   This should affect coordinate calculations")
        
        // Test if coordinates need scaling factor adjustment
        let testWindow = CGRect(x: 2000, y: -400, width: 800, height: 600)
        let scaleFactor = external.backingScaleFactor
        
        print("   Testing scaled coordinates:")
        print("   Scale factor: \(scaleFactor)")
        
        // Without scaling
        let localY = testWindow.origin.y - external.frame.origin.y
        let convertedY_noScale = external.frame.height - localY - testWindow.height
        
        // With scaling
        let scaledHeight = external.frame.height / scaleFactor
        let scaledLocalY = localY / scaleFactor
        let scaledWindowHeight = testWindow.height / scaleFactor
        let convertedY_withScale = scaledHeight - scaledLocalY - scaledWindowHeight
        
        print("   Without scaling: Y = \(convertedY_noScale)")
        print("   With scaling: Y = \(convertedY_withScale)")
        print("   Difference: \(abs(convertedY_noScale - convertedY_withScale))")
        
        if abs(convertedY_noScale - convertedY_withScale) > 50 {
            print("   🎯 SCALING FACTOR NEEDS TO BE APPLIED!")
        }
    } else {
        print("   ❌ BetterDisplay did not enable HiDPI")
        print("   Scale factor is still 1.0")
    }
}

// DIAGNOSTIC 6: Generate recommendations
func generateRecommendations() {
    print("📊 6. DIAGNOSTIC RECOMMENDATIONS")
    
    print("   Based on the diagnostics above, check for:")
    print("   1. 🔍 Clamping issues - Look for 'CLAMPING CHANGED Y POSITION' messages")
    print("   2. 🔍 Coordinate system bugs - Look for invalid local/converted coordinates")
    print("   3. 🔍 Window level issues - Look for extremely high window levels")
    print("   4. 🔍 Negative origin problems - Look for coordinate range issues")
    print("   5. 🔍 Scaling factor mismatches - Look for coordinate differences with/without scaling")
    print("")
    
    print("   Most likely causes of 'windows at bottom' issue:")
    print("   A. Clamping is forcing all Y coordinates to 0 (bottom of screen)")
    print("   B. Coordinate conversion is inverting the Y axis incorrectly")
    print("   C. NSWindow.setFrame() is not positioning overlay window correctly")
    print("   D. Window level is too high and causing display glitches")
    print("")
    
    print("   To fix:")
    print("   1. If clamping is the issue: Remove or fix the clamping logic")
    print("   2. If coordinate conversion is wrong: Fix the Accessibility→Cocoa conversion")
    print("   3. If overlay positioning is wrong: Fix NSWindow.setFrame() usage")
    print("   4. If window level is too high: Reduce the window level")
}

// Run all diagnostics
print("🚀 Running Comprehensive X-Ray Diagnostic")
print("=" + String(repeating: "=", count: 70))
print("")

captureDisplayConfiguration()
simulateRealWindowAnalysis()
checkCoordinateSystemBugs()
testXRayOverlayWindowSetup()
testBetterDisplayImpact()
generateRecommendations()

print("🎯 NEXT STEPS:")
print("   1. Review ALL diagnostic output above")
print("   2. Look for 🚨 MAJOR POSITIONING ERROR messages")
print("   3. Look for ⚠️  CLAMPING CHANGED Y POSITION messages")
print("   4. Check if any coordinate values are consistently wrong")
print("   5. Focus on the area marked with 🎯 - this is likely the root cause")
print("")
print("   The diagnostic will show exactly where the coordinate conversion is failing!")