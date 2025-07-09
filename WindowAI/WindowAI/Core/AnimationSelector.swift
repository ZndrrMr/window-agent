import Cocoa
import Foundation

// MARK: - Smart Animation Selection Service
class AnimationSelector {
    
    static let shared = AnimationSelector()
    
    private let userPreferences = UserPreferences.shared
    private var lastSelectionTime: Date = Date()
    private var recentAnimationCount: Int = 0
    private let adaptiveCountWindow: TimeInterval = 5.0 // 5-second window
    
    private init() {}
    
    // MARK: - Main Selection API
    
    /// Select the optimal animation preset for a window operation
    func selectPreset(
        for operation: WindowOperation,
        window: WindowInfo,
        context: AnimationContext,
        distance: CGFloat = 0,
        windowCount: Int = 1
    ) -> AnimationPreset {
        
        // Check for animation overrides
        if let overridePreset = checkForOverrides(operation: operation, context: context) {
            return overridePreset
        }
        
        // Start with base preset for operation
        var preset = AnimationPresets.presetForOperation(operation)
        
        // Apply contextual modifications
        preset = applyContextualAdjustments(preset, context: context)
        
        // Apply user preferences
        preset = applyUserPreferences(preset)
        
        // Apply performance optimizations
        preset = applyPerformanceOptimizations(preset, window: window, distance: distance, windowCount: windowCount)
        
        // Apply accessibility considerations
        preset = applyAccessibilityAdjustments(preset)
        
        // Apply adaptive learning
        preset = applyAdaptiveLearning(preset, operation: operation, context: context)
        
        // Track this selection for learning
        trackAnimationSelection(preset: preset, operation: operation, context: context)
        
        return preset
    }
    
    /// Select configuration for coordinated multi-window animations
    func selectConfiguration(
        for operations: [WindowOperation],
        windows: [WindowInfo],
        context: AnimationContext
    ) -> AnimationConfiguration {
        
        let windowCount = windows.count
        
        // Base configuration selection
        var config: AnimationConfiguration
        
        if windowCount == 1 {
            config = .default
        } else if windowCount <= 3 {
            config = .performance
        } else {
            config = AnimationConfiguration(
                preset: AnimationPresets.lightSnappy,
                staggerDelay: 0.05,
                coordinatedExecution: true,
                respectsReducedMotion: true
            )
        }
        
        // Adjust for context
        config = adjustConfigurationForContext(config, context: context, windowCount: windowCount)
        
        // Apply user preferences
        config = adjustConfigurationForUserPreferences(config)
        
        // Apply system performance considerations
        config = adjustConfigurationForPerformance(config, windowCount: windowCount)
        
        return config
    }
    
    // MARK: - Override Checks
    
    private func checkForOverrides(operation: WindowOperation, context: AnimationContext) -> AnimationPreset? {
        
        // Check for accessibility overrides
        if UserDefaults.standard.bool(forKey: "accessibilityReduceMotion") {
            return AnimationPresets.instant
        }
        
        // Check for user disable
        guard userPreferences.animateWindowMovement else {
            return AnimationPresets.instant
        }
        
        // Check for performance mode
        if context.performanceMode {
            return AnimationPresets.lightSnappy
        }
        
        // Check for focus mode
        if context.isFocusMode {
            return AnimationPresets.focusMode
        }
        
        // Check for presentation mode
        if context.isPresentationMode {
            return AnimationPresets.presentationMode
        }
        
        return nil
    }
    
    // MARK: - Contextual Adjustments
    
    private func applyContextualAdjustments(_ preset: AnimationPreset, context: AnimationContext) -> AnimationPreset {
        
        // Adjust for workspace type
        let contextPreset = AnimationPresets.presetForContext(context.workspaceType)
        
        // Blend presets based on confidence
        if context.confidence > 0.8 {
            return contextPreset
        } else {
            // Create hybrid preset
            let blendedDuration = (preset.duration + contextPreset.duration) / 2.0
            return AnimationPreset(
                name: "Blended (\(preset.name) + \(contextPreset.name))",
                duration: blendedDuration,
                type: preset.type,
                description: "Context-adjusted animation"
            )
        }
    }
    
    private func applyUserPreferences(_ preset: AnimationPreset) -> AnimationPreset {
        let userDuration = userPreferences.animationDuration
        
        // If user has customized duration, respect it
        if abs(userDuration - 0.3) > 0.05 { // Default is 0.3, so if significantly different
            return preset.withDuration(userDuration)
        }
        
        return preset
    }
    
    // MARK: - Performance Optimizations
    
