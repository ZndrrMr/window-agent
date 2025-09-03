#!/usr/bin/env swift

import Foundation

print("🎯 REALISTIC FOCUS-AWARE LAYOUT ENGINE")
print("======================================")

let screenSize = (width: 1440.0, height: 900.0)

struct RealisticAppRequirements {
    let name: String
    let functionalMinWidth: Double // Realistic minimum for usability (not ideal)
    let preferredWidth: Double // Ideal width when focused
    let minHeight: Double
}

// Based on your actual screenshots - more realistic functional minimums
let realisticRequirements: [String: RealisticAppRequirements] = [
    "Xcode": RealisticAppRequirements(name: "Xcode", functionalMinWidth: 300, preferredWidth: 800, minHeight: 400),
    "Arc": RealisticAppRequirements(name: "Arc", functionalMinWidth: 350, preferredWidth: 900, minHeight: 400),
    "Terminal": RealisticAppRequirements(name: "Terminal", functionalMinWidth: 250, preferredWidth: 600, minHeight: 300)
]

struct RealisticLayout {
    let app: String
    let isFocused: Bool
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    let pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int)
    let isFunctional: Bool
    let focusBonus: Double // How much extra space this app got due to focus
    
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
        
        // Check if this layout is functionally usable
        if let requirements = realisticRequirements[app] {
            self.isFunctional = Double(pixelWidth) >= requirements.functionalMinWidth && Double(pixelHeight) >= requirements.minHeight
        } else {
            self.isFunctional = true
        }
        
        // Calculate focus bonus (how much extra space due to being focused)
        if let requirements = realisticRequirements[app] {
            let functionalMinPercent = requirements.functionalMinWidth / screenSize.width
            self.focusBonus = max(0, width - functionalMinPercent)
        } else {
            self.focusBonus = 0
        }
    }
}

func generateRealisticFocusLayout(focusedApp: String, screenSize: (width: Double, height: Double)) -> [RealisticLayout] {
    let apps = ["Xcode", "Arc", "Terminal"]
    
    print("🎯 Generating layout with \(focusedApp) focused")
    
    // Step 1: Calculate functional minimums for each app
    var functionalMins: [String: Double] = [:]
    var totalFunctionalMin: Double = 0
    
    for app in apps {
        if let requirements = realisticRequirements[app] {
            let minPercent = requirements.functionalMinWidth / screenSize.width
            functionalMins[app] = minPercent
            totalFunctionalMin += minPercent
        } else {
            functionalMins[app] = 0.15 // Default 15%
            totalFunctionalMin += 0.15
        }
    }
    
    print("\n📊 Functional Minimum Widths:")
    for app in apps {
        let minPixels = Int(functionalMins[app]! * screenSize.width)
        print("  \(app): \(String(format: "%.1f", functionalMins[app]! * 100))% (\(minPixels)px)")
    }
    print("  Total minimums: \(String(format: "%.1f", totalFunctionalMin * 100))%")
    
    // Step 2: Calculate available space for focus allocation
    let availableForFocus = max(0.0, 1.0 - totalFunctionalMin)
    print("  Available for focus: \(String(format: "%.1f", availableForFocus * 100))%")
    
    // Step 3: Allocate widths with focus-aware distribution
    var finalWidths: [String: Double] = [:]
    
    if availableForFocus > 0 {
        // Give most of the bonus space to focused app, some to others for better balance
        let focusedBonus = availableForFocus * 0.75 // 75% of available space to focused app
        let peekBonus = availableForFocus * 0.25 / 2 // Remaining 25% split between peek apps
        
        for app in apps {
            if app == focusedApp {
                finalWidths[app] = functionalMins[app]! + focusedBonus
            } else {
                finalWidths[app] = functionalMins[app]! + peekBonus
            }
        }
    } else {
        // If minimums exceed screen, we need to compress intelligently
        print("⚠️  Screen too small for all functional minimums, using intelligent compression")
        
        // Give focused app preference in the compression
        let focusedMinPercent = functionalMins[focusedApp]!
        let otherApps = apps.filter { $0 != focusedApp }
        
        // Try to give focused app at least 45% of screen
        let targetFocusedPercent = max(focusedMinPercent, 0.45)
        let remainingForOthers = 1.0 - targetFocusedPercent
        
        finalWidths[focusedApp] = targetFocusedPercent
        
        // Distribute remaining space proportionally among others
        let totalOtherMins = otherApps.reduce(0) { $0 + functionalMins[$1]! }
        for app in otherApps {
            let proportion = functionalMins[app]! / totalOtherMins
            finalWidths[app] = remainingForOthers * proportion
        }
    }
    
    print("\n📐 Final Width Allocation:")
    var totalAllocated = 0.0
    for app in apps {
        let pixels = Int(finalWidths[app]! * screenSize.width)
        let focusIndicator = app == focusedApp ? "🎯" : "👁️"
        print("  \(focusIndicator) \(app): \(String(format: "%.1f", finalWidths[app]! * 100))% (\(pixels)px)")
        totalAllocated += finalWidths[app]!
    }
    print("  Total allocated: \(String(format: "%.1f", totalAllocated * 100))%")
    
    // Step 4: Create layouts maintaining left-to-right order
    var layouts: [RealisticLayout] = []
    var currentX: Double = 0.0
    
    for app in apps {
        let width = finalWidths[app]!
        let isFocused = app == focusedApp
        
        layouts.append(RealisticLayout(
            app: app,
            isFocused: isFocused,
            x: currentX,
            y: 0.0,
            width: width,
            height: 1.0,
            screenSize: screenSize
        ))
        
        currentX += width
    }
    
    return layouts
}

