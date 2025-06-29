#!/usr/bin/env swift

import Foundation

print("🔍 COMPREHENSIVE CASCADE DIAGNOSTIC")
print("===================================")

// Simulate the complete "i want to code" flow
let userIntent = "i want to code"
let screenSize = (width: 1440.0, height: 900.0)
let availableApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor", "Messages"]

print("📝 INPUT:")
print("  User Intent: '\(userIntent)'")
print("  Screen Size: \(Int(screenSize.width))x\(Int(screenSize.height))")
print("  Available Apps: \(availableApps.joined(separator: ", "))")

// Test 1: Context Extraction
print("\n🎯 TEST 1: CONTEXT EXTRACTION")
func extractContextFromIntent(_ intent: String) -> String {
    let normalized = intent.lowercased()
    if normalized.contains("code") || normalized.contains("develop") || normalized.contains("program") {
        return "coding"
    }
    if normalized.contains("design") {
        return "design"
    }
    if normalized.contains("research") || normalized.contains("browse") {
        return "research"
    }
    return "general"
}

let extractedContext = extractContextFromIntent(userIntent)
let contextCorrect = extractedContext == "coding"
print("  Expected: 'coding'")
print("  Actual: '\(extractedContext)'")
print("  Status: \(contextCorrect ? "✅ CORRECT" : "❌ WRONG")")

// Test 2: App Classification
print("\n🎯 TEST 2: APP CLASSIFICATION")
func classifyApp(_ name: String) -> String {
    let normalized = name.lowercased()
    if ["terminal", "iterm", "console"].contains(normalized) { return "textStream" }
    if ["arc", "safari", "chrome", "firefox"].contains(normalized) { return "contentCanvas" }
    if ["cursor", "xcode", "vscode", "sublime"].contains(normalized) { return "codeWorkspace" }
    if ["finder", "spotify", "music"].contains(normalized) { return "glanceableMonitor" }
    return "unknown"
}

let expectedClassifications = [
    "Terminal": "textStream",
    "Arc": "contentCanvas", 
    "Cursor": "codeWorkspace",
    "Xcode": "codeWorkspace",
    "Finder": "glanceableMonitor"
]

var classificationIssues: [String] = []
for app in ["Terminal", "Arc", "Cursor", "Xcode", "Finder"] {
    let expected = expectedClassifications[app]!
    let actual = classifyApp(app)
    let correct = actual == expected
    print("  \(app): \(actual) \(correct ? "✅" : "❌")")
    if !correct {
        classificationIssues.append("\(app) classified as \(actual), expected \(expected)")
    }
}

// Test 3: App Filtering for Coding Context (Using Production Logic)
print("\n🎯 TEST 3: APP FILTERING FOR CODING")
func getRelevanceScore(app: String, context: String) -> Double {
    let normalized = app.lowercased()
    if context == "coding" {
        if normalized.contains("cursor") { return 10.0 }
        if normalized.contains("terminal") { return 9.0 }
        if normalized.contains("arc") { return 8.0 }
        if normalized.contains("xcode") { return 7.0 }
        if normalized.contains("finder") { return 3.0 }
        return 1.0
    }
    return 5.0
}

// SIMULATE PRODUCTION LOGIC: Smart exclusion when Cursor + Xcode both available
func selectAppsWithSmartExclusion(apps: [String], context: String, maxApps: Int = 4) -> [String] {
    let appData = apps.map { ($0, getRelevanceScore(app: $0, context: context)) }
        .sorted { $0.1 > $1.1 }
    
    let hasCursor = appData.contains { $0.0.lowercased().contains("cursor") }
    let hasXcode = appData.contains { $0.0.lowercased().contains("xcode") }
    
    var selectedApps: [String] = []
    
    for (app, score) in appData {
        if selectedApps.count >= maxApps { break }
        if score < 5.0 { continue }
        
        // SMART EXCLUSION: Skip Xcode if Cursor is available for clean 3-app coding layout
        if hasCursor && hasXcode && app.lowercased().contains("xcode") {
            continue // Skip Xcode to maintain optimal 3-window layout (Cursor + Terminal + Arc)
        }
        
        selectedApps.append(app)
    }
    
    return selectedApps
}

