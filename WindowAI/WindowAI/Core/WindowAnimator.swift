import Cocoa
import QuartzCore

// MARK: - Window Animation Service
class WindowAnimator {
    
    static let shared = WindowAnimator()
    
    private let windowManager: WindowManager
    private var activeAnimations: [String: NSAnimationContext] = [:]
    
    private init() {
        self.windowManager = WindowManager.shared
    }
    
    // MARK: - Public Animation API
    
    /// Animate window to new position with smooth easing
    func animateWindowMove(_ windowInfo: WindowInfo, to newPosition: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        let animationId = "\(windowInfo.appName)_move_\(Date().timeIntervalSince1970)"
        
        print("🎬 Animating '\(windowInfo.appName)' move to \(newPosition) over \(duration)s")
        
        // Check if animations are enabled
        guard UserPreferences.shared.animateWindowMovement else {
            windowManager.moveWindow(windowInfo, to: newPosition)
            completion?()
            return
        }
        
        let currentPosition = windowInfo.bounds.origin
        let distance = sqrt(pow(newPosition.x - currentPosition.x, 2) + pow(newPosition.y - currentPosition.y, 2))
        
        // Adjust duration based on distance for natural feeling
        let adjustedDuration = min(duration * (distance / 500.0), duration * 2.0)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = adjustedDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            
            // Store animation reference
            self.activeAnimations[animationId] = context
            
            // Perform animated position change
            self.animatePositionChange(windowInfo, from: currentPosition, to: newPosition, duration: adjustedDuration)
            
        }, completionHandler: {
            self.activeAnimations.removeValue(forKey: animationId)
            print("✨ Move animation completed for '\(windowInfo.appName)'")
            completion?()
        })
    }
    
    /// Animate window resize with smooth scaling
    func animateWindowResize(_ windowInfo: WindowInfo, to newSize: CGSize, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        let animationId = "\(windowInfo.appName)_resize_\(Date().timeIntervalSince1970)"
        
        print("🎬 Animating '\(windowInfo.appName)' resize to \(newSize) over \(duration)s")
        
        guard UserPreferences.shared.animateWindowMovement else {
            windowManager.resizeWindow(windowInfo, to: newSize)
            completion?()
            return
        }
        
        let currentSize = windowInfo.bounds.size
        let sizeChange = abs(newSize.width - currentSize.width) + abs(newSize.height - currentSize.height)
        
        // Adjust duration based on size change magnitude
        let adjustedDuration = min(duration * (sizeChange / 1000.0), duration * 1.5)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = adjustedDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.activeAnimations[animationId] = context
            
            // Perform animated size change
            self.animateSizeChange(windowInfo, from: currentSize, to: newSize, duration: adjustedDuration)
            
        }, completionHandler: {
            self.activeAnimations.removeValue(forKey: animationId)
            print("✨ Resize animation completed for '\(windowInfo.appName)'")
            completion?()
        })
    }
    
    /// Animate window bounds (position + size) with coordinated movement
    func animateWindowBounds(_ windowInfo: WindowInfo, to newBounds: CGRect, duration: TimeInterval = 0.3, animationType: AnimationType = .easeInOut, completion: (() -> Void)? = nil) {
        let animationId = "\(windowInfo.appName)_bounds_\(Date().timeIntervalSince1970)"
        
        print("🎬 WindowAnimator.animateWindowBounds called!")
        print("🎬 Animating '\(windowInfo.appName)' bounds to \(newBounds) over \(duration)s")
        print("🎬 Animation type: \(animationType), current bounds: \(windowInfo.bounds)")
        
        guard UserPreferences.shared.animateWindowMovement else {
            windowManager.setWindowBounds(windowInfo, bounds: newBounds)
            completion?()
            return
        }
        
        let currentBounds = windowInfo.bounds
        let positionChange = sqrt(pow(newBounds.origin.x - currentBounds.origin.x, 2) + pow(newBounds.origin.y - currentBounds.origin.y, 2))
        let sizeChange = abs(newBounds.width - currentBounds.width) + abs(newBounds.height - currentBounds.height)
        
        // Smart duration adjustment based on total change
        let totalChange = positionChange + sizeChange
        let adjustedDuration = min(duration * (totalChange / 800.0), duration * 2.0)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = adjustedDuration
            context.timingFunction = animationType.timingFunction
            
            self.activeAnimations[animationId] = context
            
            // Perform coordinated bounds animation
            self.animateBoundsChange(windowInfo, from: currentBounds, to: newBounds, duration: adjustedDuration, animationType: animationType)
            
        }, completionHandler: {
            self.activeAnimations.removeValue(forKey: animationId)
            print("✨ Bounds animation completed for '\(windowInfo.appName)'")
            completion?()
        })
    }
    
    /// Animate multiple windows in a coordinated cascade
    func animateWindowCascade(_ windowBounds: [(WindowInfo, CGRect)], duration: TimeInterval = 0.3, staggerDelay: TimeInterval = 0.1, completion: (() -> Void)? = nil) {
        print("🎬 Starting cascade animation for \(windowBounds.count) windows")
        
        guard UserPreferences.shared.animateWindowMovement else {
            // Execute all moves instantly if animations disabled
            for (window, bounds) in windowBounds {
                windowManager.setWindowBounds(window, bounds: bounds)
            }
            completion?()
            return
        }
        
        var completedAnimations = 0
        let totalAnimations = windowBounds.count
        
        for (index, (windowInfo, newBounds)) in windowBounds.enumerated() {
            let delay = Double(index) * staggerDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.animateWindowBounds(windowInfo, to: newBounds, duration: duration, animationType: .easeOut) {
                    completedAnimations += 1
                    if completedAnimations == totalAnimations {
                        print("✨ Cascade animation completed for all \(totalAnimations) windows")
                        completion?()
                    }
                }
            }
        }
    }
    
    // MARK: - Animation Implementation
    
    private func animatePositionChange(_ windowInfo: WindowInfo, from startPos: CGPoint, to endPos: CGPoint, duration: TimeInterval) {
        let steps = Int(duration * 60) // 60 FPS
        let stepDelay = duration / Double(steps)
        
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let easedProgress = easeInOutQuart(progress)
            
            let currentX = startPos.x + (endPos.x - startPos.x) * easedProgress
            let currentY = startPos.y + (endPos.y - startPos.y) * easedProgress
            let currentPosition = CGPoint(x: currentX, y: currentY)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(step)) {
                _ = self.windowManager.moveWindow(windowInfo, to: currentPosition)
            }
        }
    }
    
    private func animateSizeChange(_ windowInfo: WindowInfo, from startSize: CGSize, to endSize: CGSize, duration: TimeInterval) {
        let steps = Int(duration * 60) // 60 FPS
        let stepDelay = duration / Double(steps)
        
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let easedProgress = easeInOutQuart(progress)
            
            let currentWidth = startSize.width + (endSize.width - startSize.width) * easedProgress
            let currentHeight = startSize.height + (endSize.height - startSize.height) * easedProgress
            let currentSize = CGSize(width: currentWidth, height: currentHeight)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(step)) {
                _ = self.windowManager.resizeWindow(windowInfo, to: currentSize)
            }
        }
    }
    
    private func animateBoundsChange(_ windowInfo: WindowInfo, from startBounds: CGRect, to endBounds: CGRect, duration: TimeInterval, animationType: AnimationType) {
        let steps = Int(duration * 60) // 60 FPS
        let stepDelay = duration / Double(steps)
        
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let easedProgress = animationType.easingFunction(progress)
            
            // Interpolate position
            let currentX = startBounds.origin.x + (endBounds.origin.x - startBounds.origin.x) * easedProgress
            let currentY = startBounds.origin.y + (endBounds.origin.y - startBounds.origin.y) * easedProgress
            
            // Interpolate size
            let currentWidth = startBounds.width + (endBounds.width - startBounds.width) * easedProgress
            let currentHeight = startBounds.height + (endBounds.height - startBounds.height) * easedProgress
            
            let currentBounds = CGRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(step)) {
                _ = self.windowManager.setWindowBounds(windowInfo, bounds: currentBounds)
            }
        }
    }
    
    // MARK: - Animation Control
    
    /// Cancel all active animations
    func cancelAllAnimations() {
        for (animationId, _) in activeAnimations {
            print("🛑 Cancelling animation: \(animationId)")
        }
        activeAnimations.removeAll()
    }
    
    /// Cancel animations for specific window
    func cancelAnimations(for windowInfo: WindowInfo) {
        let windowAnimations = activeAnimations.filter { $0.key.contains(windowInfo.appName) }
        for (animationId, _) in windowAnimations {
            print("🛑 Cancelling animation for \(windowInfo.appName): \(animationId)")
            activeAnimations.removeValue(forKey: animationId)
        }
    }
    
    // MARK: - Easing Functions
    
    private func easeInOutQuart(_ t: Double) -> Double {
        return t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4) / 2
    }
    
    func easeOutBounce(_ t: Double) -> Double {
        if t < 1 / 2.75 {
            return 7.5625 * t * t
        } else if t < 2 / 2.75 {
            let t2 = t - 1.5 / 2.75
            return 7.5625 * t2 * t2 + 0.75
        } else if t < 2.5 / 2.75 {
            let t2 = t - 2.25 / 2.75
            return 7.5625 * t2 * t2 + 0.9375
        } else {
            let t2 = t - 2.625 / 2.75
            return 7.5625 * t2 * t2 + 0.984375
        }
    }
    
    func easeInOutBack(_ t: Double) -> Double {
        let c1 = 1.70158
        let c2 = c1 * 1.525
        
        return t < 0.5
            ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
            : (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
    }
}

// MARK: - Animation Types
enum AnimationType {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case bounce
    case spring
    case back
    
    var timingFunction: CAMediaTimingFunction {
        switch self {
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        case .easeIn:
            return CAMediaTimingFunction(name: .easeIn)
        case .easeOut:
            return CAMediaTimingFunction(name: .easeOut)
        case .easeInOut:
            return CAMediaTimingFunction(name: .easeInEaseOut)
        case .bounce:
            return CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
        case .spring:
            return CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
        case .back:
            return CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
        }
    }
    
    var easingFunction: (Double) -> Double {
        switch self {
        case .linear:
            return { $0 }
        case .easeIn:
            return { $0 * $0 }
        case .easeOut:
            return { 1 - pow(1 - $0, 2) }
        case .easeInOut:
            return { $0 < 0.5 ? 2 * $0 * $0 : 1 - pow(-2 * $0 + 2, 2) / 2 }
        case .bounce:
            return WindowAnimator.shared.easeOutBounce
        case .spring:
            return { $0 < 0.5 ? 4 * $0 * $0 * $0 : 1 - pow(-2 * $0 + 2, 3) / 2 }
        case .back:
            return WindowAnimator.shared.easeInOutBack
        }
    }
}