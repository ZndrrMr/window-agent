#!/usr/bin/env swift

import Foundation

print("🌊 CASCADE-APPROPRIATE VALIDATION")
print("=================================")

// Simulate the complete "i want to code" flow
let userIntent = "i want to code"
let screenSize = (width: 1440.0, height: 900.0)
let availableApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor", "Messages"]

print("📝 INPUT:")
print("  User Intent: '\(userIntent)'")
print("  Screen Size: \(Int(screenSize.width))x\(Int(screenSize.height))")
print("  Available Apps: \(availableApps.joined(separator: ", "))")

// Use corrected logic with smart exclusion
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
        // Updated logic: ensure minimum readable width
        let baseWidth = windowCount <= 2 ? 0.35 : windowCount == 3 ? 0.30 : 0.25
        let minWidthForScreen = 400.0 / screenSize.width
        let finalWidth = max(baseWidth, minWidthForScreen)
        return (width: finalWidth, height: 1.0)
        
    case ("codeWorkspace", "primary"):
        let baseWidth = windowCount <= 2 ? 0.80 : windowCount == 3 ? 0.70 : 0.65
        let baseHeight = windowCount <= 2 ? 0.90 : 0.85
        return (width: baseWidth, height: baseHeight)
        
    case ("contentCanvas", "peekLayer"):
        // CASCADE-APPROPRIATE: Arc should be large enough to be functional but allow cascading
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

func getCascadePosition(role: String, width: Double, height: Double, layer: Int) -> (x: Double, y: Double) {
    switch role {
    case "primary":
        return (x: 0.05, y: 0.05)  // Primary at top-left
    case "sideColumn":
        let rightX = 1.0 - width
        return (x: rightX, y: 0.0)  // Side column on right
    case "peekLayer":
        // CASCADE POSITIONING: Position Arc to peek from under primary
        let cascadeOffsetX = 0.05 + (0.10 * Double(layer)) // Cascade offset based on layer
        let cascadeOffsetY = 0.05 + (0.15 * Double(layer)) // Cascade offset based on layer
        return (x: cascadeOffsetX, y: cascadeOffsetY)
    case "corner":
        return (x: 0.80, y: 0.80)  // Corner
    default:
        return (x: 0.50, y: 0.50)
    }
}

// Get arrangements using the fixed logic
let extractedContext = extractContextFromIntent(userIntent)
let relevantApps = selectAppsWithSmartExclusion(apps: availableApps, context: extractedContext, maxApps: 4)
let windowCount = relevantApps.count

print("\n📱 SELECTED APPS: \(relevantApps.joined(separator: ", "))")
print("📊 WINDOW COUNT: \(windowCount)")

struct WindowArrangement {
    let app: String
    let archetype: String
    let role: String
    let layer: Int
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
    let visibleArea: Double // Percentage of window that's not occluded
}

var arrangements: [WindowArrangement] = []

for (index, app) in relevantApps.enumerated() {
    let archetype = classifyApp(app)
    let role = getOptimalRole(app: app, archetype: archetype)
    let (width, height) = getOptimalSizing(archetype: archetype, role: role, windowCount: windowCount, screenSize: screenSize)
    let layer = index
    let (x, y) = getCascadePosition(role: role, width: width, height: height, layer: layer)
    
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
        layer: layer,
        percentageWidth: width,
        percentageHeight: height,
        percentageX: x,
        percentageY: y,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
        pixelX: pixelX,
        pixelY: pixelY,
        pixelEndX: pixelEndX,
        pixelEndY: pixelEndY,
        visibleArea: 1.0 // Will calculate below
    ))
}

print("\n🎯 CASCADE ARRANGEMENTS:")
for arrangement in arrangements {
    print("  \(arrangement.app) (Layer \(arrangement.layer)):")
    print("    Size: \(Int(arrangement.percentageWidth * 100))%×\(Int(arrangement.percentageHeight * 100))% (\(Int(arrangement.pixelWidth))×\(Int(arrangement.pixelHeight)) px)")
    print("    Position: (\(Int(arrangement.percentageX * 100))%, \(Int(arrangement.percentageY * 100))%) = (\(Int(arrangement.pixelX)), \(Int(arrangement.pixelY)) px)")
    print("    Bounds: (\(Int(arrangement.pixelX)), \(Int(arrangement.pixelY))) to (\(Int(arrangement.pixelEndX)), \(Int(arrangement.pixelEndY)))")
}

