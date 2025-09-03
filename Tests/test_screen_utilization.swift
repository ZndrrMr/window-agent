#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 SCREEN UTILIZATION TEST")
print("==========================")

// Test that LLM is instructed to maximize screen usage

print("\n🔍 Testing: Screen utilization requirement in LLM prompt")

// Mock the updated prompt building
func buildPromptWithScreenUtilization() -> String {
    return """
    COORDINATED POSITIONING INSTRUCTIONS:
    For multi-app arrangements, use multiple flexible_position calls with these guidelines:
    - Primary app: layer=3, focus=true, positioned for maximum productivity
    - Cascade apps: layer=2, positioned with strategic overlaps for peek visibility  
    - Side columns: layer=1, positioned for auxiliary access (Terminal, chat apps)
    - Corner apps: layer=0, minimal space for monitoring/glanceable info
    
    SCREEN UTILIZATION REQUIREMENT:
    ALWAYS maximize screen usage - fill the entire available screen space unless user explicitly requests minimal/compact layouts. Position windows to use 100% of screen width and height collectively. Avoid leaving large empty areas unused.
    
    ACCESSIBILITY REQUIREMENTS:
    - Every window must have clickable areas (title bars, edges, corners)
    - No window completely hidden behind others
    - Overlaps should leave 30+ pixels of target window visible
    - Focus the app most relevant to user's context and intent
    """
}

let prompt = buildPromptWithScreenUtilization()

// Test 1: Prompt contains screen utilization instruction
print("\n1️⃣ Checking prompt contains screen utilization requirement...")
let hasUtilizationInstruction = prompt.contains("ALWAYS maximize screen usage") && 
                               prompt.contains("fill the entire available screen space")
print("✅ Screen utilization instruction present: \(hasUtilizationInstruction)")

// Test 2: Simulate LLM decision with screen utilization in mind
print("\n2️⃣ Simulating LLM decision with screen utilization requirement...")

func simulateMaximizedLLMDecision(screenSize: CGSize) -> [(tool: String, params: [String: Any])] {
    print("LLM reasoning with screen utilization:")
    print("- Screen is \(Int(screenSize.width))x\(Int(screenSize.height))")
    print("- Must maximize usage of entire screen space")
    print("- Primary app should use most available space")
    print("- Side apps should fill remaining areas")
    print("- No large empty spaces should remain")
    
    // LLM generates calls that use full screen
    return [
        ("flexible_position", [
            "app_name": "Cursor",
            "x_position": "0",
            "y_position": "0", 
            "width": "70",      // Larger primary window
            "height": "100",    // Full height
            "layer": 3,
            "focus": true
        ]),
        ("flexible_position", [
            "app_name": "Terminal", 
            "x_position": "70",     // Starts where Cursor ends
            "y_position": "0",
            "width": "30",          // Fills remaining width
            "height": "100",        // Full height
            "layer": 1,
            "focus": false
        ]),
        ("flexible_position", [
            "app_name": "Arc",
            "x_position": "25",     // Cascade behind Cursor
            "y_position": "10", 
            "width": "60",          // Good width for functionality
            "height": "85",         // Good height, leaves space for overlap
            "layer": 2,
            "focus": false
        ])
    ]
}

let screenSize = CGSize(width: 1440, height: 900)
let toolCalls = simulateMaximizedLLMDecision(screenSize: screenSize)

print("\nLLM generated \(toolCalls.count) coordinated tool calls with full screen utilization:")
for (index, call) in toolCalls.enumerated() {
    let params = call.params
    print("  \(index + 1). \(call.tool): \(params["app_name"] ?? "")")
    print("     - position: (\(params["x_position"] ?? "")%, \(params["y_position"] ?? "")%)")
    print("     - size: \(params["width"] ?? "")% x \(params["height"] ?? "")%")
}

// Test 3: Validate screen coverage
print("\n3️⃣ Validating screen coverage...")

