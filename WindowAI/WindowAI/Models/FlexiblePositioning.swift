import Foundation
import CoreGraphics

// MARK: - Flexible Position
struct FlexiblePosition: Codable {
    // Position can be specified as percentage (0.0-1.0) or absolute pixels
    let x: PositionValue
    let y: PositionValue
    
    enum PositionValue: Codable {
        case percentage(Double)  // 0.0 to 1.0
        case pixels(Double)      // Absolute pixels
        case offset(Double)      // Offset from current position
        
        func toPixels(for dimension: Double, current: Double = 0) -> Double {
            switch self {
            case .percentage(let pct):
                return dimension * pct
            case .pixels(let px):
                return px
            case .offset(let off):
                return current + off
            }
        }
    }
    
    // Convenience initializers
    static func percentage(x: Double, y: Double) -> FlexiblePosition {
        return FlexiblePosition(x: .percentage(x), y: .percentage(y))
    }
    
    static func pixels(x: Double, y: Double) -> FlexiblePosition {
        return FlexiblePosition(x: .pixels(x), y: .pixels(y))
    }
    
    static func offset(x: Double, y: Double) -> FlexiblePosition {
        return FlexiblePosition(x: .offset(x), y: .offset(y))
    }
}

// MARK: - Flexible Size
struct FlexibleSize: Codable {
    let width: SizeValue
    let height: SizeValue
    
    enum SizeValue: Codable {
        case percentage(Double)   // 0.0 to 1.0 of screen
        case pixels(Double)       // Absolute pixels
        case aspectRatio(Double)  // Maintain aspect ratio based on other dimension
        case content             // Size to content (app decides)
        
        func toPixels(for dimension: Double, otherDimension: Double? = nil) -> Double? {
            switch self {
            case .percentage(let pct):
                return dimension * pct
            case .pixels(let px):
                return px
            case .aspectRatio(let ratio):
                guard let other = otherDimension else { return nil }
                return other * ratio
            case .content:
                return nil // App decides
            }
        }
    }
    
    // Convenience initializers
    static func percentage(width: Double, height: Double) -> FlexibleSize {
        return FlexibleSize(width: .percentage(width), height: .percentage(height))
    }
    
    static func pixels(width: Double, height: Double) -> FlexibleSize {
        return FlexibleSize(width: .pixels(width), height: .pixels(height))
    }
    
    static func aspectRatio(width: Double, ratio: Double) -> FlexibleSize {
        return FlexibleSize(width: .pixels(width), height: .aspectRatio(ratio))
    }
}

// MARK: - Cascade Configuration
struct CascadeConfiguration: Codable {
    let style: CascadeStyle
    let offset: CascadeOffset
    let priority: CascadePriority
    
    enum CascadeStyle: String, Codable {
        case standard    // Regular cascade with consistent offsets
        case tight       // Minimal offsets for space efficiency
        case spread      // Larger offsets for better visibility
        case diagonal    // Diagonal arrangement
        case fan         // Fan-out arrangement
        case smart       // Intelligent based on window count and screen size
    }
    
    struct CascadeOffset: Codable {
        let horizontal: Double  // Pixels or percentage
        let vertical: Double    // Pixels or percentage
        let isPercentage: Bool
        
        static let tight = CascadeOffset(horizontal: 20, vertical: 20, isPercentage: false)
        static let standard = CascadeOffset(horizontal: 50, vertical: 50, isPercentage: false)
        static let spread = CascadeOffset(horizontal: 100, vertical: 80, isPercentage: false)
        static let percentage = CascadeOffset(horizontal: 0.05, vertical: 0.05, isPercentage: true)
    }
    
    enum CascadePriority: String, Codable {
        case visibility     // Maximize visible area of each window
        case access         // Ensure clickable area for each window
        case primary        // Maximize primary window visibility
        case balanced       // Balance all factors
    }
}

// MARK: - Positioning Presets
struct PositioningPresets {
    // Percentage-based positions for flexibility across screen sizes
    static let flexiblePositions: [String: FlexiblePosition] = [
        // Precise percentage positions
        "5%": .percentage(x: 0.05, y: 0.05),
        "10%": .percentage(x: 0.10, y: 0.10),
        "15%": .percentage(x: 0.15, y: 0.15),
        "20%": .percentage(x: 0.20, y: 0.20),
        "25%": .percentage(x: 0.25, y: 0.25),
        "30%": .percentage(x: 0.30, y: 0.30),
        "35%": .percentage(x: 0.35, y: 0.35),
        "40%": .percentage(x: 0.40, y: 0.40),
        "45%": .percentage(x: 0.45, y: 0.45),
        "center": .percentage(x: 0.50, y: 0.50),
        "55%": .percentage(x: 0.55, y: 0.55),
        "60%": .percentage(x: 0.60, y: 0.60),
        "65%": .percentage(x: 0.65, y: 0.65),
        "70%": .percentage(x: 0.70, y: 0.70),
        "75%": .percentage(x: 0.75, y: 0.75),
        "80%": .percentage(x: 0.80, y: 0.80),
        "85%": .percentage(x: 0.85, y: 0.85),
        "90%": .percentage(x: 0.90, y: 0.90),
        "95%": .percentage(x: 0.95, y: 0.95),
        
        // Asymmetric positions
        "top-20": .percentage(x: 0.50, y: 0.20),
        "bottom-80": .percentage(x: 0.50, y: 0.80),
        "left-15": .percentage(x: 0.15, y: 0.50),
        "right-85": .percentage(x: 0.85, y: 0.50),
        
        // Golden ratio positions
        "golden-left": .percentage(x: 0.382, y: 0.50),
        "golden-right": .percentage(x: 0.618, y: 0.50),
        "golden-top": .percentage(x: 0.50, y: 0.382),
        "golden-bottom": .percentage(x: 0.50, y: 0.618),
    ]
    
