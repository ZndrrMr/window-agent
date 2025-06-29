#!/usr/bin/env swift

import Foundation

print("🔍 COMPREHENSIVE VALIDATION DIAGNOSTIC")
print("======================================")

// Simulate the complete "i want to code" flow with validation
let userIntent = "i want to code"
let screenSize = (width: 1440.0, height: 900.0)
let availableApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor", "Messages"]

print("📝 INPUT:")
print("  User Intent: '\(userIntent)'")
print("  Screen Size: \(Int(screenSize.width))x\(Int(screenSize.height))")
print("  Available Apps: \(availableApps.joined(separator: ", "))")

// STEP 1: Get the expected app selection and arrangements
func extractContextFromIntent(_ intent: String) -> String {
    let normalized = intent.lowercased()
    if normalized.contains("code") || normalized.contains("develop") || normalized.contains("program") {
        return "coding"
    }
    return "general"
}

func selectAppsWithSmartExclusion(apps: [String], context: String, maxApps: Int = 4) -> [String] {
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
            continue
        }
        
        selectedApps.append(app)
    }
    
    return selectedApps
}

func classifyApp(_ name: String) -> String {
    let normalized = name.lowercased()
    if ["terminal", "iterm", "console"].contains(normalized) { return "textStream" }
    if ["arc", "safari", "chrome", "firefox"].contains(normalized) { return "contentCanvas" }
    if ["cursor", "xcode", "vscode", "sublime"].contains(normalized) { return "codeWorkspace" }
    if ["finder", "spotify", "music"].contains(normalized) { return "glanceableMonitor" }
    return "unknown"
}

func getOptimalRole(app: String, archetype: String) -> String {
    switch archetype {
    case "textStream": return "sideColumn"
    case "codeWorkspace": return "primary" 
    case "contentCanvas": return "peekLayer"
    case "glanceableMonitor": return "corner"
    default: return "peekLayer"
    }
}

func getOptimalSizing(archetype: String, role: String, windowCount: Int, screenSize: (width: Double, height: Double)) -> (width: Double, height: Double) {
    switch (archetype, role) {
    case ("textStream", "sideColumn"):
        // Updated logic: ensure minimum readable width while adapting to window count
        let baseWidth = windowCount <= 2 ? 0.35 : windowCount == 3 ? 0.30 : 0.25
        // Ensure minimum 400px width for terminal readability
        let minWidthForScreen = 400.0 / screenSize.width
        let finalWidth = max(baseWidth, minWidthForScreen)
        return (width: finalWidth, height: 1.0)
        
    case ("codeWorkspace", "primary"):
        let baseWidth = windowCount <= 2 ? 0.80 : windowCount == 3 ? 0.70 : 0.65
        let baseHeight = windowCount <= 2 ? 0.90 : 0.85
        return (width: baseWidth, height: baseHeight)
        
    case ("contentCanvas", "peekLayer"):
        // Updated logic: ensure minimum functional area while adapting to window count
        let baseWidth = windowCount <= 2 ? 0.55 : windowCount == 3 ? 0.55 : 0.50
        let baseHeight = windowCount <= 2 ? 0.50 : windowCount == 3 ? 0.50 : 0.45
        
        // Ensure minimum 25% screen area for browser functionality
        let currentArea = baseWidth * baseHeight
        let minRequiredArea = 0.25 // 25% of screen
        
        if currentArea < minRequiredArea {
            // Scale proportionally to reach minimum area
            let scaleFactor = sqrt(minRequiredArea / currentArea)
            let adjustedWidth = min(baseWidth * scaleFactor, 0.65) // Cap at 65% width
            let adjustedHeight = min(baseHeight * scaleFactor, 0.60) // Cap at 60% height
            return (width: adjustedWidth, height: adjustedHeight)
        }
        
        return (width: baseWidth, height: baseHeight)
        
    default:
        return (width: 0.40, height: 0.60)
    }
}

func getOptimalPosition(role: String, width: Double, height: Double) -> (x: Double, y: Double) {
    switch role {
    case "primary":
        return (x: 0.05, y: 0.05)  // Top-left for primary
    case "sideColumn":
        let rightX = 1.0 - width
        return (x: rightX, y: 0.0)  // Right side for column
    case "peekLayer":
        // CASCADE-APPROPRIATE: Position Arc to cascade from primary with strategic overlap
        // Primary window is at (5%, 5%), so Arc cascades with offset for visibility
        let cascadeOffsetX = 0.20 // 20% horizontal offset from primary
        let cascadeOffsetY = 0.30 // 30% vertical offset from primary
        
        let peekX = 0.05 + cascadeOffsetX // 25% final position
        let peekY = 0.05 + cascadeOffsetY // 35% final position
        
        return (x: peekX, y: peekY)
    case "corner":
        return (x: 0.80, y: 0.80)  // Bottom-right corner
    default:
        return (x: 0.50, y: 0.50)
    }
}

