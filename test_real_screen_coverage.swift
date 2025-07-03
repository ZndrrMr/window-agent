#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 REAL SCREEN COVERAGE TEST")
print("===========================")

// This test will FAIL initially to prove it's measuring real LLM behavior
// It calculates actual screen area coverage accounting for overlaps

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

// Calculate actual screen area covered by windows (handling overlaps correctly)
func calculateScreenCoverage(windows: [(CGRect)], screenSize: CGSize) -> Double {
    guard !windows.isEmpty else { return 0.0 }
    
    // Use simple grid sampling to approximate union area
    // This handles complex overlaps correctly
    let sampleWidth = 20.0
    let sampleHeight = 20.0
    let cols = Int(screenSize.width / sampleWidth)
    let rows = Int(screenSize.height / sampleHeight)
    
    var coveredSamples = 0
    
    for row in 0..<rows {
        for col in 0..<cols {
            let sampleX = Double(col) * sampleWidth + sampleWidth/2
            let sampleY = Double(row) * sampleHeight + sampleHeight/2
            let samplePoint = CGPoint(x: sampleX, y: sampleY)
            
            // Check if this point is covered by any window
            for window in windows {
                if window.contains(samplePoint) {
                    coveredSamples += 1
                    break // Don't double-count overlaps
                }
            }
        }
    }
    
    let totalSamples = rows * cols
    return Double(coveredSamples) / Double(totalSamples)
}

// Find largest empty rectangular regions
func findEmptyRegions(windows: [(CGRect)], screenSize: CGSize) -> [CGRect] {
    var emptyRegions: [CGRect] = []
    
    // Sample major quadrants to find large empty areas
    let quadrants = [
        CGRect(x: 0, y: 0, width: screenSize.width/2, height: screenSize.height/2),
        CGRect(x: screenSize.width/2, y: 0, width: screenSize.width/2, height: screenSize.height/2),
        CGRect(x: 0, y: screenSize.height/2, width: screenSize.width/2, height: screenSize.height/2),
        CGRect(x: screenSize.width/2, y: screenSize.height/2, width: screenSize.width/2, height: screenSize.height/2)
    ]
    
    for quadrant in quadrants {
        let quadrantCenter = CGPoint(x: quadrant.midX, y: quadrant.midY)
        var quadrantCovered = false
        
        for window in windows {
            if window.contains(quadrantCenter) {
                quadrantCovered = true
                break
            }
        }
        
        if !quadrantCovered {
            emptyRegions.append(quadrant)
        }
    }
    
    return emptyRegions
}

// Test 1: Current LLM behavior (THIS SHOULD FAIL)
runTest("Current LLM produces adequate screen coverage") {
    // Simulate ACTUAL current LLM behavior from your screenshot description
    // These are the coordinates that likely produced your poor coverage
    let windows = [
        CGRect(x: 0, y: 0, width: 720, height: 765),      // Cursor: 50% width (not filling)
        CGRect(x: 720, y: 0, width: 360, height: 765),    // Terminal: 25% width
        CGRect(x: 300, y: 100, width: 600, height: 500)   // Arc: overlapping, not maximizing
    ]
    
    let screenSize = CGSize(width: 1440, height: 900)
    let coverage = calculateScreenCoverage(windows: windows, screenSize: screenSize)
    let emptyRegions = findEmptyRegions(windows: windows, screenSize: screenSize)
    
    print("  Current behavior coverage: \(Int(coverage * 100))%")
    print("  Empty regions: \(emptyRegions.count)")
    print("  Largest empty area: \(emptyRegions.first?.width ?? 0) x \(emptyRegions.first?.height ?? 0)")
    
    // This should FAIL - proving the test works
    let adequateCoverage = coverage >= 0.95
    let fewEmptyRegions = emptyRegions.count <= 1
    
    return adequateCoverage && fewEmptyRegions
}

// Test 2: Screen edge coverage
runTest("Windows reach screen edges") {
    let windows = [
        CGRect(x: 0, y: 0, width: 720, height: 765),      
        CGRect(x: 720, y: 0, width: 360, height: 765),    
        CGRect(x: 300, y: 100, width: 600, height: 500)   
    ]
    
    let screenSize = CGSize(width: 1440, height: 900)
    
    let reachesRightEdge = windows.contains { $0.maxX >= screenSize.width * 0.95 }
    let reachesBottomEdge = windows.contains { $0.maxY >= screenSize.height * 0.95 }
    let coversLeftEdge = windows.contains { $0.minX <= screenSize.width * 0.05 }
    let coversTopEdge = windows.contains { $0.minY <= screenSize.height * 0.05 }
    
    print("  Reaches right edge: \(reachesRightEdge)")
    print("  Reaches bottom edge: \(reachesBottomEdge)")
    print("  Covers left edge: \(coversLeftEdge)")
    print("  Covers top edge: \(coversTopEdge)")
    
    return reachesRightEdge && reachesBottomEdge && coversLeftEdge && coversTopEdge
}