// Test all focus scenarios with comprehensive validation
let testCases = ["Arc", "Xcode", "Terminal"]
var allScenariosPassed = true

for focusedApp in testCases {
    print("\n" + "🎯 TESTING: \(focusedApp.uppercased()) FOCUSED")
    print("=" + String(repeating: "=", count: 40))
    
    let layouts = generateRealisticFocusLayout(focusedApp: focusedApp, screenSize: screenSize)
    
    print("\n📱 Generated Layout:")
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        let functionalIndicator = layout.isFunctional ? "✅" : "❌"
        let bonusInfo = layout.focusBonus > 0 ? "+\(String(format: "%.1f", layout.focusBonus * 100))%" : ""
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%) \(functionalIndicator) \(bonusInfo)")
        print("    Pixels: \(layout.pixelBounds.width)×\(layout.pixelBounds.height)")
    }
    
    // Comprehensive validation
    print("\n🧪 Validation Results:")
    var scenarioPassed = true
    
    // Test 1: Focused app gets substantial space
    let focusedLayout = layouts.first { $0.isFocused }!
    let focusedAreaPercent = focusedLayout.width * 100
    if focusedAreaPercent >= 40.0 {
        print("  ✅ Focus allocation: \(focusedLayout.app) gets \(String(format: "%.1f", focusedAreaPercent))% (≥ 40%)")
    } else {
        print("  ❌ Focus allocation: \(focusedLayout.app) only gets \(String(format: "%.1f", focusedAreaPercent))% (< 40%)")
        scenarioPassed = false
    }
    
    // Test 2: All apps are functionally usable
    let allFunctional = layouts.allSatisfy { $0.isFunctional }
    if allFunctional {
        print("  ✅ Functionality: All apps meet functional minimum requirements")
    } else {
        print("  ❌ Functionality: Some apps below functional minimums")
        for layout in layouts.filter({ !$0.isFunctional }) {
            if let req = realisticRequirements[layout.app] {
                print("    • \(layout.app): \(layout.pixelBounds.width)px < \(Int(req.functionalMinWidth))px minimum")
            }
        }
        scenarioPassed = false
    }
    
    // Test 3: Focus priority is clear
    let focusedWidth = focusedLayout.width
    let maxPeekWidth = layouts.filter { !$0.isFocused }.map { $0.width }.max() ?? 0
    let focusAdvantage = (focusedWidth - maxPeekWidth) * 100
    
    if focusAdvantage >= 10.0 {
        print("  ✅ Focus priority: Focused app \(String(format: "%.1f", focusAdvantage))% larger than largest peek app")
    } else {
        print("  ❌ Focus priority: Focused app only \(String(format: "%.1f", focusAdvantage))% larger than peek apps")
        scenarioPassed = false
    }
    
    // Test 4: Peek apps remain substantial
    let peekLayouts = layouts.filter { !$0.isFocused }
    let allPeeksSubstantial = peekLayouts.allSatisfy { $0.width >= 0.12 } // At least 12% each
    if allPeeksSubstantial {
        print("  ✅ Peek visibility: All peek apps ≥ 12% width (substantial)")
    } else {
        print("  ❌ Peek visibility: Some peek apps too narrow")
        scenarioPassed = false
    }
    
    // Test 5: Perfect tiling
    let totalWidth = layouts.reduce(0) { $0 + $1.width }
    if abs(totalWidth - 1.0) < 0.01 {
        print("  ✅ Tiling: Perfect coverage (\(String(format: "%.1f", totalWidth * 100))%)")
    } else {
        print("  ❌ Tiling: Imperfect coverage (\(String(format: "%.1f", totalWidth * 100))%)")
        scenarioPassed = false
    }
    
    // Test 6: Correct ordering
    let xcode = layouts.first { $0.app == "Xcode" }!
    let arc = layouts.first { $0.app == "Arc" }!
    let terminal = layouts.first { $0.app == "Terminal" }!
    
    if xcode.x < arc.x && arc.x < terminal.x {
        print("  ✅ Ordering: Correct left-to-right sequence (Xcode → Arc → Terminal)")
    } else {
        print("  ❌ Ordering: Incorrect app sequence")
        scenarioPassed = false
    }
    
    if scenarioPassed {
        print("\n🎉 SCENARIO PASSED: Perfect focus-aware layout for \(focusedApp)!")
    } else {
        print("\n❌ SCENARIO FAILED: Issues found with \(focusedApp) focused layout")
        allScenariosPassed = false
    }
}

print("\n" + "📊 FINAL RESULTS")
print("=" + String(repeating: "=", count: 20))
if allScenariosPassed {
    print("🎉 ALL SCENARIOS PASSED! Focus-aware layout engine working perfectly.")
    print("\n✨ Ready to implement in production system!")
    print("\n📋 Key Success Factors:")
    print("• Dynamic space allocation based on focus")
    print("• Realistic functional minimums (not perfect ideals)")
    print("• Intelligent compression when screen is constrained")
    print("• Maintains left-to-right app ordering")
    print("• Ensures all apps remain substantially visible and functional")
} else {
    print("❌ SOME SCENARIOS FAILED. Need further refinement.")
}