    // Flexible sizes
    static let flexibleSizes: [String: FlexibleSize] = [
        // Precise percentage sizes
        "10%": .percentage(width: 0.10, height: 0.10),
        "15%": .percentage(width: 0.15, height: 0.15),
        "20%": .percentage(width: 0.20, height: 0.20),
        "23%": .percentage(width: 0.23, height: 0.23),
        "25%": .percentage(width: 0.25, height: 0.25),
        "30%": .percentage(width: 0.30, height: 0.30),
        "33%": .percentage(width: 0.33, height: 0.33),
        "35%": .percentage(width: 0.35, height: 0.35),
        "38%": .percentage(width: 0.38, height: 0.38),
        "40%": .percentage(width: 0.40, height: 0.40),
        "42%": .percentage(width: 0.42, height: 0.42),
        "45%": .percentage(width: 0.45, height: 0.45),
        "48%": .percentage(width: 0.48, height: 0.48),
        "50%": .percentage(width: 0.50, height: 0.50),
        "52%": .percentage(width: 0.52, height: 0.52),
        "55%": .percentage(width: 0.55, height: 0.55),
        "58%": .percentage(width: 0.58, height: 0.58),
        "60%": .percentage(width: 0.60, height: 0.60),
        "62%": .percentage(width: 0.62, height: 0.62),
        "65%": .percentage(width: 0.65, height: 0.65),
        "67%": .percentage(width: 0.67, height: 0.67),
        "70%": .percentage(width: 0.70, height: 0.70),
        "73%": .percentage(width: 0.73, height: 0.73),
        "75%": .percentage(width: 0.75, height: 0.75),
        "77%": .percentage(width: 0.77, height: 0.77),
        "80%": .percentage(width: 0.80, height: 0.80),
        "82%": .percentage(width: 0.82, height: 0.82),
        "85%": .percentage(width: 0.85, height: 0.85),
        "88%": .percentage(width: 0.88, height: 0.88),
        "90%": .percentage(width: 0.90, height: 0.90),
        "92%": .percentage(width: 0.92, height: 0.92),
        "95%": .percentage(width: 0.95, height: 0.95),
        
        // Asymmetric sizes
        "wide-short": .percentage(width: 0.80, height: 0.40),
        "tall-narrow": .percentage(width: 0.30, height: 0.80),
        "terminal-optimal": .pixels(width: 800, height: 600),
        "music-compact": .pixels(width: 400, height: 500),
        "message-peek": .percentage(width: 0.25, height: 0.40),
        
        // Golden ratio sizes
        "golden-wide": .percentage(width: 0.618, height: 0.382),
        "golden-tall": .percentage(width: 0.382, height: 0.618),
    ]
}

// MARK: - Window Arrangement
struct FlexibleWindowArrangement: Codable {
    let window: String  // App name
    let position: FlexiblePosition
    let size: FlexibleSize
    let layer: Int      // Z-index (0 = bottom, higher = on top)
    let visibility: WindowVisibility
    
    enum WindowVisibility: String, Codable {
        case full         // Completely visible
        case partial      // Partially visible (cascade)
        case minimal      // Just enough to click
        case hidden       // Completely hidden (not recommended)
    }
}

// MARK: - Intelligent Layout Engine
class FlexibleLayoutEngine {
    
