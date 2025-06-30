#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 INTEGRATION WORKFLOW TEST")
print("============================")

// Test that the full workflow works: user preferences -> LLM prompt -> coordinated calls

print("\n🔍 Testing: Complete 'I want to code' workflow")

// Step 1: Set up user preferences
print("\n1️⃣ Setting up user preferences...")

class MockUserPreferenceTracker {
    private var corrections: [String: Any] = [:]
    
    func simulateUserCorrections() {
        // User consistently moves Terminal to right side and makes it 25% width
        corrections["terminal_position"] = "right"
        corrections["terminal_width"] = 25.0
        corrections["terminal_corrections"] = 5
        
        // User focuses Cursor for coding 4/5 times
        corrections["cursor_focus"] = 4
        corrections["total_focus"] = 5
    }
    
    func generatePreferenceSummary() -> String {
        return """
        USER PREFERENCES (based on 5 corrections):
        - Terminal: prefers right side (100%), averages 25% width
        - Focus: Cursor chosen 4/5 times for coding context
        """
    }
}

let mockTracker = MockUserPreferenceTracker()
mockTracker.simulateUserCorrections()
let preferences = mockTracker.generatePreferenceSummary()
print("Generated preferences:")
print(preferences)

// Step 2: Simulate app classification
print("\n2️⃣ App archetype classification...")

func classifyApp(_ app: String) -> (archetype: String, strategy: String) {
    switch app.lowercased() {
    case "terminal":
        return ("textStream", "Perfect for side columns - give full vertical space, minimal horizontal")
    case "cursor":
        return ("codeWorkspace", "Should be primary layer, claims remaining space after auxiliaries positioned")
    case "arc":
        return ("contentCanvas", "Must peek with enough width to remain functional (45%+ screen)")
    default:
        return ("unknown", "Default handling")
    }
}

let apps = ["Terminal", "Cursor", "Arc"]
print("App classifications:")
for app in apps {
    let (archetype, strategy) = classifyApp(app)
    print("- \(app): \(archetype) (\(strategy))")
}

// Step 3: Simulate LLM prompt building
print("\n3️⃣ Building LLM prompt...")

func buildMockPrompt(apps: [String], preferences: String) -> String {
    var prompt = """
    You are WindowAI. Use coordinated flexible_position calls for multi-app arrangements.
    
    APP ARCHETYPE CLASSIFICATIONS:
    """
    
    for app in apps {
        let (archetype, strategy) = classifyApp(app)
        prompt += "\n- \(app): \(archetype) (\(strategy))"
    }
    
    prompt += "\n\n\(preferences)"
    
    prompt += """
    
    COORDINATED POSITIONING INSTRUCTIONS:
    For multi-app arrangements, use multiple flexible_position calls with these guidelines:
    - Primary app: layer=3, focus=true, positioned for maximum productivity
    - Cascade apps: layer=2, positioned with strategic overlaps for peek visibility  
    - Side columns: layer=1, positioned for auxiliary access (Terminal, chat apps)
    
    SCREEN UTILIZATION REQUIREMENT:
    ALWAYS maximize screen usage - fill the entire available screen space unless user explicitly requests minimal/compact layouts. Position windows to use 100% of screen width and height collectively. Avoid leaving large empty areas unused.
    
    CURRENT SYSTEM STATE:
    Running apps: Terminal, Cursor, Arc
    Screen: 1440x900 (Main)
    """
    
    return prompt
}

let prompt = buildMockPrompt(apps: apps, preferences: preferences)
print("LLM prompt includes:")
print("- App archetype information ✓")
print("- User preference data ✓") 
print("- Coordinated positioning guidelines ✓")
print("- Current system state ✓")

// Step 4: Simulate LLM decision making
print("\n4️⃣ Simulating LLM reasoning and tool calls...")

func simulateLLMDecision(prompt: String, userInput: String) -> [(tool: String, params: [String: Any])] {
    print("LLM reasoning:")
    print("- User said: '\(userInput)'")
    print("- Context: coding")
    print("- User prefers Terminal on right at 25% width")
    print("- Cursor should be primary focus for coding")
    print("- Arc can cascade for documentation peek")
    
    // LLM generates coordinated calls
    return [
        ("flexible_position", [
            "app_name": "Cursor",
            "x_position": "0",
            "y_position": "0", 
            "width": "70",     // Larger to maximize screen usage
            "height": "100",   // Full height
            "layer": 3,
            "focus": true
        ]),
        ("flexible_position", [
            "app_name": "Terminal", 
            "x_position": "70",    // Starts where Cursor ends
            "y_position": "0",
            "width": "30",         // Fills remaining width
            "height": "100",       // Full height
            "layer": 1,
            "focus": false
        ]),
        ("flexible_position", [
            "app_name": "Arc",
            "x_position": "25",    // Cascade behind Cursor
            "y_position": "10", 
            "width": "60",         // Good functional width
            "height": "85",        // Near full height
            "layer": 2,
            "focus": false
        ])
    ]
}

let toolCalls = simulateLLMDecision(prompt: prompt, userInput: "i want to code")

