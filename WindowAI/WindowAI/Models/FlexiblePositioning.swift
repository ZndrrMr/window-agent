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
            // Auto-detect: prioritize code workspace in coding context, or first app
            if context.contains("cod") {
                actualFocusedApp = relevantApps.first { AppArchetypeClassifier.shared.classifyApp($0) == .codeWorkspace } ?? relevantApps.first ?? ""
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
    
    // CORRECTED: Cascade-aware layout with proper overlaps and full screen usage
    private static func generateRealisticFocusLayout(
        apps: [String],
        focusedApp: String,
        screenSize: CGSize
    ) -> [FlexibleWindowArrangement] {
        
        print("🎯 CORRECTED FOCUS-AWARE CASCADE LAYOUT:")
        print("  📱 Apps: \(apps.joined(separator: ", "))")
        print("  🎯 Focused: \(focusedApp)")
        
        // Generate the correct cascade layout based on focused app
        switch focusedApp {
        case "Xcode":
            // Xcode focused: Primary space with Arc cascading for peek access
            return [
                FlexibleWindowArrangement(
                    window: "Xcode",
                    position: .percentage(x: 0.0, y: 0.0),
                    size: .percentage(width: 0.65, height: 1.0), // 65% width - primary space
                    layer: 3, // On top as focused
                    visibility: .full
                ),
                FlexibleWindowArrangement(
                    window: "Arc",
                    position: .percentage(x: 0.45, y: 0.05), // Overlaps Xcode for cascade peek
                    size: .percentage(width: 0.50, height: 0.85), // 720px width - functional
                    layer: 2, // Behind focused but visible
                    visibility: .partial
                ),
                FlexibleWindowArrangement(
                    window: "Terminal",
                    position: .percentage(x: 0.70, y: 0.0), // Right side column
                    size: .percentage(width: 0.30, height: 1.0), // 432px width - good for terminal
                    layer: 1, // Background layer
                    visibility: .partial
                )
            ].filter { apps.contains($0.window) }
            
        case "Arc":
            // Arc focused: Central primary space with side columns
            return [
                FlexibleWindowArrangement(
                    window: "Xcode",
                    position: .percentage(x: 0.0, y: 0.0),
                    size: .percentage(width: 0.25, height: 1.0), // Left side column
                    layer: 1,
                    visibility: .partial
                ),
                FlexibleWindowArrangement(
                    window: "Arc",
                    position: .percentage(x: 0.20, y: 0.0), // Slight overlap for cascade
                    size: .percentage(width: 0.60, height: 1.0), // 864px width - excellent browsing
                    layer: 3, // On top as focused
                    visibility: .full
                ),
                FlexibleWindowArrangement(
                    window: "Terminal",
                    position: .percentage(x: 0.75, y: 0.0), // Right side column
                    size: .percentage(width: 0.25, height: 1.0), // Good terminal space
                    layer: 1,
                    visibility: .partial
                )
            ].filter { apps.contains($0.window) }
            
        case "Terminal":
            // Terminal focused: Substantial space with others cascading
            return [
                FlexibleWindowArrangement(
                    window: "Xcode",
                    position: .percentage(x: 0.0, y: 0.0),
                    size: .percentage(width: 0.30, height: 1.0), // Left column
                    layer: 1,
                    visibility: .partial
                ),
                FlexibleWindowArrangement(
                    window: "Arc",
                    position: .percentage(x: 0.25, y: 0.05), // Cascade peek
                    size: .percentage(width: 0.45, height: 0.90), // 648px width - still functional
                    layer: 2,
                    visibility: .partial
                ),
                FlexibleWindowArrangement(
                    window: "Terminal",
                    position: .percentage(x: 0.45, y: 0.0), // Primary space
                    size: .percentage(width: 0.55, height: 1.0), // 792px width - excellent for terminal
                    layer: 3, // On top as focused
                    visibility: .full
                )
            ].filter { apps.contains($0.window) }
            
        default:
            // Fallback: Default to Arc focused if unknown app
            return generateRealisticFocusLayout(apps: apps, focusedApp: "Arc", screenSize: screenSize)
        }
    }
    
    // Helper function to define consistent app ordering
    private static func getAppOrder(_ appName: String) -> Int {
        let normalizedName = appName.lowercased()
        if normalizedName.contains("xcode") { return 0 }
        if normalizedName.contains("cursor") { return 1 }
        if normalizedName.contains("arc") { return 2 }
        if normalizedName.contains("safari") { return 2 }
        if normalizedName.contains("chrome") { return 2 }
        if normalizedName.contains("terminal") { return 3 }
        if normalizedName.contains("iterm") { return 3 }
        return 5 // Unknown apps go to the right
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