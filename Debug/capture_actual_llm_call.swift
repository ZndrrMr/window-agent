#!/usr/bin/env swift

import Foundation

print("🎯 CAPTURE ACTUAL LLM TOOL CALL")
print("===============================")
print("This helps us see exactly what the LLM is deciding for 'i want to code'")
print()

// Instructions for user
print("📋 STEPS TO DEBUG:")
print("1. Run the 'i want to code' command in WindowAI")
print("2. Look for debug output that shows the LLM tool call")
print("3. Copy the JSON here and run the analysis")
print()

print("🔍 WHAT TO LOOK FOR IN DEBUG OUTPUT:")
print("- Tool name: should be 'cascade_windows'")
print("- user_intent: should be 'i want to code'")
print("- arrangements array with Xcode, Arc, Terminal")
print()

print("🚨 SUSPECTED ISSUES:")
print("1. Arc and Xcode have DIFFERENT sizes (breaks cascade)")
print("2. Terminal gets >30% width")
print("3. Positions create side-by-side gaps instead of overlap")
print()

// Function to analyze any LLM tool call JSON
func analyzeCapturedLLMCall(_ jsonString: String) {
    print("🔧 ANALYZING CAPTURED LLM CALL:")
    print(String(repeating: "=", count: 35))
    
    guard let data = jsonString.data(using: .utf8),
          let toolCall = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        print("❌ Failed to parse JSON")
        return
    }
    
    // Extract tool name
    if let toolName = toolCall["name"] as? String {
        print("🛠️  Tool: \(toolName)")
    }
    
    // Extract arguments
    guard let args = toolCall["arguments"] as? [String: Any] else {
        print("❌ No arguments found")
        return
    }
    
    // Check user_intent
    if let userIntent = args["user_intent"] as? String {
        print("💭 User Intent: '\(userIntent)'")
        if userIntent.lowercased().contains("code") {
            print("   ✅ Contains 'code' - context should be 'coding'")
        } else {
            print("   ❌ Missing 'code' - context detection may fail")
        }
    } else {
        print("❌ user_intent missing - context will default to 'general'")
    }
    
    // Analyze arrangements
    guard let arrangements = args["arrangements"] as? [[String: Any]] else {
        print("❌ No arrangements found")
        return
    }
    
    print("\n📱 WINDOW ARRANGEMENTS:")
    print(String(repeating: "-", count: 25))
    
    var xcodeSize: (width: Double, height: Double)?
    var arcSize: (width: Double, height: Double)?
    var terminalSize: (width: Double, height: Double)?
    
    for (index, arrangement) in arrangements.enumerated() {
        guard let window = arrangement["window"] as? String else { continue }
        
        print("\n\(index + 1). \(window.uppercased()):")
        
        // Position
        if let position = arrangement["position"] as? [String: Any],
           let x = position["x"] as? Double,
           let y = position["y"] as? Double {
            print("   Position: (\(x), \(y))")
        }
        
        // Size
        if let size = arrangement["size"] as? [String: Any],
           let width = size["width"] as? Double,
           let height = size["height"] as? Double {
            print("   Size: \(width) × \(height) (\(Int(width * 100))% × \(Int(height * 100))%)")
            
            // Store sizes for comparison
            switch window.lowercased() {
            case "xcode": xcodeSize = (width, height)
            case "arc": arcSize = (width, height) 
            case "terminal": terminalSize = (width, height)
            default: break
            }
        }
        
        // Layer
        if let layer = arrangement["layer"] as? Int {
            print("   Layer: \(layer)")
        }
    }
    
    // Analysis
    print("\n🔍 ANALYSIS:")
    print(String(repeating: "-", count: 12))
    
    // Check if Arc and Xcode have same size (cascade requirement)
    if let xcode = xcodeSize, let arc = arcSize {
        let widthDiff = abs(xcode.width - arc.width)
        let heightDiff = abs(xcode.height - arc.height)
        
        if widthDiff <= 0.05 && heightDiff <= 0.05 {
            print("✅ CASCADE SIZES: Arc(\(arc.width)×\(arc.height)) ≈ Xcode(\(xcode.width)×\(xcode.height))")
        } else {
            print("❌ CASCADE BROKEN: Arc(\(arc.width)×\(arc.height)) ≠ Xcode(\(xcode.width)×\(xcode.height))")
            print("   🚨 This causes side-by-side tiling instead of cascade overlap!")
        }
    }
    
    // Check Terminal width
    if let terminal = terminalSize {
        if terminal.width <= 0.30 {
            print("✅ TERMINAL WIDTH: \(terminal.width) ≤ 30%")
        } else {
            print("❌ TERMINAL TOO WIDE: \(terminal.width) > 30% (violates requirement)")
        }
    }
    
    print("\n💡 KEY INSIGHT:")
    print("For proper cascade, Arc and Xcode must have IDENTICAL sizes!")
    print("Different sizes = side-by-side tiling = gaps and wrong layout")
}

// Example of how to use this
print("📝 EXAMPLE USAGE:")
print("Copy the LLM tool call JSON and run:")
print("analyzeCapturedLLMCall(\"\"\"")
print("{")
print("  \"name\": \"cascade_windows\",")
print("  \"arguments\": {")
print("    \"user_intent\": \"i want to code\",")
print("    \"arrangements\": [...")
print("    ]")
print("  }")
print("}")
print("\"\"\")")
print()
print("🎯 This will show EXACTLY what sizes the LLM is choosing!")