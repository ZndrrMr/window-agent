#!/usr/bin/env swift

import Foundation

print("🎯 FOCUS-AWARE LAYOUT TESTS")
print("===========================")

let screenSize = (width: 1440.0, height: 900.0)
let apps = ["Xcode", "Arc", "Terminal"]

struct FocusAwareLayout {
    let app: String
    let isFocused: Bool
    let x: Double // percentage
    let y: Double // percentage  
    let width: Double // percentage
    let height: Double // percentage
    let pixelBounds: (x: Int, y: Int, width: Int, height: Int, endX: Int, endY: Int)
    
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
    }
}

// Focus-aware layout generator based on your preferred design
func generateFocusAwareLayout(focusedApp: String, screenSize: (width: Double, height: Double)) -> [FocusAwareLayout] {
    var layouts: [FocusAwareLayout] = []
    
    switch focusedApp.lowercased() {
    case "arc":
        // Arc focused: Arc gets center primary space, Xcode and Terminal get side columns
        layouts.append(FocusAwareLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.20, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Arc", isFocused: true, x: 0.20, y: 0.0, width: 0.60, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Terminal", isFocused: false, x: 0.80, y: 0.0, width: 0.20, height: 1.0, screenSize: screenSize))
        
    case "xcode":
        // Xcode focused: Xcode gets left primary space, Arc gets center, Terminal gets right
        layouts.append(FocusAwareLayout(app: "Xcode", isFocused: true, x: 0.0, y: 0.0, width: 0.55, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Arc", isFocused: false, x: 0.55, y: 0.0, width: 0.30, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Terminal", isFocused: false, x: 0.85, y: 0.0, width: 0.15, height: 1.0, screenSize: screenSize))
        
    case "terminal":
        // Terminal focused: Terminal gets right primary space, Xcode left, Arc center
        layouts.append(FocusAwareLayout(app: "Xcode", isFocused: false, x: 0.0, y: 0.0, width: 0.15, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Arc", isFocused: false, x: 0.15, y: 0.0, width: 0.30, height: 1.0, screenSize: screenSize))
        layouts.append(FocusAwareLayout(app: "Terminal", isFocused: true, x: 0.45, y: 0.0, width: 0.55, height: 1.0, screenSize: screenSize))
        
    default:
        // Default to Arc focused if unknown
        return generateFocusAwareLayout(focusedApp: "Arc", screenSize: screenSize)
    }
    
    return layouts
}

// Test cases based on your preferred layout images
let testCases = [
    ("Arc", "Arc should be primary with Xcode and Terminal as substantial side columns"),
    ("Xcode", "Xcode should be primary with Arc and Terminal visible on the right"),
    ("Terminal", "Terminal should be primary with Xcode and Arc visible on the left")
]

print("🧪 RUNNING FOCUS-AWARE LAYOUT TESTS")
print("====================================")

var allTestsPassed = true

for (focusedApp, description) in testCases {
    print("\n📱 TEST: \(focusedApp.uppercased()) FOCUSED")
    print("Description: \(description)")
    
    let layouts = generateFocusAwareLayout(focusedApp: focusedApp, screenSize: screenSize)
    
    print("Generated Layout:")
    for layout in layouts {
        let focusIndicator = layout.isFocused ? "🎯" : "👁️"
        print("  \(focusIndicator) \(layout.app): \(Int(layout.width * 100))%×\(Int(layout.height * 100))% at (\(Int(layout.x * 100))%, \(Int(layout.y * 100))%)")
        print("    Pixels: \(layout.pixelBounds.width)×\(layout.pixelBounds.height) at (\(layout.pixelBounds.x), \(layout.pixelBounds.y))")
    }
    
    // Test 1: Focused app gets primary space allocation
    let focusedLayout = layouts.first { $0.isFocused }
    guard let focused = focusedLayout else {
        print("  ❌ FAIL: No focused app found")
        allTestsPassed = false
        continue
    }
    
    let focusedAreaPercentage = focused.width * focused.height * 100
    let minimumPrimaryArea = 50.0 // Focused app should get at least 50% of screen
    
    if focusedAreaPercentage >= minimumPrimaryArea {
        print("  ✅ PASS: Focused app (\(focused.app)) gets \(String(format: "%.1f", focusedAreaPercentage))% (≥ \(String(format: "%.1f", minimumPrimaryArea))%)")
    } else {
        print("  ❌ FAIL: Focused app (\(focused.app)) only gets \(String(format: "%.1f", focusedAreaPercentage))% (< \(String(format: "%.1f", minimumPrimaryArea))%)")
        allTestsPassed = false
    }
    
    // Test 2: Non-focused apps remain substantially visible (not tiny)
    let nonFocusedLayouts = layouts.filter { !$0.isFocused }
    var peekTestsPassed = true
    
    for layout in nonFocusedLayouts {
        let areaPercentage = layout.width * layout.height * 100
        let minimumPeekArea = 10.0 // Non-focused apps should get at least 10% of screen
        let maximumPeekArea = 40.0 // But not more than 40% (focused app should be clearly primary)
        
        if areaPercentage >= minimumPeekArea && areaPercentage <= maximumPeekArea {
            print("  ✅ PASS: \(layout.app) peek area \(String(format: "%.1f", areaPercentage))% (within \(String(format: "%.1f", minimumPeekArea))-\(String(format: "%.1f", maximumPeekArea))%)")
        } else {
            print("  ❌ FAIL: \(layout.app) peek area \(String(format: "%.1f", areaPercentage))% (outside \(String(format: "%.1f", minimumPeekArea))-\(String(format: "%.1f", maximumPeekArea))%)")
            peekTestsPassed = false
        }
    }
    
    if peekTestsPassed {
        print("  ✅ PASS: All non-focused apps have substantial peek areas")
    } else {
        print("  ❌ FAIL: Some non-focused apps have inadequate peek areas")
        allTestsPassed = false
    }
    
    // Test 3: Consistent left-to-right positioning (Xcode → Arc → Terminal)
    let xcode = layouts.first { $0.app == "Xcode" }
    let arc = layouts.first { $0.app == "Arc" }
    let terminal = layouts.first { $0.app == "Terminal" }
    
    if let x = xcode, let a = arc, let t = terminal {
        let correctOrder = x.x < a.x && a.x < t.x
        if correctOrder {
            print("  ✅ PASS: Apps maintain left-to-right order (Xcode: \(Int(x.x * 100))%, Arc: \(Int(a.x * 100))%, Terminal: \(Int(t.x * 100))%)")
        } else {
            print("  ❌ FAIL: Apps not in correct left-to-right order (Xcode: \(Int(x.x * 100))%, Arc: \(Int(a.x * 100))%, Terminal: \(Int(t.x * 100))%)")
            allTestsPassed = false
        }
    }
    
    // Test 4: No gaps or overlaps in tiling
    let sortedByX = layouts.sorted { $0.x < $1.x }
    var tilingTestsPassed = true
    
    for i in 0..<(sortedByX.count - 1) {
        let current = sortedByX[i]
        let next = sortedByX[i + 1]
        let currentEnd = current.x + current.width
        let gap = abs(next.x - currentEnd)
        
        if gap < 0.01 { // Allow 1% tolerance
            print("  ✅ PASS: No gap between \(current.app) and \(next.app)")
        } else {
            print("  ❌ FAIL: \(String(format: "%.1f", gap * 100))% gap between \(current.app) and \(next.app)")
            tilingTestsPassed = false
        }
    }
    
    if tilingTestsPassed {
        print("  ✅ PASS: Perfect tiling with no gaps")
    } else {
        print("  ❌ FAIL: Tiling has gaps")
        allTestsPassed = false
    }
    
    // Test 5: Minimum functional sizes (based on actual app requirements)
    var functionalSizeTests = true
    
    for layout in layouts {
        var minimumWidth: Double = 0
        var minimumHeight: Double = 0
        
        switch layout.app {
        case "Terminal":
            minimumWidth = 400 // Terminal needs at least 400px width
            minimumHeight = 300 // Terminal needs at least 300px height
        case "Arc":
            minimumWidth = 600 // Browser needs substantial width
            minimumHeight = 400 // Browser needs substantial height
        case "Xcode":
            minimumWidth = 500 // IDE needs substantial width
            minimumHeight = 400 // IDE needs substantial height
        default:
            minimumWidth = 300
            minimumHeight = 300
        }
        
        if Double(layout.pixelBounds.width) >= minimumWidth && Double(layout.pixelBounds.height) >= minimumHeight {
            print("  ✅ PASS: \(layout.app) meets minimum size (\(layout.pixelBounds.width)×\(layout.pixelBounds.height) ≥ \(Int(minimumWidth))×\(Int(minimumHeight)))")
        } else {
            print("  ❌ FAIL: \(layout.app) below minimum size (\(layout.pixelBounds.width)×\(layout.pixelBounds.height) < \(Int(minimumWidth))×\(Int(minimumHeight)))")
            functionalSizeTests = false
        }
    }
    
    if functionalSizeTests {
        print("  ✅ PASS: All apps meet minimum functional sizes")
    } else {
        print("  ❌ FAIL: Some apps below minimum functional sizes")
        allTestsPassed = false
    }
}

print("\n📊 OVERALL TEST RESULTS")
print("=======================")
if allTestsPassed {
    print("🎉 ALL TESTS PASSED! Focus-aware layout working perfectly.")
} else {
    print("❌ SOME TESTS FAILED. Need to fix focus-aware layout implementation.")
}

print("\n🔄 EXPECTED BEHAVIOR:")
print("• Focused app gets 50-70% of screen space")
print("• Non-focused apps get 10-40% each (substantial, not tiny)")
print("• Left-to-right order always: Xcode → Arc → Terminal")
print("• No gaps in tiling layout")
print("• All apps meet minimum functional sizes")
print("• Layout adapts based on which app has focus")