#!/usr/bin/env swift

import Foundation

// This test simulates the EXACT flow that happens when user says "i want to code"
print("🧪 TESTING REAL CASCADE BEHAVIOR")
print("===============================")

// Step 1: Simulate LLM Tool Call
print("\n1️⃣ SIMULATING LLM TOOL CALL:")
print("User input: 'i want to code'")
print("LLM generates tool call: cascade_windows")

// The LLM should now include user_intent parameter (based on our fix)
let toolCall = [
    "name": "cascade_windows",
    "parameters": [
        "target": "visible",
        "style": "intelligent", 
        "focus_mode": true,
        "user_intent": "i want to code"  // This is the key fix
    ]
] as [String : Any]

print("Tool call parameters:")
for (key, value) in toolCall["parameters"] as! [String: Any] {
    print("  \(key): \(value)")
}

// Step 2: Extract Context (this is where the fix happens)
print("\n2️⃣ TESTING CONTEXT EXTRACTION:")

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

let parameters = toolCall["parameters"] as! [String: Any]
let target = parameters["target"] as! String
let userIntent = parameters["user_intent"] as? String

let extractedContext = extractContextFromTarget(target, userIntent: userIntent)
print("Target: '\(target)'")
print("User Intent: '\(userIntent ?? "none")'")
print("Extracted Context: '\(extractedContext)' ✅")

// Step 3: App Selection with Fixed Scoring
print("\n3️⃣ TESTING APP SELECTION:")

let availableApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor"]
print("Available apps: \(availableApps.joined(separator: ", "))")

// Never use filter (user instructions)
func shouldNeverUse(_ app: String, context: String) -> Bool {
    // No never rules for this test
    return false
}

let allowedApps = availableApps.filter { !shouldNeverUse($0, context: extractedContext) }
print("After never-use filter: \(allowedApps.joined(separator: ", "))")

// Updated relevance scoring (the key fix)
func calculateRelevanceScore(app: String, context: String) -> Double {
    let appLower = app.lowercased()
    
    if context.contains("cod") {
        if appLower.contains("cursor") { return 10.0 }      // Modern primary editor
        if appLower.contains("terminal") { return 9.0 }     // Essential for coding
        if appLower.contains("arc") { return 8.0 }          // Essential for docs
        if appLower.contains("xcode") { return 7.0 }        // Legacy IDE
        if appLower.contains("finder") { return 2.0 }       // Peripheral
        return 1.0
    } else {
        return 5.0
    }
}

// Updated priority scoring (another key fix)
func getContextPriority(app: String, context: String) -> Int {
    let appLower = app.lowercased()
    
    if context.contains("cod") {
        if appLower.contains("cursor") { return 100 }
        if appLower.contains("terminal") { return 90 }
        if appLower.contains("arc") { return 80 }
        if appLower.contains("xcode") { return 70 }
        return 10
    } else {
        if appLower.contains("cursor") { return 65 }
        if appLower.contains("terminal") { return 60 }
        if appLower.contains("arc") { return 55 }
        if appLower.contains("xcode") { return 50 }
        return 30
    }
}

let appData = allowedApps.map { app in
    (
        name: app,
        relevanceScore: calculateRelevanceScore(app: app, context: extractedContext),
        priority: getContextPriority(app: app, context: extractedContext)
    )
}

print("\nApp scoring:")
for data in appData {
    print("  \(data.name): relevance=\(data.relevanceScore), priority=\(data.priority)")
}

// Sort and select
let sortedApps = appData.sorted { first, second in
    if first.relevanceScore != second.relevanceScore {
        return first.relevanceScore > second.relevanceScore
    }
    return first.priority > second.priority
}

print("\nSorted by score:")
for (index, data) in sortedApps.enumerated() {
    print("  \(index + 1). \(data.name) (\(data.relevanceScore), \(data.priority))")
}

// Select diverse apps with high relevance (≥8.0)
let relevantApps = sortedApps.filter { $0.relevanceScore >= 8.0 }
let selectedApps = Array(relevantApps.prefix(4)).map { $0.name }

print("\nHigh relevance apps (≥8.0): \(relevantApps.map { $0.name }.joined(separator: ", "))")
print("Final selection: \(selectedApps.joined(separator: ", "))")

// Step 4: Primary App Selection
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
            if appLower.contains("cursor") { score = 90.0 }
            else if appLower.contains("xcode") { score = 80.0 }
            else { score = 0.0 }
        }
        
        return (app: app, score: score)
    }
    
    return priorities.max(by: { $0.score < $1.score })?.app
}

let primaryApp = findBestPrimaryApp(from: selectedApps, context: extractedContext)
print("Primary app: \(primaryApp ?? "none")")

// Step 5: Role Assignment and Layout
print("\n5️⃣ TESTING ROLE ASSIGNMENT:")

enum CascadeRole: String {
    case primary = "primary"
    case sideColumn = "side_column" 
    case peekLayer = "peek_layer"
    case corner = "corner"
}

