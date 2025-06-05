import Foundation
import CoreGraphics

// MARK: - Window Role & Behavior
enum WindowRole: String, Codable {
    case primary = "primary"        // Main focus window (e.g., code editor, browser)
    case auxiliary = "auxiliary"    // Support window (e.g., terminal, documentation)
    case peripheral = "peripheral"  // Background app (e.g., music, messages)
    case floating = "floating"      // Always on top (e.g., calculator, notes)
    
    var layerPriority: Int {
        switch self {
        case .primary: return 100
        case .auxiliary: return 75
        case .peripheral: return 50
        case .floating: return 200
        }
    }
}

// MARK: - Window Layout Preferences
struct WindowLayoutPreference: Codable {
    let appCategory: AppCategory
    let defaultRole: WindowRole
    let optimalAspectRatio: CGFloat
    let minAspectRatio: CGFloat
    let maxAspectRatio: CGFloat
    let preferredPosition: PreferredPosition
    let canBePartiallyVisible: Bool
    let minVisiblePercentage: CGFloat
    
    enum PreferredPosition: String, Codable {
        case left = "left"
        case right = "right"
        case top = "top"
        case bottom = "bottom"
        case center = "center"
        case rightEdge = "right_edge"    // Docked to right edge
        case leftEdge = "left_edge"      // Docked to left edge
        case flexible = "flexible"       // Can go anywhere
    }
}

// MARK: - Intelligent Layout Engine
class IntelligentLayoutEngine {
    private let constraintsManager = AppConstraintsManager.shared
    private var layoutPreferences: [AppCategory: WindowLayoutPreference] = [:]
    
    static let shared = IntelligentLayoutEngine()
    
    private init() {
        setupDefaultPreferences()
    }
    
    // MARK: - Layout Preferences Setup
    private func setupDefaultPreferences() {
        layoutPreferences = [
            // Terminal prefers tall and narrow on the right
            .terminal: WindowLayoutPreference(
                appCategory: .terminal,
                defaultRole: .auxiliary,
                optimalAspectRatio: 0.6,    // Width/Height ratio (tall and narrow)
                minAspectRatio: 0.4,
                maxAspectRatio: 0.8,
                preferredPosition: .rightEdge,
                canBePartiallyVisible: false,
                minVisiblePercentage: 1.0
            ),
            
            // Code editors are primary focus, prefer wider
            .codeEditor: WindowLayoutPreference(
                appCategory: .codeEditor,
                defaultRole: .primary,
                optimalAspectRatio: 1.6,
                minAspectRatio: 1.2,
                maxAspectRatio: 2.0,
                preferredPosition: .center,
                canBePartiallyVisible: false,
                minVisiblePercentage: 1.0
            ),
            
            // Communication apps can be auxiliary, narrow
            .communication: WindowLayoutPreference(
                appCategory: .communication,
                defaultRole: .auxiliary,
                optimalAspectRatio: 0.7,
                minAspectRatio: 0.5,
                maxAspectRatio: 1.0,
                preferredPosition: .rightEdge,
                canBePartiallyVisible: true,
                minVisiblePercentage: 0.3     // Can be 30% visible
            ),
            
            // Browsers are usually primary focus
            .browser: WindowLayoutPreference(
                appCategory: .browser,
                defaultRole: .primary,
                optimalAspectRatio: 1.5,
                minAspectRatio: 1.2,
                maxAspectRatio: 1.8,
                preferredPosition: .center,
                canBePartiallyVisible: false,
                minVisiblePercentage: 1.0
            ),
            
            // Media apps can be peripheral
            .media: WindowLayoutPreference(
                appCategory: .media,
                defaultRole: .peripheral,
                optimalAspectRatio: 1.3,
                minAspectRatio: 1.0,
                maxAspectRatio: 1.6,
                preferredPosition: .flexible,
                canBePartiallyVisible: true,
                minVisiblePercentage: 0.2     // Can be mostly hidden
            ),
            
            // Design apps need full visibility
            .design: WindowLayoutPreference(
                appCategory: .design,
                defaultRole: .primary,
                optimalAspectRatio: 1.4,
                minAspectRatio: 1.2,
                maxAspectRatio: 1.8,
                preferredPosition: .center,
                canBePartiallyVisible: false,
                minVisiblePercentage: 1.0
            ),
            
            // Productivity apps are flexible
            .productivity: WindowLayoutPreference(
                appCategory: .productivity,
                defaultRole: .auxiliary,
                optimalAspectRatio: 1.3,
                minAspectRatio: 0.8,
                maxAspectRatio: 1.6,
                preferredPosition: .flexible,
                canBePartiallyVisible: true,
                minVisiblePercentage: 0.5
            )
        ]
    }
    
