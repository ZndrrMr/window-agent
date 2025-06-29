#!/usr/bin/env swift

import Foundation

print("🎯 LIVE LLM DECISION TESTING")
print("============================")
print("This tests what the LLM actually decides for 'i want to code'")
print()

// Simulate the exact LLM tool call we should expect
let expectedToolCall: [String: Any] = [
    "name": "cascade_windows",
    "arguments": [
        "user_intent": "i want to code",
        "arrangements": [
            [
                "window": "Xcode",
                "position": ["x": 0.0, "y": 0.0],
                "size": ["width": 0.55, "height": 0.90],
                "layer": 3
            ],
            [
                "window": "Arc", 
                "position": ["x": 0.45, "y": 0.10],
                "size": ["width": 0.55, "height": 0.90], // SAME SIZE as Xcode for proper cascade
                "layer": 2
            ],
            [
                "window": "Terminal",
                "position": ["x": 0.70, "y": 0.0],
                "size": ["width": 0.30, "height": 1.0], // ≤30% width requirement
                "layer": 1
            ]
        ]
    ]
]

// Bad LLM decision example (what we might be getting)
let badToolCall: [String: Any] = [
    "name": "cascade_windows", 
    "arguments": [
        "user_intent": "i want to code",
        "arrangements": [
            [
                "window": "Terminal", // WRONG: Terminal focused instead of Xcode
                "position": ["x": 0.0, "y": 0.0],
                "size": ["width": 0.55, "height": 0.90],
                "layer": 3
            ],
            [
                "window": "Arc",
                "position": ["x": 0.55, "y": 0.0], // WRONG: Side-by-side instead of cascade
                "size": ["width": 0.30, "height": 0.80], // WRONG: Different size than primary
                "layer": 2  
            ],
            [
                "window": "Xcode",
                "position": ["x": 0.85, "y": 0.0], // WRONG: Relegated to corner
                "size": ["width": 0.15, "height": 0.80], // WRONG: Tiny size
                "layer": 1
            ]
        ]
    ]
]

func testLLMDecision(_ toolCall: [String: Any], label: String) -> Bool {
    print("\n🧪 TESTING: \(label)")
    print(String(repeating: "=", count: label.count + 10))
    
    guard let args = toolCall["arguments"] as? [String: Any] else {
        print("❌ No arguments found")
        return false
    }
    
    guard let arrangements = args["arrangements"] as? [[String: Any]] else {
        print("❌ No arrangements found") 
        return false
    }
    
    var issues: [String] = []
    var successes: [String] = []
    
    // Find arrangements
    var xcodeArr: [String: Any]?
    var arcArr: [String: Any]?
    var terminalArr: [String: Any]?
    
    for arr in arrangements {
        guard let window = arr["window"] as? String else { continue }
        switch window.lowercased() {
        case "xcode": xcodeArr = arr
        case "arc": arcArr = arr
        case "terminal": terminalArr = arr
        default: break
        }
    }
    
    // TEST 1: Focus priority (highest layer should be Xcode for coding)
    var focusedApp = ""
    var maxLayer = -1
    
    for arr in arrangements {
        if let window = arr["window"] as? String,
           let layer = arr["layer"] as? Int,
           layer > maxLayer {
            maxLayer = layer
            focusedApp = window
        }
    }
    
    if focusedApp.lowercased() == "xcode" {
        successes.append("✅ FOCUS CORRECT: Xcode has highest layer (\(maxLayer))")
    } else {
        issues.append("❌ FOCUS WRONG: \(focusedApp) focused instead of Xcode")
    }
    
    // TEST 2: Cascade sizes (Arc and Xcode should be same size)
    if let xcode = xcodeArr, let arc = arcArr {
        let sizesMatch = testCascadeSizes(xcode: xcode, arc: arc, issues: &issues, successes: &successes)
    } else {
        issues.append("❌ Missing Xcode or Arc arrangement")
    }
    
    // TEST 3: Terminal width constraint
    if let terminal = terminalArr {
        testTerminalWidth(terminal, issues: &issues, successes: &successes)
    }
    
    // TEST 4: Cascade positioning
    if let xcode = xcodeArr, let arc = arcArr {
        testCascadePositioning(xcode: xcode, arc: arc, issues: &issues, successes: &successes)
    }
    
    // Print results
    print("\n✅ SUCCESSES:")
    for success in successes {
        print("   \(success)")
    }
    
    if !issues.isEmpty {
        print("\n❌ ISSUES:")
        for issue in issues {
            print("   \(issue)")
        }
    }
    
    let isCorrect = issues.isEmpty
    print("\n📊 RESULT: \(isCorrect ? "✅ CORRECT" : "❌ INCORRECT") (\(successes.count) successes, \(issues.count) issues)")
    
    return isCorrect
}