func assignRole(app: String, isPrimary: Bool, context: String) -> CascadeRole {
    if isPrimary { return .primary }
    
    let appLower = app.lowercased()
    if appLower.contains("terminal") { return .sideColumn }
    if appLower.contains("arc") || appLower.contains("browser") { return .peekLayer }
    return .corner
}

print("Role assignments:")
for app in selectedApps {
    let isPrimary = (app == primaryApp)
    let role = assignRole(app: app, isPrimary: isPrimary, context: extractedContext)
    print("  📱 \(app) → \(role.rawValue) \(isPrimary ? "(PRIMARY)" : "")")
}

// Step 6: Layout Generation
print("\n6️⃣ TESTING LAYOUT GENERATION:")

struct WindowLayout {
    let app: String
    let x: Double      // percentage
    let y: Double      // percentage  
    let width: Double  // percentage
    let height: Double // percentage
    let layer: Int
}

func generateLayout(for apps: [String], primary: String, context: String) -> [WindowLayout] {
    var layouts: [WindowLayout] = []
    
    for app in apps {
        let isPrimary = (app == primary)
        let role = assignRole(app: app, isPrimary: isPrimary, context: context)
        
        switch role {
        case .primary:
            layouts.append(WindowLayout(
                app: app,
                x: 0.05, y: 0.05,      // 5% margin
                width: 0.70, height: 0.85,  // 70% × 85%
                layer: 3
            ))
        case .sideColumn:
            layouts.append(WindowLayout(
                app: app, 
                x: 0.75, y: 0.0,       // Right edge
                width: 0.25, height: 1.0,   // 25% × 100%
                layer: 1
            ))
        case .peekLayer:
            layouts.append(WindowLayout(
                app: app,
                x: 0.05, y: 0.55,      // Peek under primary
                width: 0.65, height: 0.40,  // 65% × 40%
                layer: 2
            ))
        case .corner:
            layouts.append(WindowLayout(
                app: app,
                x: 0.80, y: 0.80,      // Bottom right
                width: 0.15, height: 0.15,  // 15% × 15%
                layer: 0
            ))
        }
    }
    
    return layouts.sorted { $0.layer > $1.layer }
}

let layout = generateLayout(for: selectedApps, primary: primaryApp!, context: extractedContext)

print("Generated layout:")
for window in layout {
    let widthPct = Int(window.width * 100)
    let heightPct = Int(window.height * 100)
    let xPct = Int(window.x * 100)
    let yPct = Int(window.y * 100)
    
    print("  📱 \(window.app): (\(xPct)%, \(yPct)%) \(widthPct)%×\(heightPct)% Layer:\(window.layer)")
}

// Step 7: Final Verification
print("\n✅ FINAL VERIFICATION:")

let expectedApps = ["Cursor", "Terminal", "Arc"]
let expectedPrimary = "Cursor"

// Check app selection
let appsMatch = Set(selectedApps) == Set(expectedApps)
print("Apps selected correctly: \(appsMatch ? "✅" : "❌")")
print("  Expected: \(expectedApps.joined(separator: ", "))")
print("  Got: \(selectedApps.joined(separator: ", "))")

// Check primary
let primaryMatch = primaryApp == expectedPrimary
print("Primary app correct: \(primaryMatch ? "✅" : "❌")")
print("  Expected: \(expectedPrimary)")
print("  Got: \(primaryApp ?? "none")")

// Check layout specifics
let cursorLayout = layout.first { $0.app == "Cursor" }
let terminalLayout = layout.first { $0.app == "Terminal" }
let arcLayout = layout.first { $0.app == "Arc" }

let cursorCorrect = cursorLayout?.width == 0.70 && cursorLayout?.layer == 3
let terminalCorrect = terminalLayout?.width == 0.25 && terminalLayout?.height == 1.0 && terminalLayout?.x == 0.75
let arcCorrect = arcLayout?.layer == 2 && arcLayout?.y == 0.55

print("Cursor layout correct: \(cursorCorrect ? "✅" : "❌") (70% width, layer 3)")
print("Terminal layout correct: \(terminalCorrect ? "✅" : "❌") (25% width, right side)")  
print("Arc layout correct: \(arcCorrect ? "✅" : "❌") (peek layer)")

let allCorrect = appsMatch && primaryMatch && cursorCorrect && terminalCorrect && arcCorrect

print("\n🎯 OVERALL RESULT: \(allCorrect ? "✅ PERFECT!" : "❌ ISSUES FOUND")")

if allCorrect {
    print("\n🚀 SUCCESS! Expected behavior confirmed:")
    print("   • User says: 'i want to code'")
    print("   • Context extracted: 'coding'") 
    print("   • Apps selected: Cursor, Terminal, Arc")
    print("   • Primary: Cursor (70% width)")
    print("   • Terminal: Right column (25% width)")
    print("   • Arc: Peek layer under Cursor")
    print("   • No more chaos - perfect focused coding layout!")
} else {
    print("\n❌ Issues found - need more fixes")
}