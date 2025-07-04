import Cocoa
import QuartzCore

// MARK: - Animation Presets
struct AnimationPresets {
    
    // MARK: - Timing Curves
    static let lightSnappy = AnimationPreset(
        name: "Light Snappy",
        duration: 0.2,
        type: .easeOut,
        description: "Quick, responsive movement for small adjustments"
    )
    
    static let defaultSmooth = AnimationPreset(
        name: "Default Smooth",
        duration: 0.3,
        type: .easeInOut,
        description: "Balanced movement for general window operations"
    )
    
    static let dramatic = AnimationPreset(
        name: "Dramatic",
        duration: 0.5,
        type: .back,
        description: "Eye-catching movement with slight overshoot"
    )
    
    static let playful = AnimationPreset(
        name: "Playful",
        duration: 0.6,
        type: .bounce,
        description: "Fun bouncy movement for delightful interactions"
    )
    
    static let springy = AnimationPreset(
        name: "Springy",
        duration: 0.4,
        type: .spring,
        description: "Natural spring-like movement"
    )
    
    static let instant = AnimationPreset(
        name: "Instant",
        duration: 0.0,
        type: .linear,
        description: "No animation - immediate positioning"
    )
    
    // MARK: - Context-Specific Presets
    static let codingWorkspace = AnimationPreset(
        name: "Coding Workspace",
        duration: 0.25,
        type: .easeOut,
        description: "Quick, efficient animations for development workflow"
    )
    
    static let designWorkspace = AnimationPreset(
        name: "Design Workspace", 
        duration: 0.4,
        type: .spring,
        description: "Smooth, refined animations for creative work"
    )
    
    static let presentationMode = AnimationPreset(
        name: "Presentation Mode",
        duration: 0.5,
        type: .easeInOut,
        description: "Deliberate, visible animations for demonstrations"
    )
    
    static let focusMode = AnimationPreset(
        name: "Focus Mode",
        duration: 0.15,
        type: .easeIn,
        description: "Minimal, non-distracting animations for concentration"
    )
    
    // MARK: - Operation-Specific Presets
    static let maximize = AnimationPreset(
        name: "Maximize",
        duration: 0.35,
        type: .easeOut,
        description: "Smooth expansion to full screen"
    )
    
    static let minimize = AnimationPreset(
        name: "Minimize",
        duration: 0.25,
        type: .easeIn,
        description: "Quick collapse animation"
    )
    
    static let restore = AnimationPreset(
        name: "Restore",
        duration: 0.3,
        type: .back,
        description: "Attention-grabbing restoration from minimized state"
    )
    
    static let cascade = AnimationPreset(
        name: "Cascade",
        duration: 0.2,
        type: .easeOut,
        description: "Staggered positioning for multiple windows"
    )
    
    static let snap = AnimationPreset(
        name: "Snap",
        duration: 0.18,
        type: .easeOut,
        description: "Quick snapping to grid positions"
    )
    
    static let arrange = AnimationPreset(
        name: "Arrange",
        duration: 0.4,
        type: .easeInOut,
        description: "Coordinated movement for workspace arrangements"
    )
    
    // MARK: - Collections
    static let allPresets: [AnimationPreset] = [
        lightSnappy, defaultSmooth, dramatic, playful, springy, instant,
        codingWorkspace, designWorkspace, presentationMode, focusMode,
        maximize, minimize, restore, cascade, snap, arrange
    ]
    
    static let basicPresets: [AnimationPreset] = [
        instant, lightSnappy, defaultSmooth, dramatic, playful, springy
    ]
    
    static let contextPresets: [AnimationPreset] = [
        codingWorkspace, designWorkspace, presentationMode, focusMode
    ]
    
    static let operationPresets: [AnimationPreset] = [
        maximize, minimize, restore, cascade, snap, arrange
    ]
    
    // MARK: - Preset Selection Logic
    static func presetForOperation(_ operation: WindowOperation) -> AnimationPreset {
        switch operation {
        case .maximize:
            return maximize
        case .minimize:
            return minimize
        case .restore:
            return restore
        case .move:
            return defaultSmooth
        case .resize:
            return defaultSmooth
        case .snap:
            return snap
        case .cascade:
            return cascade
        case .arrange:
            return arrange
        case .focus:
            return lightSnappy
        }
    }
    
    static func presetForContext(_ context: String) -> AnimationPreset {
        let lowerContext = context.lowercased()
        
        if lowerContext.contains("coding") || lowerContext.contains("development") {
            return codingWorkspace
        } else if lowerContext.contains("design") || lowerContext.contains("creative") {
            return designWorkspace
        } else if lowerContext.contains("presentation") || lowerContext.contains("demo") {
            return presentationMode
        } else if lowerContext.contains("focus") || lowerContext.contains("concentration") {
            return focusMode
        } else {
            return defaultSmooth
        }
    }
    