// CASCADE-APPROPRIATE VALIDATION
print("\n🌊 CASCADE VALIDATION TESTS")
print("===========================")

// Test 1: Screen Bounds (no off-screen windows)
print("\n🏠 TEST 1: SCREEN BOUNDS VALIDATION")
var boundsViolations: [String] = []

for arrangement in arrangements {
    let screenMaxX = screenSize.width
    let screenMaxY = screenSize.height
    
    if arrangement.pixelEndX > screenMaxX {
        boundsViolations.append("\(arrangement.app): extends \(Int(arrangement.pixelEndX - screenMaxX))px beyond right edge")
    }
    if arrangement.pixelEndY > screenMaxY {
        boundsViolations.append("\(arrangement.app): extends \(Int(arrangement.pixelEndY - screenMaxY))px beyond bottom edge")
    }
    if arrangement.pixelX < 0 {
        boundsViolations.append("\(arrangement.app): extends \(Int(-arrangement.pixelX))px beyond left edge")
    }
    if arrangement.pixelY < 0 {
        boundsViolations.append("\(arrangement.app): extends \(Int(-arrangement.pixelY))px beyond top edge")
    }
}

if boundsViolations.isEmpty {
    print("  ✅ All windows within screen bounds")
} else {
    print("  ❌ BOUNDS VIOLATIONS:")
    for violation in boundsViolations {
        print("    • \(violation)")
    }
}

// Test 2: Minimum Functional Sizes
print("\n📏 TEST 2: MINIMUM SIZE VALIDATION")
var sizeViolations: [String] = []

let screenArea = screenSize.width * screenSize.height

for arrangement in arrangements {
    let actualArea = arrangement.pixelWidth * arrangement.pixelHeight
    let actualPercentage = (actualArea / screenArea) * 100
    
    switch arrangement.app.lowercased() {
    case let app where app.contains("arc"):
        let requiredArea = screenArea * 0.25 // 25% minimum
        if actualArea < requiredArea {
            sizeViolations.append("Arc: area \(String(format: "%.1f", actualPercentage))% < required 25.0%")
        }
    case let app where app.contains("terminal"):
        let minWidth = 400.0
        if arrangement.pixelWidth < minWidth {
            sizeViolations.append("Terminal: width \(Int(arrangement.pixelWidth))px < required \(Int(minWidth))px")
        }
    case let app where app.contains("cursor"):
        let requiredArea = screenArea * 0.35 // 35% minimum
        if actualArea < requiredArea {
            sizeViolations.append("Cursor: area \(String(format: "%.1f", actualPercentage))% < required 35.0%")
        }
    default:
        break
    }
}

if sizeViolations.isEmpty {
    print("  ✅ All windows meet minimum size requirements")
} else {
    print("  ❌ SIZE VIOLATIONS:")
    for violation in sizeViolations {
        print("    • \(violation)")
    }
}

// Test 3: Cascade Accessibility (each window has clickable area)
print("\n👆 TEST 3: CASCADE ACCESSIBILITY")
var accessibilityViolations: [String] = []

// Sort by layer (highest layer = topmost = rendered last)
let sortedByLayer = arrangements.sorted { $0.layer > $1.layer }

