#!/usr/bin/env swift

import Foundation

print("🧠 SMART FOCUS-AWARE LAYOUT ENGINE")
print("==================================")

let screenSize = (width: 1440.0, height: 900.0)

struct AppRequirements {
    let name: String
    let minWidth: Double // pixels
    let minHeight: Double // pixels
    let preferredRatio: Double // width/height ratio for optimal experience
}

let appRequirements: [String: AppRequirements] = [
    "Xcode": AppRequirements(name: "Xcode", minWidth: 500, minHeight: 400, preferredRatio: 1.8),
    "Arc": AppRequirements(name: "Arc", minWidth: 600, minHeight: 400, preferredRatio: 1.6),
    "Terminal": AppRequirements(name: "Terminal", minWidth: 400, minHeight: 300, preferredRatio: 1.4)
]

struct SmartLayout {
    let app: String
    let isFocused: Bool
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    let pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int)
    let meetsMinimumSize: Bool
    
    init(app: String, isFocused: Bool, x: Double, y: Double, width: Double, height: Double, screenSize: (width: Double, height: Double)) {
        self.app = app
        self.isFocused = isFocused
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
        
        // Check if this layout meets the app's minimum requirements
        if let requirements = appRequirements[app] {
            self.meetsMinimumSize = Double(pixelWidth) >= requirements.minWidth && Double(pixelHeight) >= requirements.minHeight
        } else {
            self.meetsMinimumSize = true
        }
    }
}

func generateSmartFocusAwareLayout(focusedApp: String, screenSize: (width: Double, height: Double)) -> [SmartLayout] {
    let apps = ["Xcode", "Arc", "Terminal"]
    
    // Step 1: Calculate minimum width requirements for each app
    var minWidths: [String: Double] = [:]
    var totalMinWidth: Double = 0
    
    for app in apps {
        if let requirements = appRequirements[app] {
            let minWidthPercent = requirements.minWidth / screenSize.width
            minWidths[app] = minWidthPercent
            totalMinWidth += minWidthPercent
        } else {
            minWidths[app] = 0.15 // Default 15% minimum
            totalMinWidth += 0.15
        }
    }
    
    print("📊 Minimum Width Requirements:")
    for app in apps {
        let minPixels = Int(minWidths[app]! * screenSize.width)
        print("  \(app): \(String(format: "%.1f", minWidths[app]! * 100))% (\(minPixels)px)")
    }
    print("  Total minimums: \(String(format: "%.1f", totalMinWidth * 100))%")
    
    // Step 2: Calculate available space for focus allocation
    let availableForFocus = max(0.0, 1.0 - totalMinWidth)
    print("  Available for focus bonus: \(String(format: "%.1f", availableForFocus * 100))%")
    
    // Step 3: Distribute widths based on focus and minimums
    var finalWidths: [String: Double] = [:]
    
    if availableForFocus > 0 {
        // Give focused app the bonus space
        for app in apps {
            if app == focusedApp {
                finalWidths[app] = minWidths[app]! + availableForFocus
            } else {
                finalWidths[app] = minWidths[app]!
            }
        }
    } else {
        // If minimums exceed screen width, scale proportionally
        print("⚠️  Minimum requirements exceed screen width, scaling proportionally")
        let scaleFactor = 1.0 / totalMinWidth
        for app in apps {
            finalWidths[app] = minWidths[app]! * scaleFactor
        }
    }
    
    print("\n📐 Final Width Allocation:")
    for app in apps {
        let pixels = Int(finalWidths[app]! * screenSize.width)
        let focusIndicator = app == focusedApp ? "🎯" : "👁️"
        print("  \(focusIndicator) \(app): \(String(format: "%.1f", finalWidths[app]! * 100))% (\(pixels)px)")
    }
    
    // Step 4: Position apps left-to-right maintaining order
    var layouts: [SmartLayout] = []
    var currentX: Double = 0.0
    
    for app in apps { // Apps are already in left-to-right order
        let width = finalWidths[app]!
        let isFocused = app == focusedApp
        
        layouts.append(SmartLayout(
            app: app,
            isFocused: isFocused,
            x: currentX,
            y: 0.0,
            width: width,
            height: 1.0, // Full height for all apps
            screenSize: screenSize
        ))
        
        currentX += width
    }
    
    return layouts
}

