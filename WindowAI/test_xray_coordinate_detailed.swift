#!/usr/bin/env swift

import Foundation
import Cocoa

print("🔍 Detailed X-Ray Coordinate Conversion Analysis")
print("================================================")

// Test the exact issue described by the user
func testExternalMonitorShift() {
    print("\n🖥️  ACTUAL DISPLAY CONFIGURATION:")
    print("==================================")
    
    let screens = NSScreen.screens
    for (index, screen) in screens.enumerated() {
        print("Display \(index): \(screen.frame)")
        if screen == NSScreen.main {
            print("  ^ Main display")
        }
    }
    
    print("\n🧪 TESTING COORDINATE CONVERSION EDGE CASES:")
    print("=============================================")
    
    // Test cases that would reveal the shifting issue
    let testCases: [(description: String, window: CGRect, expectedDisplay: Int)] = [
        ("Main display top-left", CGRect(x: 50, y: 50, width: 400, height: 300), 0),
        ("Main display center", CGRect(x: 500, y: 300, width: 400, height: 300), 0),
        ("External display top area", CGRect(x: 1500, y: -500, width: 400, height: 300), 1),
        ("External display center", CGRect(x: 2000, y: 200, width: 400, height: 300), 1),
        ("External display bottom", CGRect(x: 1800, y: 700, width: 400, height: 300), 1)
    ]
    
    for (description, window, expectedDisplay) in testCases {
        guard expectedDisplay < screens.count else { continue }
        
        let screen = screens[expectedDisplay]
        print("\n📋 Test Case: \(description)")
        print("   Window: \(window)")
        print("   Target Display: \(expectedDisplay) (\(screen.frame))")
        
        // OLD conversion logic
        let oldY = screen.frame.height - (window.origin.y - screen.frame.origin.y) - window.height
        let oldConversion = CGRect(
            x: window.origin.x - screen.frame.origin.x,
            y: oldY,
            width: window.width,
            height: window.height
        )
        
        // NEW conversion logic  
        let newY = screen.frame.height - (window.origin.y + window.height - screen.frame.origin.y)
        let newConversion = CGRect(
            x: window.origin.x - screen.frame.origin.x,
            y: newY,
            width: window.width,
            height: window.height
        )
        
        print("   OLD result: \(oldConversion)")
        print("   NEW result: \(newConversion)")
        
        // Check if results are different
        if oldConversion.origin.y != newConversion.origin.y {
            print("   🚨 DIFFERENT Y-coordinates! Difference: \(oldConversion.origin.y - newConversion.origin.y)")
        } else {
            print("   ✅ Same Y-coordinate")
        }
        
        // Check if coordinates are reasonable for the display
        let oldValid = oldConversion.origin.y >= 0 && oldConversion.origin.y <= screen.frame.height
        let newValid = newConversion.origin.y >= 0 && newConversion.origin.y <= screen.frame.height
        
        print("   OLD valid: \(oldValid ? "✅" : "❌") - Y: \(oldConversion.origin.y)")
        print("   NEW valid: \(newValid ? "✅" : "❌") - Y: \(newConversion.origin.y)")
    }
}