    // Generate focus-aware dynamic layout based on user intent and focus
    static func generateFocusAwareLayout(
        for windows: [String],
        screenSize: CGSize,
        focusedApp: String? = nil,
        context: String = "general"
    ) -> [FlexibleWindowArrangement] {
        
        let filter = ContextualAppFilter.shared
        
        // STEP 1: Smart app filtering - only keep relevant apps
        let relevantApps = filter.selectRelevantApps(
            from: windows,
            for: context,
            maxApps: 4
        )
        
        print("🎯 FOCUS-AWARE LAYOUT:")
        print("  📝 Context: '\(context)'")
        print("  🎯 Focused: \(focusedApp ?? "Auto-detect")")
        print("  📱 Apps: \(relevantApps.joined(separator: ", "))")
        
        // STEP 2: Determine focused app (use provided or auto-detect primary)
        let actualFocusedApp: String
        if let focused = focusedApp, relevantApps.contains(focused) {
            actualFocusedApp = focused
        } else {
            // Auto-detect: prioritize by archetype priority for context
            if context.contains("cod") {
                // Sort apps by coding context priority (codeWorkspace > contentCanvas > textStream > glanceableMonitor)
                print("  🔍 DEBUG: Focus resolution for coding context:")
                for app in relevantApps {
                    let archetype = AppArchetypeClassifier.shared.classifyApp(app)
                    let priority = getCodingContextPriority(archetype)
                    print("    📱 \(app): \(archetype.rawValue) (priority \(priority))")
                }
                
                let sortedByPriority = relevantApps.sorted { app1, app2 in
                    let archetype1 = AppArchetypeClassifier.shared.classifyApp(app1)
                    let archetype2 = AppArchetypeClassifier.shared.classifyApp(app2)
                    let priority1 = getCodingContextPriority(archetype1)
                    let priority2 = getCodingContextPriority(archetype2)
                    return priority1 < priority2
                }
                print("  🎯 Sorted by priority: \(sortedByPriority)")
                actualFocusedApp = sortedByPriority.first ?? ""
            } else {
                actualFocusedApp = relevantApps.first ?? ""
            }
        }
        
        print("  🎯 Focus resolved to: \(actualFocusedApp)")
        
        // STEP 3: Generate focus-aware tiling layout
        return generateRealisticFocusLayout(
            apps: relevantApps,
            focusedApp: actualFocusedApp,
            screenSize: screenSize
        )
    }
    
    // ARCHETYPE-BASED: Dynamic cascade layout that works with ANY apps
    private static func generateRealisticFocusLayout(
        apps: [String],
        focusedApp: String,
        screenSize: CGSize
    ) -> [FlexibleWindowArrangement] {
        
        print("🎯 ARCHETYPE-BASED CASCADE LAYOUT:")
        print("  📱 Apps: \(apps.joined(separator: ", "))")
        print("  🎯 Focused: \(focusedApp)")
        
        // Step 1: Classify all apps by archetype
        let classifier = AppArchetypeClassifier.shared
        var appArchetypes: [(app: String, archetype: AppArchetype)] = []
        for app in apps {
            let archetype = classifier.classifyApp(app)
            appArchetypes.append((app, archetype))
            print("  📱 \(app) → \(archetype.displayName)")
        }
        
        // Step 2: Get focused app archetype
        let focusedArchetype = classifier.classifyApp(focusedApp)
        print("  🎯 Focused archetype: \(focusedArchetype.displayName)")
        
        // Step 3: Sort apps into layout roles based on archetypes
        var primaryApp: String? = nil
        var sideColumnApps: [String] = []
        var cascadeApps: [String] = []
        var cornerApps: [String] = []
        
        // Assign roles based on archetype and focus
        for (app, archetype) in appArchetypes {
            if app == focusedApp {
                primaryApp = app
            } else {
                switch archetype {
                case .textStream:
                    sideColumnApps.append(app)
                case .contentCanvas:
                    cascadeApps.append(app)
                case .codeWorkspace:
                    if app != focusedApp {
                        cascadeApps.append(app)
                    }
                case .glanceableMonitor:
                    cornerApps.append(app)
                case .unknown:
                    cascadeApps.append(app)
                }
            }
        }
        
        // Step 4: Build layout based on focused archetype pattern
        var arrangements: [FlexibleWindowArrangement] = []
        
        // Add focused app first (always on top)
        if let primary = primaryApp {
            let primarySize = getPrimarySize(for: focusedArchetype, appCount: apps.count)
            let primaryPosition = getPrimaryPosition(for: focusedArchetype)
            
            arrangements.append(FlexibleWindowArrangement(
                window: primary,
                position: primaryPosition,
                size: primarySize,
                layer: 3, // Always on top
                visibility: .full
            ))
        }
        
        // Add side column apps (text streams)
        var sideColumnIndex = 0
        for sideApp in sideColumnApps {
            let position = getSideColumnPosition(index: sideColumnIndex, total: sideColumnApps.count)
            let size = getSideColumnSize(for: .textStream, isFocused: sideApp == focusedApp)
            
            arrangements.append(FlexibleWindowArrangement(
                window: sideApp,
                position: position,
                size: size,
                layer: sideApp == focusedApp ? 3 : 1,
                visibility: sideApp == focusedApp ? .full : .partial
            ))
            sideColumnIndex += 1
        }
        
        // Add cascade apps (content canvas, other code workspaces)
        var cascadeIndex = 0
        for cascadeApp in cascadeApps {
            let archetype = classifier.classifyApp(cascadeApp)
            let position = getCascadePosition(
                index: cascadeIndex,
                total: cascadeApps.count,
                focusedArchetype: focusedArchetype,
                hasSideColumns: !sideColumnApps.isEmpty
            )
            let size = getCascadeSize(
                for: archetype,
                isFocused: cascadeApp == focusedApp,
                focusedArchetype: focusedArchetype
            )
            
            arrangements.append(FlexibleWindowArrangement(
                window: cascadeApp,
                position: position,
                size: size,
                layer: cascadeApp == focusedApp ? 3 : 2,
                visibility: cascadeApp == focusedApp ? .full : .partial
            ))
            cascadeIndex += 1
        }
        
        // Add corner apps (monitors) - SCREEN-MAXIMIZED SIZES
        var cornerIndex = 0
        for cornerApp in cornerApps {
            let position = getCornerPosition(index: cornerIndex)
            let archetype = classifier.classifyApp(cornerApp)
            
            // Use proper archetype-based sizing instead of tiny hardcoded 15%
            let size = getCascadeSize(
                for: archetype,
                isFocused: false,
                focusedArchetype: focusedArchetype
            )
            
            arrangements.append(FlexibleWindowArrangement(
                window: cornerApp,
                position: position,
                size: size,  // No longer hardcoded tiny 15%!
                layer: 0,
                visibility: .minimal
            ))
            cornerIndex += 1
        }
        
        // FINAL STEP: Ensure 100% screen coverage through perfect tiling
        let perfectArrangements = ensurePerfectScreenCoverage(arrangements, screenSize: screenSize)
        
        return perfectArrangements
    }
    