// Get current arrangements
let extractedContext = extractContextFromIntent(userIntent)
let relevantApps = selectAppsWithSmartExclusion(apps: availableApps, context: extractedContext, maxApps: 4)
let windowCount = relevantApps.count

print("\n📱 SELECTED APPS: \(relevantApps.joined(separator: ", "))")
print("📊 WINDOW COUNT: \(windowCount)")

// Generate arrangements
struct WindowArrangement {
    let app: String
    let archetype: String
    let role: String
    let percentageWidth: Double
    let percentageHeight: Double
    let percentageX: Double
    let percentageY: Double
    let pixelWidth: Double
    let pixelHeight: Double
    let pixelX: Double
    let pixelY: Double
    let pixelEndX: Double
    let pixelEndY: Double
}

var arrangements: [WindowArrangement] = []

for app in relevantApps {
    let archetype = classifyApp(app)
    let role = getOptimalRole(app: app, archetype: archetype)
    let (width, height) = getOptimalSizing(archetype: archetype, role: role, windowCount: windowCount, screenSize: screenSize)
    let (x, y) = getOptimalPosition(role: role, width: width, height: height)
    
    let pixelWidth = width * screenSize.width
    let pixelHeight = height * screenSize.height
    let pixelX = x * screenSize.width
    let pixelY = y * screenSize.height
    let pixelEndX = pixelX + pixelWidth
    let pixelEndY = pixelY + pixelHeight
    
    arrangements.append(WindowArrangement(
        app: app,
        archetype: archetype,
        role: role,
        percentageWidth: width,
        percentageHeight: height,
        percentageX: x,
        percentageY: y,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
        pixelX: pixelX,
        pixelY: pixelY,
        pixelEndX: pixelEndX,
        pixelEndY: pixelEndY
    ))
}

print("\n🎯 CURRENT ARRANGEMENTS:")
for arrangement in arrangements {
    print("  \(arrangement.app):")
    print("    Size: \(Int(arrangement.percentageWidth * 100))%×\(Int(arrangement.percentageHeight * 100))% (\(Int(arrangement.pixelWidth))×\(Int(arrangement.pixelHeight)) px)")
    print("    Position: (\(Int(arrangement.percentageX * 100))%, \(Int(arrangement.percentageY * 100))%) = (\(Int(arrangement.pixelX)), \(Int(arrangement.pixelY)) px)")
    print("    Bounds: (\(Int(arrangement.pixelX)), \(Int(arrangement.pixelY))) to (\(Int(arrangement.pixelEndX)), \(Int(arrangement.pixelEndY)))")
}

// VALIDATION TESTS
print("\n🔧 VALIDATION TESTS")
print("==================")

// Test 1: Screen Bounds Validation
print("\n🏠 TEST 1: SCREEN BOUNDS VALIDATION")
var boundsViolations: [String] = []

for arrangement in arrangements {
    let screenMaxX = screenSize.width
    let screenMaxY = screenSize.height
    
    // Check if window extends beyond screen bounds
    if arrangement.pixelEndX > screenMaxX {
        boundsViolations.append("\(arrangement.app): extends \(Int(arrangement.pixelEndX - screenMaxX))px beyond right edge (end: \(Int(arrangement.pixelEndX)), screen: \(Int(screenMaxX)))")
    }
    if arrangement.pixelEndY > screenMaxY {
        boundsViolations.append("\(arrangement.app): extends \(Int(arrangement.pixelEndY - screenMaxY))px beyond bottom edge (end: \(Int(arrangement.pixelEndY)), screen: \(Int(screenMaxY)))")
    }
    if arrangement.pixelX < 0 {
        boundsViolations.append("\(arrangement.app): extends \(Int(-arrangement.pixelX))px beyond left edge (start: \(Int(arrangement.pixelX)))")
    }
    if arrangement.pixelY < 0 {
        boundsViolations.append("\(arrangement.app): extends \(Int(-arrangement.pixelY))px beyond top edge (start: \(Int(arrangement.pixelY)))")
    }
}