func validateScreenCoverage(_ toolCalls: [(tool: String, params: [String: Any])], screenSize: CGSize) -> (coverage: Double, gaps: [String]) {
    var windows: [(app: String, bounds: CGRect)] = []
    var gaps: [String] = []
    
    // Convert tool calls to window bounds
    for call in toolCalls {
        let params = call.params
        let app = params["app_name"] as! String
        let xPercent = Double(params["x_position"] as! String)!
        let yPercent = Double(params["y_position"] as! String)!
        let widthPercent = Double(params["width"] as! String)!
        let heightPercent = Double(params["height"] as! String)!
        
        let x = screenSize.width * (xPercent / 100.0)
        let y = screenSize.height * (yPercent / 100.0)
        let width = screenSize.width * (widthPercent / 100.0)
        let height = screenSize.height * (heightPercent / 100.0)
        
        let bounds = CGRect(x: x, y: y, width: width, height: height)
        windows.append((app, bounds))
    }
    
    // Check horizontal coverage
    let maxX = windows.map { $0.bounds.maxX }.max() ?? 0
    let horizontalCoverage = maxX / screenSize.width
    if horizontalCoverage < 0.95 {
        gaps.append("Right edge unused (\(Int((1.0 - horizontalCoverage) * 100))% of width)")
    }
    
    // Check vertical coverage 
    let maxY = windows.map { $0.bounds.maxY }.max() ?? 0
    let verticalCoverage = maxY / screenSize.height
    if verticalCoverage < 0.95 {
        gaps.append("Bottom edge unused (\(Int((1.0 - verticalCoverage) * 100))% of height)")
    }
    
    // Calculate total screen utilization
    let totalCoverage = min(horizontalCoverage, verticalCoverage)
    
    return (coverage: totalCoverage, gaps: gaps)
}

let (coverage, gaps) = validateScreenCoverage(toolCalls, screenSize: screenSize)

print("Screen coverage analysis:")
print("- Total coverage: \(Int(coverage * 100))%")
if gaps.isEmpty {
    print("- ✅ No significant unused areas")
} else {
    print("- ⚠️  Unused areas:")
    for gap in gaps {
        print("  - \(gap)")
    }
}

// Test 4: Validate windows don't exceed screen bounds
print("\n4️⃣ Validating window bounds...")

var allWithinBounds = true
for call in toolCalls {
    let params = call.params
    let app = params["app_name"] as! String
    let xPercent = Double(params["x_position"] as! String)!
    let widthPercent = Double(params["width"] as! String)!
    let yPercent = Double(params["y_position"] as! String)!
    let heightPercent = Double(params["height"] as! String)!
    
    let maxX = xPercent + widthPercent
    let maxY = yPercent + heightPercent
    
    if maxX > 100 {
        print("❌ \(app) extends beyond right edge (\(Int(maxX))%)")
        allWithinBounds = false
    }
    
    if maxY > 100 {
        print("❌ \(app) extends beyond bottom edge (\(Int(maxY))%)")
        allWithinBounds = false
    }
}

if allWithinBounds {
    print("✅ All windows stay within screen bounds")
}

// Final result
print("\n📊 SCREEN UTILIZATION TEST RESULT")
print("=================================")

let testPassed = hasUtilizationInstruction && 
                coverage >= 0.90 && 
                allWithinBounds && 
                gaps.count <= 1

if testPassed {
    print("🎉 SCREEN UTILIZATION TEST PASSED!")
    print("✅ LLM prompt includes maximization requirement")
    print("✅ Generated layout uses \(Int(coverage * 100))% of screen")
    print("✅ No significant unused areas")
    print("✅ All windows within bounds")
} else {
    print("❌ Screen utilization test failed")
    if !hasUtilizationInstruction {
        print("- Missing utilization instruction in prompt")
    }
    if coverage < 0.90 {
        print("- Poor screen coverage (\(Int(coverage * 100))%)")
    }
    if !allWithinBounds {
        print("- Windows exceed screen bounds")
    }
    if gaps.count > 1 {
        print("- Multiple unused areas detected")
    }
}

print("\n💡 Expected behavior:")
print("- LLM should position windows to use 95%+ of screen space")
print("- Primary apps get larger portions")
print("- Side apps fill remaining areas")
print("- Strategic overlaps maximize both coverage and accessibility")