#!/usr/bin/env swift

import Foundation

print("🔍 LLM TOOL CALL ANALYSIS")
print("========================")
print("Testing what the LLM actually decides vs what we expect")
print()

// STEP 1: Test the LLM's actual tool call decisions
print("📋 EXPECTED BEHAVIOR FOR 'i want to code':")
print("1. Context should be 'coding' (from user_intent parameter)")
print("2. Arc and Xcode should get SAME CASCADE SIZE")
print("3. Arc should cascade FROM Xcode position")
print("4. Terminal should be ≤30% width")
print()

// Expected cascade sizes for Arc and Xcode
struct ExpectedCascade {
    let app: String
    let width: Double
    let height: Double
    let x: Double
    let y: Double
    let shouldBeSameSize: Bool
}

let expectedArrangement = [
    ExpectedCascade(app: "Xcode", width: 0.55, height: 0.90, x: 0.0, y: 0.0, shouldBeSameSize: true),
    ExpectedCascade(app: "Arc", width: 0.55, height: 0.90, x: 0.45, y: 0.10, shouldBeSameSize: true), // SAME SIZE as Xcode
    ExpectedCascade(app: "Terminal", width: 0.30, height: 1.0, x: 0.70, y: 0.0, shouldBeSameSize: false)
]

print("💡 KEY INSIGHT: Arc and Xcode should have IDENTICAL CASCADE SIZES")
print("   Xcode: 55% width, 90% height")
print("   Arc:   55% width, 90% height (SAME SIZE for proper cascade)")
print("   Only position differs: Arc offset by (45%, 10%) from Xcode")
print()

print("🚨 ACTUAL PROBLEM: LLM probably making different size decisions")
print("   - If Arc gets smaller size than Xcode = wrong cascade")
print("   - If Terminal gets >30% width = wrong constraint")
print("   - If positions don't cascade properly = gap issues")
print()

// Test function to analyze LLM tool calls
func analyzeLLMToolCall(_ toolCall: [String: Any]) -> Bool {
    print("🔧 ANALYZING LLM TOOL CALL:")
    
    guard let toolName = toolCall["name"] as? String else {
        print("❌ No tool name found")
        return false
    }
    
    print("   Tool: \(toolName)")
    
    guard let args = toolCall["arguments"] as? [String: Any] else {
        print("❌ No arguments found")
        return false
    }
    
    // Check for cascade_windows tool
    if toolName == "cascade_windows" {
        return analyzeCascadeToolCall(args)
    }
    
    return false
}

func analyzeCascadeToolCall(_ args: [String: Any]) -> Bool {
    var issues: [String] = []
    var successes: [String] = []
    
    // Check user_intent preservation
    if let userIntent = args["user_intent"] as? String {
        if userIntent.lowercased().contains("code") {
            successes.append("✅ user_intent preserved: '\(userIntent)'")
        } else {
            issues.append("❌ user_intent wrong: '\(userIntent)' (should contain 'code')")
        }
    } else {
        issues.append("❌ user_intent missing from tool call")
    }
    
    // Check window arrangements
    if let arrangements = args["arrangements"] as? [[String: Any]] {
        return analyzeWindowArrangements(arrangements, issues: &issues, successes: &successes)
    } else {
        issues.append("❌ No arrangements found in tool call")
    }
    
    // Print results
    for success in successes {
        print("   \(success)")
    }
    for issue in issues {
        print("   \(issue)")
    }
    
    return issues.isEmpty
}

func analyzeWindowArrangements(_ arrangements: [[String: Any]], issues: inout [String], successes: inout [String]) -> Bool {
    var xcodeArrangement: [String: Any]?
    var arcArrangement: [String: Any]?
    var terminalArrangement: [String: Any]?
    
    // Parse arrangements
    for arrangement in arrangements {
        guard let window = arrangement["window"] as? String else { continue }
        
        switch window.lowercased() {
        case "xcode":
            xcodeArrangement = arrangement
        case "arc":
            arcArrangement = arrangement
        case "terminal":
            terminalArrangement = arrangement
        default:
            break
        }
    }
    
    // Analyze Xcode and Arc cascade sizes
    if let xcode = xcodeArrangement, let arc = arcArrangement {
        let cascadeCorrect = analyzeCascadeSizes(xcode: xcode, arc: arc, issues: &issues, successes: &successes)
        if !cascadeCorrect {
            return false
        }
    } else {
        if xcodeArrangement == nil { issues.append("❌ Xcode arrangement missing") }
        if arcArrangement == nil { issues.append("❌ Arc arrangement missing") }
    }
    
    // Analyze Terminal width constraint
    if let terminal = terminalArrangement {
        analyzeTerminalWidth(terminal, issues: &issues, successes: &successes)
    }
    
    return issues.isEmpty
}

