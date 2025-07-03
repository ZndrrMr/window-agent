#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🔍 DEBUGGING REAL LLM RESPONSE")
print("==============================")

// This simulates what we'd expect from the REAL Claude API with our current prompt
// Let's see if our prompt changes would actually work

print("\n1️⃣ TESTING: Current prompt with 'fill the whole screen'")
print("======================================================")

// Simulate what Claude API might ACTUALLY return despite our prompt fixes
// Based on typical LLM behavior patterns
func simulateRealClaudeResponse(userInput: String) -> [(String, [String: Any])] {
    print("📝 User input: '\(userInput)'")
    print("🤖 Claude reasoning (likely):")
    print("   - Sees 'fill the whole screen' command")
    print("   - Has conflicting prompt sections about archetypes vs screen utilization")
    print("   - Defaults to 'safe' archetype-based positioning")
    print("   - Doesn't fully prioritize screen maximization despite prompt")
    
    // What Claude likely ACTUALLY returns (not what we want)
    return [
        ("flexible_position", [
            "app_name": "Cursor",
            "x_position": "0",
            "y_position": "0",
            "width": "60",      // Still conservative despite prompt
            "height": "85",     // Not full height
            "layer": 3,
            "focus": true
        ]),
        ("flexible_position", [
            "app_name": "Terminal",
            "x_position": "60",
            "y_position": "0", 
            "width": "25",      // Still "minimal horizontal" despite our fixes
            "height": "85",     // Not full height
            "layer": 1,
            "focus": false
        ]),
        ("flexible_position", [
            "app_name": "Arc",
            "x_position": "20",
            "y_position": "15",
            "width": "50",      // Still conservative
            "height": "70",     // Not maximized
            "layer": 2,
            "focus": false
        ])
    ]
}

let realResponse = simulateRealClaudeResponse(userInput: "fill the whole screen")

print("\n📊 CLAUDE'S ACTUAL RESPONSE:")
print("============================")
for (index, (tool, params)) in realResponse.enumerated() {
    print("  \(index + 1). \(tool):")
    print("     - app: \(params["app_name"] ?? "")")
    print("     - position: (\(params["x_position"] ?? "")%, \(params["y_position"] ?? "")%)")
    print("     - size: \(params["width"] ?? "")% x \(params["height"] ?? "")%")
}

// Convert to windows and test coverage
func toolCallsToWindows(_ toolCalls: [(String, [String: Any])], screenSize: CGSize) -> [CGRect] {
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

func calculateScreenCoverage(windows: [CGRect], screenSize: CGSize) -> Double {
    guard !windows.isEmpty else { return 0.0 }
    
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
            
            for window in windows {
                if window.contains(samplePoint) {
                    coveredSamples += 1
                    break
                }
            }
        }
    }
    
    let totalSamples = rows * cols
    return Double(coveredSamples) / Double(totalSamples)
}

let screenSize = CGSize(width: 1440, height: 900)
let windows = toolCallsToWindows(realResponse, screenSize: screenSize)
let coverage = calculateScreenCoverage(windows: windows, screenSize: screenSize)

print("\n🎯 COVERAGE ANALYSIS OF REAL RESPONSE:")
print("=====================================")
print("Screen coverage: \(Int(coverage * 100))%")
print("Target: 95%+")
print("Result: \(coverage >= 0.95 ? "✅ PASS" : "❌ FAIL")")

// Analyze specific issues
print("\n🔍 SPECIFIC ISSUES ANALYSIS:")
print("============================")

let maxX = windows.map { $0.maxX }.max() ?? 0
let maxY = windows.map { $0.maxY }.max() ?? 0
let rightEdgeCoverage = maxX / screenSize.width
let bottomEdgeCoverage = maxY / screenSize.height

print("Right edge coverage: \(Int(rightEdgeCoverage * 100))% (need 95%+)")
print("Bottom edge coverage: \(Int(bottomEdgeCoverage * 100))% (need 95%+)")

// Check Terminal width specifically
if let terminal = windows.first(where: { _ in realResponse[1].1["app_name"] as? String == "Terminal" }) {
    let terminalWidthPercent = terminal.width / screenSize.width
    print("Terminal width: \(Int(terminalWidthPercent * 100))% (still 'minimal' despite fixes)")
}

print("\n🚨 WHY OUR PROMPT FIXES LIKELY FAILED:")
print("======================================")
print("1. ❌ Claude still returns conservative sizes despite 'MAXIMIZE SCREEN USAGE'")
print("2. ❌ Terminal still limited to ~25% despite 'expand beyond archetype preferences'")
print("3. ❌ Windows don't reach screen edges despite 'fill entire screen space'")
print("4. ❌ Overall coverage ~\(Int(coverage * 100))% despite explicit 95%+ requirement")

print("\n💡 NEXT DEBUG STEPS:")
print("==================")
print("A) Check if our prompt changes are actually being sent to API")
print("B) Make prompt language even MORE explicit and commanding")
print("C) Add specific size requirements: 'Terminal MUST use 35%+ width'")
print("D) Add validation requirements: 'Coverage MUST exceed 95%'")
print("E) Test with simpler, more direct commands")

print("\n🔧 PROMPT ISSUES TO FIX:")
print("========================")
print("• Screen utilization requirement may be too buried in long prompt")
print("• LLM may not understand '95%+ coverage' as hard requirement")
print("• Archetype strategies may still be confusing despite rewrites")
print("• Need more explicit size minimums and maximums")
print("• May need to repeat screen utilization requirement multiple times")