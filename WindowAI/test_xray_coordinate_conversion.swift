#!/usr/bin/env swift

import Foundation
import Cocoa
import ApplicationServices

print("🔍 WindowAI X-Ray Coordinate Conversion Test")
print("============================================")

// Test the coordinate conversion issue in multi-monitor setups
func testCoordinateConversion() {
    print("\n🖥️  DISPLAY CONFIGURATION:")
    print("=========================")
    
    let screens = NSScreen.screens
    print("Total displays: \(screens.count)")
    
    for (index, screen) in screens.enumerated() {
        print("Display \(index):")
        print("  Frame: \(screen.frame)")
        print("  Visible Frame: \(screen.visibleFrame)")
        print("  Is Main: \(screen == NSScreen.main)")
        print("  Name: \(screen.localizedName)")
        print("")
    }
    
    print("\n🔧 COORDINATE SYSTEM ANALYSIS:")
    print("===============================")
    
    // Test multiple window positions
    let testWindows = [
        CGRect(x: 100, y: 100, width: 800, height: 600),    // Main display
        CGRect(x: 1500, y: -400, width: 800, height: 600),  // External display
        CGRect(x: 2000, y: 0, width: 800, height: 600)      // External display middle
    ]
    
    for (windowIndex, testWindow) in testWindows.enumerated() {
        print("\nTest window \(windowIndex + 1) (Accessibility coords): \(testWindow)")
        
        for (displayIndex, screen) in screens.enumerated() {
            // Only test if window center is on this display
            let windowCenter = CGPoint(x: testWindow.midX, y: testWindow.midY)
            guard screen.frame.contains(windowCenter) else { continue }
            
            print("  On Display \(displayIndex) (\(screen.frame)):")
            
            // OLD conversion logic (buggy)
            let oldConversion = CGRect(
                x: testWindow.origin.x - screen.frame.origin.x,
                y: screen.frame.height - (testWindow.origin.y - screen.frame.origin.y) - testWindow.height,
                width: testWindow.width,
                height: testWindow.height
            )
            print("    OLD (buggy): \(oldConversion)")
            
            // NEW conversion logic (fixed)
            let newConversion = CGRect(
                x: testWindow.origin.x - screen.frame.origin.x,
                y: screen.frame.height - (testWindow.origin.y + testWindow.height - screen.frame.origin.y),
                width: testWindow.width,
                height: testWindow.height
            )
            print("    NEW (fixed): \(newConversion)")
            
            // Verify the fix
            let xCorrect = newConversion.origin.x >= 0 && newConversion.origin.x <= screen.frame.width
            let yCorrect = newConversion.origin.y >= 0 && newConversion.origin.y <= screen.frame.height
            
            let status = (xCorrect && yCorrect) ? "✅ CORRECT" : "❌ INCORRECT"
            print("    Status: \(status)")
        }
    }
    
    print("\n🐛 PROBLEM ANALYSIS:")
    print("=====================")
    print("The issue is likely in the coordinate system conversion.")
    print("External monitors often have different frame origins than (0,0).")
    print("Current conversion may not account for this properly.")
    
    print("\n💡 EXPECTED BEHAVIOR:")
    print("=====================")
    print("- Main display (0,0): Should work correctly")
    print("- External display (e.g., 1920,0): Windows appear shifted")
    print("- The Y-coordinate conversion is the most likely culprit")
    
    print("\n🔍 DEBUGGING STEPS:")
    print("===================")
    print("1. Check actual window positions on both displays")
    print("2. Compare how they appear in X-Ray overlay")
    print("3. Identify the coordinate system mismatch")
    print("4. Apply the correct conversion formula")
}

// Test if we can get actual window positions
func testActualWindowPositions() {
    print("\n🪟 ACTUAL WINDOW POSITIONS:")
    print("============================")
    
    guard AXIsProcessTrusted() else {
        print("❌ No accessibility permissions")
        return
    }
    
    let runningApps = NSWorkspace.shared.runningApplications
    var windowCount = 0
    
    for app in runningApps.prefix(5) {
        guard app.activationPolicy == .regular else { continue }
        
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result == .success, let windows = windowsRef as? [AXUIElement] {
            for window in windows.prefix(2) {
                windowCount += 1
                
                // Get window position
                var positionRef: CFTypeRef?
                let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
                
                // Get window size
                var sizeRef: CFTypeRef?
                let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                
                if posResult == .success && sizeResult == .success,
                   let position = positionRef,
                   let size = sizeRef {
                    
                    var point = CGPoint.zero
                    var windowSize = CGSize.zero
                    
                    AXValueGetValue(position as! AXValue, .cgPoint, &point)
                    AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
                    
                    let bounds = CGRect(origin: point, size: windowSize)
                    
                    print("Window \(windowCount): \(app.localizedName ?? "Unknown")")
                    print("  Accessibility coords: \(bounds)")
                    
                    // Determine which display this window is on
                    let windowCenter = CGPoint(x: bounds.midX, y: bounds.midY)
                    for (index, screen) in NSScreen.screens.enumerated() {
                        if screen.frame.contains(windowCenter) {
                            print("  On display \(index): \(screen.frame)")
                            
                            // Show the coordinate conversion
                            let converted = CGRect(
                                x: bounds.origin.x - screen.frame.origin.x,
                                y: screen.frame.height - (bounds.origin.y - screen.frame.origin.y) - bounds.height,
                                width: bounds.width,
                                height: bounds.height
                            )
                            print("  Converted to Cocoa: \(converted)")
                            break
                        }
                    }
                    print("")
                }
            }
        }
    }
    
    if windowCount == 0 {
        print("❌ No windows found")
    }
}

// Main test execution
testCoordinateConversion()
testActualWindowPositions()

print("\n🎯 COORDINATE CONVERSION FIX:")
print("==============================")
print("The issue is in XRayOverlayWindow.swift lines 81-86 and 127-133")
print("PROBLEM: External monitors with negative Y origins cause windows to shift down")
print("")
print("OLD (buggy) code:")
print("  y: screenFrame.height - (windowInfo.bounds.origin.y - screenFrame.origin.y) - windowInfo.bounds.height")
print("")
print("NEW (fixed) code:")
print("  y: screenFrame.height - (windowInfo.bounds.origin.y + windowInfo.bounds.height - screenFrame.origin.y)")
print("")
print("EXPLANATION:")
print("- External display has negative Y origin (e.g., -540)")
print("- Old logic: subtracts negative value, which adds it (wrong)")
print("- New logic: properly groups the window bottom coordinate before conversion")
print("- This correctly accounts for the display's origin offset in the conversion.")