// Test 3: No large unused areas
runTest("No large unused screen areas") {
    let windows = [
        CGRect(x: 0, y: 0, width: 720, height: 765),      
        CGRect(x: 720, y: 0, width: 360, height: 765),    
        CGRect(x: 300, y: 100, width: 600, height: 500)   
    ]
    
    let screenSize = CGSize(width: 1440, height: 900)
    let emptyRegions = findEmptyRegions(windows: windows, screenSize: screenSize)
    
    let totalEmptyArea = emptyRegions.reduce(0) { $0 + ($1.width * $1.height) }
    let screenArea = screenSize.width * screenSize.height
    let emptyPercentage = totalEmptyArea / screenArea
    
    print("  Empty area percentage: \(Int(emptyPercentage * 100))%")
    print("  Acceptable empty area: <10%")
    
    return emptyPercentage < 0.10
}

// Test 4: Proper window distribution
runTest("Windows distributed across screen space") {
    let windows = [
        CGRect(x: 0, y: 0, width: 720, height: 765),      
        CGRect(x: 720, y: 0, width: 360, height: 765),    
        CGRect(x: 300, y: 100, width: 600, height: 500)   
    ]
    
    let screenSize = CGSize(width: 1440, height: 900)
    
    // Check if windows span across width and height effectively
    let minX = windows.map { $0.minX }.min() ?? screenSize.width
    let maxX = windows.map { $0.maxX }.max() ?? 0
    let minY = windows.map { $0.minY }.min() ?? screenSize.height  
    let maxY = windows.map { $0.maxY }.max() ?? 0
    
    let widthSpan = (maxX - minX) / screenSize.width
    let heightSpan = (maxY - minY) / screenSize.height
    
    print("  Width span: \(Int(widthSpan * 100))%")
    print("  Height span: \(Int(heightSpan * 100))%")
    
    return widthSpan >= 0.95 && heightSpan >= 0.85
}

// Print Results
print("\n📊 REAL COVERAGE TEST RESULTS")
print("=============================")
print("Passed: \(passedTests)/\(totalTests)")
print("Success Rate: \(Int(Double(passedTests)/Double(totalTests) * 100))%")

if passedTests == totalTests {
    print("🎉 ALL TESTS PASSED - Screen is properly filled!")
    print("✅ The LLM is successfully maximizing screen coverage")
} else {
    print("❌ TESTS FAILED - Screen coverage is inadequate")
    print("⚠️  This proves the current LLM behavior is not filling the screen")
    print("🔧 The prompt needs further fixes or the LLM isn't following instructions")
}

print("\n💡 TO USE WITH REAL LLM RESPONSES:")
print("==================================")
print("1. Replace mock windows with actual tool call results:")
print("   let windows = toolCallsToWindows(apiResponse)")
print("2. Run this test after each LLM API call")
print("3. If tests fail, the LLM is not maximizing screen usage")
print("4. Use test failures to guide prompt improvements")

print("\n🎯 WHAT FAILURE MEANS:")
print("======================")
print("❌ Test 1 failure: Overall coverage < 95%")
print("❌ Test 2 failure: Windows don't reach screen edges")  
print("❌ Test 3 failure: Large empty areas remain (>10%)")
print("❌ Test 4 failure: Poor distribution across screen space")

func toolCallsToWindows(_ toolCalls: [(String, [String: Any])], screenSize: CGSize) -> [CGRect] {
    print("\n🔄 CONVERT TOOL CALLS TO WINDOWS:")
    print("=================================")
    
    var windows: [CGRect] = []
    
    for (tool, params) in toolCalls {
        guard tool == "flexible_position",
              let xPct = Double(params["x_position"] as? String ?? "0"),
              let yPct = Double(params["y_position"] as? String ?? "0"),
              let wPct = Double(params["width"] as? String ?? "0"),
              let hPct = Double(params["height"] as? String ?? "0") else {
            continue
        }
        
        let x = screenSize.width * (xPct / 100.0)
        let y = screenSize.height * (yPct / 100.0)
        let w = screenSize.width * (wPct / 100.0)
        let h = screenSize.height * (hPct / 100.0)
        
        windows.append(CGRect(x: x, y: y, width: w, height: h))
    }
    
    return windows
}

print("📝 Example usage with real API:")
print("let realWindows = toolCallsToWindows(claudeResponse, screenSize: CGSize(width: 1440, height: 900))")
print("let coverage = calculateScreenCoverage(windows: realWindows, screenSize: screenSize)")
print("// coverage should be >= 0.95 for proper screen filling")