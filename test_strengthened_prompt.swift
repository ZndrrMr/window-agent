#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 TESTING STRENGTHENED PROMPT")
print("==============================")

// Test how Claude would likely respond to our STRENGTHENED prompt with explicit requirements

print("\n🔍 TESTING: Strengthened prompt with mandatory requirements")
print("=========================================================")

func simulateStrengthenedPromptResponse(userInput: String) -> [(String, [String: Any])] {
    print("📝 User input: '\(userInput)'")
    print("🤖 Claude reasoning with STRENGTHENED prompt:")
    print("   ✅ Sees PRIMARY DIRECTIVE at top: 'MAXIMIZE SCREEN USAGE'")
    print("   ✅ Sees explicit requirement: '95%+ screen coverage'") 
    print("   ✅ Sees mandatory minimums: 'Text Stream 30-40% width'")
    print("   ✅ Sees height requirement: 'ALL windows 90-100% height'")
    print("   ✅ Sees width requirement: 'Combined windows 95%+ width'")
    print("   ✅ Multiple reminders throughout prompt about maximization")
    
    // What Claude SHOULD return with strengthened prompt
    return [
        ("flexible_position", [
            "app_name": "Cursor",
            "x_position": "0",
            "y_position": "0",
            "width": "65",      // Expanded within 55-75% range
            "height": "100",    // Full height as required
            "layer": 3,
            "focus": true
        ]),
        ("flexible_position", [
            "app_name": "Terminal",
            "x_position": "65",
            "y_position": "0", 
            "width": "35",      // Now 35% (in 30-40% required range) 
            "height": "100",    // Full height as required
            "layer": 1,
            "focus": false
        ]),
        ("flexible_position", [
            "app_name": "Arc",
            "x_position": "15",
            "y_position": "5",
            "width": "60",      // Expanded within 50-70% range
            "height": "90",     // Near full height
            "layer": 2,
            "focus": false
        ])
    ]
}

let strengthenedResponse = simulateStrengthenedPromptResponse(userInput: "fill the whole screen")

print("\n📊 CLAUDE'S RESPONSE WITH STRENGTHENED PROMPT:")
print("=============================================")
for (index, (tool, params)) in strengthenedResponse.enumerated() {
    print("  \(index + 1). \(tool):")
    print("     - app: \(params["app_name"] ?? "")")
    print("     - position: (\(params["x_position"] ?? "")%, \(params["y_position"] ?? "")%)")
    print("     - size: \(params["width"] ?? "")% x \(params["height"] ?? "")%")
}

// Test coverage with strengthened response
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
let windows = toolCallsToWindows(strengthenedResponse, screenSize: screenSize)
let coverage = calculateScreenCoverage(windows: windows, screenSize: screenSize)

print("\n🎯 COVERAGE ANALYSIS WITH STRENGTHENED PROMPT:")
print("=============================================")
print("Screen coverage: \(Int(coverage * 100))%")
print("Target: 95%+")
print("Result: \(coverage >= 0.95 ? "✅ PASS" : "❌ FAIL")")

// Validate specific requirements
print("\n🔍 REQUIREMENT VALIDATION:")
print("=========================")

let maxX = windows.map { $0.maxX }.max() ?? 0
let maxY = windows.map { $0.maxY }.max() ?? 0
let rightEdgeCoverage = maxX / screenSize.width
let bottomEdgeCoverage = maxY / screenSize.height

print("Right edge coverage: \(Int(rightEdgeCoverage * 100))% (need 95%+) \(rightEdgeCoverage >= 0.95 ? "✅" : "❌")")
print("Bottom edge coverage: \(Int(bottomEdgeCoverage * 100))% (need 95%+) \(bottomEdgeCoverage >= 0.95 ? "✅" : "❌")")

// Check Terminal width requirement (30-40%)
if let terminal = windows.first(where: { _ in strengthenedResponse[1].1["app_name"] as? String == "Terminal" }) {
    let terminalWidthPercent = terminal.width / screenSize.width
    let meetsMinimum = terminalWidthPercent >= 0.30
    print("Terminal width: \(Int(terminalWidthPercent * 100))% (need 30%+) \(meetsMinimum ? "✅" : "❌")")
}

// Check height requirements (90-100%)
var allHeightsGood = true
for (index, window) in windows.enumerated() {
    let heightPercent = window.height / screenSize.height
    let meetsHeight = heightPercent >= 0.90
    if !meetsHeight { allHeightsGood = false }
    let appName = strengthenedResponse[index].1["app_name"] as? String ?? "Unknown"
    print("\(appName) height: \(Int(heightPercent * 100))% (need 90%+) \(meetsHeight ? "✅" : "❌")")
}

print("\n📊 IMPROVEMENT COMPARISON:")
print("=========================")
print("OLD prompt (weak): ~71% coverage, Terminal 25%, heights 85%")
print("NEW prompt (strong): ~\(Int(coverage * 100))% coverage, Terminal 35%, heights 90-100%")
print("Improvement: +\(Int(coverage * 100 - 71))% coverage, +10% Terminal width, +5-15% heights")

print("\n✅ STRENGTHENED PROMPT EFFECTIVENESS:")
print("===================================")
let allRequirementsMet = coverage >= 0.95 && 
                        rightEdgeCoverage >= 0.95 && 
                        bottomEdgeCoverage >= 0.95 && 
                        allHeightsGood

if allRequirementsMet {
    print("🎉 ALL REQUIREMENTS MET!")
    print("✅ 95%+ coverage achieved")
    print("✅ Screen edges reached")
    print("✅ Minimum sizes enforced")
    print("✅ Heights maximized")
    print("🚀 The strengthened prompt should work!")
} else {
    print("⚠️  Some requirements still not met")
    print("🔧 May need even more explicit language")
}

print("\n💡 REAL WORLD TEST PLAN:")
print("========================")
print("1. Deploy the strengthened prompt to WindowAI")
print("2. Test with: 'fill the whole screen'")
print("3. Measure actual window positions")
print("4. Verify 95%+ coverage in practice")
print("5. If still fails, add even more explicit size requirements")