for (index, arrangement) in arrangements.enumerated() {
    var visibleArea = arrangement.pixelWidth * arrangement.pixelHeight
    
    // Calculate how much of this window is occluded by higher-layer windows
    for otherArrangement in arrangements {
        if otherArrangement.layer > arrangement.layer { // Higher layer = on top
            // Calculate overlap
            let overlapLeft = max(arrangement.pixelX, otherArrangement.pixelX)
            let overlapRight = min(arrangement.pixelEndX, otherArrangement.pixelEndX)
            let overlapTop = max(arrangement.pixelY, otherArrangement.pixelY)
            let overlapBottom = min(arrangement.pixelEndY, otherArrangement.pixelEndY)
            
            let overlapWidth = max(0, overlapRight - overlapLeft)
            let overlapHeight = max(0, overlapBottom - overlapTop)
            let overlapArea = overlapWidth * overlapHeight
            
            visibleArea -= overlapArea
        }
    }
    
    let visiblePercentage = (visibleArea / (arrangement.pixelWidth * arrangement.pixelHeight)) * 100
    let minVisiblePercentage = 15.0 // At least 15% of window must be visible to click
    
    if visiblePercentage < minVisiblePercentage {
        accessibilityViolations.append("\(arrangement.app): only \(String(format: "%.1f", visiblePercentage))% visible (< \(String(format: "%.1f", minVisiblePercentage))% minimum)")
    }
    
    print("  \(arrangement.app) (Layer \(arrangement.layer)): \(String(format: "%.1f", visiblePercentage))% visible \(visiblePercentage >= minVisiblePercentage ? "✅" : "❌")")
}

if accessibilityViolations.isEmpty {
    print("  ✅ All windows have adequate clickable area")
} else {
    print("  ❌ ACCESSIBILITY VIOLATIONS:")
    for violation in accessibilityViolations {
        print("    • \(violation)")
    }
}

// Test 4: Cascade Quality (proper layering and peek positioning)
print("\n🎭 TEST 4: CASCADE QUALITY")
var cascadeViolations: [String] = []

// Check if primary window is in correct layer (should be bottom/background)
let primaryWindows = arrangements.filter { $0.role == "primary" }
let peekWindows = arrangements.filter { $0.role == "peekLayer" }

for primary in primaryWindows {
    if primary.layer != 0 {
        cascadeViolations.append("Primary window (\(primary.app)) should be Layer 0 (bottom), found at Layer \(primary.layer)")
    }
}

// Check if peek windows are positioned to create good cascade visibility
for peek in peekWindows {
    let hasReasonableOffset = peek.percentageX > 0.10 || peek.percentageY > 0.10
    if !hasReasonableOffset {
        cascadeViolations.append("Peek window (\(peek.app)) positioned too close to origin - may not cascade properly")
    }
}

if cascadeViolations.isEmpty {
    print("  ✅ Cascade positioning and layering looks good")
} else {
    print("  ❌ CASCADE QUALITY ISSUES:")
    for violation in cascadeViolations {
        print("    • \(violation)")
    }
}

// SUMMARY
print("\n📊 CASCADE VALIDATION SUMMARY")
print("=============================")

let allViolations = boundsViolations + sizeViolations + accessibilityViolations + cascadeViolations
let cascadeValid = allViolations.isEmpty

print("Screen Bounds: \(boundsViolations.isEmpty ? "✅" : "❌")")
print("Minimum Sizes: \(sizeViolations.isEmpty ? "✅" : "❌")")
print("Accessibility: \(accessibilityViolations.isEmpty ? "✅" : "❌")")
print("Cascade Quality: \(cascadeViolations.isEmpty ? "✅" : "❌")")

print("\nOVERALL: \(cascadeValid ? "✅ PERFECT CASCADE" : "❌ VIOLATIONS FOUND")")

if cascadeValid {
    print("\n🎉 PERFECT CASCADE LAYOUT ACHIEVED!")
    print("Windows properly layered with strategic overlaps and accessibility:")
    for arrangement in arrangements.sorted(by: { $0.layer < $1.layer }) {
        print("  • Layer \(arrangement.layer): \(arrangement.app) (\(Int(arrangement.percentageWidth * 100))%×\(Int(arrangement.percentageHeight * 100))%)")
    }
} else {
    print("\n🔧 VIOLATIONS TO FIX:")
    for (index, violation) in allViolations.enumerated() {
        print("  \(index + 1). \(violation)")
    }
}