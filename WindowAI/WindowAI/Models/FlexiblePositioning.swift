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
        
        // Add corner apps (monitors)
        var cornerIndex = 0
        for cornerApp in cornerApps {
            let position = getCornerPosition(index: cornerIndex)
            
            arrangements.append(FlexibleWindowArrangement(
                window: cornerApp,
                position: position,
                size: .percentage(width: 0.15, height: 0.15),
                layer: 0,
                visibility: .minimal
            ))
            cornerIndex += 1
        }
        
        return arrangements
    }
    
    // MARK: - Dynamic Sizing Functions
    
    private static func getPrimarySize(for archetype: AppArchetype, appCount: Int) -> FlexibleSize {
        switch archetype {
        case .codeWorkspace:
            // IDEs need more space, scale down with more apps
            let width = appCount <= 2 ? 0.70 : appCount == 3 ? 0.55 : 0.50
            let height = appCount <= 2 ? 0.90 : 0.85
            return .percentage(width: width, height: height)
            
        case .contentCanvas:
            // Browsers/design tools need good width
            let width = appCount <= 2 ? 0.65 : appCount == 3 ? 0.55 : 0.50
            let height = 0.90
            return .percentage(width: width, height: height)
            
        case .textStream:
            // Text streams as primary (e.g., focused Terminal)
            let width = min(0.30, 500.0 / 1440.0) // Max 30% or 500px
            let height = 1.0
            return .percentage(width: width, height: height)
            
        case .glanceableMonitor:
            // Monitors rarely primary, but if so, small window
            return .percentage(width: 0.30, height: 0.40)
            
        case .unknown:
            // Default to content canvas sizing
            return .percentage(width: 0.55, height: 0.85)
        }
    }
    
    private static func getPrimaryPosition(for archetype: AppArchetype) -> FlexiblePosition {
        switch archetype {
        case .textStream:
            // Text streams as primary go to the right
            return .percentage(x: 0.70, y: 0.0)
        case .glanceableMonitor:
            // Monitors in corner
            return .percentage(x: 0.70, y: 0.60)
        default:
            // Most apps start at origin
            return .percentage(x: 0.0, y: 0.0)
        }
    }
    
    private static func getSideColumnPosition(index: Int, total: Int) -> FlexiblePosition {
        // Side columns go to the right edge
        let x = index == 0 ? 0.75 : 0.70 - (Double(index) * 0.05)
        return .percentage(x: x, y: 0.0)
    }
    
    private static func getSideColumnSize(for archetype: AppArchetype, isFocused: Bool) -> FlexibleSize {
        // Text streams get consistent narrow width
        let width = isFocused ? 0.30 : 0.25
        let height = isFocused ? 1.0 : 0.85
        return .percentage(width: width, height: height)
    }
    
    private static func getCascadePosition(
        index: Int,
        total: Int,
        focusedArchetype: AppArchetype,
        hasSideColumns: Bool
    ) -> FlexiblePosition {
        // Dynamic cascade positioning based on context
        let baseX: Double
        let baseY: Double
        
        switch focusedArchetype {
        case .codeWorkspace:
            // When IDE is focused, cascade from right side
            baseX = 0.45
            baseY = 0.10
        case .contentCanvas:
            // When browser is focused, cascade from left
            baseX = 0.20
            baseY = 0.05
        case .textStream:
            // When terminal is focused, cascade in center
            baseX = 0.35
            baseY = 0.10
        default:
            baseX = 0.30
            baseY = 0.10
        }
        
        // Apply cascade offset based on index
        let offsetX = Double(index) * 0.15
        let offsetY = Double(index) * 0.15
        
        return .percentage(
            x: min(baseX + offsetX, 0.60),
            y: min(baseY + offsetY, 0.50)
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
        
        // Non-focused cascade apps
        switch archetype {
        case .contentCanvas:
            // Browsers need minimum functional width
            return .percentage(width: 0.35, height: 0.80)
        case .codeWorkspace:
            // Secondary IDEs
            return .percentage(width: 0.40, height: 0.80)
        default:
            return .percentage(width: 0.35, height: 0.75)
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