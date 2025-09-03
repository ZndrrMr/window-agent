#!/usr/bin/env swift

import Foundation

print("🤖 LLM VARIABILITY TEST FOR CODING LAYOUT")
print("=========================================")
print("Testing 'i want to code' command multiple times to check LLM consistency")
print("Requirement: Terminal should be ≤30% focused, ≤25% unfocused")
print()

struct LLMTestRun {
    let runNumber: Int
    let command: String
    let expectedApps: [String]
    let terminalMaxPercent: Double
    let description: String
}

let testRuns = [
    LLMTestRun(
        runNumber: 1,
        command: "i want to code",
        expectedApps: ["Xcode", "Terminal", "Arc"],
        terminalMaxPercent: 30.0,
        description: "Basic coding setup request"
    ),
    LLMTestRun(
        runNumber: 2, 
        command: "set up my coding environment",
        expectedApps: ["Xcode", "Terminal", "Arc"],
        terminalMaxPercent: 30.0,
        description: "Alternative phrasing for coding setup"
    ),
    LLMTestRun(
        runNumber: 3,
        command: "i want to code in swift",
        expectedApps: ["Xcode", "Terminal", "Arc"],
        terminalMaxPercent: 30.0,
        description: "Language-specific coding request"
    ),
    LLMTestRun(
        runNumber: 4,
        command: "open my development workspace",
        expectedApps: ["Xcode", "Terminal", "Arc"],
        terminalMaxPercent: 30.0,
        description: "Workspace-focused request"
    ),
    LLMTestRun(
        runNumber: 5,
        command: "i want to code",
        expectedApps: ["Xcode", "Terminal", "Arc"],
        terminalMaxPercent: 30.0,
        description: "Repeat of run 1 to test consistency"
    )
]

print("📋 TEST SCENARIOS:")
for run in testRuns {
    print("  \(run.runNumber). '\(run.command)' - \(run.description)")
}

print("\n🎯 TERMINAL WIDTH REQUIREMENTS:")
print("  • Terminal focused: ≤30%")
print("  • Terminal unfocused: ≤25%")
print("  • Arc functional width: ≥500px")
print("  • Full screen usage: ≥95%")

// Simulate LLM responses - in real test, this would call actual LLM
func simulateLLMResponse(for command: String, run: Int) -> (focusedApp: String, layout: [(app: String, width: Double, height: Double)]) {
    // Simulate some variability in LLM responses
    let variations = [
        // Current broken implementation
        (focusedApp: "Terminal", layout: [
            (app: "Xcode", width: 0.30, height: 0.85),
            (app: "Arc", width: 0.45, height: 0.80),
            (app: "Terminal", width: 0.50, height: 1.0) // TOO WIDE!
        ]),
        // Xcode-focused variant
        (focusedApp: "Xcode", layout: [
            (app: "Xcode", width: 0.60, height: 0.90),
            (app: "Arc", width: 0.45, height: 0.80),
            (app: "Terminal", width: 0.30, height: 0.85) // STILL TOO WIDE!
        ]),
        // Another Terminal-focused variant
        (focusedApp: "Terminal", layout: [
            (app: "Xcode", width: 0.35, height: 0.85),
            (app: "Arc", width: 0.40, height: 0.80),
            (app: "Terminal", width: 0.45, height: 1.0) // TOO WIDE!
        ])
    ]
    
    // Use modulo to cycle through variations and add some randomness
    let index = (run - 1) % variations.count
    return variations[index]
}

print("\n🧪 RUNNING MULTIPLE LLM TESTS:")
print("=============================")

var allTestsPassed = true
var terminalWidthFailures: [String] = []
var functionalityFailures: [String] = []

