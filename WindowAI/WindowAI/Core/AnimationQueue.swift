import Cocoa
import Foundation

// MARK: - Animation Queue Manager
class AnimationQueue {
    
    static let shared = AnimationQueue()
    
    private var activeAnimations: [String: AnimationTask] = [:]
    private var queuedAnimations: [AnimationTask] = []
    private var isProcessingQueue = false
    private let maxConcurrentAnimations = 8
    private let animationLock = NSLock()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Queue a single window animation
    func queueAnimation(
        id: String,
        windowInfo: WindowInfo,
        operation: AnimationOperation,
        preset: AnimationPreset = AnimationPresets.defaultSmooth,
        priority: AnimationPriority = .normal,
        completion: (() -> Void)? = nil
    ) {
        print("🎯 queueAnimation called - id: \(id), window: \(windowInfo.appName), operation: \(operation)")
        
        let task = AnimationTask(
            id: id,
            windowInfo: windowInfo,
            operation: operation,
            preset: preset,
            priority: priority,
            completion: completion
        )
        
        print("📋 Created animation task, calling queueAnimationTask")
        queueAnimationTask(task)
    }
    
    /// Queue multiple coordinated animations
    func queueCoordinatedAnimations(
        _ animations: [(WindowInfo, AnimationOperation)],
        preset: AnimationPreset = AnimationPresets.cascade,
        staggerDelay: TimeInterval = 0.1,
        groupId: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        let group = groupId ?? "coordinated_\(Date().timeIntervalSince1970)"
        var completedCount = 0
        let totalCount = animations.count
        
        for (index, (windowInfo, operation)) in animations.enumerated() {
            let taskId = "\(group)_\(index)"
            let delay = Double(index) * staggerDelay
            
            let task = AnimationTask(
                id: taskId,
                windowInfo: windowInfo,
                operation: operation,
                preset: preset,
                priority: .normal,
                delay: delay,
                groupId: group,
                completion: {
                    completedCount += 1
                    if completedCount == totalCount {
                        completion?()
                    }
                }
            )
            
            queueAnimationTask(task)
        }
    }
    
    /// Queue workspace transition with smart sequencing
    func queueWorkspaceTransition(
        windows: [WindowInfo],
        targetBounds: [CGRect],
        configuration: AnimationConfiguration = .default,
        completion: (() -> Void)? = nil
    ) {
        guard windows.count == targetBounds.count else {
            print("❌ AnimationQueue: Window count doesn't match target bounds count")
            completion?()
            return
        }
        
        let groupId = "workspace_\(Date().timeIntervalSince1970)"
        var completedCount = 0
        let totalCount = windows.count
        
        // Sort windows by priority (focused window first, then by distance to move)
        let sortedPairs = zip(windows, targetBounds).sorted { (pair1, pair2) in
            let (window1, bounds1) = pair1
            let (window2, bounds2) = pair2
            
            // Prioritize focused window
            let app1 = NSWorkspace.shared.frontmostApplication?.localizedName
            let app2 = NSWorkspace.shared.frontmostApplication?.localizedName
            
            if window1.appName == app1 && window2.appName != app2 {
                return true
            } else if window1.appName != app1 && window2.appName == app2 {
                return false
            }
            
            // Then sort by distance to move (shorter moves first)
            let distance1 = calculateDistance(from: window1.bounds.origin, to: bounds1.origin)
            let distance2 = calculateDistance(from: window2.bounds.origin, to: bounds2.origin)
            
            return distance1 < distance2
        }
        
        for (index, (window, bounds)) in sortedPairs.enumerated() {
            let taskId = "\(groupId)_\(index)"
            let delay = Double(index) * configuration.staggerDelay
            
            let operation = AnimationOperation.bounds(bounds)
            let adjustedPreset = AnimationPresets.adjustPresetForWindowCount(
                configuration.preset,
                windowCount: totalCount
            )
            
            let task = AnimationTask(
                id: taskId,
                windowInfo: window,
                operation: operation,
                preset: adjustedPreset,
                priority: index == 0 ? .high : .normal, // First window gets high priority
                delay: delay,
                groupId: groupId,
                completion: {
                    completedCount += 1
                    if completedCount == totalCount {
                        print("✨ Workspace transition completed: \(totalCount) windows")
                        completion?()
                    }
                }
            )
            
            queueAnimationTask(task)
        }
    }
    
    /// Cancel animations for specific window
    func cancelAnimations(for windowInfo: WindowInfo) {
        animationLock.lock()
        defer { animationLock.unlock() }
        
        // Cancel active animations
        let windowAnimations = activeAnimations.filter { $0.value.windowInfo.appName == windowInfo.appName }
        for (id, task) in windowAnimations {
            task.cancel()
            activeAnimations.removeValue(forKey: id)
            print("🛑 Cancelled active animation: \(id)")
        }
        
        // Remove queued animations
        queuedAnimations.removeAll { task in
            let shouldRemove = task.windowInfo.appName == windowInfo.appName
            if shouldRemove {
                print("🛑 Removed queued animation: \(task.id)")
            }
            return shouldRemove
        }
    }
    
