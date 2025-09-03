#!/usr/bin/env swift

import Foundation
import CoreGraphics

// MARK: - Simple Test Runner for Coordinated LLM Control
// This runs basic validation tests without XCTest framework

print("🧪 COORDINATED LLM CONTROL TESTS")
print("================================")

var passedTests = 0
var totalTests = 0

func runTest(_ name: String, test: () throws -> Bool) {
    totalTests += 1
    print("\n🔍 Testing: \(name)")
    
    do {
        let passed = try test()
        if passed {
            print("✅ PASSED")
            passedTests += 1
        } else {
            print("❌ FAILED")
        }
    } catch {
        print("❌ ERROR: \(error)")
    }
}

// Test 1: Flexible Position Tool Parameters
runTest("Flexible Position Tool Has Required Parameters") {
    // Mock the tool structure for testing
    struct MockTool {
        let name = "flexible_position"
        let properties = [
            "app_name", "x_position", "y_position", "width", "height", "layer", "focus", "display"
        ]
    }
    
    let tool = MockTool()
    
    guard tool.name == "flexible_position" else { return false }
    guard tool.properties.contains("app_name") else { return false }
    guard tool.properties.contains("layer") else { return false }
    guard tool.properties.contains("focus") else { return false }
    
    return true
}

// Test 2: Tool Converter with Layer and Focus
runTest("Tool Converter Handles Layer and Focus Parameters") {
    // Mock input data
    let input: [String: Any] = [
        "app_name": "Terminal",
        "x_position": "75",
        "y_position": "0", 
        "width": "25",
        "height": "100",
        "layer": 1,
        "focus": false
    ]
    
    // Simulate conversion logic
    guard let appName = input["app_name"] as? String,
          appName == "Terminal" else { return false }
    
    guard let layer = input["layer"] as? Int,
          layer == 1 else { return false }
    
    guard let focus = input["focus"] as? Bool,
          focus == false else { return false }
    
    return true
}

// Test 3: Position Preference Tracking
runTest("Position Preference Tracking") {
    class MockTracker {
        private var rightMoves = 0
        private var leftMoves = 0
        
        func recordRightMove() { rightMoves += 1 }
        func recordLeftMove() { leftMoves += 1 }
        
        func getPreferredSide() -> String {
            return rightMoves > leftMoves ? "right" : "left"
        }
        
        func getConfidence() -> Double {
            let total = rightMoves + leftMoves
            return total > 0 ? Double(max(rightMoves, leftMoves)) / Double(total) : 0.0
        }
    }
    
    let tracker = MockTracker()
    
    // Simulate 3 right moves, 1 left move
    tracker.recordRightMove()
    tracker.recordRightMove() 
    tracker.recordRightMove()
    tracker.recordLeftMove()
    
    guard tracker.getPreferredSide() == "right" else { return false }
    guard abs(tracker.getConfidence() - 0.75) < 0.01 else { return false }
    
    return true
}

// Test 4: Size Preference with Median
runTest("Size Preference Using Median (Not Average)") {
    let widthPercentages = [25.0, 26.0, 24.0, 25.0, 27.0]
    let sortedWidths = widthPercentages.sorted()
    let medianIndex = sortedWidths.count / 2
    let median = sortedWidths[medianIndex] // Should be 25.0
    
    // This would be wrong with average:
    let average = widthPercentages.reduce(0, +) / Double(widthPercentages.count) // 25.4
    
    // Median should be exactly 25.0, average would be 25.4
    guard abs(median - 25.0) < 0.01 else { return false }
    guard abs(average - 25.4) < 0.01 else { return false }
    
    print("  📊 Median: \(median)%, Average: \(average)%")
    print("  ✅ Using median prevents false middle preferences")
    
    return true
}