    private func applyPerformanceOptimizations(
        _ preset: AnimationPreset,
        window: WindowInfo,
        distance: CGFloat,
        windowCount: Int
    ) -> AnimationPreset {
        
        var optimizedPreset = preset
        
        // Adjust for distance
        if distance > 0 {
            optimizedPreset = AnimationPresets.adjustPresetForDistance(optimizedPreset, distance: distance)
        }
        
        // Adjust for multiple windows
        if windowCount > 1 {
            optimizedPreset = AnimationPresets.adjustPresetForWindowCount(optimizedPreset, windowCount: windowCount)
        }
        
        // Check recent animation load
        updateAnimationLoad()
        if recentAnimationCount > 5 {
            // High animation load - use faster animations
            let speedupFactor = 0.7
            optimizedPreset = optimizedPreset.withDuration(optimizedPreset.duration * speedupFactor)
        }
        
        // Check for low-power mode (if available)
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return AnimationPresets.lightSnappy
        }
        
        return optimizedPreset
    }
    
    private func applyAccessibilityAdjustments(_ preset: AnimationPreset) -> AnimationPreset {
        // Check for motion sensitivity
        if UserDefaults.standard.bool(forKey: "accessibilityReduceMotion") {
            return AnimationPresets.instant
        }
        
        // Check for other accessibility preferences
        if UserDefaults.standard.bool(forKey: "accessibilityIncreaseContrast") {
            // User may prefer more obvious animations
            return preset.withType(.easeInOut)
        }
        
        return preset
    }
    
    // MARK: - Adaptive Learning
    
    private func applyAdaptiveLearning(_ preset: AnimationPreset, operation: WindowOperation, context: AnimationContext) -> AnimationPreset {
        
        // Check for learned user preferences for this operation type
        if let learnedDuration = getLearnedDuration(for: operation, context: context.workspaceType) {
            return preset.withDuration(learnedDuration)
        }
        
        // Check for time-of-day preferences
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 9 || hour > 18 {
            // Outside work hours - use more playful animations
            if preset.duration < 0.5 {
                return AnimationPresets.playful
            }
        }
        
        return preset
    }
    
    // MARK: - Configuration Adjustments
    
    private func adjustConfigurationForContext(_ config: AnimationConfiguration, context: AnimationContext, windowCount: Int) -> AnimationConfiguration {
        
        var adjustedConfig = config
        
        // Adjust stagger delay based on context
        switch context.workspaceType.lowercased() {
        case "coding", "development":
            // Fast, efficient transitions
            adjustedConfig = AnimationConfiguration(
                preset: config.preset,
                staggerDelay: 0.05,
                coordinatedExecution: true,
                respectsReducedMotion: config.respectsReducedMotion
            )
        case "design", "creative":
            // More deliberate, visible transitions
            adjustedConfig = AnimationConfiguration(
                preset: config.preset,
                staggerDelay: 0.15,
                coordinatedExecution: true,
                respectsReducedMotion: config.respectsReducedMotion
            )
        case "presentation":
            // Slow, dramatic transitions
            adjustedConfig = AnimationConfiguration(
                preset: AnimationPresets.dramatic,
                staggerDelay: 0.3,
                coordinatedExecution: true,
                respectsReducedMotion: config.respectsReducedMotion
            )
        default:
            // Keep default
            break
        }
        
        return adjustedConfig
    }
    
    private func adjustConfigurationForUserPreferences(_ config: AnimationConfiguration) -> AnimationConfiguration {
        let userPreset = AnimationPresets.presetForUserPreference()
        
        return AnimationConfiguration(
            preset: userPreset,
            staggerDelay: config.staggerDelay,
            coordinatedExecution: config.coordinatedExecution,
            respectsReducedMotion: config.respectsReducedMotion
        )
    }
    
    private func adjustConfigurationForPerformance(_ config: AnimationConfiguration, windowCount: Int) -> AnimationConfiguration {
        
        // For many windows, reduce stagger delay and use performance preset
        if windowCount > 6 {
            return AnimationConfiguration(
                preset: AnimationPresets.lightSnappy,
                staggerDelay: 0.03,
                coordinatedExecution: true,
                respectsReducedMotion: config.respectsReducedMotion
            )
        } else if windowCount > 10 {
            // Very many windows - minimal animation
            return AnimationConfiguration(
                preset: AnimationPresets.instant,
                staggerDelay: 0.0,
                coordinatedExecution: false,
                respectsReducedMotion: config.respectsReducedMotion
            )
        }
        
        return config
    }
    
    // MARK: - Learning and Tracking
    
    private func trackAnimationSelection(preset: AnimationPreset, operation: WindowOperation, context: AnimationContext) {
        // Store selection for learning
        let selection = AnimationSelection(
            preset: preset,
            operation: operation,
            context: context,
            timestamp: Date()
        )
        
        storeAnimationSelection(selection)
    }
    
    private func updateAnimationLoad() {
        let now = Date()
        
        // Reset count if enough time has passed
        if now.timeIntervalSince(lastSelectionTime) > adaptiveCountWindow {
            recentAnimationCount = 0
        }
        
        recentAnimationCount += 1
        lastSelectionTime = now
    }
    
    private func getLearnedDuration(for operation: WindowOperation, context: String) -> TimeInterval? {
        // This would fetch from persistent storage
        // For now, return nil (no learned preference)
        return nil
    }
    
    private func storeAnimationSelection(_ selection: AnimationSelection) {
        // This would store to persistent storage for learning
        // For now, just log
        print("📊 Animation selection: \(selection.preset.name) for \(selection.operation) in \(selection.context.workspaceType)")
    }
    
    // MARK: - Utility Methods
    
    /// Get optimal preset for app type
    func presetForApp(_ appName: String, operation: WindowOperation = .move) -> AnimationPreset {
        let bundleID = getBundleID(for: appName)
        
        // App-specific presets
        switch bundleID {
        case "com.apple.Terminal", "com.googlecode.iterm2":
            return AnimationPresets.codingWorkspace
        case "com.figma.Desktop", "com.bohemiancoding.sketch3":
            return AnimationPresets.designWorkspace
        case "com.microsoft.VSCode", "com.apple.dt.Xcode":
            return AnimationPresets.codingWorkspace
        default:
            return AnimationPresets.presetForOperation(operation)
        }
    }
    
    /// Check if system is under heavy load
    private func isSystemUnderLoad() -> Bool {
        // This could check CPU usage, memory pressure, etc.
        // For now, use animation count as proxy
        return recentAnimationCount > 8
    }
    
    // Use centralized app discovery service for bundle ID resolution
    private func getBundleID(for appName: String) -> String? {
        return AppDiscoveryService.shared.getBundleID(for: appName)
    }
}

