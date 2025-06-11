import Cocoa
import CoreGraphics

// MARK: - Cascade Layout Style
enum CascadeStyle {
    case classic // Traditional cascade with fixed offset
    case intelligent // Adaptive cascade based on window importance
    case compact // Minimal offset for maximum visibility
    case spread // Larger offset for better title bar access
    
    var offsetPercentage: CGFloat {
        switch self {
        case .classic: return 0.03 // 3% of screen width/height
        case .intelligent: return 0.0 // Calculated dynamically
        case .compact: return 0.015 // 1.5% for tight spaces
        case .spread: return 0.05 // 5% for more separation
        }
    }
}

// MARK: - Window Importance
struct WindowImportance {
    let window: WindowInfo
    let score: Double // 0.0 to 1.0
    let factors: [String: Double]
    
    static func calculate(for window: WindowInfo, 
                         context: UserContext?,
                         appPreferences: [String: Double]) -> WindowImportance {
        var factors: [String: Double] = [:]
        var totalScore = 0.0
        
        // App preference score (40% weight)
        let appPreference = appPreferences[window.appName.lowercased()] ?? 0.5
        factors["app_preference"] = appPreference
        totalScore += appPreference * 0.4
        
        // App category importance (30% weight)
        let categoryScore = getCategoryImportance(for: window.appName)
        factors["category_importance"] = categoryScore
        totalScore += categoryScore * 0.3
        
        // Current window size (20% weight) - larger windows are often more important
        let sizeScore = calculateSizeImportance(window.bounds.size)
        factors["window_size"] = sizeScore
        totalScore += sizeScore * 0.2
        
        // Recency (10% weight) - if we had focus history
        factors["recency"] = 0.5 // Default for now
        totalScore += 0.5 * 0.1
        
        return WindowImportance(window: window, score: totalScore, factors: factors)
    }
    
    private static func getCategoryImportance(for appName: String) -> Double {
        // Get category from app constraints
        if let constraints = AppConstraintsManager.shared.getConstraintsByAppName(appName) {
            switch constraints.category {
            case .codeEditor: return 0.9
            case .browser: return 0.8
            case .design: return 0.85
            case .terminal: return 0.7
            case .communication: return 0.6
            case .productivity: return 0.7
            case .media: return 0.5
            case .database: return 0.75
            case .other: return 0.5
            }
        }
        return 0.5
    }
    
    private static func calculateSizeImportance(_ size: CGSize) -> Double {
        let area = size.width * size.height
        let screenArea = NSScreen.main?.frame.size.width ?? 1920 * (NSScreen.main?.frame.size.height ?? 1080)
        let ratio = area / screenArea
        
        // Normalize to 0-1 range
        return min(1.0, ratio * 2) // Windows taking 50% of screen get max score
    }
}

// MARK: - Cascade Positioner
class CascadePositioner {
    
