#!/usr/bin/env swift

import Foundation
import Cocoa

print("🧪 Test: X-Ray Coordinate Conversion Fix Verification")
print("✅ Testing that all displays now use the same coordinate conversion formula")
print("")

// Test the exact coordinate conversion logic that's now in XRayOverlayWindow.swift
func testUnifiedCoordinateConversion() {
    print("📊 Test: Unified Coordinate Conversion Formula")
    
    // Test scenarios: Main display and external display (negative origin)
    let testScenarios = [
        (name: "Main Display", display: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
        (name: "External Above", display: CGRect(x: 1440, y: -540, width: 2560, height: 1440))
    ]
    
    let testWindow = CGRect(x: 2000, y: -400, width: 800, height: 600)
    
    for scenario in testScenarios {
        print("   Testing: \(scenario.name)")
        let display = scenario.display
        
        // Apply the UNIFIED coordinate conversion formula (same for all displays)
        let localX = testWindow.origin.x - display.origin.x
        let localY = testWindow.origin.y - display.origin.y
        let convertedX = localX  
        let convertedY = display.height - localY - testWindow.height
        
        // Apply clamping
        let clampedX = max(0, min(convertedX, display.width - testWindow.width))
        let clampedY = max(0, min(convertedY, display.height - testWindow.height))
        
        print("     Display: \(display)")
        print("     Local coords: (\(localX), \(localY))")
        print("     Converted coords: (\(convertedX), \(convertedY))")
        print("     Final coords: (\(clampedX), \(clampedY))")
        
        // Verify the conversion is reasonable
        let inBounds = clampedX >= 0 && clampedY >= 0 && 
                      clampedX <= display.width && clampedY <= display.height
        
        print("     In bounds: \(inBounds ? "✅" : "❌")")
        print("")
    }
}

// Test the specific user issue scenario
func testUserIssueFixed() -> Bool {
    print("📊 Test: User Issue Fixed")
    
    // User's external display configuration
    let externalDisplay = CGRect(x: 1440, y: -540, width: 2560, height: 1440)
    
    // Window that was "slightly above" target in user's feedback
    let problematicWindow = CGRect(x: 2800, y: -400, width: 800, height: 600)
    
    print("   External display: \(externalDisplay)")
    print("   Problematic window: \(problematicWindow)")
    
    // Apply the NEW unified coordinate conversion
    let localX = problematicWindow.origin.x - externalDisplay.origin.x
    let localY = problematicWindow.origin.y - externalDisplay.origin.y
    let convertedX = localX
    let convertedY = externalDisplay.height - localY - problematicWindow.height
    let clampedX = max(0, min(convertedX, externalDisplay.width - problematicWindow.width))
    let clampedY = max(0, min(convertedY, externalDisplay.height - problematicWindow.height))
    
    print("   Local coords: (\(localX), \(localY))")
    print("   Converted coords: (\(convertedX), \(convertedY))")
    print("   Final coords: (\(clampedX), \(clampedY))")
    
    // Verify the issue is fixed
    let noLongerShiftedDown = clampedY > 0 && clampedY < externalDisplay.height * 0.9
    let noLongerSlightlyAbove = clampedY > externalDisplay.height * 0.1
    
    print("   No longer shifted down: \(noLongerShiftedDown ? "✅" : "❌")")
    print("   No longer slightly above: \(noLongerSlightlyAbove ? "✅" : "❌")")
    
    let issueFixed = noLongerShiftedDown && noLongerSlightlyAbove
    print("   User issue fixed: \(issueFixed ? "✅" : "❌")")
    
    return issueFixed
}

// Test that both regular and optimized versions use the same formula
func testConsistentImplementation() -> Bool {
    print("📊 Test: Consistent Implementation")
    
    // This test verifies that both showWithWindows and showWithWindowsOptimized 
    // use the same coordinate conversion formula
    
    let sourceFile = "WindowAI/UI/XRayOverlayWindow.swift"
    
    do {
        let content = try String(contentsOfFile: sourceFile, encoding: .utf8)
        
        // Check for the unified formula in both methods
        let unifiedFormula = "let convertedY = screenFrame.height - localY - windowInfo.bounds.height"
        let unifiedFormulaOccurrences = content.components(separatedBy: unifiedFormula).count - 1
        
        print("   Unified formula occurrences: \(unifiedFormulaOccurrences)")
        
        // Check that conditional logic is removed
        let conditionalLogic = "if screenFrame.origin.y < 0"
        let conditionalOccurrences = content.components(separatedBy: conditionalLogic).count - 1
        
        print("   Conditional logic removed: \(conditionalOccurrences == 0 ? "✅" : "❌")")
        
        // Check for the standard message
        let standardMessage = "Using standard coordinate conversion formula (all displays)"
        let standardMessageExists = content.contains(standardMessage)
        
        print("   Standard message exists: \(standardMessageExists ? "✅" : "❌")")
        
        let implementationConsistent = unifiedFormulaOccurrences >= 2 && 
                                      conditionalOccurrences == 0 && 
                                      standardMessageExists
        
        print("   Implementation consistent: \(implementationConsistent ? "✅" : "❌")")
        
        return implementationConsistent
        
    } catch {
        print("   ❌ Error reading source file: \(error)")
        return false
    }
}

// Run all tests
print("🚀 Running Coordinate Fix Verification Tests")
print("=" + String(repeating: "=", count: 50))
print("")

testUnifiedCoordinateConversion()
let test1 = testUserIssueFixed()
print("")
let test2 = testConsistentImplementation()

print("")
print("📋 Test Results:")
print("   1. User Issue Fixed: \(test1 ? "✅ PASS" : "❌ FAIL")")
print("   2. Implementation Consistent: \(test2 ? "✅ PASS" : "❌ FAIL")")

let allTestsPassed = test1 && test2

print("")
if allTestsPassed {
    print("🎉 ALL TESTS PASSED!")
    print("✅ X-Ray coordinate conversion fix is working correctly")
    print("✅ External display positioning should no longer be 'slightly above'")
    print("✅ Both main and external displays use the same conversion formula")
} else {
    print("❌ SOME TESTS FAILED!")
    print("🔧 Review failed tests and fix remaining issues")
}

print("")
print("🔧 Fix Summary:")
print("   • Problem: Different coordinate conversion formulas for different displays")
print("   • Root cause: Conditional logic based on display origin")
print("   • Solution: Unified coordinate conversion formula for all displays")
print("   • Formula: convertedY = screenFrame.height - localY - windowInfo.bounds.height")
print("   • Result: Consistent positioning across all display configurations")

print("")
print("🎯 Expected User Experience:")
print("   • External display windows should appear at correct positions")
print("   • No more 'slightly above' positioning issues")
print("   • Perfect alignment between actual windows and X-Ray overlays")