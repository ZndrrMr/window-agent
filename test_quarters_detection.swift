#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 QUARTERS DETECTION TEST")
print("=========================")
print("This test detects uniform quarters vs intelligent proportional layout")
print("DO NOT CHANGE THIS TEST - it must fail first, then we iterate the implementation")
print("")

func testQuartersDetection() -> Bool {
    // Test coordinates from the actual WindowAI log output
    let testWindows = [
        ("Xcode", CGRect(x: 0.0, y: 0.0, width: 778.3333333333334, height: 450.31185031185026)),
        ("Arc", CGRect(x: 778.3333333333334, y: 0.0, width: 661.6666666666666, height: 450.31185031185026)), 
        ("Finder", CGRect(x: 0.0, y: 450.31185031185026, width: 778.3333333333334, height: 449.68814968814974)),
        ("Terminal", CGRect(x: 778.3333333333334, y: 450.31185031185026, width: 661.6666666666666, height: 449.68814968814974))
    ]
    
    let screenSize = CGSize(width: 1440, height: 900)
    
    print("📊 ANALYZING LAYOUT:")
    print("===================")
    for (app, bounds) in testWindows {
        let widthPercent = (bounds.width / screenSize.width) * 100
        let heightPercent = (bounds.height / screenSize.height) * 100
        let areaPercent = (bounds.width * bounds.height) / (screenSize.width * screenSize.height) * 100
        
        print("📱 \(app):")
        print("  📐 Position: (\(Int(bounds.origin.x)), \(Int(bounds.origin.y)))")
        print("  📏 Size: \(Int(bounds.width))×\(Int(bounds.height)) (\(String(format: "%.1f", widthPercent))%×\(String(format: "%.1f", heightPercent))%)")
        print("  📊 Area: \(String(format: "%.1f", areaPercent))%")
        print("")
    }
    
    // QUARTERS DETECTION ALGORITHM
    print("🔍 QUARTERS DETECTION:")
    print("=====================")
    
    // Check if all windows have approximately the same area (quarters = ~25% each)
    let areas = testWindows.map { (_, bounds) in
        (bounds.width * bounds.height) / (screenSize.width * screenSize.height)
    }
    
    let avgArea = areas.reduce(0, +) / Double(areas.count)
    let maxDeviation = areas.map { abs($0 - avgArea) }.max() ?? 0
    
    print("📊 Area analysis:")
    for (index, area) in areas.enumerated() {
        print("  \(testWindows[index].0): \(String(format: "%.1f", area * 100))%")
    }
    print("  Average area: \(String(format: "%.1f", avgArea * 100))%")
    print("  Max deviation: \(String(format: "%.1f", maxDeviation * 100))%")
    print("")
    
    // UNIFORM QUARTERS TEST
    let isUniformQuarters = maxDeviation < 0.05 && abs(avgArea - 0.25) < 0.05
    
    // GRID LAYOUT TEST  
    let sortedByX = testWindows.sorted { $0.1.origin.x < $1.1.origin.x }
    let sortedByY = testWindows.sorted { $0.1.origin.y < $1.1.origin.y }
    
    let leftWindows = sortedByX.prefix(2)
    let rightWindows = sortedByX.suffix(2)
    let topWindows = sortedByY.prefix(2) 
    let bottomWindows = sortedByY.suffix(2)
    
    let hasGridStructure = leftWindows.allSatisfy { abs($0.1.origin.x - sortedByX.first!.1.origin.x) < 10 } &&
                          rightWindows.allSatisfy { abs($0.1.origin.x - sortedByX.last!.1.origin.x) < 10 } &&
                          topWindows.allSatisfy { abs($0.1.origin.y - sortedByY.first!.1.origin.y) < 10 } &&
                          bottomWindows.allSatisfy { abs($0.1.origin.y - sortedByY.last!.1.origin.y) < 10 }
    
    print("🎯 TEST RESULTS:")
    print("===============")
    print("✅ Uniform area sizes: \(isUniformQuarters ? "YES (quarters detected!)" : "NO")")
    print("✅ 2×2 grid structure: \(hasGridStructure ? "YES (grid detected!)" : "NO")")
    print("")
    
    if isUniformQuarters && hasGridStructure {
        print("❌ FAIL: UNIFORM QUARTERS DETECTED!")
        print("   This is the old arrangeQuartersLayout() behavior")
        print("   All windows are approximately 25% area in a 2×2 grid")
        print("   FlexibleLayoutEngine is NOT working!")
        print("")
        print("🔧 Expected intelligent layout:")
        print("   - Different apps should have different sizes based on archetypes")
        print("   - Code workspace (Xcode) should be largest (~50-60% area)")
        print("   - Content canvas (Arc) should be medium (~30-40% area)")  
        print("   - Text stream (Terminal) should be narrow vertical strip")
        print("   - Glanceable monitor (Finder) should be small corner")
        return false
    } else {
        print("✅ PASS: INTELLIGENT PROPORTIONAL LAYOUT!")
        print("   Windows have different sizes based on app archetypes")
        print("   FlexibleLayoutEngine is working correctly!")
        return true
    }
}

let testResult = testQuartersDetection()

print("")
print("🎯 FINAL RESULT:")
print("===============")
if testResult {
    print("✅ TEST PASSED: Intelligent proportional layout detected")
} else {
    print("❌ TEST FAILED: Uniform quarters detected - fix the implementation!")
}

exit(testResult ? 0 : 1)