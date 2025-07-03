#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🔍 CASCADE FLOW DEBUGGER")
print("========================")
print("This will show us exactly what FlexibleLayoutEngine is producing")
print("")

// Simulate the FlexibleLayoutEngine logic
func debugFlexibleLayout() {
    print("🎯 Simulating FlexibleLayoutEngine.generateFocusAwareLayout()")
    print("============================================================")
    
    // Test with 4 apps like you have
    let testApps = ["Xcode", "Arc", "Terminal", "Finder"]
    let screenSize = CGSize(width: 1920, height: 1080)
    
    print("📱 Input apps: \(testApps.joined(separator: ", "))")
    print("🖥️ Screen size: \(screenSize)")
    print("")
    
    // Step 1: App filtering (should keep all 4)
    print("STEP 1: App Filtering")
    print("--------------------")
    print("✅ All 4 apps kept (assuming they're all relevant)")
    print("")
    
    // Step 2: Focus resolution  
    print("STEP 2: Focus Resolution")
    print("-----------------------")
    print("🎯 Focused app: Xcode (assumed primary for coding)")
    print("")
    
    // Step 3: generateRealisticFocusLayout
    print("STEP 3: Archetype Classification")
    print("--------------------------------")
    let archetypes = [
        "Xcode": "codeWorkspace",
        "Arc": "contentCanvas", 
        "Terminal": "textStream",
        "Finder": "glanceableMonitor"
    ]
    
    for (app, archetype) in archetypes {
        print("📱 \(app) → \(archetype)")
    }
    print("")
    
    // Step 4: Role assignment
    print("STEP 4: Role Assignment")
    print("----------------------")
    print("🎯 Primary: Xcode (focused)")
    print("📚 Cascade: Arc (contentCanvas)")
    print("📝 Side Column: Terminal (textStream)")
    print("👁️ Corner: Finder (glanceableMonitor)")
    print("")
    
    // Step 5: Initial sizing (before ensurePerfectScreenCoverage)
    print("STEP 5: Initial Archetype-Based Sizing")
    print("=====================================")
    print("🎯 Xcode (primary): 60%×90% = 54% area")
    print("📚 Arc (cascade): 65%×95% = 61.75% area") 
    print("📝 Terminal (side): 30%×90% = 27% area")
    print("👁️ Finder (corner): 45%×90% = 40.5% area")
    print("")
    
    // Step 6: The critical point - ensurePerfectScreenCoverage
    print("STEP 6: ensurePerfectScreenCoverage() - THE CRITICAL POINT")
    print("=========================================================")
    print("This is where the magic should happen...")
    print("")
    
    // Simulate area calculation
    let areas = [
        ("Xcode", 0.54),
        ("Arc", 0.6175),
        ("Terminal", 0.27),
        ("Finder", 0.405)
    ]
    
    let sortedByArea = areas.sorted { $0.1 > $1.1 }
    print("📊 Apps sorted by area (largest first):")
    for (index, (app, area)) in sortedByArea.enumerated() {
        print("  \(index + 1). \(app): \(Int(area * 10000)/100)% area")
    }
    print("")
    
    print("🧮 For 4 apps, should use intelligent 2×2 with proportional sizing:")
    print("--------------------------------------------------------------------")
    
    // Calculate what SHOULD happen
    let app1 = sortedByArea[0] // Arc (largest)
    let app2 = sortedByArea[1] // Xcode  
    let app3 = sortedByArea[2] // Finder
    let app4 = sortedByArea[3] // Terminal (smallest)
    
    print("📐 Proportional splits calculation:")
    print("  Top row: \(app1.0) vs \(app2.0)")
    print("  Bottom row: \(app3.0) vs \(app4.0)")
    print("  Left col: \(app1.0) vs \(app3.0)")
    print("  Right col: \(app2.0) vs \(app4.0)")
    print("")
    
    // Simulate normalization
    func normalize(_ values: [Double]) -> [Double] {
        let sum = values.reduce(0, +)
        return values.map { $0 / sum }
    }
    
    let topRowSplit = normalize([app1.1, app2.1])
    let bottomRowSplit = normalize([app3.1, app4.1])
    let leftColSplit = normalize([app1.1, app3.1])
    let rightColSplit = normalize([app2.1, app4.1])
    
    let leftWidth = (topRowSplit[0] + bottomRowSplit[0]) / 2.0
    let rightWidth = 1.0 - leftWidth
    let topHeight = (leftColSplit[0] + rightColSplit[0]) / 2.0
    let bottomHeight = 1.0 - topHeight
    
    print("🎯 EXPECTED INTELLIGENT LAYOUT:")
    print("==============================")
    print("📱 \(app1.0): Top-left (\(Int(leftWidth*100))%×\(Int(topHeight*100))%) = \(Int(leftWidth*topHeight*10000)/100)%")
    print("📱 \(app2.0): Top-right (\(Int(rightWidth*100))%×\(Int(topHeight*100))%) = \(Int(rightWidth*topHeight*10000)/100)%") 
    print("📱 \(app3.0): Bottom-left (\(Int(leftWidth*100))%×\(Int(bottomHeight*100))%) = \(Int(leftWidth*bottomHeight*10000)/100)%")
    print("📱 \(app4.0): Bottom-right (\(Int(rightWidth*100))%×\(Int(bottomHeight*100))%) = \(Int(rightWidth*bottomHeight*10000)/100)%")
    print("")
    
    print("❌ If you're seeing uniform 25% quarters, then:")
    print("===============================================")
    print("1. The old ensurePerfectScreenCoverage() is still running")
    print("2. The build didn't pick up the changes")
    print("3. There's a different code path being used")
    print("4. The app needs to be restarted to load new code")
    print("")
    
    print("✅ If you're seeing proportional layout like above, then:")
    print("========================================================")
    print("The intelligent proportional tessellation is working!")
    print("The primary app gets the most space, others are proportional")
    print("")
}

debugFlexibleLayout()

print("🔍 DEBUGGING QUESTIONS:")
print("======================")
print("1. Are you seeing the proportional layout shown above?")
print("2. Or are you still seeing uniform 25% quarters?")
print("3. Did you restart WindowAI after the code changes?")
print("4. Can you run this debug script and compare the expected vs actual?")