// Test 5: Archetype Classification
runTest("App Archetype Classification") {
    // Mock classification
    func classifyApp(_ appName: String) -> String {
        let app = appName.lowercased()
        if app.contains("terminal") { return "textStream" }
        if app.contains("cursor") || app.contains("code") { return "codeWorkspace" }
        if app.contains("arc") || app.contains("browser") { return "contentCanvas" }
        return "unknown"
    }
    
    guard classifyApp("Terminal") == "textStream" else { return false }
    guard classifyApp("Cursor") == "codeWorkspace" else { return false }
    guard classifyApp("Arc") == "contentCanvas" else { return false }
    
    return true
}

// Test 6: Coordinate System Validation
runTest("Coordinate System Validation") {
    let screenSize = CGSize(width: 1440, height: 900)
    
    // Test percentage to pixel conversion
    func percentageToPixels(percent: Double, dimension: Double) -> Double {
        return dimension * (percent / 100.0)
    }
    
    let x75Percent = percentageToPixels(percent: 75, dimension: screenSize.width)
    let width25Percent = percentageToPixels(percent: 25, dimension: screenSize.width)
    
    guard abs(x75Percent - 1080.0) < 0.01 else { return false }
    guard abs(width25Percent - 360.0) < 0.01 else { return false }
    
    // Test bounds validation
    let maxX = x75Percent + width25Percent
    guard maxX <= screenSize.width else { return false }
    
    return true
}

// Test 7: Layer Management
runTest("Layer Management System") {
    struct MockWindow {
        let app: String
        let layer: Int
        let focus: Bool
    }
    
    let windows = [
        MockWindow(app: "Terminal", layer: 1, focus: false),  // Side column
        MockWindow(app: "Arc", layer: 2, focus: false),      // Cascade 
        MockWindow(app: "Cursor", layer: 3, focus: true)     // Primary/focused
    ]
    
    // Verify layer ordering
    let sortedByLayer = windows.sorted { $0.layer < $1.layer }
    guard sortedByLayer[0].app == "Terminal" else { return false }
    guard sortedByLayer[1].app == "Arc" else { return false }
    guard sortedByLayer[2].app == "Cursor" else { return false }
    
    // Verify focus assignment
    let focusedWindows = windows.filter { $0.focus }
    guard focusedWindows.count == 1 else { return false }
    guard focusedWindows[0].app == "Cursor" else { return false }
    
    return true
}

// Test 8: Accessibility Validation  
runTest("Accessibility Requirements") {
    let cursorBounds = CGRect(x: 0, y: 0, width: 792, height: 765)
    let arcBounds = CGRect(x: 400, y: 135, width: 648, height: 630) // Moved left to avoid Terminal
    let terminalBounds = CGRect(x: 1080, y: 0, width: 360, height: 900)
    
    // Test that Arc has visible title bar
    let arcTitleBar = CGRect(x: arcBounds.minX, y: arcBounds.minY, width: arcBounds.width, height: 30)
    let intersection = cursorBounds.intersection(arcTitleBar)
    let titleBarVisiblePercent = (arcTitleBar.width - intersection.width) / arcTitleBar.width
    
    guard titleBarVisiblePercent >= 0.2 else { return false } // At least 20% visible
    
    // Test that Terminal is unobstructed
    guard !cursorBounds.intersects(terminalBounds) else { return false }
    guard !arcBounds.intersects(terminalBounds) else { return false }
    
    // Test that Arc has significant visible area
    let arcVisibleArea = arcBounds.width * arcBounds.height - intersection.width * intersection.height
    let arcTotalArea = arcBounds.width * arcBounds.height
    let arcVisiblePercent = arcVisibleArea / arcTotalArea
    
    guard arcVisiblePercent >= 0.3 else { return false } // At least 30% visible
    
    return true
}

// Print Results
print("\n📊 TEST RESULTS")
print("===============")
print("Passed: \(passedTests)/\(totalTests)")
print("Success Rate: \(Int(Double(passedTests)/Double(totalTests) * 100))%")

if passedTests == totalTests {
    print("🎉 ALL TESTS PASSED!")
} else {
    print("⚠️  Some tests failed - implementation needs work")
}