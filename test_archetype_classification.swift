#!/usr/bin/env swift

import Foundation

print("🔍 TESTING ARCHETYPE CLASSIFICATION")
print("===================================")

// Simulate the classification logic
func classifyApp(_ appName: String) -> String {
    let normalizedName = appName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Direct matches from database
    let archetypeDatabase: [String: String] = [
        "terminal": "textStream",
        "iterm": "textStream", 
        "iterm2": "textStream",
        "arc": "contentCanvas",
        "safari": "contentCanvas",
        "chrome": "contentCanvas",
        "cursor": "codeWorkspace",
        "xcode": "codeWorkspace",
        "finder": "glanceableMonitor"
    ]
    
    print("  📱 Testing: '\(appName)' → normalized: '\(normalizedName)'")
    
    // Direct match
    if let archetype = archetypeDatabase[normalizedName] {
        print("    ✅ Direct match: \(archetype)")
        return archetype
    }
    
    // Fuzzy matching
    for (knownApp, archetype) in archetypeDatabase {
        if normalizedName.contains(knownApp) || knownApp.contains(normalizedName) {
            print("    ✅ Fuzzy match '\(knownApp)': \(archetype)")
            return archetype
        }
    }
    
    // Pattern-based classification
    if normalizedName.contains("terminal") || normalizedName.contains("console") {
        print("    ✅ Pattern match (terminal): textStream")
        return "textStream"
    }
    
    if normalizedName.contains("browser") || normalizedName.contains("web") {
        print("    ✅ Pattern match (browser): contentCanvas")
        return "contentCanvas"
    }
    
    if normalizedName.contains("code") || normalizedName.contains("editor") {
        print("    ✅ Pattern match (code): codeWorkspace")
        return "codeWorkspace"
    }
    
    print("    ❓ Default: contentCanvas")
    return "contentCanvas"
}

// Test the apps from the log
let testApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor", "Messages"]

print("\n📊 CLASSIFICATION RESULTS:")
for app in testApps {
    let result = classifyApp(app)
    print("  \(app) → \(result)")
}

print("\n🎯 FOCUS ON TERMINAL:")
let terminalResults = [
    ("Terminal", classifyApp("Terminal")),
    ("terminal", classifyApp("terminal")),
    ("TERMINAL", classifyApp("TERMINAL")),
    ("Terminal.app", classifyApp("Terminal.app"))
]

for (input, result) in terminalResults {
    let expected = result == "textStream" ? "✅" : "❌"
    print("  '\(input)' → \(result) \(expected)")
}

print("\n💡 IF TERMINAL IS GETTING contentCanvas:")
print("   It means the app name might not be exactly 'Terminal'")
print("   OR there's a bug in the classification logic")
print("   OR the role assignment is wrong even with correct archetype")

// Test potential different app names
let potentialNames = ["Terminal", "Apple Terminal", "com.apple.Terminal", "Terminal.app", "OSX Terminal"]
print("\n🔍 TESTING POTENTIAL APP NAMES:")
for name in potentialNames {
    let result = classifyApp(name)
    print("  '\(name)' → \(result)")
}