let relevantApps = selectAppsWithSmartExclusion(apps: availableApps, context: extractedContext, maxApps: 4)

let expectedSelection = ["Cursor", "Terminal", "Arc"] // Core coding apps
let actualSelection = Array(relevantApps)

print("  Expected: \(expectedSelection.joined(separator: ", "))")
print("  Actual: \(actualSelection.joined(separator: ", "))")

let selectionCorrect = Set(expectedSelection).isSubset(of: Set(actualSelection))
print("  Core apps selected: \(selectionCorrect ? "✅" : "❌")")

// Test 4: Role Assignment
print("\n🎯 TEST 4: ROLE ASSIGNMENT")
func getOptimalRole(app: String, archetype: String) -> String {
    switch archetype {
    case "textStream": return "sideColumn"
    case "codeWorkspace": return "primary" 
    case "contentCanvas": return "peekLayer"
    case "glanceableMonitor": return "corner"
    default: return "peekLayer"
    }
}

let expectedRoles = [
    "Cursor": "primary",
    "Terminal": "sideColumn", 
    "Arc": "peekLayer",
    "Finder": "corner"
]

var roleIssues: [String] = []
for app in ["Cursor", "Terminal", "Arc", "Finder"] {
    let archetype = classifyApp(app)
    let actualRole = getOptimalRole(app: app, archetype: archetype)
    let expectedRole = expectedRoles[app]!
    let correct = actualRole == expectedRole
    print("  \(app) (\(archetype)): \(actualRole) \(correct ? "✅" : "❌")")
    if !correct {
        roleIssues.append("\(app) assigned \(actualRole), expected \(expectedRole)")
    }
}

// Test 5: Sizing Calculations
print("\n🎯 TEST 5: SIZING CALCULATIONS")
func getOptimalSizing(archetype: String, role: String, windowCount: Int) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        let baseWidth = windowCount <= 2 ? 0.35 : windowCount == 3 ? 0.25 : 0.20
        return (width: baseWidth, height: 1.0)
    case ("codeWorkspace", "primary"):
        let baseWidth = windowCount <= 2 ? 0.80 : windowCount == 3 ? 0.70 : 0.65
        let baseHeight = windowCount <= 2 ? 0.90 : 0.85
        return (width: baseWidth, height: baseHeight)
    case ("contentCanvas", "peekLayer"):
        let baseWidth = windowCount <= 2 ? 0.55 : windowCount == 3 ? 0.45 : 0.40
        let baseHeight = windowCount <= 3 ? 0.45 : 0.35
        return (width: baseWidth, height: baseHeight)
    default:
        return (width: 0.40, height: 0.60)
    }
}

let windowCount = actualSelection.count
let expectedSizes = [
    "Cursor": (width: 0.70, height: 0.85),    // 70% primary for 3 windows
    "Terminal": (width: 0.25, height: 1.0),   // 25% side column for 3 windows  
    "Arc": (width: 0.45, height: 0.45)        // 45% peek layer for 3 windows
]

var sizingIssues: [String] = []
for app in ["Cursor", "Terminal", "Arc"] {
    let archetype = classifyApp(app) 
    let role = getOptimalRole(app: app, archetype: archetype)
    let actualSize = getOptimalSizing(archetype: archetype, role: role, windowCount: windowCount)
    let expectedSize = expectedSizes[app]!
    
    let widthMatch = abs(actualSize.width - expectedSize.width) < 0.01
    let heightMatch = abs(actualSize.height - expectedSize.height) < 0.01
    let correct = widthMatch && heightMatch
    
    print("  \(app): \(Int(actualSize.width * 100))%×\(Int(actualSize.height * 100))% \(correct ? "✅" : "❌")")
    if !correct {
        sizingIssues.append("\(app) sized \(Int(actualSize.width * 100))%×\(Int(actualSize.height * 100))%, expected \(Int(expectedSize.width * 100))%×\(Int(expectedSize.height * 100))%")
    }
}