func testCascadeSizes(xcode: [String: Any], arc: [String: Any], issues: inout [String], successes: inout [String]) -> Bool {
    guard let xcodeSize = xcode["size"] as? [String: Any],
          let xcodeW = xcodeSize["width"] as? Double,
          let xcodeH = xcodeSize["height"] as? Double else {
        issues.append("❌ Cannot parse Xcode size")
        return false
    }
    
    guard let arcSize = arc["size"] as? [String: Any],
          let arcW = arcSize["width"] as? Double, 
          let arcH = arcSize["height"] as? Double else {
        issues.append("❌ Cannot parse Arc size")
        return false
    }
    
    let widthDiff = abs(xcodeW - arcW)
    let heightDiff = abs(xcodeH - arcH)
    
    if widthDiff <= 0.05 && heightDiff <= 0.05 {
        successes.append("✅ CASCADE SIZES MATCH: Xcode(\(xcodeW)×\(xcodeH)) ≈ Arc(\(arcW)×\(arcH))")
        return true
    } else {
        issues.append("❌ CASCADE SIZES DIFFERENT: Xcode(\(xcodeW)×\(xcodeH)) ≠ Arc(\(arcW)×\(arcH))")
        issues.append("   This breaks cascade overlap! Arc should be same size as Xcode")
        return false
    }
}

func testTerminalWidth(_ terminal: [String: Any], issues: inout [String], successes: inout [String]) {
    guard let terminalSize = terminal["size"] as? [String: Any],
          let width = terminalSize["width"] as? Double else {
        issues.append("❌ Cannot parse Terminal width")
        return
    }
    
    if width <= 0.30 {
        successes.append("✅ TERMINAL WIDTH OK: \(width) ≤ 30%")
    } else {
        issues.append("❌ TERMINAL WIDTH TOO BIG: \(width) > 30%")
    }
}

func testCascadePositioning(xcode: [String: Any], arc: [String: Any], issues: inout [String], successes: inout [String]) {
    guard let xcodePos = xcode["position"] as? [String: Any],
          let xcodeX = xcodePos["x"] as? Double,
          let _ = xcodePos["y"] as? Double else {
        issues.append("❌ Cannot parse Xcode position")
        return
    }
    
    guard let arcPos = arc["position"] as? [String: Any],
          let arcX = arcPos["x"] as? Double,
          let _ = arcPos["y"] as? Double else {
        issues.append("❌ Cannot parse Arc position")
        return
    }
    
    // For proper cascade, Arc should overlap Xcode, not be side-by-side
    if arcX > xcodeX + 0.30 { // More than 30% offset = side-by-side tiling
        issues.append("❌ SIDE-BY-SIDE TILING: Arc at x=\(arcX), Xcode at x=\(xcodeX) (gap too big)")
        issues.append("   Should be overlapping cascade, not separate tiles")
    } else {
        successes.append("✅ CASCADE OVERLAP: Arc properly overlaps Xcode")
    }
}

// Run tests
print("🧪 TESTING EXPECTED (CORRECT) LLM DECISION:")
let expectedResult = testLLMDecision(expectedToolCall, label: "Expected Correct Decision")

print("\n" + String(repeating: "=", count: 50))

print("\n🚨 TESTING PROBLEMATIC LLM DECISION:")
let badResult = testLLMDecision(badToolCall, label: "Actual Problem Decision")

print("\n" + String(repeating: "=", count: 50))
print("\n📋 SUMMARY:")
print("Expected decision: \(expectedResult ? "✅ PASS" : "❌ FAIL")")
print("Problematic decision: \(badResult ? "✅ PASS" : "❌ FAIL") (should fail)")

print("\n🎯 TO DEBUG ACTUAL LLM:")
print("1. Run 'i want to code' command")
print("2. Capture the LLM tool call JSON")  
print("3. Run: testLLMDecision(actualToolCall, label: \"Actual LLM\")")
print("4. This will show EXACTLY what the LLM is deciding wrong")

print("\n💡 KEY CASCADE REQUIREMENT:")
print("Arc and Xcode MUST have identical sizes for proper cascade overlap!")
print("If they have different sizes, you get side-by-side tiling instead of cascade.")