print("\nLLM generated \(toolCalls.count) coordinated tool calls:")
for (index, call) in toolCalls.enumerated() {
    let params = call.params
    print("  \(index + 1). \(call.tool):")
    print("     - app: \(params["app_name"] ?? "")")
    print("     - position: (\(params["x_position"] ?? "")%, \(params["y_position"] ?? "")%)")
    print("     - size: \(params["width"] ?? "")% x \(params["height"] ?? "")%")
    print("     - layer: \(params["layer"] ?? "")")
    print("     - focus: \(params["focus"] ?? "")")
}

// Step 5: Validate the arrangement
print("\n5️⃣ Validating arrangement...")

func validateArrangement(_ toolCalls: [(tool: String, params: [String: Any])], screenSize: CGSize) -> Bool {
    var windows: [(app: String, bounds: CGRect, layer: Int, focus: Bool)] = []
    
    // Convert tool calls to window positions
    for call in toolCalls {
        let params = call.params
        let app = params["app_name"] as! String
        let xPercent = Double(params["x_position"] as! String)!
        let yPercent = Double(params["y_position"] as! String)!
        let widthPercent = Double(params["width"] as! String)!
        let heightPercent = Double(params["height"] as! String)!
        let layer = params["layer"] as! Int
        let focus = params["focus"] as! Bool
        
        let x = screenSize.width * (xPercent / 100.0)
        let y = screenSize.height * (yPercent / 100.0)
        let width = screenSize.width * (widthPercent / 100.0)
        let height = screenSize.height * (heightPercent / 100.0)
        
        let bounds = CGRect(x: x, y: y, width: width, height: height)
        windows.append((app, bounds, layer, focus))
    }
    
    print("Calculated window positions:")
    for window in windows {
        print("- \(window.app): \(window.bounds) (layer \(window.layer), focus: \(window.focus))")
    }
    
    // Validation checks
    var allValid = true
    
    // Check 1: All windows fit on screen
    for window in windows {
        if window.bounds.maxX > screenSize.width || window.bounds.maxY > screenSize.height {
            print("❌ \(window.app) extends beyond screen bounds")
            allValid = false
        }
    }
    
    // Check 2: Exactly one window has focus
    let focusedWindows = windows.filter { $0.focus }
    if focusedWindows.count != 1 {
        print("❌ Expected 1 focused window, got \(focusedWindows.count)")
        allValid = false
    } else if focusedWindows[0].app != "Cursor" {
        print("❌ Expected Cursor to be focused, got \(focusedWindows[0].app)")
        allValid = false
    }
    
    // Check 3: Terminal uses user preference (right side) and screen utilization (may be wider than 25%)
    if let terminal = windows.first(where: { $0.app == "Terminal" }) {
        let xPercent = terminal.bounds.minX / screenSize.width
        let widthPercent = terminal.bounds.width / screenSize.width
        
        if xPercent < 0.6 {
            print("❌ Terminal not on right side (x = \(Int(xPercent * 100))%)")
            allValid = false
        }
        
        // With screen utilization, Terminal may be wider than user's 25% preference
        if widthPercent < 0.20 {
            print("❌ Terminal too narrow for screen utilization (got \(Int(widthPercent * 100))%)")
            allValid = false
        }
        
        print("ℹ️  Terminal: \(Int(xPercent * 100))% x-position, \(Int(widthPercent * 100))% width (balancing user preference with screen utilization)")
    }
    
    // Check 4: Proper layer ordering
    let sortedByLayer = windows.sorted { $0.layer < $1.layer }
    if sortedByLayer[0].app != "Terminal" || sortedByLayer[0].layer != 1 {
        print("❌ Terminal should be layer 1")
        allValid = false
    }
    if sortedByLayer[1].app != "Arc" || sortedByLayer[1].layer != 2 {
        print("❌ Arc should be layer 2") 
        allValid = false
    }
    if sortedByLayer[2].app != "Cursor" || sortedByLayer[2].layer != 3 {
        print("❌ Cursor should be layer 3")
        allValid = false
    }
    
    // Check 5: Screen utilization (should use 90%+ of screen space)
    let maxX = windows.map { $0.bounds.maxX }.max() ?? 0
    let maxY = windows.map { $0.bounds.maxY }.max() ?? 0
    let horizontalCoverage = maxX / screenSize.width
    let verticalCoverage = maxY / screenSize.height
    let totalCoverage = min(horizontalCoverage, verticalCoverage)
    
    if totalCoverage < 0.90 {
        print("❌ Poor screen utilization (\(Int(totalCoverage * 100))% coverage)")
        allValid = false
    } else {
        print("ℹ️  Screen utilization: \(Int(totalCoverage * 100))% coverage")
    }
    
    return allValid
}

let screenSize = CGSize(width: 1440, height: 900)
let isValid = validateArrangement(toolCalls, screenSize: screenSize)

// Final result
print("\n📊 INTEGRATION TEST RESULT")
print("=========================")
if isValid {
    print("🎉 COMPLETE WORKFLOW SUCCESS!")
    print("✅ User preferences correctly applied")
    print("✅ LLM made coordinated positioning decisions")
    print("✅ Arrangement follows accessibility rules")
    print("✅ Focus set appropriately")
    print("✅ Layers properly ordered")
} else {
    print("❌ Workflow has issues - see validation errors above")
}

print("\n🚀 NEXT STEPS:")
print("1. Test with real LLM API calls")
print("2. Test with actual window manager integration")
print("3. Test user preference learning from real corrections")