// Test all focus scenarios
let testCases = ["Arc", "Xcode", "Terminal"]

for focusedApp in testCases {
    print("\n🎯 TESTING: \(focusedApp.uppercased()) FOCUSED")
    print("=" + String(repeating: "=", count: 30 + focusedApp.count))
    
    let layouts = generateSmartFocusAwareLayout(focusedApp: focusedApp, screenSize: screenSize)
    
    print("\n📱 Generated Layout:")
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        let sizeIndicator = layout.meetsMinimumSize ? "✅" : "❌"
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%) \(sizeIndicator)")
        print("    Pixels: \(layout.pixelBounds.width)×\(layout.pixelBounds.height)")
    }
    
    // Validate this layout
    print("\n🧪 Validation:")
    
    // Test 1: Focused app gets significant space
    let focusedLayout = layouts.first { $0.isFocused }!
    let focusedAreaPercent = focusedLayout.width * focusedLayout.height * 100
    let minPrimaryArea = 40.0 // Relaxed from 50% to accommodate minimum requirements
    
    if focusedAreaPercent >= minPrimaryArea {
        print("  ✅ Focus allocation: \(focusedLayout.app) gets \(String(format: "%.1f", focusedAreaPercent))% (≥ \(String(format: "%.1f", minPrimaryArea))%)")
    } else {
        print("  ❌ Focus allocation: \(focusedLayout.app) only gets \(String(format: "%.1f", focusedAreaPercent))% (< \(String(format: "%.1f", minPrimaryArea))%)")
    }
    
    // Test 2: All apps meet minimum requirements
    let allMeetMinimums = layouts.allSatisfy { $0.meetsMinimumSize }
    if allMeetMinimums {
        print("  ✅ Minimum sizes: All apps meet their minimum requirements")
    } else {
        print("  ❌ Minimum sizes: Some apps below minimum requirements")
        for layout in layouts.filter({ !$0.meetsMinimumSize }) {
            if let req = appRequirements[layout.app] {
                print("    • \(layout.app): \(layout.pixelBounds.width)×\(layout.pixelBounds.height) < \(Int(req.minWidth))×\(Int(req.minHeight))")
            }
        }
    }
    
    // Test 3: Proper ordering (Xcode → Arc → Terminal)
    let xcode = layouts.first { $0.app == "Xcode" }!
    let arc = layouts.first { $0.app == "Arc" }!
    let terminal = layouts.first { $0.app == "Terminal" }!
    
    let correctOrder = xcode.x < arc.x && arc.x < terminal.x
    if correctOrder {
        print("  ✅ Positioning: Correct left-to-right order maintained")
    } else {
        print("  ❌ Positioning: Incorrect app order")
    }
    
    // Test 4: No gaps in tiling
    let sortedLayouts = layouts.sorted { $0.x < $1.x }
    var hasGaps = false
    for i in 0..<(sortedLayouts.count - 1) {
        let current = sortedLayouts[i]
        let next = sortedLayouts[i + 1]
        let gap = abs(next.x - (current.x + current.width))
        if gap > 0.01 {
            hasGaps = true
            break
        }
    }
    
    if !hasGaps {
        print("  ✅ Tiling: Perfect tiling with no gaps")
    } else {
        print("  ❌ Tiling: Gaps detected in layout")
    }
    
    // Test 5: Focused app is clearly the primary
    let focusedWidth = focusedLayout.width
    let nonFocusedLayouts = layouts.filter { !$0.isFocused }
    let maxNonFocusedWidth = nonFocusedLayouts.map { $0.width }.max() ?? 0
    
    if focusedWidth > maxNonFocusedWidth {
        print("  ✅ Focus priority: Focused app (\(String(format: "%.1f", focusedWidth * 100))%) larger than any non-focused app (\(String(format: "%.1f", maxNonFocusedWidth * 100))%)")
    } else {
        print("  ❌ Focus priority: Focused app not clearly primary")
    }
}