// Test 6: Position Calculations  
print("\n🎯 TEST 6: POSITION CALCULATIONS")
func getOptimalPosition(role: String, width: Double) -> (x: Double, y: Double) {
    switch role {
    case "primary":
        return (x: 0.05, y: 0.05)  // Top-left for primary
    case "sideColumn":
        let rightX = 1.0 - width
        return (x: rightX, y: 0.0)  // Right side for column
    case "peekLayer":
        let peekY = 1.0 - 0.45  // Bottom peek
        return (x: 0.05, y: peekY)
    case "corner":
        return (x: 0.80, y: 0.80)  // Bottom-right corner
    default:
        return (x: 0.50, y: 0.50)
    }
}

let expectedPositions = [
    "Cursor": (x: 0.05, y: 0.05),     // Primary top-left
    "Terminal": (x: 0.75, y: 0.0),    // Right side (1.0 - 0.25)
    "Arc": (x: 0.05, y: 0.55)         // Bottom peek (1.0 - 0.45)
]

var positionIssues: [String] = []
for app in ["Cursor", "Terminal", "Arc"] {
    let archetype = classifyApp(app)
    let role = getOptimalRole(app: app, archetype: archetype) 
    let size = getOptimalSizing(archetype: archetype, role: role, windowCount: windowCount)
    let actualPos = getOptimalPosition(role: role, width: size.width)
    let expectedPos = expectedPositions[app]!
    
    let xMatch = abs(actualPos.x - expectedPos.x) < 0.01
    let yMatch = abs(actualPos.y - expectedPos.y) < 0.01
    let correct = xMatch && yMatch
    
    print("  \(app): (\(Int(actualPos.x * 100))%, \(Int(actualPos.y * 100))%) \(correct ? "✅" : "❌")")
    if !correct {
        positionIssues.append("\(app) positioned at (\(Int(actualPos.x * 100))%, \(Int(actualPos.y * 100))%), expected (\(Int(expectedPos.x * 100))%, \(Int(expectedPos.y * 100))%)")
    }
}

// Summary
print("\n📊 DIAGNOSTIC SUMMARY")
print("====================")

let allIssues = classificationIssues + roleIssues + sizingIssues + positionIssues
let systemWorking = contextCorrect && selectionCorrect && allIssues.isEmpty

print("Context Detection: \(contextCorrect ? "✅" : "❌")")
print("App Selection: \(selectionCorrect ? "✅" : "❌")")  
print("Classification: \(classificationIssues.isEmpty ? "✅" : "❌")")
print("Role Assignment: \(roleIssues.isEmpty ? "✅" : "❌")")
print("Sizing: \(sizingIssues.isEmpty ? "✅" : "❌")")
print("Positioning: \(positionIssues.isEmpty ? "✅" : "❌")")

print("\nOVERALL: \(systemWorking ? "✅ SYSTEM WORKING" : "❌ ISSUES FOUND")")

if !allIssues.isEmpty {
    print("\n🔧 ISSUES TO FIX:")
    for (index, issue) in allIssues.enumerated() {
        print("  \(index + 1). \(issue)")
    }
}

if systemWorking {
    print("\n🎉 All systems functioning correctly!")
    print("Expected 'i want to code' result:")
    print("  • Cursor: 70%×85% at (5%, 5%) - Primary workspace")
    print("  • Terminal: 25%×100% at (75%, 0%) - Right side column") 
    print("  • Arc: 45%×45% at (5%, 55%) - Bottom peek layer")
}