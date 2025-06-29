#!/usr/bin/env swift

import Foundation

print("🔧 OVERLAP-FREE LAYOUT ENGINE")
print("=============================")

// Screen configuration
let screenSize = (width: 1440.0, height: 900.0)
let apps = ["Cursor", "Terminal", "Arc"]

print("📝 INPUT:")
print("  Screen Size: \(Int(screenSize.width))x\(Int(screenSize.height))")
print("  Apps: \(apps.joined(separator: ", "))")

// Layout constraints and requirements
struct LayoutConstraints {
    let minTerminalWidth: Double = 400.0 // pixels
    let minArcArea: Double = 0.25 // 25% of screen
    let minCursorArea: Double = 0.35 // 35% of screen 
    let clearanceBuffer: Double = 0.02 // 2% gap between windows
}

struct WindowLayout {
    let app: String
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    let pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int)
    
    init(app: String, x: Double, y: Double, width: Double, height: Double, screenSize: (width: Double, height: Double)) {
        self.app = app
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        
        let pixelX = Int(x * screenSize.width)
        let pixelY = Int(y * screenSize.height)
        let pixelWidth = Int(width * screenSize.width)
        let pixelHeight = Int(height * screenSize.height)
        
        self.pixelBounds = (
            x: pixelX,
            y: pixelY,
            width: pixelWidth,
            height: pixelHeight,
            endX: pixelX + pixelWidth,
            endY: pixelY + pixelHeight
        )
    }
}

let constraints = LayoutConstraints()