func analyzeCascadeSizes(xcode: [String: Any], arc: [String: Any], issues: inout [String], successes: inout [String]) -> Bool {
    // Extract Xcode size
    guard let xcodeSize = xcode["size"] as? [String: Any],
          let xcodeWidth = xcodeSize["width"] as? Double,
          let xcodeHeight = xcodeSize["height"] as? Double else {
        issues.append("❌ Cannot parse Xcode size")
        return false
    }
    
    // Extract Arc size
    guard let arcSize = arc["size"] as? [String: Any],
          let arcWidth = arcSize["width"] as? Double,
          let arcHeight = arcSize["height"] as? Double else {
        issues.append("❌ Cannot parse Arc size")
        return false
    }
    
    // Check if sizes are the same (allowing 5% tolerance)
    let widthDiff = abs(xcodeWidth - arcWidth)
    let heightDiff = abs(xcodeHeight - arcHeight)
    
    if widthDiff <= 0.05 && heightDiff <= 0.05 {
        successes.append("✅ CASCADE SIZES CORRECT: Xcode(\(xcodeWidth)×\(xcodeHeight)) ≈ Arc(\(arcWidth)×\(arcHeight))")
    } else {
        issues.append("❌ CASCADE SIZES WRONG: Xcode(\(xcodeWidth)×\(xcodeHeight)) ≠ Arc(\(arcWidth)×\(arcHeight))")
        issues.append("   Width diff: \(widthDiff), Height diff: \(heightDiff)")
        return false
    }
    
    // Check cascade positioning
    analyzeCascadePositioning(xcode: xcode, arc: arc, issues: &issues, successes: &successes)
    
    return true
}

func analyzeCascadePositioning(xcode: [String: Any], arc: [String: Any], issues: inout [String], successes: inout [String]) {
    // Extract positions
    guard let xcodePos = xcode["position"] as? [String: Any],
          let xcodeX = xcodePos["x"] as? Double,
          let xcodeY = xcodePos["y"] as? Double else {
        issues.append("❌ Cannot parse Xcode position")
        return
    }
    
    guard let arcPos = arc["position"] as? [String: Any],
          let arcX = arcPos["x"] as? Double,
          let arcY = arcPos["y"] as? Double else {
        issues.append("❌ Cannot parse Arc position")
        return
    }
    
    // Check if Arc cascades from Xcode (offset positioning)
    let expectedArcX = xcodeX + 0.45  // Arc should start where Xcode overlaps
    let expectedArcY = xcodeY + 0.10  // Slight vertical offset
    
    let xDiff = abs(arcX - expectedArcX)
    let yDiff = abs(arcY - expectedArcY)
    
    if xDiff <= 0.05 && yDiff <= 0.05 {
        successes.append("✅ CASCADE POSITIONING CORRECT: Arc offset properly from Xcode")
    } else {
        issues.append("❌ CASCADE POSITIONING WRONG:")
        issues.append("   Xcode: (\(xcodeX), \(xcodeY))")
        issues.append("   Arc: (\(arcX), \(arcY)) - Expected: (\(expectedArcX), \(expectedArcY))")
    }
}

func analyzeTerminalWidth(_ terminal: [String: Any], issues: inout [String], successes: inout [String]) {
    guard let terminalSize = terminal["size"] as? [String: Any],
          let terminalWidth = terminalSize["width"] as? Double else {
        issues.append("❌ Cannot parse Terminal size")
        return
    }
    
    if terminalWidth <= 0.30 {
        successes.append("✅ TERMINAL WIDTH CORRECT: \(terminalWidth) ≤ 30%")
    } else {
        issues.append("❌ TERMINAL WIDTH WRONG: \(terminalWidth) > 30% (violates requirement)")
    }
}

print("🧪 TEST FRAMEWORK READY")
print("To use this, capture the actual LLM tool call from 'i want to code' and analyze it:")
print()
print("Example usage:")
print("let toolCall = [\"name\": \"cascade_windows\", \"arguments\": [...]]")
print("let isCorrect = analyzeLLMToolCall(toolCall)")
print()
print("🎯 This will tell us EXACTLY what the LLM is deciding wrong")