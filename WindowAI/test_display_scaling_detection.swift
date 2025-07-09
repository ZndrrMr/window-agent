#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 DISPLAY SCALING DETECTION")
print("🎯 Goal: Check if displays are HiDPI/Retina and their scaling factors")
print("")

func analyzeDisplayScaling() {
    print("📊 Display Scaling Analysis")
    
    let screens = NSScreen.screens
    print("   Connected screens: \(screens.count)")
    print("")
    
    for (index, screen) in screens.enumerated() {
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        let backingScaleFactor = screen.backingScaleFactor
        let isMain = screen == NSScreen.main
        
        print("   Screen \(index): \(isMain ? "MAIN" : "EXTERNAL")")
        print("     Frame: \(frame)")
        print("     Visible frame: \(visibleFrame)")
        print("     Backing scale factor: \(backingScaleFactor)")
        
        // Determine if this is a HiDPI/Retina display
        let isHiDPI = backingScaleFactor > 1.0
        let displayType = isHiDPI ? "HiDPI/Retina" : "Standard DPI"
        print("     Display type: \(displayType)")
        
        // Calculate actual pixel dimensions
        let actualPixelWidth = frame.width * backingScaleFactor
        let actualPixelHeight = frame.height * backingScaleFactor
        print("     Logical size: \(Int(frame.width))×\(Int(frame.height))")
        print("     Actual pixels: \(Int(actualPixelWidth))×\(Int(actualPixelHeight))")
        
        // Get device description for more details
        let deviceDescription = screen.deviceDescription
        if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            print("     Screen number: \(screenNumber)")
        }
        
        if let colorSpace = deviceDescription[NSDeviceDescriptionKey("NSColorSpace")] as? NSColorSpace {
            print("     Color space: \(colorSpace.localizedName ?? "Unknown")")
        }
        
        // Check if this matches your setup
        if isMain {
            print("     📱 This is your MacBook display")
            if backingScaleFactor == 2.0 {
                print("     ✅ Confirmed: MacBook with 2x Retina scaling")
            } else {
                print("     ⚠️  Unexpected: MacBook with \(backingScaleFactor)x scaling")
            }
        } else {
            print("     🖥️  This is your external monitor")
            if backingScaleFactor == 1.0 {
                print("     ✅ Confirmed: External monitor with 1x standard DPI")
            } else {
                print("     ⚠️  Unexpected: External monitor with \(backingScaleFactor)x scaling")
            }
        }
        
        print("")
    }
}

func testScalingImpactOnCoordinates() {
    print("📊 Scaling Impact on Coordinates")
    
    let screens = NSScreen.screens
    guard screens.count >= 2 else {
        print("   ⚠️  Need at least 2 displays for this test")
        return
    }
    
    let mainScreen = NSScreen.main!
    let externalScreen = screens.first { $0 != mainScreen }!
    
    print("   Main screen scaling: \(mainScreen.backingScaleFactor)")
    print("   External screen scaling: \(externalScreen.backingScaleFactor)")
    
    let scalingDifference = abs(mainScreen.backingScaleFactor - externalScreen.backingScaleFactor)
    print("   Scaling difference: \(scalingDifference)")
    
    if scalingDifference > 0.1 {
        print("   🚨 SCALING MISMATCH DETECTED!")
        print("   This could cause coordinate conversion issues")
        
        // Simulate coordinate impact
        let testWindow = CGRect(x: 2000, y: -400, width: 800, height: 600)
        let externalFrame = externalScreen.frame
        
        print("")
        print("   Simulating coordinate impact:")
        print("   Test window: \(testWindow)")
        print("   External frame: \(externalFrame)")
        
        // Without scaling compensation
        let localY = testWindow.origin.y - externalFrame.origin.y
        let convertedY_noScaling = externalFrame.height - localY - testWindow.height
        
        // With scaling compensation
        let convertedY_withScaling = (externalFrame.height - localY - testWindow.height) / externalScreen.backingScaleFactor
        
        print("   Without scaling: Y = \(convertedY_noScaling)")
        print("   With scaling: Y = \(convertedY_withScaling)")
        print("   Difference: \(abs(convertedY_noScaling - convertedY_withScaling)) pixels")
        
        let percentDifference = abs(convertedY_noScaling - convertedY_withScaling) / externalFrame.height * 100
        print("   Percentage difference: \(percentDifference)%")
        
        if percentDifference > 5 {
            print("   🎯 This could explain the 'slightly above' positioning issue!")
        }
    } else {
        print("   ✅ No significant scaling difference detected")
    }
}

func checkSystemDisplayPreferences() {
    print("📊 System Display Preferences")
    
    // Check if system has any non-standard display settings
    let mainScreen = NSScreen.main!
    
    print("   Main screen details:")
    print("     Maximum frames per second: \(mainScreen.maximumFramesPerSecond)")
    print("     Display update granularity: \(mainScreen.displayUpdateGranularity)")
    
    // Check if there are any display-specific settings affecting coordinates
    let userDefaults = UserDefaults.standard
    
    // Some relevant display-related preferences
    if let displayPrefs = userDefaults.object(forKey: "com.apple.universalaccess") {
        print("     Universal access settings exist")
    }
    
    // Check for any custom display arrangements
    print("     Display arrangement info:")
    for (index, screen) in NSScreen.screens.enumerated() {
        let frame = screen.frame
        print("       Screen \(index): origin(\(frame.origin.x), \(frame.origin.y))")
        
        if frame.origin.x != 0 || frame.origin.y != 0 {
            print("       -> This screen has non-zero origin (custom arrangement)")
        }
    }
}

// Run all tests
print("🚀 Running Display Scaling Detection")
print("=" + String(repeating: "=", count: 50))
print("")

analyzeDisplayScaling()
testScalingImpactOnCoordinates()
checkSystemDisplayPreferences()

print("🎯 Summary:")
print("   • Check if your external monitor shows 'Standard DPI' while MacBook shows 'HiDPI/Retina'")
print("   • Look for 'SCALING MISMATCH DETECTED' message")
print("   • This would confirm if scaling factors are causing the positioning issue")
print("   • The coordinate difference calculation shows the exact pixel offset this would cause")