// Test the mathematical equivalence
func testMathematicalEquivalence() {
    print("\n🧮 MATHEMATICAL EQUIVALENCE TEST:")
    print("==================================")
    
    let testWindow = CGRect(x: 1500, y: -400, width: 800, height: 600)
    let testScreen = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    print("Test window: \(testWindow)")
    print("Test screen: \(testScreen)")
    
    // OLD formula: screenFrame.height - (windowInfo.bounds.origin.y - screenFrame.origin.y) - windowInfo.bounds.height
    let oldFormula = testScreen.height - (testWindow.origin.y - testScreen.origin.y) - testWindow.height
    print("OLD formula: \(testScreen.height) - (\(testWindow.origin.y) - \(testScreen.origin.y)) - \(testWindow.height)")
    print("           = \(testScreen.height) - (\(testWindow.origin.y - testScreen.origin.y)) - \(testWindow.height)")
    print("           = \(testScreen.height) - \(testWindow.origin.y - testScreen.origin.y) - \(testWindow.height)")
    print("           = \(oldFormula)")
    
    // NEW formula: screenFrame.height - (windowInfo.bounds.origin.y + windowInfo.bounds.height - screenFrame.origin.y)
    let newFormula = testScreen.height - (testWindow.origin.y + testWindow.height - testScreen.origin.y)
    print("NEW formula: \(testScreen.height) - (\(testWindow.origin.y) + \(testWindow.height) - \(testScreen.origin.y))")
    print("           = \(testScreen.height) - (\(testWindow.origin.y + testWindow.height - testScreen.origin.y))")
    print("           = \(newFormula)")
    
    print("Difference: \(oldFormula - newFormula)")
    
    // Let's expand both formulas algebraically
    print("\n🔢 ALGEBRAIC EXPANSION:")
    print("=======================")
    print("OLD: height - (window.y - screen.y) - window.height")
    print("   = height - window.y + screen.y - window.height")
    print("   = height - window.height - window.y + screen.y")
    print("")
    print("NEW: height - (window.y + window.height - screen.y)")
    print("   = height - window.y - window.height + screen.y")
    print("   = height - window.height - window.y + screen.y")
    print("")
    print("🔍 CONCLUSION: The formulas are MATHEMATICALLY EQUIVALENT!")
    print("The issue may be elsewhere, not in the coordinate conversion.")
}

// Test actual window detection on external monitor
func testActualWindowDetection() {
    print("\n🪟 ACTUAL WINDOW DETECTION ON EXTERNAL MONITOR:")
    print("===============================================")
    
    guard AXIsProcessTrusted() else {
        print("❌ No accessibility permissions")
        return
    }
    
    let screens = NSScreen.screens
    guard screens.count > 1 else {
        print("❌ No external monitor detected")
        return
    }
    
    let externalScreen = screens[1]
    print("External monitor: \(externalScreen.frame)")
    
    // Find windows on external monitor
    let runningApps = NSWorkspace.shared.runningApplications
    var externalWindows: [CGRect] = []
    
    for app in runningApps {
        guard app.activationPolicy == .regular else { continue }
        
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result == .success, let windows = windowsRef as? [AXUIElement] {
            for window in windows {
                var positionRef: CFTypeRef?
                var sizeRef: CFTypeRef?
                
                let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
                let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                
                if posResult == .success && sizeResult == .success,
                   let position = positionRef,
                   let size = sizeRef {
                    
                    var point = CGPoint.zero
                    var windowSize = CGSize.zero
                    
                    AXValueGetValue(position as! AXValue, .cgPoint, &point)
                    AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
                    
                    let bounds = CGRect(origin: point, size: windowSize)
                    let windowCenter = CGPoint(x: bounds.midX, y: bounds.midY)
                    
                    // Check if window is on external monitor
                    if externalScreen.frame.contains(windowCenter) {
                        externalWindows.append(bounds)
                        print("External window: \(bounds) (\(app.localizedName ?? "Unknown"))")
                        
                        // Test coordinate conversion
                        let oldY = externalScreen.frame.height - (bounds.origin.y - externalScreen.frame.origin.y) - bounds.height
                        let newY = externalScreen.frame.height - (bounds.origin.y + bounds.height - externalScreen.frame.origin.y)
                        
                        print("  OLD Y: \(oldY)")
                        print("  NEW Y: \(newY)")
                        print("  Difference: \(oldY - newY)")
                    }
                }
            }
        }
    }
    
    if externalWindows.isEmpty {
        print("❌ No windows found on external monitor")
    } else {
        print("✅ Found \(externalWindows.count) windows on external monitor")
    }
}

// Main execution
testExternalMonitorShift()
testMathematicalEquivalence()
testActualWindowDetection()

print("\n🎯 ANALYSIS CONCLUSION:")
print("========================")
print("The OLD and NEW coordinate conversion formulas are mathematically equivalent.")
print("This suggests the issue might be:")
print("1. In the window filtering logic (which display a window belongs to)")
print("2. In the overlay window positioning itself")
print("3. In a different part of the coordinate system")
print("4. The issue may have been fixed by a different change")
print("")
print("Need to investigate the actual user report more carefully.")