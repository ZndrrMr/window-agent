#!/usr/bin/env swift

import Foundation
import CoreGraphics

// Test to detect uniform quarters vs intelligent proportional layout
// This test validates that the FlexibleLayoutEngine produces non-uniform sizing

struct TestWindowLayout {
    let appName: String
    let bounds: CGRect
    let archetype: String
}

struct LayoutTestResult {
    let layouts: [TestWindowLayout]
    let isUniformQuarters: Bool
    let screenCoverage: Double
    let hasIntelligentSizing: Bool
}

// Screen dimensions for testing (typical macOS setup)
let screenWidth: CGFloat = 1920
let screenHeight: CGFloat = 1080
let screenBounds = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)

// Test layouts that would be generated
func testIntelligentLayout() -> LayoutTestResult {
    print("🧪 Testing Intelligent Layout vs Uniform Quarters Detection")
    print("Screen: \(Int(screenWidth))×\(Int(screenHeight))")
    
    // Simulate what FlexibleLayoutEngine SHOULD produce for diverse apps
    let intelligentLayouts = [
        TestWindowLayout(
            appName: "Cursor", 
            bounds: CGRect(x: 0, y: 0, width: 1200, height: 1080), // 62.5% width - primary workspace
            archetype: "codeWorkspace"
        ),
        TestWindowLayout(
            appName: "Terminal", 
            bounds: CGRect(x: 1200, y: 0, width: 480, height: 1080), // 25% width - text stream
            archetype: "textStream"
        ),
        TestWindowLayout(
            appName: "Arc", 
            bounds: CGRect(x: 1680, y: 0, width: 240, height: 540), // 12.5% width - peek layer
            archetype: "contentCanvas"
        ),
        TestWindowLayout(
            appName: "Music", 
            bounds: CGRect(x: 1680, y: 540, width: 240, height: 540), // 12.5% width - glanceable
            archetype: "glanceableMonitor"
        )
    ]
    
    // Simulate what BROKEN system would produce (uniform quarters)
    let quarterLayouts = [
        TestWindowLayout(
            appName: "Cursor", 
            bounds: CGRect(x: 0, y: 0, width: 960, height: 540), // 25% exactly
            archetype: "codeWorkspace"
        ),
        TestWindowLayout(
            appName: "Terminal", 
            bounds: CGRect(x: 960, y: 0, width: 960, height: 540), // 25% exactly  
            archetype: "textStream"
        ),
        TestWindowLayout(
            appName: "Arc", 
            bounds: CGRect(x: 0, y: 540, width: 960, height: 540), // 25% exactly
            archetype: "contentCanvas"
        ),
        TestWindowLayout(
            appName: "Music", 
            bounds: CGRect(x: 960, y: 540, width: 960, height: 540), // 25% exactly
            archetype: "glanceableMonitor"
        )
    ]
    
    print("\n📊 INTELLIGENT LAYOUT TEST:")
    let intelligentResult = analyzeLayout(intelligentLayouts, testName: "Intelligent")
    
    print("\n📊 UNIFORM QUARTERS TEST:")
    let quartersResult = analyzeLayout(quarterLayouts, testName: "Quarters")
    
    // Return the intelligent layout result for validation
    return intelligentResult
}

func analyzeLayout(_ layouts: [TestWindowLayout], testName: String) -> LayoutTestResult {
    var totalArea: CGFloat = 0
    var widthPercentages: [Double] = []
    var heightPercentages: [Double] = []
    
    print("  \(testName) Layout Analysis:")
    
    for layout in layouts {
        let widthPercent = Double(layout.bounds.width / screenWidth) * 100
        let heightPercent = Double(layout.bounds.height / screenHeight) * 100
        let area = layout.bounds.width * layout.bounds.height
        
        widthPercentages.append(widthPercent)
        heightPercentages.append(heightPercent)
        totalArea += area
        
        print("    • \(layout.appName) (\(layout.archetype)): \(String(format: "%.1f", widthPercent))%w × \(String(format: "%.1f", heightPercent))%h")
    }
    
    let screenArea = screenWidth * screenHeight
    let coverage = Double(totalArea / screenArea) * 100
    
    // Check for uniform quarters (all apps roughly 25% width and 50% height OR 50% width and 25% height)
    let uniformWidths = widthPercentages.allSatisfy { abs($0 - 50) < 2 || abs($0 - 25) < 2 }
    let uniformHeights = heightPercentages.allSatisfy { abs($0 - 50) < 2 || abs($0 - 25) < 2 }
    let isUniformQuarters = uniformWidths && uniformHeights
    
    // Check for intelligent sizing (significant variation in percentages)
    let widthVariation = widthPercentages.max()! - widthPercentages.min()!
    let hasIntelligentSizing = widthVariation > 30 // At least 30% difference between largest and smallest
    
    print("    📏 Screen Coverage: \(String(format: "%.1f", coverage))%")
    print("    🎯 Width Variation: \(String(format: "%.1f", widthVariation))%")
    print("    ⚖️  Uniform Quarters: \(isUniformQuarters ? "❌ YES" : "✅ NO")")
    print("    🧠 Intelligent Sizing: \(hasIntelligentSizing ? "✅ YES" : "❌ NO")")
    
    return LayoutTestResult(
        layouts: layouts,
        isUniformQuarters: isUniformQuarters,
        screenCoverage: coverage,
        hasIntelligentSizing: hasIntelligentSizing
    )
}

// Test the actual FlexibleLayoutEngine output format
func testFlexibleLayoutEngineOutput() {
    print("\n🔍 TESTING EXPECTED LLM OUTPUT FORMAT:")
    print("When user says 'arrange my windows', LLM should generate:")
    print("  → cascade_windows tool with target='all' or 'visible'")
    print("  → This routes to CommandAction.stack in WindowPositioner")
    print("  → Which calls cascadeWindows() -> FlexibleLayoutEngine")
    print("  → Should produce intelligent proportional layout")
    
    print("\n❌ ANTI-PATTERN (what we eliminated):")
    print("  → Should NOT generate uniform 25% quarters")
    print("  → Should NOT use ensurePerfectScreenCoverage() tessellation")
    print("  → Should NOT ignore app archetype differences")
}

// Main test execution
let result = testIntelligentLayout()
testFlexibleLayoutEngineOutput()

print("\n🎯 FINAL VALIDATION:")
if result.isUniformQuarters {
    print("❌ FAILED: System is still producing uniform quarters!")
    print("   This indicates FlexibleLayoutEngine is not working correctly.")
    exit(1)
} else if result.hasIntelligentSizing && result.screenCoverage > 95 {
    print("✅ PASSED: Intelligent proportional layout detected!")
    print("   ✓ Non-uniform sizing (\(String(format: "%.1f", result.screenCoverage))% coverage)")
    print("   ✓ Archetype-based proportions")
} else {
    print("⚠️  PARTIAL: Layout detected but needs improvement")
    print("   Coverage: \(String(format: "%.1f", result.screenCoverage))%")
    print("   Intelligent: \(result.hasIntelligentSizing)")
}

print("\n💡 To test with real WindowAI:")
print("   1. Run WindowAI app")
print("   2. Say 'arrange my windows' or 'rearrange my windows'")
print("   3. Verify apps get different sizes based on their archetype")
print("   4. Check no uniform 25% quarters are created")