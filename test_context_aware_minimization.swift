#!/usr/bin/env swift

/**
 * Test Context-Aware Minimization Logic
 * 
 * This simulates the "code" command with Steam, Music, Calendar, Messages
 * to verify that irrelevant apps are identified for minimization.
 */

import Foundation

// Mock the context-aware minimization logic
func identifyContextIrrelevantApps(apps: [String], userInput: String) -> [String] {
    let userInputLower = userInput.lowercased()
    var irrelevantApps: [String] = []
    
    // Define context patterns and their irrelevant apps
    let contextPatterns: [String: [String]] = [
        // Coding context patterns
        "cod": ["Steam", "Music", "Spotify", "Calendar", "Messages", "Mail", "Photos", "TV", "Podcasts"],
        "develop": ["Steam", "Music", "Spotify", "Calendar", "Messages", "Mail", "Photos", "TV", "Podcasts"],
        "program": ["Steam", "Music", "Spotify", "Calendar", "Messages", "Mail", "Photos", "TV", "Podcasts"],
    ]
    
    // Always irrelevant apps regardless of context
    let alwaysIrrelevantApps = ["Steam", "Activity Monitor", "Console", "Disk Utility"]
    
    // Find matching context pattern
    var contextIrrelevantApps: [String] = []
    for (pattern, apps) in contextPatterns {
        if userInputLower.contains(pattern) {
            contextIrrelevantApps = apps
            break
        }
    }
    
    // If no specific context found, use always irrelevant apps
    if contextIrrelevantApps.isEmpty {
        contextIrrelevantApps = alwaysIrrelevantApps
    }
    
    // Find apps that are both present and context-irrelevant
    let appSet = Set(apps)
    for app in contextIrrelevantApps {
        if appSet.contains(app) {
            irrelevantApps.append(app)
        }
    }
    
    // Limit minimization to avoid over-minimizing (keep at least 4-5 apps visible)
    let maxToMinimize = max(0, apps.count - 5)
    if irrelevantApps.count > maxToMinimize {
        irrelevantApps = Array(irrelevantApps.prefix(maxToMinimize))
    }
    
    return irrelevantApps
}

print("🧪 TESTING CONTEXT-AWARE MINIMIZATION")
print(String(repeating: "=", count: 50))

// Test case: User's actual scenario
let testApps = ["Cursor", "Arc", "Messages", "Xcode", "Calendar", "Figma", "Notion", "Music", "Claude", "Terminal", "Steam"]
let userCommand = "code"

print("📱 Unminimized apps: \(testApps.count)")
for (index, app) in testApps.enumerated() {
    print("  \(index + 1). \(app)")
}

print("\n🤖 User command: \"\(userCommand)\"")

let irrelevantApps = identifyContextIrrelevantApps(apps: testApps, userInput: userCommand)

print("\n🎯 CONTEXT-AWARE ANALYSIS:")
print("Apps to minimize: \(irrelevantApps.count)")
for app in irrelevantApps {
    print("  ❌ \(app) (not relevant for coding)")
}

print("\nApps to keep visible: \(testApps.count - irrelevantApps.count)")
let appsToKeep = testApps.filter { !irrelevantApps.contains($0) }
for app in appsToKeep {
    print("  ✅ \(app) (relevant for coding)")
}

print("\n📊 EXPECTED RESULTS:")
print("- Steam: ❌ Should be minimized (gaming, not coding)")  
print("- Music: ❌ Should be minimized (entertainment, not coding)")
print("- Calendar: ❌ Should be minimized (scheduling, not coding)")
print("- Messages: ❌ Should be minimized (communication, not coding)")
print("- Cursor: ✅ Should stay (primary IDE)")
print("- Terminal: ✅ Should stay (development tool)")
print("- Arc: ✅ Should stay (documentation/research)")
print("- Claude: ✅ Should stay (AI assistance)")
print("- Xcode: ✅ Should stay (secondary IDE)")

print("\n🎯 SUCCESS CRITERIA:")
if irrelevantApps.contains("Steam") && irrelevantApps.contains("Music") && irrelevantApps.contains("Calendar") && irrelevantApps.contains("Messages") {
    print("✅ PASS: All expected irrelevant apps identified for minimization")
} else {
    print("❌ FAIL: Some irrelevant apps were not identified")
}

if appsToKeep.contains("Cursor") && appsToKeep.contains("Terminal") && appsToKeep.contains("Claude") {
    print("✅ PASS: All core coding apps preserved")
} else {
    print("❌ FAIL: Some core coding apps would be minimized")
}

let finalWindowCount = appsToKeep.count
if finalWindowCount >= 4 && finalWindowCount <= 7 {
    print("✅ PASS: Final window count (\(finalWindowCount)) is optimal for layout")
} else {
    print("❌ FAIL: Final window count (\(finalWindowCount)) may cause layout issues")
}

print("\n" + String(repeating: "=", count: 50))
print("🎯 EXPECTED OUTCOME:")
print("With these minimizations, the LLM should be able to position")
print("\(finalWindowCount) coding-relevant apps with proper ≥40×40px visibility")
print("instead of trying to position all \(testApps.count) apps and failing.")