    // MARK: - Intelligent Size Calculation
    func calculateOptimalSize(for appName: String, availableSpace: CGRect, otherWindows: [WindowInfo]) -> CGRect {
        guard let constraints = constraintsManager.getConstraintsByAppName(appName),
              let preference = layoutPreferences[constraints.category] else {
            // Default to 60% of available space
            return CGRect(
                x: availableSpace.minX,
                y: availableSpace.minY,
                width: availableSpace.width * 0.6,
                height: availableSpace.height * 0.7
            )
        }
        
        // Calculate optimal size based on aspect ratio
        let optimalAspectRatio = preference.optimalAspectRatio
        var width: CGFloat
        var height: CGFloat
        
        // Determine role and available space
        let role = determineWindowRole(constraints: constraints, otherWindows: otherWindows)
        
        switch role {
        case .primary:
            // Primary windows get 60-80% of space
            width = availableSpace.width * 0.7
            height = width / optimalAspectRatio
            
            // Adjust if height is too large
            if height > availableSpace.height * 0.85 {
                height = availableSpace.height * 0.85
                width = height * optimalAspectRatio
            }
            
        case .auxiliary:
            // Auxiliary windows get 30-40% of width
            if preference.preferredPosition == .rightEdge || preference.preferredPosition == .leftEdge {
                width = availableSpace.width * 0.35
                height = availableSpace.height * 0.8
                
                // Ensure aspect ratio is respected
                let currentRatio = width / height
                if currentRatio > preference.maxAspectRatio {
                    width = height * preference.maxAspectRatio
                } else if currentRatio < preference.minAspectRatio {
                    height = width / preference.minAspectRatio
                }
            } else {
                width = availableSpace.width * 0.4
                height = width / optimalAspectRatio
            }
            
        case .peripheral:
            // Peripheral windows are smaller
            width = availableSpace.width * 0.3
            height = width / optimalAspectRatio
            
        case .floating:
            // Floating windows are compact
            width = min(400, availableSpace.width * 0.3)
            height = width / optimalAspectRatio
        }
        
        // Validate against constraints
        let validatedSize = CGSize(width: width, height: height)  // Already validated by aspect ratio above
        
        // Calculate position
        let position = calculateOptimalPosition(
            windowSize: validatedSize,
            preference: preference,
            availableSpace: availableSpace,
            otherWindows: otherWindows,
            role: role
        )
        
        return CGRect(origin: position, size: validatedSize)
    }
    
    // MARK: - Position Calculation
    private func calculateOptimalPosition(
        windowSize: CGSize,
        preference: WindowLayoutPreference,
        availableSpace: CGRect,
        otherWindows: [WindowInfo],
        role: WindowRole
    ) -> CGPoint {
        
        let gap: CGFloat = 10  // Window gap
        
        switch preference.preferredPosition {
        case .rightEdge:
            return CGPoint(
                x: availableSpace.maxX - windowSize.width,
                y: availableSpace.minY + (availableSpace.height - windowSize.height) / 2
            )
            
        case .leftEdge:
            return CGPoint(
                x: availableSpace.minX,
                y: availableSpace.minY + (availableSpace.height - windowSize.height) / 2
            )
            
        case .center:
            return CGPoint(
                x: availableSpace.minX + (availableSpace.width - windowSize.width) / 2,
                y: availableSpace.minY + (availableSpace.height - windowSize.height) / 2
            )
            
        case .left:
            return CGPoint(
                x: availableSpace.minX + gap,
                y: availableSpace.minY + gap
            )
            
        case .right:
            // Position on right side but not edge
            let primaryWindowWidth = availableSpace.width * 0.65
            return CGPoint(
                x: availableSpace.minX + primaryWindowWidth + gap,
                y: availableSpace.minY + gap
            )
            
        case .top:
            return CGPoint(
                x: availableSpace.minX + (availableSpace.width - windowSize.width) / 2,
                y: availableSpace.minY + gap
            )
            
        case .bottom:
            return CGPoint(
                x: availableSpace.minX + (availableSpace.width - windowSize.width) / 2,
                y: availableSpace.maxY - windowSize.height - gap
            )
            
        case .flexible:
            // Find best position based on other windows
            return findOptimalFlexiblePosition(
                windowSize: windowSize,
                availableSpace: availableSpace,
                otherWindows: otherWindows,
                canOverlap: preference.canBePartiallyVisible
            )
        }
    }
    