// MARK: - Animation Context
struct AnimationContext {
    let workspaceType: String
    let confidence: Double
    let performanceMode: Bool
    let isFocusMode: Bool
    let isPresentationMode: Bool
    let userPresent: Bool
    
    static let `default` = AnimationContext(
        workspaceType: "general",
        confidence: 0.5,
        performanceMode: false,
        isFocusMode: false,
        isPresentationMode: false,
        userPresent: true
    )
    
    static func fromCommand(_ command: WindowCommand) -> AnimationContext {
        let workspaceType = command.target
        let confidence = 0.8 // High confidence for explicit commands
        
        return AnimationContext(
            workspaceType: workspaceType,
            confidence: confidence,
            performanceMode: false,
            isFocusMode: workspaceType.lowercased().contains("focus"),
            isPresentationMode: workspaceType.lowercased().contains("presentation"),
            userPresent: true
        )
    }
    
    static func fromWorkspace(_ workspaceName: String) -> AnimationContext {
        return AnimationContext(
            workspaceType: workspaceName,
            confidence: 0.9,
            performanceMode: false,
            isFocusMode: workspaceName.lowercased().contains("focus"),
            isPresentationMode: workspaceName.lowercased().contains("presentation"),
            userPresent: true
        )
    }
}

// MARK: - Animation Selection Record
private struct AnimationSelection {
    let preset: AnimationPreset
    let operation: WindowOperation
    let context: AnimationContext
    let timestamp: Date
}

// MARK: - Smart Preset Extensions
extension AnimationSelector {
    
    /// Get preset for multiple coordinated operations
    func presetForCoordinatedOperations(_ operations: [WindowOperation]) -> AnimationPreset {
        // If all operations are the same type, use that preset
        if Set(operations).count == 1, let operation = operations.first {
            return AnimationPresets.presetForOperation(operation)
        }
        
        // Mixed operations - use versatile preset
        return AnimationPresets.arrange
    }
    
    /// Get optimal stagger delay for window count
    func optimalStaggerDelay(for windowCount: Int) -> TimeInterval {
        switch windowCount {
        case 1:
            return 0.0
        case 2...3:
            return 0.1
        case 4...6:
            return 0.08
        case 7...10:
            return 0.05
        default:
            return 0.03
        }
    }
    
    /// Check if animation should be instant based on context
    func shouldUseInstantAnimation(context: AnimationContext) -> Bool {
        return context.performanceMode || 
               !userPreferences.animateWindowMovement ||
               UserDefaults.standard.bool(forKey: "accessibilityReduceMotion")
    }
}