if boundsViolations.isEmpty {
    print("  ✅ All windows within screen bounds")
} else {
    print("  ❌ BOUNDS VIOLATIONS FOUND:")
    for violation in boundsViolations {
        print("    • \(violation)")
    }
}

// Test 2: Minimum Size Validation
print("\n📏 TEST 2: MINIMUM SIZE VALIDATION")
var sizeViolations: [String] = []

// Dynamic minimum size calculation based on screen and context
let screenArea = screenSize.width * screenSize.height
let minimumAreaPercentage = 0.25  // 25% of screen area minimum for main content apps
let minimumContentAppArea = screenArea * minimumAreaPercentage

// Context-aware minimum sizes
func getMinimumAreaRequirement(app: String, archetype: String, role: String) -> Double {
    switch (archetype, role) {
    case ("contentCanvas", "peekLayer"):
        // Content canvas needs enough space to be functional
        return minimumContentAppArea
    case ("codeWorkspace", "primary"):
        // Code workspace needs substantial space
        return screenArea * 0.35  // 35% minimum
    case ("textStream", "sideColumn"):
        // Text streams need height but can be narrow
        return screenArea * 0.15  // 15% minimum
    case ("glanceableMonitor", "corner"):
        // Monitors just need to be visible
        return screenArea * 0.02  // 2% minimum
    default:
        return screenArea * 0.10  // 10% default minimum
    }
}

for arrangement in arrangements {
    let actualArea = arrangement.pixelWidth * arrangement.pixelHeight
    let requiredArea = getMinimumAreaRequirement(app: arrangement.app, archetype: arrangement.archetype, role: arrangement.role)
    let actualPercentage = (actualArea / screenArea) * 100
    let requiredPercentage = (requiredArea / screenArea) * 100
    
    if actualArea < requiredArea {
        sizeViolations.append("\(arrangement.app): area \(String(format: "%.1f", actualPercentage))% < required \(String(format: "%.1f", requiredPercentage))% (actual: \(Int(actualArea)), required: \(Int(requiredArea)))")
    }
}

if sizeViolations.isEmpty {
    print("  ✅ All windows meet minimum size requirements")
} else {
    print("  ❌ SIZE VIOLATIONS FOUND:")
    for violation in sizeViolations {
        print("    • \(violation)")
    }
}

// Test 3: App-Specific Validation 
print("\n🎯 TEST 3: APP-SPECIFIC VALIDATION")
var appViolations: [String] = []

for arrangement in arrangements {
    let app = arrangement.app.lowercased()
    
    // Arc-specific validation
    if app.contains("arc") {
        let actualWidthPx = arrangement.pixelWidth
        let actualHeightPx = arrangement.pixelHeight
        let minFunctionalWidth = screenSize.width * 0.30  // 30% minimum for browser functionality
        let minFunctionalHeight = screenSize.height * 0.40  // 40% minimum for browser functionality
        
        if actualWidthPx < minFunctionalWidth {
            appViolations.append("Arc: width \(Int(actualWidthPx))px < functional minimum \(Int(minFunctionalWidth))px (\(String(format: "%.1f", (actualWidthPx/screenSize.width)*100))% < 30%)")
        }
        if actualHeightPx < minFunctionalHeight {
            appViolations.append("Arc: height \(Int(actualHeightPx))px < functional minimum \(Int(minFunctionalHeight))px (\(String(format: "%.1f", (actualHeightPx/screenSize.height)*100))% < 40%)")
        }
    }
    
    // Terminal-specific validation
    if app.contains("terminal") {
        let actualWidthPx = arrangement.pixelWidth
        let minTerminalWidth = 400.0  // Minimum for readable terminal
        
        if actualWidthPx < minTerminalWidth {
            appViolations.append("Terminal: width \(Int(actualWidthPx))px < readable minimum \(Int(minTerminalWidth))px")
        }
    }
    
    // Cursor-specific validation  
    if app.contains("cursor") {
        let actualArea = arrangement.pixelWidth * arrangement.pixelHeight
        let minCodeWorkspaceArea = screenArea * 0.40  // Code workspace needs substantial space
        
        if actualArea < minCodeWorkspaceArea {
            appViolations.append("Cursor: area \(String(format: "%.1f", (actualArea/screenArea)*100))% < workspace minimum 40%")
        }
    }
}

if appViolations.isEmpty {
    print("  ✅ All apps meet specific functional requirements")
} else {
    print("  ❌ APP-SPECIFIC VIOLATIONS FOUND:")
    for violation in appViolations {
        print("    • \(violation)")
    }
}

