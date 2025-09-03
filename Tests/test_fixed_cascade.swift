#!/usr/bin/env swift

import Foundation

print("🧪 TESTING FIXED CASCADE SYSTEM")
print("==============================")

// Test the exact scenario that failed
let allApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor"]
let originalUserIntent = "i want to code"

print("📱 Input apps: \(allApps.joined(separator: ", "))")
print("💬 Original user intent: '\(originalUserIntent)'")

// Test 1: Context Extraction
print("\n1️⃣ TESTING IMPROVED CONTEXT EXTRACTION:")

func extractContextFromTarget(_ target: String, userIntent: String?) -> String {
    // First check if there's a user intent that gives context clues
    if let intent = userIntent?.lowercased() {
        if intent.contains("code") || intent.contains("coding") || intent.contains("develop") || intent.contains("program") {
            return "coding"
        } else if intent.contains("design") || intent.contains("create") || intent.contains("art") {
            return "design"
        } else if intent.contains("research") || intent.contains("browse") || intent.contains("read") || intent.contains("study") {
            return "research"
        }
    }
    
    // Fallback to target analysis
    let targetLower = target.lowercased()
    if targetLower.contains("cod") || targetLower.contains("develop") {
        return "coding"
    }
    
    return "general"
}

let context = extractContextFromTarget("visible", userIntent: originalUserIntent)
print("  Target: 'visible'")
print("  User Intent: '\(originalUserIntent)'")
print("  Extracted Context: '\(context)' ✅")

// Test 2: Updated Priority System
print("\n2️⃣ TESTING UPDATED PRIORITY SYSTEM:")

func getContextPriority(app: String, context: String) -> Int {
    let appLower = app.lowercased()
    
    switch context {
    case let ctx where ctx.contains("cod"):
        // Coding: Prefer Cursor over Xcode, Terminal essential
        if appLower.contains("cursor") { return 100 }
        if appLower.contains("terminal") { return 90 }
        if appLower.contains("arc") { return 80 }
        if appLower.contains("xcode") { return 70 } // Lower than Cursor
        return 10
        
    default:
        // Even for general contexts, prefer modern tools
        if appLower.contains("cursor") { return 65 } // Higher than Xcode even in general
        if appLower.contains("terminal") { return 60 }
        if appLower.contains("arc") { return 55 }
        if appLower.contains("xcode") { return 50 } // Lower priority in general
        return 30
    }
}

print("  Priorities for context '\(context)':")
for app in allApps {
    let priority = getContextPriority(app: app, context: context)
    print("    \(app): \(priority)")
}

// Test 3: Full App Selection Process
print("\n3️⃣ TESTING FULL APP SELECTION PROCESS:")

func calculateRelevanceScore(app: String, context: String) -> Double {
    let appLower = app.lowercased()
    
    if context.contains("cod") {
        if appLower.contains("cursor") || appLower.contains("xcode") || appLower.contains("code") {
            return 10.0 // Primary code editors
        }
        if appLower.contains("terminal") || appLower.contains("iterm") {
            return 8.0 // Essential for coding
        }
        if appLower.contains("arc") || appLower.contains("safari") || appLower.contains("chrome") {
            return 6.0 // Documentation/research
        }
        if appLower.contains("finder") || appLower.contains("spotify") {
            return 2.0 // Peripheral
        }
        return 1.0 // Irrelevant
    } else {
        return 5.0 // Neutral relevance for non-coding
    }
}

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

// Simulate filtering out irrelevant apps and selecting top apps
let relevantApps = sortedApps.filter { $0.relevanceScore >= 6.0 } // Only keep highly relevant apps
let selectedApps = Array(relevantApps.prefix(3)).map { $0.name }

print("\n  📱 Highly relevant apps (score >= 6.0): \(relevantApps.map { $0.name }.joined(separator: ", "))")
print("  ✅ Final selection (top 3): \(selectedApps.joined(separator: ", "))")

// Test 4: Primary App Selection
print("\n4️⃣ TESTING PRIMARY APP SELECTION:")

func findBestPrimaryApp(from apps: [String], context: String) -> String? {
    let priorities = apps.map { app -> (app: String, score: Double) in
        let appLower = app.lowercased()
        let score: Double
        
        if context.contains("cod") {
            if appLower.contains("cursor") { score = 100.0 }
            else if appLower.contains("xcode") { score = 80.0 }
            else { score = 0.0 }
        } else {
            // Even for general contexts, prefer Cursor
            if appLower.contains("cursor") { score = 90.0 }
            else if appLower.contains("xcode") { score = 80.0 }
            else { score = 0.0 }
        }
        
        return (app: app, score: score)
    }
    
    return priorities.max(by: { $0.score < $1.score })?.app
}

let primaryApp = findBestPrimaryApp(from: selectedApps, context: context)
print("  Primary app for context '\(context)': \(primaryApp ?? "none") ✅")

// Test 5: Role Assignments
print("\n5️⃣ TESTING CASCADE ROLE ASSIGNMENTS:")

enum CascadeRole {
    case primary, sideColumn, peekLayer, corner
}

func assignRole(app: String, isPrimary: Bool) -> CascadeRole {
    let appLower = app.lowercased()
    
    if isPrimary {
        return .primary
    } else if appLower.contains("terminal") {
        return .sideColumn // Text Stream archetype
    } else if appLower.contains("arc") || appLower.contains("browser") {
        return .peekLayer // Content Canvas archetype
    } else {
        return .corner // Default for others
    }
}

print("  Role assignments:")
for app in selectedApps {
    let isPrimary = (app == primaryApp)
    let role = assignRole(app: app, isPrimary: isPrimary)
    print("    📱 \(app) → \(role) \(isPrimary ? "(PRIMARY)" : "")")
}

// Test 6: Verification
print("\n✅ VERIFICATION:")
let expectedApps = ["Cursor", "Terminal", "Arc"]
let expectedPrimary = "Cursor"
let expectedContext = "coding"

let appsMatch = Set(selectedApps) == Set(expectedApps)
let primaryMatch = primaryApp == expectedPrimary
let contextMatch = context == expectedContext

print("  Apps selected correctly: \(appsMatch ? "✅" : "❌") (expected: \(expectedApps.joined(separator: ", ")), got: \(selectedApps.joined(separator: ", ")))")
print("  Primary app correct: \(primaryMatch ? "✅" : "❌") (expected: \(expectedPrimary), got: \(primaryApp ?? "none"))")
print("  Context detected correctly: \(contextMatch ? "✅" : "❌") (expected: \(expectedContext), got: \(context))")

let allCorrect = appsMatch && primaryMatch && contextMatch
print("\n🎯 OVERALL RESULT: \(allCorrect ? "✅ ALL FIXES WORKING" : "❌ ISSUES REMAIN")")

if allCorrect {
    print("\n🎉 SUCCESS! The fixes address all the issues:")
    print("   • Context now properly extracted from 'i want to code' → 'coding'")
    print("   • Cursor now prioritized over Xcode in all contexts")
    print("   • Smart filtering selects only relevant apps")
    print("   • Cursor correctly assigned as primary")
    print("   • Layout should now be: Cursor 70%, Terminal 25% right, Arc peek")
}