    /// Cancel all animations in a group
    func cancelAnimationGroup(_ groupId: String) {
        animationLock.lock()
        defer { animationLock.unlock() }
        
        // Cancel active animations in group
        let groupAnimations = activeAnimations.filter { $0.value.groupId == groupId }
        for (id, task) in groupAnimations {
            task.cancel()
            activeAnimations.removeValue(forKey: id)
            print("🛑 Cancelled group animation: \(id)")
        }
        
        // Remove queued animations in group
        queuedAnimations.removeAll { task in
            let shouldRemove = task.groupId == groupId
            if shouldRemove {
                print("🛑 Removed queued group animation: \(task.id)")
            }
            return shouldRemove
        }
    }
    
    /// Cancel all animations
    func cancelAllAnimations() {
        animationLock.lock()
        defer { animationLock.unlock() }
        
        for (id, task) in activeAnimations {
            task.cancel()
            print("🛑 Cancelled animation: \(id)")
        }
        
        activeAnimations.removeAll()
        queuedAnimations.removeAll()
        isProcessingQueue = false
        
        print("🛑 All animations cancelled")
    }
    
    /// Emergency cleanup - cancel all and reset queue
    func emergencyReset() {
        print("🚨 Emergency animation queue reset")
        cancelAllAnimations()
        
        // Force reset processing state
        animationLock.lock()
        isProcessingQueue = false
        animationLock.unlock()
    }
    
    /// Get current queue status
    func getQueueStatus() -> AnimationQueueStatus {
        animationLock.lock()
        defer { animationLock.unlock() }
        
        return AnimationQueueStatus(
            activeAnimations: activeAnimations.count,
            queuedAnimations: queuedAnimations.count,
            isProcessing: isProcessingQueue
        )
    }
    
    // MARK: - Private Implementation
    
    private func queueAnimationTask(_ task: AnimationTask) {
        animationLock.lock()
        defer { animationLock.unlock() }
        
        // Check if there's already an animation for this window
        let existingActiveAnimation = activeAnimations.values.first { $0.windowInfo.appName == task.windowInfo.appName }
        if let existing = existingActiveAnimation {
            existing.cancel()
            activeAnimations.removeValue(forKey: existing.id)
            print("🔄 Cancelled existing animation for \(task.windowInfo.appName)")
        }
        
        // Remove any queued animations for this window
        queuedAnimations.removeAll { $0.windowInfo.appName == task.windowInfo.appName }
        
        // Add to queue based on priority
        if task.priority == .high {
            queuedAnimations.insert(task, at: 0)
        } else {
            queuedAnimations.append(task)
        }
        
        print("📥 Queued animation: \(task.id) (Priority: \(task.priority), Queue: \(queuedAnimations.count))")
        
        // Start processing if not already running
        print("🔍 Checking if should start processing - isProcessingQueue: \(isProcessingQueue)")
        if !isProcessingQueue {
            print("🚀 Calling processQueue()")
            isProcessingQueue = true
            
            // Call processNextAnimations directly to avoid method call issues
            DispatchQueue.main.async {
                print("📱 Direct main queue execution")
                self.processNextAnimations()
            }
        } else {
            print("⏸️ Queue already processing, not starting new process")
        }
    }
    
    private func processQueue() {
        animationLock.lock()
        print("🔄 processQueue called - currently processing: \(isProcessingQueue)")
        guard !isProcessingQueue else {
            animationLock.unlock()
            print("⏸️ Queue already processing, skipping")
            return
        }
        isProcessingQueue = true
        animationLock.unlock()
        
        print("🚀 Starting queue processing, isMainThread: \(Thread.isMainThread)")
        
        // Try immediate execution first, then fallback to async
        if Thread.isMainThread {
            print("📱 Already on main thread, calling processNextAnimations directly")
            self.processNextAnimations()
        } else {
            print("📱 Dispatching to main thread")
            DispatchQueue.main.async {
                print("📱 On main thread, calling processNextAnimations")
                self.processNextAnimations()
            }
        }
    }
    
