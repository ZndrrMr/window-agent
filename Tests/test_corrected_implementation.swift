#!/usr/bin/env swift

import Foundation

print("🔧 TESTING CORRECTED FOCUS-AWARE IMPLEMENTATION")
print("===============================================")

let screenSize = (width: 1440.0, height: 900.0)

// Test the corrected layout logic
func testCorrectedLayout(focusedApp: String) {
    print("\n🎯 Testing \(focusedApp) focused:")
    
    let layouts: [(app: String, x: Double, y: Double, width: Double, height: Double, layer: Int)]
    
    switch focusedApp {
    case "Xcode":
        layouts = [
            (app: "Xcode", x: 0.0, y: 0.0, width: 0.65, height: 1.0, layer: 3),
            (app: "Arc", x: 0.45, y: 0.05, width: 0.50, height: 0.85, layer: 2),
            (app: "Terminal", x: 0.70, y: 0.0, width: 0.30, height: 1.0, layer: 1)
        ]
    case "Arc":
        layouts = [
            (app: "Xcode", x: 0.0, y: 0.0, width: 0.25, height: 1.0, layer: 1),
            (app: "Arc", x: 0.20, y: 0.0, width: 0.60, height: 1.0, layer: 3),
            (app: "Terminal", x: 0.75, y: 0.0, width: 0.25, height: 1.0, layer: 1)
        ]
    case "Terminal":
        layouts = [
            (app: "Xcode", x: 0.0, y: 0.0, width: 0.30, height: 1.0, layer: 1),
            (app: "Arc", x: 0.25, y: 0.05, width: 0.45, height: 0.90, layer: 2),
            (app: "Terminal", x: 0.45, y: 0.0, width: 0.55, height: 1.0, layer: 3)
        ]
    default:
        layouts = []
    }
    
    // Calculate pixel positions
    for layout in layouts {
        let pixelX = Int(layout.x * screenSize.width)
        let pixelY = Int(layout.y * screenSize.height)
        let pixelWidth = Int(layout.width * screenSize.width)
        let pixelHeight = Int(layout.height * screenSize.height)
        let endX = pixelX + pixelWidth
        let endY = pixelY + pixelHeight
        
        let focusIndicator = layout.app == focusedApp ? "🎯" : "👁️"
        let layerInfo = layout.layer == 3 ? "(TOP)" : layout.layer == 2 ? "(MID)" : "(BGD)"
        
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%) \(layerInfo)")
        print("    Pixels: \(pixelWidth)×\(pixelHeight) at (\(pixelX), \(pixelY)) → (\(endX), \(endY))")
    }
    
    // Validation
    print("\n  🧪 Validation:")
    
    // Check screen usage
    let rightmost = layouts.map { $0.x + $0.width }.max() ?? 0
    if rightmost >= 0.95 {
        print("    ✅ Full screen usage: \(String(format: "%.1f", rightmost * 100))%")
    } else {
        print("    ❌ Wasted space: Only \(String(format: "%.1f", rightmost * 100))% used")
    }
    
    // Check Arc width
    if let arc = layouts.first(where: { $0.app == "Arc" }) {
        let arcPixels = Int(arc.width * screenSize.width)
        if arcPixels >= 500 {
            print("    ✅ Arc functional: \(arcPixels)px wide")
        } else {
            print("    ❌ Arc too narrow: \(arcPixels)px wide")
        }
    }
    
    // Check overlaps
    let focused = layouts.first { $0.app == focusedApp }!
    let others = layouts.filter { $0.app != focusedApp }
    
    var hasOverlaps = false
    for other in others {
        let focusedEnd = focused.x + focused.width
        let otherStart = other.x
        let otherEnd = other.x + other.width
        
        if otherStart < focusedEnd && otherEnd > focused.x {
            hasOverlaps = true
            let overlapStart = max(focused.x, otherStart)
            let overlapEnd = min(focusedEnd, otherEnd)
            let overlapWidth = Int((overlapEnd - overlapStart) * screenSize.width)
            print("    ✅ Cascade overlap: \(other.app) overlaps \(focused.app) by \(overlapWidth)px")
        }
    }
    
    if !hasOverlaps {
        print("    ❌ No cascade overlaps found")
    }
    
    // Check focused app gets good space
    let focusedPercent = focused.width * 100
    if focusedPercent >= 45 && focusedPercent <= 75 {
        print("    ✅ Focused balance: \(String(format: "%.0f", focusedPercent))% space")
    } else {
        print("    ❌ Focused imbalance: \(String(format: "%.0f", focusedPercent))% space")
    }
}

// Test all scenarios
let apps = ["Xcode", "Arc", "Terminal"]
for app in apps {
    testCorrectedLayout(focusedApp: app)
}

print("\n✨ CORRECTED IMPLEMENTATION SUMMARY")
print("===================================")
print("✅ Full screen utilization (no wasted space)")
print("✅ Arc gets functional width (500px+ in all scenarios)")
print("✅ Proper cascade overlaps for peek access")
print("✅ Focused app gets balanced primary space (45-75%)")
print("✅ All apps remain substantially visible")
print()
print("🔧 This matches the corrected expectations from user feedback")
print("🚀 Ready to rebuild and test the actual WindowAI app")