for testRun in testRuns {
    print("\n🔄 RUN \(testRun.runNumber): '\(testRun.command)'")
    print("   \(testRun.description)")
    
    let response = simulateLLMResponse(for: testRun.command, run: testRun.runNumber)
    
    print("   📱 LLM Response:")
    print("     Focused app: \(response.focusedApp)")
    
    var runPassed = true
    var terminal: (app: String, width: Double, height: Double)?
    
    for app in response.layout {
        let widthPercent = app.width * 100
        let pixels = Int(app.width * 1440) // Assuming 1440px screen
        let focusIcon = (app.app == response.focusedApp) ? "🎯" : "👁️"
        
        print("     \(focusIcon) \(app.app): \(String(format: "%.0f", widthPercent))% (\(pixels)px)")
        
        if app.app == "Terminal" {
            terminal = app
        }
    }
    
    print("   🧪 Validation:")
    
    // Test 1: Terminal width requirement
    if let term = terminal {
        let terminalPercent = term.width * 100
        let isFocused = term.app == response.focusedApp
        let maxAllowed = isFocused ? 30.0 : 25.0
        let focusStatus = isFocused ? "focused" : "unfocused"
        
        if terminalPercent <= maxAllowed {
            print("     ✅ Terminal width: \(String(format: "%.0f", terminalPercent))% (≤\(maxAllowed)% for \(focusStatus))")
        } else {
            print("     ❌ Terminal TOO WIDE: \(String(format: "%.0f", terminalPercent))% (exceeds \(maxAllowed)% for \(focusStatus))")
            runPassed = false
            terminalWidthFailures.append("Run \(testRun.runNumber): \(String(format: "%.0f", terminalPercent))% (limit: \(maxAllowed)%)")
        }
    }
    
    // Test 2: Arc functional width
    if let arc = response.layout.first(where: { $0.app == "Arc" }) {
        let arcPixels = Int(arc.width * 1440)
        if arcPixels >= 500 {
            print("     ✅ Arc functional: \(arcPixels)px (≥500px)")
        } else {
            print("     ❌ Arc too narrow: \(arcPixels)px (<500px)")
            runPassed = false
            functionalityFailures.append("Run \(testRun.runNumber): Arc only \(arcPixels)px")
        }
    }
    
    // Test 3: Screen usage
    let maxWidth = response.layout.map { $0.width }.max() ?? 0
    let screenUsage = maxWidth * 100
    if screenUsage >= 95 {
        print("     ✅ Screen usage: \(String(format: "%.0f", screenUsage))%")
    } else {
        print("     ❌ Wasted space: \(String(format: "%.0f", screenUsage))% used")
        runPassed = false
        functionalityFailures.append("Run \(testRun.runNumber): Only \(String(format: "%.0f", screenUsage))% screen used")
    }
    
    // Test 4: Expected apps present
    let presentApps = Set(response.layout.map { $0.app })
    let expectedApps = Set(testRun.expectedApps)
    if presentApps.isSuperset(of: expectedApps) {
        print("     ✅ Expected apps present: \(expectedApps.joined(separator: ", "))")
    } else {
        let missing = expectedApps.subtracting(presentApps)
        print("     ❌ Missing apps: \(missing.joined(separator: ", "))")
        runPassed = false
        functionalityFailures.append("Run \(testRun.runNumber): Missing apps \(missing)")
    }
    
    if !runPassed {
        allTestsPassed = false
        print("   ❌ RUN \(testRun.runNumber) FAILED")
    } else {
        print("   ✅ RUN \(testRun.runNumber) PASSED")
    }
}

print("\n📊 OVERALL TEST RESULTS")
print("=======================")

if allTestsPassed {
    print("🎉 ALL \(testRuns.count) RUNS PASSED!")
    print("The LLM and layout system consistently meet requirements")
} else {
    print("❌ SOME RUNS FAILED - LLM/Layout system needs fixes")
    
    if !terminalWidthFailures.isEmpty {
        print("\n🔥 TERMINAL WIDTH VIOLATIONS:")
        for failure in terminalWidthFailures {
            print("   • \(failure)")
        }
    }
    
    if !functionalityFailures.isEmpty {
        print("\n🔧 FUNCTIONALITY ISSUES:")
        for failure in functionalityFailures {
            print("   • \(failure)")
        }
    }
}

let passCount = testRuns.count - (terminalWidthFailures.count + functionalityFailures.count)
let successRate = Double(passCount) / Double(testRuns.count) * 100

print("\n📈 SUCCESS METRICS:")
print("   Runs passed: \(passCount)/\(testRuns.count)")
print("   Success rate: \(String(format: "%.0f", successRate))%")
print("   Terminal width failures: \(terminalWidthFailures.count)")
print("   Functionality failures: \(functionalityFailures.count)")

if successRate < 100 {
    print("\n🚀 REQUIRED FIXES:")
    print("1. Update FlexiblePositioning.swift Terminal widths:")
    print("   • Terminal focused: 30% (currently 50%)")
    print("   • Terminal unfocused: 25% (currently 30%)")
    print("2. Test again with updated implementation")
    print("3. Ensure consistent behavior across multiple LLM calls")
}

print("\n🎯 NEXT: Fix FlexiblePositioning.swift and retest")