    private func processNextAnimations() {
        print("📱 processNextAnimations called")
        animationLock.lock()
        
        // Check if we can start more animations
        let availableSlots = maxConcurrentAnimations - activeAnimations.count
        print("🔄 Processing animations: available=\(availableSlots), queued=\(queuedAnimations.count), active=\(activeAnimations.count)")
        
        guard availableSlots > 0 && !queuedAnimations.isEmpty else {
            print("❌ Cannot process: availableSlots=\(availableSlots), queuedAnimations.count=\(queuedAnimations.count)")
            isProcessingQueue = false
            animationLock.unlock()
            if queuedAnimations.isEmpty {
                print("✅ Animation queue empty")
            } else {
                print("⏸️ No available slots for animations")
            }
            return
        }
        
        // Take animations to start
        let animationsToStart = Array(queuedAnimations.prefix(availableSlots))
        queuedAnimations.removeFirst(min(availableSlots, queuedAnimations.count))
        
        animationLock.unlock()
        
        // Start animations
        for task in animationsToStart {
            startAnimation(task)
        }
        
        // Continue processing if there are more animations queued
        if !queuedAnimations.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.processNextAnimations()
            }
        } else {
            animationLock.lock()
            isProcessingQueue = false
            animationLock.unlock()
        }
    }
    
    private func startAnimation(_ task: AnimationTask) {
        print("🎬 startAnimation called for: \(task.id)")
        // Add to active animations
        animationLock.lock()
        activeAnimations[task.id] = task
        animationLock.unlock()
        
        print("🎬 Starting animation: \(task.id) (Active: \(activeAnimations.count))")
        
        // Apply delay if specified
        let startTime = DispatchTime.now() + task.delay
        DispatchQueue.main.asyncAfter(deadline: startTime) {
            guard !task.isCancelled else {
                print("❌ Animation cancelled before execution: \(task.id)")
                self.animationCompleted(taskId: task.id)
                return
            }
            
            print("▶️ Executing animation: \(task.id)")
            self.executeAnimation(task)
        }
    }
    
    private func executeAnimation(_ task: AnimationTask) {
        let animator = WindowAnimator.shared
        
        print("🎨 Executing animation operation: \(task.operation)")
        
        switch task.operation {
        case .move(let position):
            print("📍 Moving window to: \(position)")
            animator.animateWindowMove(
                task.windowInfo,
                to: position,
                duration: task.preset.duration
            ) {
                print("✅ Move animation completed for: \(task.id)")
                self.animationCompleted(taskId: task.id, success: true)
            }
            
        case .resize(let size):
            print("📐 Resizing window to: \(size)")
            animator.animateWindowResize(
                task.windowInfo,
                to: size,
                duration: task.preset.duration
            ) {
                print("✅ Resize animation completed for: \(task.id)")
                self.animationCompleted(taskId: task.id, success: true)
            }
            
        case .bounds(let bounds):
            print("📦 Setting window bounds to: \(bounds)")
            print("📦 Using preset duration: \(task.preset.duration), type: \(task.preset.type)")
            animator.animateWindowBounds(
                task.windowInfo,
                to: bounds,
                duration: task.preset.duration,
                animationType: task.preset.type
            ) {
                print("✅ Bounds animation completed for: \(task.id)")
                self.animationCompleted(taskId: task.id, success: true)
            }
        }
    }
    
    private func animationCompleted(taskId: String, success: Bool = false) {
        animationLock.lock()
        let task = activeAnimations.removeValue(forKey: taskId)
        animationLock.unlock()
        
        if let task = task {
            print("✨ Animation completed: \(taskId) (Success: \(success))")
            task.completion?()
        }
        
        // Continue processing queue
        if !queuedAnimations.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.processNextAnimations()
            }
        }
    }
    
    private func calculateDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Animation Task
class AnimationTask {
    let id: String
    let windowInfo: WindowInfo
    let operation: AnimationOperation
    let preset: AnimationPreset
    let priority: AnimationPriority
    let delay: TimeInterval
    let groupId: String?
    let completion: (() -> Void)?
    
    private(set) var isCancelled = false
    
    init(
        id: String,
        windowInfo: WindowInfo,
        operation: AnimationOperation,
        preset: AnimationPreset,
        priority: AnimationPriority = .normal,
        delay: TimeInterval = 0.0,
        groupId: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        self.id = id
        self.windowInfo = windowInfo
        self.operation = operation
        self.preset = preset
        self.priority = priority
        self.delay = delay
        self.groupId = groupId
        self.completion = completion
    }
    
    func cancel() {
        isCancelled = true
    }
}

// MARK: - Animation Operation
enum AnimationOperation {
    case move(CGPoint)
    case resize(CGSize)
    case bounds(CGRect)
}

// MARK: - Animation Priority
enum AnimationPriority {
    case low
    case normal
    case high
}

// MARK: - Queue Status
struct AnimationQueueStatus {
    let activeAnimations: Int
    let queuedAnimations: Int
    let isProcessing: Bool
    
    var totalAnimations: Int {
        return activeAnimations + queuedAnimations
    }
}

// MARK: - Queue Extensions
extension AnimationQueue {
    
    /// Queue focus animation with high priority
    func queueFocusAnimation(for windowInfo: WindowInfo) {
        queueAnimation(
            id: "focus_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .move(windowInfo.bounds.origin), // Maintain position but trigger focus
            preset: AnimationPresets.lightSnappy,
            priority: .high
        )
    }
    
    /// Queue restoration animation for minimized window
    func queueRestoreAnimation(for windowInfo: WindowInfo, to bounds: CGRect) {
        queueAnimation(
            id: "restore_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .bounds(bounds),
            preset: AnimationPresets.restore,
            priority: .high
        )
    }
    
    /// Quick snap animation for grid positioning
    func queueSnapAnimation(for windowInfo: WindowInfo, to bounds: CGRect) {
        queueAnimation(
            id: "snap_\(windowInfo.appName)_\(Date().timeIntervalSince1970)",
            windowInfo: windowInfo,
            operation: .bounds(bounds),
            preset: AnimationPresets.snap,
            priority: .normal
        )
    }
}