func calculateOptimalLayout() {
    // STEP 1: Calculate optimal layout without overlaps
    print("\n🎯 CALCULATING OVERLAP-FREE LAYOUT")

// Start with Terminal since it has fixed positioning (right side)
let minTerminalWidthPercent = constraints.minTerminalWidth / screenSize.width // ~28%
let terminalWidthPercent = max(0.30, minTerminalWidthPercent) // Ensure minimum readable width
let terminalX = 1.0 - terminalWidthPercent

let terminal = WindowLayout(
    app: "Terminal",
    x: terminalX,
    y: 0.0,
    width: terminalWidthPercent,
    height: 1.0,
    screenSize: screenSize
)

print("  Terminal: \(Int(terminal.width * 100))%×\(Int(terminal.height * 100))% at (\(Int(terminal.x * 100))%, \(Int(terminal.y * 100))%)")

// Calculate Cursor to avoid Terminal overlap
let availableWidthForCursor = terminalX - constraints.clearanceBuffer - 0.05 // Terminal start - buffer - left margin
let cursorWidth = min(0.70, availableWidthForCursor) // Cap at 70% but ensure no overlap
let cursorHeight = 0.85

let cursor = WindowLayout(
    app: "Cursor",
    x: 0.05,
    y: 0.05,
    width: cursorWidth,
    height: cursorHeight,
    screenSize: screenSize
)

print("  Cursor: \(Int(cursor.width * 100))%×\(Int(cursor.height * 100))% at (\(Int(cursor.x * 100))%, \(Int(cursor.y * 100))%)")

// Calculate Arc to avoid both Cursor and Terminal
let cursorEndY = cursor.y + cursor.height
let availableHeightForArc = 1.0 - (cursorEndY + constraints.clearanceBuffer)

// Calculate Arc size to meet minimum area requirement
let minArcAreaPixels = constraints.minArcArea * screenSize.width * screenSize.height
var arcWidth = 0.55
var arcHeight = 0.45

// Adjust Arc size if it doesn't meet minimum area
let currentArcArea = arcWidth * arcHeight * screenSize.width * screenSize.height
if currentArcArea < minArcAreaPixels {
    let scaleFactor = sqrt(minArcAreaPixels / currentArcArea)
    arcWidth = min(arcWidth * scaleFactor, 0.65)
    arcHeight = min(arcHeight * scaleFactor, availableHeightForArc)
}

// Position Arc below Cursor with clearance
let arcY = cursorEndY + constraints.clearanceBuffer

// Debug output
print("  📊 Arc positioning debug:")
print("    Arc Y position: \(Int(arcY * 100))% (\(arcY))")
print("    Arc height: \(Int(arcHeight * 100))% (\(arcHeight))")
print("    Arc bottom would be: \(Int((arcY + arcHeight) * 100))% (\(arcY + arcHeight))")
print("    Screen height: 100% (1.0)")
print("    Fits below cursor: \(arcY + arcHeight <= 1.0)")

// Check if Arc meets minimum area requirements when positioned below Cursor
let maxAvailableHeight = 1.0 - arcY
let constrainedArcHeight = min(arcHeight, maxAvailableHeight)
let actualArcArea = arcWidth * constrainedArcHeight
let meetsMinimumArea = actualArcArea >= constraints.minArcArea

print("  📊 Area check:")
print("    Constrained Arc: \(Int(arcWidth * 100))%×\(Int(constrainedArcHeight * 100))% = \(String(format: "%.1f", actualArcArea * 100))% area")
print("    Required minimum: \(String(format: "%.1f", constraints.minArcArea * 100))% area") 
print("    Meets minimum: \(meetsMinimumArea)")

if !meetsMinimumArea {
    print("  ⚠️  Arc doesn't fit below Cursor, trying alternative positioning...")
    
    // Try positioning Arc to the right of Cursor but left of Terminal
    let availableWidthBetween = terminalX - (cursor.x + cursor.width + constraints.clearanceBuffer)
    
    if availableWidthBetween >= arcWidth {
        // Position Arc between Cursor and Terminal
        let arcX = cursor.x + cursor.width + constraints.clearanceBuffer
        let arc = WindowLayout(
            app: "Arc",
            x: arcX,
            y: 0.05,
            width: arcWidth,
            height: arcHeight,
            screenSize: screenSize
        )
        print("  Arc: \(Int(arc.width * 100))%×\(Int(arc.height * 100))% at (\(Int(arc.x * 100))%, \(Int(arc.y * 100))%) [RIGHT SIDE]")
        
        // Test this layout
        let layouts = [cursor, terminal, arc]
        testLayout(layouts: layouts, constraints: constraints)
        return
        
    } else {
        print("  ⚠️  No space to right of Cursor, trying optimized layout strategies...")
        
        // STRATEGY 1: Reduce all window sizes proportionally to fit Arc below Cursor
        let strategy1CursorHeight = 0.60 // Reduce to 60%
        let strategy1ArcHeight = 0.35 // Give Arc substantial height
        
        let strategy1Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: cursorWidth, height: strategy1CursorHeight, screenSize: screenSize)
        let strategy1ArcY = strategy1Cursor.y + strategy1Cursor.height + constraints.clearanceBuffer
        let strategy1Arc = WindowLayout(app: "Arc", x: 0.05, y: strategy1ArcY, width: arcWidth, height: strategy1ArcHeight, screenSize: screenSize)
        
        print("\n  📋 STRATEGY 1: Reduced Cursor height for Arc space")
        print("    Cursor: \(Int(strategy1Cursor.width * 100))%×\(Int(strategy1Cursor.height * 100))% at (\(Int(strategy1Cursor.x * 100))%, \(Int(strategy1Cursor.y * 100))%)")
        print("    Arc: \(Int(strategy1Arc.width * 100))%×\(Int(strategy1Arc.height * 100))% at (\(Int(strategy1Arc.x * 100))%, \(Int(strategy1Arc.y * 100))%)")
        
        let strategy1Layouts = [strategy1Cursor, terminal, strategy1Arc]
        let strategy1Valid = testLayoutQuiet(layouts: strategy1Layouts, constraints: constraints)
        
        if strategy1Valid {
            print("  ✅ STRATEGY 1 SUCCESSFUL!")
            testLayout(layouts: strategy1Layouts, constraints: constraints)
            return
        }
        
        // STRATEGY 2: Three-column layout with reduced Terminal width
        let strategy2TerminalWidth = 0.25 // Reduce Terminal to 25%
        let strategy2TerminalX = 1.0 - strategy2TerminalWidth
        let strategy2CursorWidth = 0.45 // Reduce Cursor width
        let strategy2ArcWidth = 0.25 // Arc in middle column
        let strategy2ArcX = strategy2CursorWidth + 0.05 + constraints.clearanceBuffer
        
        let strategy2Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: strategy2CursorWidth, height: 0.85, screenSize: screenSize)
        let strategy2Terminal = WindowLayout(app: "Terminal", x: strategy2TerminalX, y: 0.0, width: strategy2TerminalWidth, height: 1.0, screenSize: screenSize)
        let strategy2Arc = WindowLayout(app: "Arc", x: strategy2ArcX, y: 0.05, width: strategy2ArcWidth, height: 0.80, screenSize: screenSize)
        
        print("\n  📋 STRATEGY 2: Three-column layout")
        print("    Cursor: \(Int(strategy2Cursor.width * 100))%×\(Int(strategy2Cursor.height * 100))% at (\(Int(strategy2Cursor.x * 100))%, \(Int(strategy2Cursor.y * 100))%)")
        print("    Arc: \(Int(strategy2Arc.width * 100))%×\(Int(strategy2Arc.height * 100))% at (\(Int(strategy2Arc.x * 100))%, \(Int(strategy2Arc.y * 100))%)")
        print("    Terminal: \(Int(strategy2Terminal.width * 100))%×\(Int(strategy2Terminal.height * 100))% at (\(Int(strategy2Terminal.x * 100))%, \(Int(strategy2Terminal.y * 100))%)")
        
        let strategy2Layouts = [strategy2Cursor, strategy2Terminal, strategy2Arc]
        let strategy2Valid = testLayoutQuiet(layouts: strategy2Layouts, constraints: constraints)
        
        if strategy2Valid {
            print("  ✅ STRATEGY 2 SUCCESSFUL!")
            testLayout(layouts: strategy2Layouts, constraints: constraints)
            return
        }
        
        // STRATEGY 3: Hybrid layout with Arc as overlay (partial overlap acceptable)
        let strategy3CursorWidth = 0.65
        let strategy3ArcWidth = 0.40
        let strategy3ArcHeight = 0.50
        let strategy3ArcX = 0.30 // Position Arc with minimal overlap
        let strategy3ArcY = 0.45 // Position Arc in lower area
        
        let strategy3Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: strategy3CursorWidth, height: 0.85, screenSize: screenSize)
        let strategy3Arc = WindowLayout(app: "Arc", x: strategy3ArcX, y: strategy3ArcY, width: strategy3ArcWidth, height: strategy3ArcHeight, screenSize: screenSize)
        
        print("\n  📋 STRATEGY 3: Hybrid layout (minimal controlled overlap)")
        print("    Cursor: \(Int(strategy3Cursor.width * 100))%×\(Int(strategy3Cursor.height * 100))% at (\(Int(strategy3Cursor.x * 100))%, \(Int(strategy3Cursor.y * 100))%)")
        print("    Arc: \(Int(strategy3Arc.width * 100))%×\(Int(strategy3Arc.height * 100))% at (\(Int(strategy3Arc.x * 100))%, \(Int(strategy3Arc.y * 100))%)")
        
        let strategy3Layouts = [strategy3Cursor, terminal, strategy3Arc]
        let strategy3Valid = testLayoutQuiet(layouts: strategy3Layouts, constraints: constraints)
        
        if strategy3Valid {
            print("  ✅ STRATEGY 3 SUCCESSFUL!")
            testLayout(layouts: strategy3Layouts, constraints: constraints)
            return
        }
        
        // STRATEGY 4: Optimal balanced layout (guaranteed to work)
        print("\n  📋 STRATEGY 4: Optimal balanced layout")
        
        // Calculate exact dimensions to meet all requirements
        let strategy4TerminalWidth = max(0.28, constraints.minTerminalWidth / screenSize.width) // ≥400px
        let strategy4TerminalX = 1.0 - strategy4TerminalWidth
        
        // Arc needs √25% ≈ 50%×50% for 25% area
        let strategy4ArcWidth = 0.50 
        let strategy4ArcHeight = 0.50 // 50%×50% = 25% area exactly
        
        // Position Arc in bottom-left to avoid overlaps
        let strategy4ArcX = 0.05
        let strategy4ArcY = 1.0 - strategy4ArcHeight // Bottom-aligned
        
        // Cursor gets remaining space
        let strategy4CursorWidth = strategy4TerminalX - 0.05 - 0.02 // Up to terminal start minus buffer
        let strategy4CursorHeight = strategy4ArcY - 0.05 - 0.02 // Up to Arc start minus buffer
        
        let strategy4Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: strategy4CursorWidth, height: strategy4CursorHeight, screenSize: screenSize)
        let strategy4Terminal = WindowLayout(app: "Terminal", x: strategy4TerminalX, y: 0.0, width: strategy4TerminalWidth, height: 1.0, screenSize: screenSize)
        let strategy4Arc = WindowLayout(app: "Arc", x: strategy4ArcX, y: strategy4ArcY, width: strategy4ArcWidth, height: strategy4ArcHeight, screenSize: screenSize)
        
        print("    Cursor: \(Int(strategy4Cursor.width * 100))%×\(Int(strategy4Cursor.height * 100))% at (\(Int(strategy4Cursor.x * 100))%, \(Int(strategy4Cursor.y * 100))%)")
        print("    Terminal: \(Int(strategy4Terminal.width * 100))%×\(Int(strategy4Terminal.height * 100))% at (\(Int(strategy4Terminal.x * 100))%, \(Int(strategy4Terminal.y * 100))%)")
        print("    Arc: \(Int(strategy4Arc.width * 100))%×\(Int(strategy4Arc.height * 100))% at (\(Int(strategy4Arc.x * 100))%, \(Int(strategy4Arc.y * 100))%)")
        
        let strategy4Layouts = [strategy4Cursor, strategy4Terminal, strategy4Arc]
        let strategy4Valid = testLayoutQuiet(layouts: strategy4Layouts, constraints: constraints)
        
        if strategy4Valid {
            print("  ✅ STRATEGY 4 SUCCESSFUL!")
            testLayout(layouts: strategy4Layouts, constraints: constraints)
            return
        }
        
        // STRATEGY 5: Perfect balanced layout (optimized proportions)
        print("\n  📋 STRATEGY 5: Perfect balanced layout")
        
        // Give Terminal minimum required width
        let strategy5TerminalWidth = constraints.minTerminalWidth / screenSize.width // Exactly 400px
        let strategy5TerminalX = 1.0 - strategy5TerminalWidth
        
        // Arc gets exactly 25% area using optimal dimensions
        let strategy5ArcWidth = 0.45  // Slightly narrower
        let strategy5ArcHeight = 0.56 // Taller to maintain 25% area (45%×56% = 25.2%)
        
        // Position Arc in bottom-left
        let strategy5ArcX = 0.05
        let strategy5ArcY = 1.0 - strategy5ArcHeight
        
        // Cursor gets maximum remaining space
        let strategy5CursorWidth = strategy5TerminalX - 0.05 - 0.01 // Minimal buffer
        let strategy5CursorHeight = strategy5ArcY - 0.05 - 0.01 // Minimal buffer
        
        let strategy5Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: strategy5CursorWidth, height: strategy5CursorHeight, screenSize: screenSize)
        let strategy5Terminal = WindowLayout(app: "Terminal", x: strategy5TerminalX, y: 0.0, width: strategy5TerminalWidth, height: 1.0, screenSize: screenSize)
        let strategy5Arc = WindowLayout(app: "Arc", x: strategy5ArcX, y: strategy5ArcY, width: strategy5ArcWidth, height: strategy5ArcHeight, screenSize: screenSize)
        
        print("    Cursor: \(Int(strategy5Cursor.width * 100))%×\(Int(strategy5Cursor.height * 100))% at (\(Int(strategy5Cursor.x * 100))%, \(Int(strategy5Cursor.y * 100))%)")
        print("    Terminal: \(Int(strategy5Terminal.width * 100))%×\(Int(strategy5Terminal.height * 100))% at (\(Int(strategy5Terminal.x * 100))%, \(Int(strategy5Terminal.y * 100))%)")
        print("    Arc: \(Int(strategy5Arc.width * 100))%×\(Int(strategy5Arc.height * 100))% at (\(Int(strategy5Arc.x * 100))%, \(Int(strategy5Arc.y * 100))%)")
        
        let strategy5Layouts = [strategy5Cursor, strategy5Terminal, strategy5Arc]
        let strategy5Valid = testLayoutQuiet(layouts: strategy5Layouts, constraints: constraints)
        
        if strategy5Valid {
            print("  ✅ STRATEGY 5 SUCCESSFUL!")
            testLayout(layouts: strategy5Layouts, constraints: constraints)
            return
        }
        
        // STRATEGY 6: Cursor-priority layout (maximum Cursor area while meeting other minimums)
        print("\n  📋 STRATEGY 6: Cursor-priority layout (final attempt)")
        
        // Give Terminal absolute minimum width
        let strategy6TerminalWidth = constraints.minTerminalWidth / screenSize.width // Exactly 400px
        let strategy6TerminalX = 1.0 - strategy6TerminalWidth
        
        // Calculate maximum possible Cursor area while leaving space for Arc minimum
        let availableWidthForCursor = strategy6TerminalX - 0.05 - 0.01 // Space minus buffers
        
        // Arc gets minimum 25% area but positioned to maximize Cursor space  
        let strategy6ArcWidth = 0.40  // Narrower Arc
        let strategy6ArcHeight = 0.625 // Taller Arc (40% × 62.5% = 25% area exactly)
        
        // Position Arc in bottom corner
        let strategy6ArcX = 0.05
        let strategy6ArcY = 1.0 - strategy6ArcHeight
        
        // Cursor gets maximum possible space
        let strategy6CursorWidth = availableWidthForCursor
        let strategy6CursorHeight = strategy6ArcY - 0.05 - 0.01 // Up to Arc start
        
        let strategy6Cursor = WindowLayout(app: "Cursor", x: 0.05, y: 0.05, width: strategy6CursorWidth, height: strategy6CursorHeight, screenSize: screenSize)
        let strategy6Terminal = WindowLayout(app: "Terminal", x: strategy6TerminalX, y: 0.0, width: strategy6TerminalWidth, height: 1.0, screenSize: screenSize)
        let strategy6Arc = WindowLayout(app: "Arc", x: strategy6ArcX, y: strategy6ArcY, width: strategy6ArcWidth, height: strategy6ArcHeight, screenSize: screenSize)
        
        print("    Cursor: \(Int(strategy6Cursor.width * 100))%×\(Int(strategy6Cursor.height * 100))% at (\(Int(strategy6Cursor.x * 100))%, \(Int(strategy6Cursor.y * 100))%)")
        print("    Terminal: \(Int(strategy6Terminal.width * 100))%×\(Int(strategy6Terminal.height * 100))% at (\(Int(strategy6Terminal.x * 100))%, \(Int(strategy6Terminal.y * 100))%)")
        print("    Arc: \(Int(strategy6Arc.width * 100))%×\(Int(strategy6Arc.height * 100))% at (\(Int(strategy6Arc.x * 100))%, \(Int(strategy6Arc.y * 100))%)")
        
        let strategy6Layouts = [strategy6Cursor, strategy6Terminal, strategy6Arc]
        testLayout(layouts: strategy6Layouts, constraints: constraints)
    }
} else {
    // Arc fits below Cursor
    print("  📊 Creating Arc below Cursor:")
    print("    Using arcY: \(arcY), arcHeight: \(arcHeight)")
    print("    Available height below cursor: \(1.0 - arcY)")
    
    // Adjust Arc height to fit available space
    let maxAvailableHeight = 1.0 - arcY
    let finalArcHeight = min(arcHeight, maxAvailableHeight)
    
    print("    Final Arc height: \(finalArcHeight) (\(Int(finalArcHeight * 100))%)")
    
    let arc = WindowLayout(
        app: "Arc",
        x: 0.05,
        y: arcY,
        width: arcWidth,
        height: finalArcHeight,
        screenSize: screenSize
    )
    
    print("  Arc: \(Int(arc.width * 100))%×\(Int(arc.height * 100))% at (\(Int(arc.x * 100))%, \(Int(arc.y * 100))%) [BELOW CURSOR]")
    
    // Test this layout
    let layouts = [cursor, terminal, arc]
    testLayout(layouts: layouts, constraints: constraints)
}
}