    private let windowManager: WindowManager
    private let constraintsManager = AppConstraintsManager.shared
    private let patternManager = IntelligentPatternManager.shared
    private let learningService = LearningService.shared
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    // MARK: - Helper Methods
    private func getBundleID(for appName: String) -> String? {
        return NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.lowercased() == appName.lowercased()
        }?.bundleIdentifier
    }
    
    // MARK: - Public API
    func arrangeCascade(windows: [WindowInfo],
                       style: CascadeStyle = .intelligent,
                       context: UserContext? = nil,
                       screenBounds: CGRect? = nil) -> [WindowArrangement] {
        
        guard !windows.isEmpty else { return [] }
        
        let bounds = screenBounds ?? NSScreen.main?.visibleFrame ?? .zero
        let appPreferences = buildAppPreferences()
        
        // Sort windows by importance
        let sortedWindows = windows.map { window in
            WindowImportance.calculate(for: window, context: context, appPreferences: appPreferences)
        }.sorted { $0.score > $1.score }
        
        // Calculate cascade parameters based on style and screen size
        let cascadeParams = calculateCascadeParameters(
            style: style,
            windowCount: windows.count,
            screenBounds: bounds,
            isUltrawide: ScreenConfiguration.current.isUltrawide
        )
        
        var arrangements: [WindowArrangement] = []
        
        for (index, importance) in sortedWindows.enumerated() {
            let arrangement = calculateWindowPosition(
                importance: importance,
                index: index,
                totalWindows: windows.count,
                cascadeParams: cascadeParams,
                screenBounds: bounds
            )
            arrangements.append(arrangement)
        }
        
        // Record the pattern for learning
        recordCascadePattern(arrangements: arrangements, context: context)
        
        return arrangements
    }
    
    func arrangeIntelligentLayout(windows: [WindowInfo],
                                 userIntent: String,
                                 context: UserContext? = nil) -> [WindowArrangement] {
        
        let screenConfig = ScreenConfiguration.current
        let activeApps = windows.map { $0.appName }
        
        // Find similar patterns from history
        let patternMatches = patternManager.findSimilarPatterns(
            to: context,
            screenConfig: screenConfig,
            activeApps: activeApps
        )
        
        // Decide between cascade and tiled based on patterns and screen size
        if shouldUseTiledLayout(windows: windows, patterns: patternMatches, screenConfig: screenConfig) {
            return arrangeTiledLayout(windows: windows, context: context)
        } else {
            // Use cascade with intelligent positioning
            return arrangeCascade(windows: windows, style: .intelligent, context: context)
        }
    }
    
    // MARK: - Cascade Calculation
    private func calculateCascadeParameters(style: CascadeStyle,
                                          windowCount: Int,
                                          screenBounds: CGRect,
                                          isUltrawide: Bool) -> CascadeParameters {
        
        switch style {
        case .intelligent:
            return calculateIntelligentCascadeParams(
                windowCount: windowCount,
                screenBounds: screenBounds,
                isUltrawide: isUltrawide
            )
        default:
            let baseOffset = style.offsetPercentage
            return CascadeParameters(
                offsetX: screenBounds.width * baseOffset,
                offsetY: screenBounds.height * baseOffset,
                primaryWindowScale: 0.7,
                secondaryWindowScale: 0.6,
                auxiliaryWindowScale: 0.5,
                maxCascadeSteps: min(windowCount, 10)
            )
        }
    }
    
    private func calculateIntelligentCascadeParams(windowCount: Int,
                                                  screenBounds: CGRect,
                                                  isUltrawide: Bool) -> CascadeParameters {
        // Adapt cascade based on screen size and window count
        let screenArea = screenBounds.width * screenBounds.height
        let isLargeScreen = screenArea > 3_000_000 // Roughly 4K
        
        // Base offset calculation
        var offsetX: CGFloat
        var offsetY: CGFloat
        
        if isUltrawide {
            // Ultrawide: more horizontal offset, less vertical
            offsetX = screenBounds.width * 0.04
            offsetY = screenBounds.height * 0.02
        } else if isLargeScreen {
            // Large screen: generous offsets
            offsetX = screenBounds.width * 0.035
            offsetY = screenBounds.height * 0.035
        } else {
            // Laptop/small screen: compact offsets
            offsetX = screenBounds.width * 0.02
            offsetY = screenBounds.height * 0.025
        }
        
        // Adjust for window count
        if windowCount > 5 {
            // Many windows: reduce offset to fit more
            offsetX *= 0.7
            offsetY *= 0.7
        }
        
        // Window scaling based on importance
        let primaryScale: CGFloat = isUltrawide ? 0.6 : 0.7
        let secondaryScale: CGFloat = primaryScale * 0.85
        let auxiliaryScale: CGFloat = primaryScale * 0.7
        
        return CascadeParameters(
            offsetX: offsetX,
            offsetY: offsetY,
            primaryWindowScale: primaryScale,
            secondaryWindowScale: secondaryScale,
            auxiliaryWindowScale: auxiliaryScale,
            maxCascadeSteps: min(windowCount, isLargeScreen ? 12 : 8)
        )
    }
    
    private func calculateWindowPosition(importance: WindowImportance,
                                       index: Int,
                                       totalWindows: Int,
                                       cascadeParams: CascadeParameters,
                                       screenBounds: CGRect) -> WindowArrangement {
        
        let window = importance.window
        var size: CGSize
        var position: CGPoint
        var visibility: WindowVisibility
        var role: WindowRole
        
        // Determine role based on importance score
        if index == 0 {
            role = .primary
            size = CGSize(
                width: screenBounds.width * cascadeParams.primaryWindowScale,
                height: screenBounds.height * cascadeParams.primaryWindowScale
            )
        } else if index <= 2 && importance.score > 0.6 {
            role = .secondary
            size = CGSize(
                width: screenBounds.width * cascadeParams.secondaryWindowScale,
                height: screenBounds.height * cascadeParams.secondaryWindowScale
            )
        } else {
            role = .auxiliary
            size = CGSize(
                width: screenBounds.width * cascadeParams.auxiliaryWindowScale,
                height: screenBounds.height * cascadeParams.auxiliaryWindowScale
            )
        }
        
        // Apply app constraints
        let bundleID = getBundleID(for: window.appName) ?? ""
        size = constraintsManager.validateWindowSize(size, for: bundleID)
        
        // Calculate cascade position
        let cascadeStep = min(index, cascadeParams.maxCascadeSteps - 1)
        let baseX = screenBounds.minX + (screenBounds.width - size.width) * 0.2 // Start 20% from left
        let baseY = screenBounds.minY + (screenBounds.height - size.height) * 0.1 // Start 10% from top
        
        position = CGPoint(
            x: baseX + (cascadeParams.offsetX * CGFloat(cascadeStep)),
            y: baseY + (cascadeParams.offsetY * CGFloat(cascadeStep))
        )
        
        // Ensure window stays within screen bounds
        position.x = min(position.x, screenBounds.maxX - size.width)
        position.y = min(position.y, screenBounds.maxY - size.height)
        
        // Calculate visibility based on overlap
        visibility = calculateVisibility(
            index: index,
            totalWindows: totalWindows,
            windowSize: size,
            cascadeParams: cascadeParams
        )
        
        return WindowArrangement(
            window: window,
            targetBounds: CGRect(origin: position, size: size),
            layerIndex: index,
            visibility: visibility,
            role: role
        )
    }
    
    private func calculateVisibility(index: Int,
                                   totalWindows: Int,
                                   windowSize: CGSize,
                                   cascadeParams: CascadeParameters) -> WindowVisibility {
        if index == 0 {
            return .fullyVisible
        }
        
        // Calculate approximate overlap based on cascade parameters
        let overlapPercentage = 1.0 - (cascadeParams.offsetX * CGFloat(index) / windowSize.width)
        
        switch overlapPercentage {
        case 0.9...: return .fullyVisible
        case 0.6..<0.9: return .mostlyVisible
        case 0.3..<0.6: return .partiallyVisible
        case 0.1..<0.3: return .minimallyVisible
        default: return .hidden
        }
    }
    
    // MARK: - Tiled Layout Alternative
    private func shouldUseTiledLayout(windows: [WindowInfo],
                                    patterns: [PatternMatch],
                                    screenConfig: ScreenConfiguration) -> Bool {
        // Use tiled layout for:
        // 1. <= 3 windows on regular screens
        // 2. <= 4 windows on ultrawide
        // 3. When patterns suggest tiled preference
        
        if windows.count <= 2 {
            return true // Always tile 2 windows
        }
        
        if screenConfig.isUltrawide && windows.count <= 4 {
            return true
        }
        
        // Check if patterns suggest tiling
        if let bestMatch = patterns.first, bestMatch.confidence > 0.7 {
            let tiledCount = bestMatch.pattern.windowArrangement.filter { 
                $0.visibility == .fullyVisible 
            }.count
            if Double(tiledCount) / Double(bestMatch.pattern.windowArrangement.count) > 0.8 {
                return true
            }
        }
        
        return false
    }
    
    private func arrangeTiledLayout(windows: [WindowInfo],
                                  context: UserContext?) -> [WindowArrangement] {
        let screenBounds = NSScreen.main?.visibleFrame ?? .zero
        let appPreferences = buildAppPreferences()
        
        // Sort by importance
        let sortedWindows = windows.map { window in
            WindowImportance.calculate(for: window, context: context, appPreferences: appPreferences)
        }.sorted { $0.score > $1.score }
        
        var arrangements: [WindowArrangement] = []
        
        switch windows.count {
        case 1:
            // Single window - maximize
            arrangements.append(WindowArrangement(
                window: sortedWindows[0].window,
                targetBounds: screenBounds,
                layerIndex: 0,
                visibility: .fullyVisible,
                role: .primary
            ))
            
        case 2:
            // Two windows - side by side
            let leftBounds = CGRect(
                x: screenBounds.minX,
                y: screenBounds.minY,
                width: screenBounds.width * 0.6, // Primary gets 60%
                height: screenBounds.height
            )
            let rightBounds = CGRect(
                x: screenBounds.minX + leftBounds.width,
                y: screenBounds.minY,
                width: screenBounds.width * 0.4, // Secondary gets 40%
                height: screenBounds.height
            )
            
            arrangements.append(WindowArrangement(
                window: sortedWindows[0].window,
                targetBounds: leftBounds,
                layerIndex: 0,
                visibility: .fullyVisible,
                role: .primary
            ))
            arrangements.append(WindowArrangement(
                window: sortedWindows[1].window,
                targetBounds: rightBounds,
                layerIndex: 1,
                visibility: .fullyVisible,
                role: .secondary
            ))
            
        default:
            // 3+ windows - use intelligent grid
            arrangements = arrangeIntelligentGrid(sortedWindows: sortedWindows, screenBounds: screenBounds)
        }
        
        return arrangements
    }
    
    private func arrangeIntelligentGrid(sortedWindows: [WindowImportance],
                                      screenBounds: CGRect) -> [WindowArrangement] {
        var arrangements: [WindowArrangement] = []
        
        // Primary window gets left 60%
        let primaryBounds = CGRect(
            x: screenBounds.minX,
            y: screenBounds.minY,
            width: screenBounds.width * 0.6,
            height: screenBounds.height
        )
        
        arrangements.append(WindowArrangement(
            window: sortedWindows[0].window,
            targetBounds: primaryBounds,
            layerIndex: 0,
            visibility: .fullyVisible,
            role: .primary
        ))
        
        // Remaining windows stack on the right
        let rightWidth = screenBounds.width * 0.4
        let remainingCount = sortedWindows.count - 1
        let stackHeight = screenBounds.height / CGFloat(remainingCount)
        
        for (index, importance) in sortedWindows.dropFirst().enumerated() {
            let bounds = CGRect(
                x: screenBounds.minX + primaryBounds.width,
                y: screenBounds.minY + (stackHeight * CGFloat(index)),
                width: rightWidth,
                height: stackHeight
            )
            
            arrangements.append(WindowArrangement(
                window: importance.window,
                targetBounds: bounds,
                layerIndex: index + 1,
                visibility: .fullyVisible,
                role: index == 0 ? .secondary : .auxiliary
            ))
        }
        
        return arrangements
    }
    
    // MARK: - Helper Methods
    private func buildAppPreferences() -> [String: Double] {
        var preferences: [String: Double] = [:]
        
        // Get preferences from learning service
        for app in NSWorkspace.shared.runningApplications {
            if let appName = app.localizedName {
                preferences[appName.lowercased()] = learningService.getAppPreference(for: appName)
            }
        }
        
        return preferences
    }
    
    private func recordCascadePattern(arrangements: [WindowArrangement], context: UserContext?) {
        let snapshots = arrangements.map { arrangement in
            WindowSnapshot(
                appName: arrangement.window.appName,
                bundleID: getBundleID(for: arrangement.window.appName),
                bounds: arrangement.targetBounds,
                layerIndex: arrangement.layerIndex,
                visibility: arrangement.visibility,
                role: arrangement.role
            )
        }
        
        let pattern = WindowUsagePattern(
            sessionDuration: 0, // Will be updated later
            activeApps: arrangements.map { $0.window.appName },
            windowArrangement: snapshots,
            userContext: context,
            screenConfiguration: ScreenConfiguration.current
        )
        
        patternManager.recordPattern(pattern)
    }
}

// MARK: - Supporting Types
struct CascadeParameters {
    let offsetX: CGFloat
    let offsetY: CGFloat
    let primaryWindowScale: CGFloat
    let secondaryWindowScale: CGFloat
    let auxiliaryWindowScale: CGFloat
    let maxCascadeSteps: Int
}

struct WindowArrangement {
    let window: WindowInfo
    let targetBounds: CGRect
    let layerIndex: Int
    let visibility: WindowVisibility
    let role: WindowRole
}