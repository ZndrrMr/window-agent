#!/usr/bin/env swift

import Foundation

print("🔍 DEBUGGING CASCADE SYSTEM ISSUES")
print("==================================")

// Test the exact scenario from the log
let allApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor"]
let context = "visible" // This was the context from the log

print("📱 Input apps: \(allApps.joined(separator: ", "))")
print("📝 Context: '\(context)'")

// Test 1: App Classification
print("\n1️⃣ TESTING APP CLASSIFICATION:")
func classifyApp(_ app: String) -> String {
    let appLower = app.lowercased()
    if appLower.contains("cursor") || appLower.contains("code") {
        return "Code Workspace"
    } else if appLower.contains("xcode") {
        return "Code Workspace"
    } else if appLower.contains("terminal") {
        return "Text Stream"
    } else if appLower.contains("arc") || appLower.contains("browser") {
        return "Content Canvas"
    } else if appLower.contains("finder") {
        return "Glanceable Monitor"
    } else if appLower.contains("display") {
        return "Content Canvas"
    }
    return "Unknown"
}

for app in allApps {
    let archetype = classifyApp(app)
    print("  📱 \(app) → \(archetype)")
}

// Test 2: Context Analysis
print("\n2️⃣ ANALYZING CONTEXT ISSUE:")
print("  Problem: Context is 'visible' not 'coding'")
print("  Impact: This bypasses coding-specific prioritization")

// Test 3: Smart Filtering Logic
print("\n3️⃣ TESTING SMART FILTERING LOGIC:")

func calculateRelevanceScore(app: String, context: String) -> Double {
    let appLower = app.lowercased()
    let contextLower = context.lowercased()
    
    // The problem: "visible" context doesn't match "cod" patterns
    if contextLower.contains("cod") {
        if appLower.contains("cursor") { return 10.0 }
        if appLower.contains("terminal") { return 8.0 }
        if appLower.contains("arc") { return 6.0 }
        if appLower.contains("xcode") { return 7.0 } // Lower than Cursor
        return 1.0
    } else {
        // For "visible" context, all apps get equal treatment
        return 5.0 // Neutral relevance
    }
}

func getContextPriority(app: String, context: String) -> Int {
    let appLower = app.lowercased()
    let contextLower = context.lowercased()
    
    if contextLower.contains("cod") {
        if appLower.contains("cursor") { return 100 }
        if appLower.contains("terminal") { return 90 }
        if appLower.contains("arc") { return 80 }
        if appLower.contains("xcode") { return 70 } // Lower priority
        return 10
    } else {
        // For non-coding contexts, default priority
        if appLower.contains("xcode") { return 60 } // Xcode gets higher default priority
        if appLower.contains("cursor") { return 55 }
        return 50
    }
}

print("  Relevance scores for context '\(context)':")
for app in allApps {
    let relevance = calculateRelevanceScore(app: app, context: context)
    let priority = getContextPriority(app: app, context: context)
    print("    \(app): relevance=\(relevance), priority=\(priority)")
}

// Test 4: App Selection Simulation
print("\n4️⃣ SIMULATING APP SELECTION:")

let appData = allApps.map { app in
    (
        name: app,
        relevanceScore: calculateRelevanceScore(app: app, context: context),
        priority: getContextPriority(app: app, context: context)
    )
}

let sortedApps = appData.sorted { first, second in
    if first.relevanceScore != second.relevanceScore {
        return first.relevanceScore > second.relevanceScore
    }
    return first.priority > second.priority
}

print("  Sorted by relevance + priority:")
for (index, appData) in sortedApps.enumerated() {
    print("    \(index + 1). \(appData.name) (relevance: \(appData.relevanceScore), priority: \(appData.priority))")
}

// Simulate selecting top 4
let selectedApps = Array(sortedApps.prefix(4)).map { $0.name }
print("\n  Selected top 4: \(selectedApps.joined(separator: ", "))")

// Test 5: Primary App Selection
print("\n5️⃣ TESTING PRIMARY APP SELECTION:")

func findBestPrimaryApp(from apps: [String], context: String) -> String? {
    let priorities = apps.map { app -> (app: String, score: Double) in
        let appLower = app.lowercased()
        let score: Double
        
        if context.contains("cod") {
            if appLower.contains("cursor") { score = 100.0 }
            else if appLower.contains("xcode") { score = 80.0 }
            else { score = 0.0 }
        } else {
            // For non-coding contexts, Xcode gets preference as established IDE
            if appLower.contains("xcode") { score = 90.0 }
            else if appLower.contains("cursor") { score = 85.0 }
            else { score = 0.0 }
        }
        
        return (app: app, score: score)
    }
    
    return priorities.max(by: { $0.score < $1.score })?.app
}

let primaryApp = findBestPrimaryApp(from: selectedApps, context: context)
print("  Primary app for context '\(context)': \(primaryApp ?? "none")")

// Test 6: Identify the Root Problems
print("\n🚨 ROOT PROBLEMS IDENTIFIED:")
print("  1. Context Mismatch:")
print("     • User said 'i want to code' but context became 'visible'")
print("     • Should be 'coding' context for proper prioritization")
print("  2. Default Prioritization:")
print("     • When context isn't 'coding', Xcode gets higher priority than Cursor")
print("     • This explains why Xcode was selected as primary")
print("  3. Filtering Logic:")
print("     • BetterDisplay and Cursor were filtered out")
print("     • Need to check why Cursor specifically was excluded")

// Test 7: Suggest Fixes
print("\n💡 REQUIRED FIXES:")
print("  1. Context Detection:")
print("     • 'i want to code' should map to 'coding' context, not 'visible'")
print("  2. App Prioritization:")
print("     • Even for non-coding contexts, Cursor should be preferred over Xcode")
print("     • Update priority scoring to favor modern tools")
print("  3. Filtering Review:")
print("     • Ensure Cursor is never filtered out when coding tools are needed")
print("     • BetterDisplay should be filtered out (correctly done)")

print("\n🎯 EXPECTED CORRECT BEHAVIOR:")
print("  Input: 'i want to code'")
print("  Context: 'coding' (not 'visible')")
print("  Selected: Cursor, Terminal, Arc")
print("  Primary: Cursor")
print("  Layout: Cursor 70%, Terminal 25% right, Arc peek")