func testLayoutQuiet(layouts: [WindowLayout], constraints: LayoutConstraints) -> Bool {
    // Quick validation without output - returns true if layout is valid
    
    // Check screen bounds
    for layout in layouts {
        if layout.pixelBounds.endX > Int(screenSize.width) || layout.pixelBounds.endY > Int(screenSize.height) ||
           layout.pixelBounds.x < 0 || layout.pixelBounds.y < 0 {
            return false
        }
    }
    
    // Check overlaps
    for i in 0..<layouts.count {
        for j in (i+1)..<layouts.count {
            let layout1 = layouts[i]
            let layout2 = layouts[j]
            
            let overlapLeft = max(layout1.pixelBounds.x, layout2.pixelBounds.x)
            let overlapRight = min(layout1.pixelBounds.endX, layout2.pixelBounds.endX)
            let overlapTop = max(layout1.pixelBounds.y, layout2.pixelBounds.y)
            let overlapBottom = min(layout1.pixelBounds.endY, layout2.pixelBounds.endY)
            
            let overlapWidth = max(0, overlapRight - overlapLeft)
            let overlapHeight = max(0, overlapBottom - overlapTop)
            let overlapArea = overlapWidth * overlapHeight
            
            if overlapArea > 0 {
                return false
            }
        }
    }
    
    // Check minimum requirements
    for layout in layouts {
        switch layout.app {
        case "Terminal":
            if layout.pixelBounds.width < Int(constraints.minTerminalWidth) {
                return false
            }
        case "Arc":
            let actualArea = Double(layout.pixelBounds.width * layout.pixelBounds.height)
            let requiredArea = constraints.minArcArea * screenSize.width * screenSize.height
            if actualArea < requiredArea {
                return false
            }
        case "Cursor":
            let actualArea = Double(layout.pixelBounds.width * layout.pixelBounds.height)
            let requiredArea = constraints.minCursorArea * screenSize.width * screenSize.height
            if actualArea < requiredArea {
                return false
            }
        default:
            break
        }
    }
    
    return true
}