// Test 4: CASCADE ACCESSIBILITY (strategic overlaps with clickable areas)
print("\n👆 TEST 4: CASCADE ACCESSIBILITY")
var accessibilityViolations: [String] = []

// Calculate visible area for each window (considering strategic overlaps)
for arrangement in arrangements {
    var visibleArea = arrangement.pixelWidth * arrangement.pixelHeight
    
    // Calculate how much of this window is occluded by higher-layer windows
    for otherArrangement in arrangements {
        if otherArrangement.app != arrangement.app && arrangement.app != "Terminal" { // Terminal doesn't get occluded
            // Calculate overlap
            let overlapLeft = max(arrangement.pixelX, otherArrangement.pixelX)
            let overlapRight = min(arrangement.pixelEndX, otherArrangement.pixelEndX)
            let overlapTop = max(arrangement.pixelY, otherArrangement.pixelY)
            let overlapBottom = min(arrangement.pixelEndY, otherArrangement.pixelEndY)
            
            let overlapWidth = max(0, overlapRight - overlapLeft)
            let overlapHeight = max(0, overlapBottom - overlapTop)
            let overlapArea = overlapWidth * overlapHeight
            
            // Only subtract overlap if the other window is on top (later in processing = higher layer)
            let otherIndex = arrangements.firstIndex { $0.app == otherArrangement.app } ?? 0
            let currentIndex = arrangements.firstIndex { $0.app == arrangement.app } ?? 0
            
            if otherIndex > currentIndex {
                visibleArea -= overlapArea
            }
        }
    }
    
    let visiblePercentage = (visibleArea / (arrangement.pixelWidth * arrangement.pixelHeight)) * 100
    let minVisiblePercentage = 15.0 // At least 15% of window must be visible to click
    
    if visiblePercentage < minVisiblePercentage {
        accessibilityViolations.append("\(arrangement.app): only \(String(format: "%.1f", visiblePercentage))% visible (< \(String(format: "%.1f", minVisiblePercentage))% minimum)")
    }
    
    print("  \(arrangement.app): \(String(format: "%.1f", visiblePercentage))% visible \(visiblePercentage >= minVisiblePercentage ? "✅" : "❌")")
}

if accessibilityViolations.isEmpty {
    print("  ✅ All windows have adequate clickable area in cascade")
} else {
    print("  ❌ CASCADE ACCESSIBILITY VIOLATIONS:")
    for violation in accessibilityViolations {
        print("    • \(violation)")
    }
}

// SUMMARY
print("\n📊 CASCADE VALIDATION SUMMARY") 
print("=============================")

let allViolations = boundsViolations + sizeViolations + appViolations + accessibilityViolations
let cascadeValid = allViolations.isEmpty

print("Screen Bounds: \(boundsViolations.isEmpty ? "✅" : "❌")")
print("Minimum Sizes: \(sizeViolations.isEmpty ? "✅" : "❌")")
print("App Requirements: \(appViolations.isEmpty ? "✅" : "❌")")
print("Cascade Accessibility: \(accessibilityViolations.isEmpty ? "✅" : "❌")")

print("\nOVERALL: \(cascadeValid ? "✅ PERFECT CASCADE" : "❌ VIOLATIONS FOUND")")

if !allViolations.isEmpty {
    print("\n🔧 ALL VIOLATIONS TO FIX:")
    for (index, violation) in allViolations.enumerated() {
        print("  \(index + 1). \(violation)")
    }
    
    print("\n💡 SUGGESTED FIXES:")
    
    // Arc size fix
    if appViolations.contains(where: { $0.contains("Arc") && $0.contains("width") }) {
        print("  • Arc width too small: Increase contentCanvas peekLayer minimum width to 30%")
    }
    if appViolations.contains(where: { $0.contains("Arc") && $0.contains("height") }) {
        print("  • Arc height too small: Increase contentCanvas peekLayer minimum height to 40%")
    }
    
    // Screen bounds fix
    if !boundsViolations.isEmpty {
        print("  • Off-screen positioning: Add bounds validation to position calculation")
    }
    
    // Size violations fix
    if !sizeViolations.isEmpty {
        print("  • Size violations: Implement dynamic minimum size constraints")
    }
}

if cascadeValid {
    print("\n🎉 Perfect cascade achieved! All windows properly layered with strategic overlaps and accessibility.")
}