    // MARK: - Role Determination
    private func determineWindowRole(constraints: AppConstraints, otherWindows: [WindowInfo]) -> WindowRole {
        // If no other windows, this is primary
        if otherWindows.isEmpty {
            return .primary
        }
        
        // Get default role for category
        let defaultRole = layoutPreferences[constraints.category]?.defaultRole ?? .auxiliary
        
        // Check if there's already a primary window
        let hasPrimaryWindow = otherWindows.contains { window in
            if let otherConstraints = constraintsManager.getConstraintsByAppName(window.appName) {
                return layoutPreferences[otherConstraints.category]?.defaultRole == .primary
            }
            return false
        }
        
        // If no primary and this could be primary, make it primary
        if !hasPrimaryWindow && defaultRole == .primary {
            return .primary
        }
        
        return defaultRole
    }
    
    // MARK: - Flexible Positioning
    private func findOptimalFlexiblePosition(
        windowSize: CGSize,
        availableSpace: CGRect,
        otherWindows: [WindowInfo],
        canOverlap: Bool
    ) -> CGPoint {
        
        let gap: CGFloat = 10
        
        // Try positions in order of preference
        let positions = [
            CGPoint(x: availableSpace.maxX - windowSize.width - gap,
                   y: availableSpace.minY + gap),  // Top right
            CGPoint(x: availableSpace.minX + gap,
                   y: availableSpace.maxY - windowSize.height - gap),  // Bottom left
            CGPoint(x: availableSpace.maxX - windowSize.width - gap,
                   y: availableSpace.maxY - windowSize.height - gap),  // Bottom right
            CGPoint(x: availableSpace.minX + gap,
                   y: availableSpace.minY + gap)  // Top left
        ]
        
        // Find position with least overlap
        var bestPosition = positions[0]
        var minOverlap = CGFloat.infinity
        
        for position in positions {
            let testRect = CGRect(origin: position, size: windowSize)
            let overlap = calculateTotalOverlap(testRect: testRect, otherWindows: otherWindows)
            
            if overlap < minOverlap {
                minOverlap = overlap
                bestPosition = position
            }
            
            // If no overlap, use this position
            if overlap == 0 {
                break
            }
        }
        
        return bestPosition
    }
    
    private func calculateTotalOverlap(testRect: CGRect, otherWindows: [WindowInfo]) -> CGFloat {
        var totalOverlap: CGFloat = 0
        
        for window in otherWindows {
            let intersection = testRect.intersection(window.bounds)
            if !intersection.isNull {
                totalOverlap += intersection.width * intersection.height
            }
        }
        
        return totalOverlap
    }
    
    // MARK: - Layout Arrangement
    func arrangeWindows(_ windows: [WindowInfo], in screenBounds: CGRect) -> [WindowArrangement] {
        var arrangements: [WindowArrangement] = []
        var remainingSpace = screenBounds
        var positionedWindows: [WindowInfo] = []
        
        // Sort windows by role priority
        let sortedWindows = windows.sorted { window1, window2 in
            let role1 = getWindowRole(for: window1)
            let role2 = getWindowRole(for: window2)
            return role1.layerPriority > role2.layerPriority
        }
        
        for window in sortedWindows {
            let optimalBounds = calculateOptimalSize(
                for: window.appName,
                availableSpace: remainingSpace,
                otherWindows: positionedWindows
            )
            
            arrangements.append(WindowArrangement(
                window: window,
                targetBounds: optimalBounds,
                role: getWindowRole(for: window)
            ))
            
            positionedWindows.append(window)
            
            // Update remaining space for auxiliary windows
            if getWindowRole(for: window) == .primary {
                // Reduce available space for next windows
                if let preference = getLayoutPreference(for: window) {
                    switch preference.preferredPosition {
                    case .left:
                        remainingSpace.origin.x += optimalBounds.width + 10
                        remainingSpace.size.width -= optimalBounds.width + 10
                    case .right:
                        remainingSpace.size.width -= optimalBounds.width + 10
                    default:
                        break
                    }
                }
            }
        }
        
        return arrangements
    }
    
    private func getWindowRole(for window: WindowInfo) -> WindowRole {
        guard let constraints = constraintsManager.getConstraintsByAppName(window.appName),
              let preference = layoutPreferences[constraints.category] else {
            return .auxiliary
        }
        return preference.defaultRole
    }
    
    private func getLayoutPreference(for window: WindowInfo) -> WindowLayoutPreference? {
        guard let constraints = constraintsManager.getConstraintsByAppName(window.appName) else {
            return nil
        }
        return layoutPreferences[constraints.category]
    }
}

// MARK: - Window Arrangement Result
struct WindowArrangement {
    let window: WindowInfo
    let targetBounds: CGRect
    let role: WindowRole
}