    // MARK: - 100% Screen Coverage Guarantee
    
    private static func ensurePerfectScreenCoverage(
        _ arrangements: [FlexibleWindowArrangement],
        screenSize: CGSize
    ) -> [FlexibleWindowArrangement] {
        
        print("🎯 ENSURING 100% SCREEN COVERAGE WITH INTELLIGENT PROPORTIONS")
        print("===========================================================")
        
        guard arrangements.count >= 2 else {
            // Single app - just maximize it
            if let arrangement = arrangements.first {
                let perfectArrangement = FlexibleWindowArrangement(
                    window: arrangement.window,
                    position: .percentage(x: 0, y: 0),
                    size: .percentage(width: 1.0, height: 1.0),
                    layer: arrangement.layer,
                    visibility: arrangement.visibility
                )
                print("  Single app: \(arrangement.window) → 100% coverage")
                return [perfectArrangement]
            }
            return arrangements
        }
        
        // PRESERVE INTELLIGENT SIZING: Use archetype-based proportional layout
        // Calculate total area preferences from intelligent sizing
        var appPreferences: [(window: String, widthPref: Double, heightPref: Double, area: Double)] = []
        
        for arrangement in arrangements {
            let widthPct = extractPercentage(from: arrangement.size.width)
            let heightPct = extractPercentage(from: arrangement.size.height)
            let area = widthPct * heightPct
            appPreferences.append((
                window: arrangement.window, 
                widthPref: widthPct, 
                heightPref: heightPct, 
                area: area
            ))
            print("  \(arrangement.window): archetype size \(Int(widthPct*100))%×\(Int(heightPct*100))% (area: \(Int(area*10000)/100)%)")
        }
        
        // Sort by area (largest gets priority positioning)
        let sortedApps = appPreferences.sorted { $0.area > $1.area }
        let primaryApp = sortedApps[0]
        
        print("  Primary app (largest): \(primaryApp.window)")
        
        // Create intelligent tessellation based on archetype proportions
        var perfectArrangements: [FlexibleWindowArrangement] = []
        
        switch arrangements.count {
        case 2:
            // Two apps: Use archetype proportions horizontally or vertically
            let app1 = sortedApps[0]
            let app2 = sortedApps[1]
            
            // Determine split based on larger app's proportions
            if app1.widthPref > app1.heightPref {
                // Wide primary → vertical split
                let split = normalizeToSum([app1.widthPref, app2.widthPref], target: 1.0)
                
                perfectArrangements.append(FlexibleWindowArrangement(
                    window: app1.window,
                    position: .percentage(x: 0, y: 0),
                    size: .percentage(width: split[0], height: 1.0),
                    layer: arrangements.first { $0.window == app1.window }!.layer,
                    visibility: .full
                ))
                
                perfectArrangements.append(FlexibleWindowArrangement(
                    window: app2.window,
                    position: .percentage(x: split[0], y: 0),
                    size: .percentage(width: split[1], height: 1.0),
                    layer: arrangements.first { $0.window == app2.window }!.layer,
                    visibility: .full
                ))
                
            } else {
                // Tall primary → horizontal split
                let split = normalizeToSum([app1.heightPref, app2.heightPref], target: 1.0)
                
                perfectArrangements.append(FlexibleWindowArrangement(
                    window: app1.window,
                    position: .percentage(x: 0, y: 0),
                    size: .percentage(width: 1.0, height: split[0]),
                    layer: arrangements.first { $0.window == app1.window }!.layer,
                    visibility: .full
                ))
                
                perfectArrangements.append(FlexibleWindowArrangement(
                    window: app2.window,
                    position: .percentage(x: 0, y: split[0]),
                    size: .percentage(width: 1.0, height: split[1]),
                    layer: arrangements.first { $0.window == app2.window }!.layer,
                    visibility: .full
                ))
            }
            
        case 3:
            // Three apps: Primary gets major space, two others share remainder
            let app1 = sortedApps[0] // Primary
            let app2 = sortedApps[1] 
            let app3 = sortedApps[2]
            
            // Primary gets 60-70% of space, others share the rest
            let primaryWidth = max(0.6, min(0.7, app1.widthPref * 1.2)) // Scale up primary
            let remainingWidth = 1.0 - primaryWidth
            let split = normalizeToSum([app2.heightPref, app3.heightPref], target: 1.0)
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app1.window,
                position: .percentage(x: 0, y: 0),
                size: .percentage(width: primaryWidth, height: 1.0),
                layer: arrangements.first { $0.window == app1.window }!.layer,
                visibility: .full
            ))
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app2.window,
                position: .percentage(x: primaryWidth, y: 0),
                size: .percentage(width: remainingWidth, height: split[0]),
                layer: arrangements.first { $0.window == app2.window }!.layer,
                visibility: .full
            ))
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app3.window,
                position: .percentage(x: primaryWidth, y: split[0]),
                size: .percentage(width: remainingWidth, height: split[1]),
                layer: arrangements.first { $0.window == app3.window }!.layer,
                visibility: .full
            ))
            
        default:
            // Four+ apps: Intelligent 2×2 with proportional sizing
            let app1 = sortedApps[0] // Top-left (primary)
            let app2 = sortedApps[1] // Top-right
            let app3 = sortedApps[2] // Bottom-left
            let app4 = sortedApps[3] // Bottom-right
            
            // Calculate proportional splits based on archetype preferences
            let topRowSplit = normalizeToSum([app1.widthPref, app2.widthPref], target: 1.0)
            let bottomRowSplit = normalizeToSum([app3.widthPref, app4.widthPref], target: 1.0)
            let leftColSplit = normalizeToSum([app1.heightPref, app3.heightPref], target: 1.0)
            let rightColSplit = normalizeToSum([app2.heightPref, app4.heightPref], target: 1.0)
            
            // Use average of row and column constraints for balanced layout
            let leftWidth = (topRowSplit[0] + bottomRowSplit[0]) / 2.0
            let rightWidth = 1.0 - leftWidth
            let topHeight = (leftColSplit[0] + rightColSplit[0]) / 2.0
            let bottomHeight = 1.0 - topHeight
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app1.window,
                position: .percentage(x: 0, y: 0),
                size: .percentage(width: leftWidth, height: topHeight),
                layer: arrangements.first { $0.window == app1.window }!.layer,
                visibility: .full
            ))
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app2.window,
                position: .percentage(x: leftWidth, y: 0),
                size: .percentage(width: rightWidth, height: topHeight),
                layer: arrangements.first { $0.window == app2.window }!.layer,
                visibility: .full
            ))
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app3.window,
                position: .percentage(x: 0, y: topHeight),
                size: .percentage(width: leftWidth, height: bottomHeight),
                layer: arrangements.first { $0.window == app3.window }!.layer,
                visibility: .full
            ))
            
            perfectArrangements.append(FlexibleWindowArrangement(
                window: app4.window,
                position: .percentage(x: leftWidth, y: topHeight),
                size: .percentage(width: rightWidth, height: bottomHeight),
                layer: arrangements.first { $0.window == app4.window }!.layer,
                visibility: .full
            ))
        }
        
        // Reorder to match original arrangement order
        var reorderedArrangements: [FlexibleWindowArrangement] = []
        for originalArrangement in arrangements {
            if let perfectArrangement = perfectArrangements.first(where: { $0.window == originalArrangement.window }) {
                reorderedArrangements.append(perfectArrangement)
            }
        }
        
        print("  Result: Intelligent proportional layout → 100% coverage with archetype-based sizing")
        
        return reorderedArrangements
    }
    
    // Helper function to normalize values to sum to target while preserving proportions
    private static func normalizeToSum(_ values: [Double], target: Double) -> [Double] {
        let sum = values.reduce(0, +)
        guard sum > 0 else { 
            // Equal distribution if no valid input
            let equal = target / Double(values.count)
            return Array(repeating: equal, count: values.count) 
        }
        return values.map { ($0 / sum) * target }
    }
    
    // Helper function to extract percentage value from SizeValue
    private static func extractPercentage(from sizeValue: FlexibleSize.SizeValue) -> Double {
        switch sizeValue {
        case .percentage(let pct):
            return pct
        case .pixels(let px):
            return px / 1440.0  // Approximate percentage based on typical screen width
        case .aspectRatio(let ratio):
            return ratio * 0.5  // Approximate
        case .content:
            return 0.25  // Default assumption
        }
    }
    
    // MARK: - Dynamic Sizing Functions
    
    private static func getPrimarySize(for archetype: AppArchetype, appCount: Int) -> FlexibleSize {
        // SCREEN-MAXIMIZED primary sizes - expand beyond typical archetype limitations
        switch archetype {
        case .codeWorkspace:
            // IDEs get maximum space for productivity, scale appropriately with app count
            let width = appCount <= 2 ? 0.80 : appCount == 3 ? 0.65 : 0.60  // Increased from 0.70/0.55/0.50
            let height = appCount <= 2 ? 0.95 : 0.90  // Increased from 0.90/0.85
            return .percentage(width: width, height: height)
            
        case .contentCanvas:
            // Browsers/design tools expanded for better functionality and screen coverage
            let width = appCount <= 2 ? 0.75 : appCount == 3 ? 0.65 : 0.60  // Increased from 0.65/0.55/0.50
            let height = 0.95  // Increased from 0.90
            return .percentage(width: width, height: height)
            
        case .textStream:
            // Text streams expanded beyond minimal size - NO HARDCODED PIXEL CONSTRAINTS
            let width = appCount <= 2 ? 0.45 : appCount == 3 ? 0.40 : 0.35  // Dynamic scaling, no pixel limits
            let height = 1.0  // Full height
            return .percentage(width: width, height: height)
            
        case .glanceableMonitor:
            // Monitors expanded when primary for better screen utilization
            return .percentage(width: 0.45, height: 0.60)  // Increased from 0.30x0.40
            
        case .unknown:
            // Default to larger sizing for screen maximization
            return .percentage(width: 0.65, height: 0.90)  // Increased from 0.55x0.85
        }
    }
    
    private static func getPrimaryPosition(for archetype: AppArchetype) -> FlexiblePosition {
        // SCREEN-MAXIMIZED positioning - start from left edge to fill screen
        switch archetype {
        case .textStream:
            // Text streams start from left edge for maximum screen utilization (was 0.70 - huge waste!)
            return .percentage(x: 0.0, y: 0.0)
        case .glanceableMonitor:
            // Monitors start from left edge too when primary
            return .percentage(x: 0.0, y: 0.0)  // Changed from corner positioning
        default:
            // All apps start at origin for maximum screen coverage
            return .percentage(x: 0.0, y: 0.0)
        }
    }
    
    private static func getSideColumnPosition(index: Int, total: Int) -> FlexiblePosition {
        // SCREEN-MAXIMIZED side columns - position to complement main windows better
        let x = index == 0 ? 0.65 : 0.60 - (Double(index) * 0.05)  // Moved left from 0.75/0.70 for better coverage
        return .percentage(x: x, y: 0.0)
    }
    
    private static func getSideColumnSize(for archetype: AppArchetype, isFocused: Bool) -> FlexibleSize {
        // Expanded side column sizes for better screen utilization
        let width = isFocused ? 0.35 : 0.30  // Increased from 0.30/0.25
        let height = isFocused ? 1.0 : 0.90  // Increased from 1.0/0.85
        return .percentage(width: width, height: height)
    }
    
    private static func getCascadePosition(
        index: Int,
        total: Int,
        focusedArchetype: AppArchetype,
        hasSideColumns: Bool
    ) -> FlexiblePosition {
        // SCREEN-MAXIMIZED cascade positioning - fill entire screen space
        let baseX: Double
        let baseY: Double
        
        // OPTIMIZE: Start from screen edges to maximize coverage
        switch focusedArchetype {
        case .codeWorkspace:
            // When IDE is focused, start from left edge to maximize space
            baseX = 0.05  // Start from left edge (was 0.45)
            baseY = 0.02  // Start from top edge (was 0.10)
        case .contentCanvas:
            // When browser is focused, start from left edge
            baseX = 0.02  // Start from left edge (was 0.20)
            baseY = 0.02  // Start from top edge (was 0.05)
        case .textStream:
            // When terminal is focused, still start from left to fill screen
            baseX = 0.05  // Start from left edge (was 0.35 - huge waste!)
            baseY = 0.02  // Start from top edge (was 0.10)
        default:
            baseX = 0.05  // Always start from left edge
            baseY = 0.02  // Always start from top edge
        }
        
        // OPTIMIZED cascade offsets - tighter spacing to maximize coverage
        let offsetX = Double(index) * 0.08  // Reduced from 0.15 to fit more windows
        let offsetY = Double(index) * 0.06  // Reduced from 0.15 for better coverage
        
        // SCREEN UTILIZATION: Allow windows to span entire screen width
        return .percentage(
            x: min(baseX + offsetX, 0.95),  // Increased to 0.95 to reach near screen edge
            y: min(baseY + offsetY, 0.25)   // Reduced to 0.25 to keep cascade tighter at top
        )
    }
    
    private static func getCascadeSize(
        for archetype: AppArchetype,
        isFocused: Bool,
        focusedArchetype: AppArchetype
    ) -> FlexibleSize {
        if isFocused {
            return getPrimarySize(for: archetype, appCount: 3)
        }
        
        // SCREEN-MAXIMIZED sizes for non-focused cascade apps
        switch archetype {
        case .contentCanvas:
            // Browsers expanded for maximum screen coverage and functionality
            return .percentage(width: 0.65, height: 0.95)  // Further increased from 0.55x0.90
        case .codeWorkspace:
            // Secondary IDEs get maximum space for productivity
            return .percentage(width: 0.70, height: 0.95)  // Further increased from 0.60x0.90
        case .textStream:
            // Terminal/console apps expanded significantly beyond minimal size
            return .percentage(width: 0.55, height: 0.95)  // Further increased from 0.45x0.90
        case .glanceableMonitor:
            // System monitors expanded to maximize available space
            return .percentage(width: 0.45, height: 0.90)  // Further increased from 0.35x0.85
        default:
            return .percentage(width: 0.60, height: 0.90)  // Further increased default sizes
        }
    }
    
    private static func getCornerPosition(index: Int) -> FlexiblePosition {
        let positions = [
            (x: 0.80, y: 0.80), // Bottom right
            (x: 0.05, y: 0.80), // Bottom left
            (x: 0.80, y: 0.05), // Top right
            (x: 0.05, y: 0.05)  // Top left
        ]
        let pos = positions[min(index, positions.count - 1)]
        return .percentage(x: pos.x, y: pos.y)
    }
    
    // Context-aware priority system for focus resolution
    private static func getCodingContextPriority(_ archetype: AppArchetype) -> Int {
        switch archetype {
        case .codeWorkspace: return 1    // Highest priority (IDEs, editors)
        case .contentCanvas: return 2    // Documentation, browsers
        case .textStream: return 3       // Terminal, logs, supporting tools
        case .glanceableMonitor: return 4 // Background monitors
        case .unknown: return 5          // Lowest priority
        }
    }
    
    
    // Calculate optimal position based on role and archetype
    private static func calculateOptimalPosition(for role: CascadeRole, archetype: AppArchetype, screenSize: CGSize) -> FlexiblePosition {
        switch (role, archetype) {
        case (.primary, .codeWorkspace):
            // Code workspace: leave margin for peek zones
            return .percentage(x: 0.05, y: 0.05)
        case (.primary, .contentCanvas):
            // Content canvas: center for best viewing
            return .percentage(x: 0.10, y: 0.10)
        case (.primary, .textStream):
            // Text stream: optimize for reading flow
            return .percentage(x: 0.05, y: 0.0)
        case (.primary, .glanceableMonitor):
            // Monitor: corner position
            return .percentage(x: 0.75, y: 0.75)
        default:
            // Default positioning
            return .percentage(x: 0.05, y: 0.05)
        }
    }
    
    // Enhanced arrangement creation with better conflict resolution
    private static func createSmartArchetypeArrangement(
        window: String,
        archetype: AppArchetype,
        role: CascadeRole,
        index: Int,
        totalWindows: Int,
        screenSize: CGSize,
        usedRightColumn: inout Bool,
        usedBottomPeek: inout Bool,
        usedLeftPeek: inout Bool,
        cornerIndex: inout Int
    ) -> FlexibleWindowArrangement {
        
        let classifier = AppArchetypeClassifier.shared
        let (optimalWidth, optimalHeight) = classifier.getOptimalSizing(for: archetype, screenSize: screenSize, role: role, windowCount: totalWindows)
        
        // Use archetype-based dynamic sizing instead of hardcoded values
        switch role {
        case .primary:
            // Primary window: use optimal sizing for this archetype
            return FlexibleWindowArrangement(
                window: window,
                position: calculateOptimalPosition(for: role, archetype: archetype, screenSize: screenSize),
                size: .percentage(width: optimalWidth, height: optimalHeight),
                layer: 3,
                visibility: .full
            )
            
        case .sideColumn:
            // Side column: position based on archetype behavior
            let rightX = 1.0 - optimalWidth
            return FlexibleWindowArrangement(
                window: window,
                position: .percentage(x: rightX, y: 0.0),
                size: .percentage(width: optimalWidth, height: optimalHeight),
                layer: 1,
                visibility: .full
            )
            
        case .peekLayer:
            // CASCADE-APPROPRIATE: Position Arc to cascade from primary with strategic overlap
            if !usedBottomPeek {
                usedBottomPeek = true
                
                // CASCADE POSITIONING: Strategic offset from primary window for optimal accessibility
                // Primary window is at (5%, 5%), so Arc cascades with offset for visibility
                let cascadeOffsetX = 0.20 // 20% horizontal offset from primary
                let cascadeOffsetY = 0.30 // 30% vertical offset from primary
                
                let peekX = 0.05 + cascadeOffsetX // 25% final position
                let peekY = 0.05 + cascadeOffsetY // 35% final position
                
                return FlexibleWindowArrangement(
                    window: window,
                    position: .percentage(x: peekX, y: peekY),
                    size: .percentage(width: optimalWidth, height: optimalHeight),
                    layer: 2,
                    visibility: .partial
                )
            } else if !usedLeftPeek {
                usedLeftPeek = true
                return FlexibleWindowArrangement(
                    window: window,
                    position: .percentage(x: 0.05, y: 0.30),
                    size: .percentage(width: optimalWidth, height: optimalHeight),
                    layer: 2,
                    visibility: .partial
                )
            } else {
                // Fallback position
                return FlexibleWindowArrangement(
                    window: window,
                    position: .percentage(x: 0.50, y: 0.60),
                    size: .percentage(width: optimalWidth, height: optimalHeight),
                    layer: 2,
                    visibility: .partial
                )
            }
            
        case .corner:
            // Minimal apps: corners only
            let cornerPositions = [
                (x: 0.80, y: 0.80), // Bottom right
                (x: 0.05, y: 0.80), // Bottom left
                (x: 0.80, y: 0.05), // Top right  
                (x: 0.05, y: 0.05)  // Top left
            ]
            
            let position = cornerPositions[min(cornerIndex, cornerPositions.count - 1)]
            cornerIndex += 1
            
            return FlexibleWindowArrangement(
                window: window,
                position: .percentage(x: position.x, y: position.y),
                size: .percentage(width: 0.15, height: 0.15), // Small corner
                layer: 0,
                visibility: .minimal
            )
        }
    }
    
    // Legacy method for backward compatibility
    private static func createArchetypeBasedArrangement(
        window: String,
        archetype: AppArchetype,
        role: CascadeRole,
        index: Int,
        totalWindows: Int,
        screenSize: CGSize,
        usedRightColumn: inout Bool,
        usedBottomPeek: inout Bool,
        cornerIndex: inout Int
    ) -> FlexibleWindowArrangement {
        var usedLeftPeek = false
        return createSmartArchetypeArrangement(
            window: window,
            archetype: archetype,
            role: role,
            index: index,
            totalWindows: totalWindows,
            screenSize: screenSize,
            usedRightColumn: &usedRightColumn,
            usedBottomPeek: &usedBottomPeek,
            usedLeftPeek: &usedLeftPeek,
            cornerIndex: &cornerIndex
        )
    }
    
    private static func calculatePrimarySizeRatio(windowCount: Int) -> Double {
        switch windowCount {
        case 1: return 0.90
        case 2: return 0.75
        case 3: return 0.65
        case 4: return 0.60
        case 5...6: return 0.55
        default: return 0.50
        }
    }
    
    private static func calculateCascadePosition(
        index: Int,
        totalWindows: Int,
        style: CascadeConfiguration.CascadeStyle,
        offset: CascadeConfiguration.CascadeOffset,
        screenSize: CGSize
    ) -> FlexiblePosition {
        
        let baseOffset = offset.isPercentage ? 
            offset.horizontal * screenSize.width : 
            offset.horizontal
        
        switch style {
        case .standard, .smart:
            let x = 0.05 + (Double(index) * baseOffset / screenSize.width)
            let y = 0.05 + (Double(index) * baseOffset / screenSize.height)
            return .percentage(x: min(x, 0.60), y: min(y, 0.60))
            
        case .tight:
            let x = 0.05 + (Double(index) * 0.03)
            let y = 0.05 + (Double(index) * 0.03)
            return .percentage(x: x, y: y)
            
        case .spread:
            let x = 0.05 + (Double(index) * 0.10)
            let y = 0.05 + (Double(index) * 0.08)
            return .percentage(x: min(x, 0.70), y: min(y, 0.70))
            
        case .diagonal:
            let progress = Double(index) / Double(totalWindows - 1)
            return .percentage(x: 0.05 + (progress * 0.70), y: 0.05 + (progress * 0.70))
            
        case .fan:
            let angle = (Double(index) * .pi / 6) - .pi / 4
            let radius = 0.3
            let x = 0.5 + (radius * cos(angle))
            let y = 0.5 + (radius * sin(angle))
            return .percentage(x: x, y: y)
        }
    }
    
    private static func calculateCascadeSize(
        index: Int,
        totalWindows: Int,
        primarySize: Double,
        screenSize: CGSize
    ) -> FlexibleSize {
        
        // Secondary windows get progressively smaller but maintain usability
        let sizeReduction = 1.0 - (Double(index) * 0.1)
        let secondarySize = primarySize * max(sizeReduction, 0.4)
        
        return .percentage(width: secondarySize, height: secondarySize)
    }
    
    // Smart cascade positioning - windows peek from strategic locations
    private static func calculateSmartCascadePosition(
        index: Int,
        totalWindows: Int,
        primarySize: Double,
        screenSize: CGSize
    ) -> FlexiblePosition {
        
        // Position secondary windows around the primary window for easy access
        switch index {
        case 1:
            // Second window: peek from right side
            return .percentage(x: primarySize - 0.15, y: 0.10)
        case 2:
            // Third window: peek from bottom
            return .percentage(x: 0.10, y: primarySize - 0.10)
        case 3:
            // Fourth window: peek from bottom-right corner
            return .percentage(x: primarySize - 0.20, y: primarySize - 0.15)
        case 4:
            // Fifth window: top-right corner
            return .percentage(x: 0.85, y: 0.05)
        default:
            // Additional windows: distribute along edges
            let edgePosition = Double(index - 5) * 0.15
            if index % 2 == 0 {
                // Even indices: along right edge
                return .percentage(x: 0.90, y: 0.20 + edgePosition)
            } else {
                // Odd indices: along bottom edge
                return .percentage(x: 0.20 + edgePosition, y: 0.90)
            }
        }
    }
    
    private static func calculateSmartCascadeSize(
        index: Int,
        totalWindows: Int,
        position: FlexiblePosition,
        primarySize: Double,
        minPeekSize: Double
    ) -> FlexibleSize {
        
        // Size windows to ensure they peek out properly
        switch index {
        case 1:
            // Second window: wider to peek from right
            return .percentage(width: 0.35, height: primarySize * 0.8)
        case 2:
            // Third window: taller to peek from bottom
            return .percentage(width: primarySize * 0.7, height: 0.35)
        case 3:
            // Fourth window: medium square for corner
            return .percentage(width: 0.30, height: 0.30)
        case 4:
            // Fifth window: compact for top corner
            return .percentage(width: 0.25, height: 0.25)
        default:
            // Additional windows: ensure minimum peek size
            let baseSize = max(0.25 - Double(index - 5) * 0.03, minPeekSize)
            return .percentage(width: baseSize, height: baseSize)
        }
    }
}