func testLayout(layouts: [WindowLayout], constraints: LayoutConstraints) {
    print("\n🧪 TESTING OVERLAP-FREE LAYOUT")
    print("=============================")
    
    // Display layout summary
    for layout in layouts {
        print("  \(layout.app):")
        print("    Size: \(Int(layout.width * 100))%×\(Int(layout.height * 100))% (\(layout.pixelBounds.width)×\(layout.pixelBounds.height) px)")
        print("    Position: (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%) = (\(layout.pixelBounds.x), \(layout.pixelBounds.y) px)")
        print("    Bounds: (\(layout.pixelBounds.x), \(layout.pixelBounds.y)) to (\(layout.pixelBounds.endX), \(layout.pixelBounds.endY))")
    }
    
    // Test 1: Screen bounds
    print("\n🏠 SCREEN BOUNDS TEST:")
    var boundsViolations: [String] = []
    
    for layout in layouts {
        if layout.pixelBounds.endX > Int(screenSize.width) {
            boundsViolations.append("\(layout.app): extends \(layout.pixelBounds.endX - Int(screenSize.width))px beyond right edge")
        }
        if layout.pixelBounds.endY > Int(screenSize.height) {
            boundsViolations.append("\(layout.app): extends \(layout.pixelBounds.endY - Int(screenSize.height))px beyond bottom edge")
        }
        if layout.pixelBounds.x < 0 {
            boundsViolations.append("\(layout.app): extends \(-layout.pixelBounds.x)px beyond left edge")
        }
        if layout.pixelBounds.y < 0 {
            boundsViolations.append("\(layout.app): extends \(-layout.pixelBounds.y)px beyond top edge")
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
    
    // Test 2: Overlaps
    print("\n🔄 OVERLAP TEST:")
    var overlapViolations: [String] = []
    
    for i in 0..<layouts.count {
        for j in (i+1)..<layouts.count {
            let layout1 = layouts[i]
            let layout2 = layouts[j]
            
            let overlapLeft = max(layout1.pixelBounds.x, layout2.pixelBounds.x)
            let overlapRight = min(layout1.pixelBounds.endX, layout2.pixelBounds.endX)
            let overlapTop = max(layout1.pixelBounds.y, layout2.pixelBounds.y)
            let overlapBottom = min(layout1.pixelBounds.endY, layout2.pixelBounds.endY)
            
            let overlapWidth = max(0, overlapRight - overlapLeft)
            let overlapHeight = max(0, overlapBottom - overlapTop)
            let overlapArea = overlapWidth * overlapHeight
            
            if overlapArea > 0 {
                overlapViolations.append("\(layout1.app) ↔ \(layout2.app): \(overlapArea)px² overlap")
            }
        }
    }
    
    if overlapViolations.isEmpty {
        print("  ✅ No overlaps detected")
    } else {
        print("  ❌ OVERLAP VIOLATIONS:")
        for violation in overlapViolations {
            print("    • \(violation)")
        }
    }
    
    // Test 3: Minimum requirements
    print("\n📏 MINIMUM REQUIREMENTS TEST:")
    var requirementViolations: [String] = []
    
    for layout in layouts {
        switch layout.app {
        case "Terminal":
            if layout.pixelBounds.width < Int(constraints.minTerminalWidth) {
                requirementViolations.append("Terminal: width \(layout.pixelBounds.width)px < required \(Int(constraints.minTerminalWidth))px")
            }
        case "Arc":
            let actualArea = Double(layout.pixelBounds.width * layout.pixelBounds.height)
            let requiredArea = constraints.minArcArea * screenSize.width * screenSize.height
            if actualArea < requiredArea {
                requirementViolations.append("Arc: area \(String(format: "%.1f", (actualArea / (screenSize.width * screenSize.height)) * 100))% < required \(String(format: "%.1f", constraints.minArcArea * 100))%")
            }
        case "Cursor":
            let actualArea = Double(layout.pixelBounds.width * layout.pixelBounds.height)
            let requiredArea = constraints.minCursorArea * screenSize.width * screenSize.height
            if actualArea < requiredArea {
                requirementViolations.append("Cursor: area \(String(format: "%.1f", (actualArea / (screenSize.width * screenSize.height)) * 100))% < required \(String(format: "%.1f", constraints.minCursorArea * 100))%")
            }
        default:
            break
        }
    }
    
    if requirementViolations.isEmpty {
        print("  ✅ All minimum requirements met")
    } else {
        print("  ❌ REQUIREMENT VIOLATIONS:")
        for violation in requirementViolations {
            print("    • \(violation)")
        }
    }
    
    // Summary
    let allViolations = boundsViolations + overlapViolations + requirementViolations
    let layoutValid = allViolations.isEmpty
    
    print("\n📊 LAYOUT VALIDATION SUMMARY:")
    print("Screen Bounds: \(boundsViolations.isEmpty ? "✅" : "❌")")
    print("No Overlaps: \(overlapViolations.isEmpty ? "✅" : "❌")")
    print("Min Requirements: \(requirementViolations.isEmpty ? "✅" : "❌")")
    print("\nOVERALL: \(layoutValid ? "✅ VALID LAYOUT" : "❌ VIOLATIONS FOUND")")
    
    if layoutValid {
        print("\n🎉 PERFECT OVERLAP-FREE LAYOUT ACHIEVED!")
        print("Recommended layout for 'i want to code':")
        for layout in layouts {
            print("  • \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
        }
    } else {
        print("\n🔧 VIOLATIONS TO FIX:")
        for (index, violation) in allViolations.enumerated() {
            print("  \(index + 1). \(violation)")
        }
    }
}

// Execute the layout calculation
calculateOptimalLayout()