    static func presetForUserPreference() -> AnimationPreset {
        let preferences = UserPreferences.shared
        
        // Check if animations are disabled
        guard preferences.animateWindowMovement else {
            return instant
        }
        
        // Use custom duration if specified
        let customDuration = preferences.animationDuration
        
        if customDuration <= 0.1 {
            return lightSnappy
        } else if customDuration <= 0.25 {
            return AnimationPreset(
                name: "Custom Fast",
                duration: customDuration,
                type: .easeOut,
                description: "User-customized fast animation"
            )
        } else if customDuration <= 0.4 {
            return AnimationPreset(
                name: "Custom Medium",
                duration: customDuration,
                type: .easeInOut,
                description: "User-customized medium animation"
            )
        } else {
            return AnimationPreset(
                name: "Custom Slow",
                duration: customDuration,
                type: .easeInOut,
                description: "User-customized slow animation"
            )
        }
    }
    
    // MARK: - Dynamic Adjustment
    static func adjustPresetForDistance(_ preset: AnimationPreset, distance: CGFloat) -> AnimationPreset {
        // Adjust duration based on movement distance
        let baseDistance: CGFloat = 500.0
        let distanceMultiplier = min(distance / baseDistance, 2.0) // Cap at 2x
        let adjustedDuration = preset.duration * Double(distanceMultiplier)
        
        return AnimationPreset(
            name: "\(preset.name) (Adjusted)",
            duration: adjustedDuration,
            type: preset.type,
            description: preset.description
        )
    }
    
    static func adjustPresetForWindowCount(_ preset: AnimationPreset, windowCount: Int) -> AnimationPreset {
        // Reduce individual animation duration when animating many windows
        let countMultiplier = max(0.5, 1.0 - (Double(windowCount - 1) * 0.1))
        let adjustedDuration = preset.duration * countMultiplier
        
        return AnimationPreset(
            name: "\(preset.name) (Multi-window)",
            duration: adjustedDuration,
            type: preset.type,
            description: preset.description
        )
    }
}

// MARK: - Animation Preset Structure
struct AnimationPreset {
    let name: String
    let duration: TimeInterval
    let type: AnimationType
    let description: String
    
    // Computed properties for convenience
    var timingFunction: CAMediaTimingFunction {
        return type.timingFunction
    }
    
    var easingFunction: (Double) -> Double {
        return type.easingFunction
    }
    
    // Create preset with custom parameters
    func withDuration(_ duration: TimeInterval) -> AnimationPreset {
        return AnimationPreset(
            name: "\(name) (Custom Duration)",
            duration: duration,
            type: type,
            description: description
        )
    }
    
    func withType(_ type: AnimationType) -> AnimationPreset {
        return AnimationPreset(
            name: "\(name) (Custom Type)",
            duration: duration,
            type: type,
            description: description
        )
    }
}

// MARK: - Window Operation Types
enum WindowOperation {
    case maximize
    case minimize
    case restore
    case move
    case resize
    case snap
    case cascade
    case arrange
    case focus
}

// MARK: - Animation Configuration
struct AnimationConfiguration {
    let preset: AnimationPreset
    let staggerDelay: TimeInterval
    let coordinatedExecution: Bool
    let respectsReducedMotion: Bool
    
    static let `default` = AnimationConfiguration(
        preset: AnimationPresets.defaultSmooth,
        staggerDelay: 0.1,
        coordinatedExecution: true,
        respectsReducedMotion: true
    )
    
    static let performance = AnimationConfiguration(
        preset: AnimationPresets.lightSnappy,
        staggerDelay: 0.05,
        coordinatedExecution: true,
        respectsReducedMotion: true
    )
    
    static let accessibility = AnimationConfiguration(
        preset: AnimationPresets.instant,
        staggerDelay: 0.0,
        coordinatedExecution: false,
        respectsReducedMotion: true
    )
    
    // Create configuration based on system preferences
    static func fromSystemPreferences() -> AnimationConfiguration {
        // Check for reduce motion preference using UserDefaults
        let reduceMotion = UserDefaults.standard.bool(forKey: "accessibilityReduceMotion")
        
        if reduceMotion {
            return accessibility
        }
        
        return AnimationConfiguration(
            preset: AnimationPresets.presetForUserPreference(),
            staggerDelay: 0.1,
            coordinatedExecution: true,
            respectsReducedMotion: true
        )
    }
}

// MARK: - Preset Validation
extension AnimationPresets {
    static func validatePreset(_ preset: AnimationPreset) -> Bool {
        return preset.duration >= 0.0 && preset.duration <= 2.0
    }
    
    static func sanitizePreset(_ preset: AnimationPreset) -> AnimationPreset {
        let clampedDuration = max(0.0, min(2.0, preset.duration))
        
        if clampedDuration == preset.duration {
            return preset
        }
        
        return AnimationPreset(
            name: "\(preset.name) (Sanitized)",
            duration: clampedDuration,
            type: preset.type,
            description: preset.description
        )
    }
}