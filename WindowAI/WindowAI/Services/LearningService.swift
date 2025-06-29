import Foundation

// MARK: - User Feedback and Learning
struct UserFeedback: Codable {
    let id: UUID
    let commandText: String
    let interpretedCommands: [WindowCommand]
    let userCorrection: [WindowCommand]?
    let correctionType: CorrectionType
    let timestamp: Date
    let context: String?
    
    init(commandText: String, 
         interpretedCommands: [WindowCommand],
         userCorrection: [WindowCommand]? = nil,
         correctionType: CorrectionType = .none,
         context: String? = nil) {
        self.id = UUID()
        self.commandText = commandText
        self.interpretedCommands = interpretedCommands
        self.userCorrection = userCorrection
        self.correctionType = correctionType
        self.timestamp = Date()
        self.context = context
    }
}

enum CorrectionType: String, Codable, CaseIterable {
    case none = "none"
    case wrongApp = "wrong_app"
    case wrongPosition = "wrong_position"
    case wrongSize = "wrong_size"
    case missingApp = "missing_app"
    case extraApp = "extra_app"
    case wrongWorkspace = "wrong_workspace"
    
    var displayName: String {
        switch self {
        case .none: return "No Correction"
        case .wrongApp: return "Wrong App"
        case .wrongPosition: return "Wrong Position"
        case .wrongSize: return "Wrong Size"
        case .missingApp: return "Missing App"
        case .extraApp: return "Extra App"
        case .wrongWorkspace: return "Wrong Workspace"
        }
    }
}

// MARK: - Learning Patterns
struct CommandPattern: Codable {
    let pattern: String // Regex or keyword pattern
    let commands: [WindowCommand]
    let confidence: Double // 0.0 to 1.0
    let usageCount: Int
    let successRate: Double
    let lastUsed: Date
}

// MARK: - Window Adjustment Tracking
struct WindowAdjustment: Codable {
    let id: UUID
    let appName: String
    let originalBounds: CGRect
    let adjustedBounds: CGRect
    let adjustmentType: AdjustmentType
    let timeElapsed: TimeInterval // Time between arrangement and adjustment
    let context: String? // What command/arrangement triggered this
    let timestamp: Date
    
    init(appName: String, originalBounds: CGRect, adjustedBounds: CGRect, timeElapsed: TimeInterval, context: String? = nil) {
        self.id = UUID()
        self.appName = appName
        self.originalBounds = originalBounds
        self.adjustedBounds = adjustedBounds
        self.timeElapsed = timeElapsed
        self.context = context
        self.timestamp = Date()
        
        // Determine adjustment type
        let positionChanged = originalBounds.origin != adjustedBounds.origin
        let sizeChanged = originalBounds.size != adjustedBounds.size
        
        if positionChanged && sizeChanged {
            self.adjustmentType = .both
        } else if positionChanged {
            self.adjustmentType = .position
        } else if sizeChanged {
            self.adjustmentType = .size
        } else {
            self.adjustmentType = .none
        }
    }
}

enum AdjustmentType: String, Codable {
    case none = "none"
    case position = "position"
    case size = "size"
    case both = "both"
}

// Window arrangement tracking
struct ArrangementRecord {
    let id: UUID
    let windows: [WindowInfo]
    let arrangedBounds: [String: CGRect] // app name -> bounds
    let timestamp: Date
    let context: String
    
    init(windows: [WindowInfo], arrangedBounds: [String: CGRect], context: String) {
        self.id = UUID()
        self.windows = windows
        self.arrangedBounds = arrangedBounds
        self.timestamp = Date()
        self.context = context
    }
}

// MARK: - Learning Service
class LearningService: ObservableObject {
    @Published private var userFeedbacks: [UserFeedback] = []
    @Published private var commandPatterns: [CommandPattern] = []
    @Published private var appPreferences: [String: Double] = [:] // App name -> preference score
    @Published private var windowAdjustments: [WindowAdjustment] = []
    @Published private var activeArrangements: [ArrangementRecord] = []
    
    private let workspaceManager = WorkspaceManager.shared
    private let maxFeedbackHistory = 1000
    private let maxAdjustmentHistory = 500
    private let adjustmentDetectionThreshold: TimeInterval = 30.0 // Consider adjustments within 30 seconds
    
    static let shared = LearningService()
    
    private init() {
        loadFeedbackHistory()
        loadCommandPatterns()
        loadAppPreferences()
        loadWindowAdjustments()
    }
    
    // MARK: - Public API
    func recordFeedback(_ feedback: UserFeedback) {
        userFeedbacks.append(feedback)
        
        // Limit history size
        if userFeedbacks.count > maxFeedbackHistory {
            userFeedbacks.removeFirst(userFeedbacks.count - maxFeedbackHistory)
        }
        
        processNewFeedback(feedback)
        saveFeedbackHistory()
    }
    
    func recordCommandSuccess(commandText: String, commands: [WindowCommand]) {
        let feedback = UserFeedback(
            commandText: commandText,
            interpretedCommands: commands,
            correctionType: .none
        )
        recordFeedback(feedback)
        updateCommandPatterns(for: commandText, commands: commands, success: true)
    }
    
    func recordCommandFailure(commandText: String, commands: [WindowCommand], correction: [WindowCommand]) {
        let correctionType = determineCorrectionType(original: commands, corrected: correction)
        let feedback = UserFeedback(
            commandText: commandText,
            interpretedCommands: commands,
            userCorrection: correction,
            correctionType: correctionType
        )
        recordFeedback(feedback)
        updateCommandPatterns(for: commandText, commands: commands, success: false)
    }
    
    func getAppPreference(for appName: String) -> Double {
        return appPreferences[appName.lowercased()] ?? 0.5
    }
    
    func adjustAppPreference(for appName: String, delta: Double) {
        let currentPreference = getAppPreference(for: appName)
        let newPreference = max(0.0, min(1.0, currentPreference + delta))
        appPreferences[appName.lowercased()] = newPreference
        saveAppPreferences()
    }
    
    func getSuggestedCommands(for input: String) -> [WindowCommand] {
        // Find matching patterns
        let matchingPatterns = commandPatterns.filter { pattern in
            input.lowercased().contains(pattern.pattern.lowercased())
        }.sorted { $0.confidence > $1.confidence }
        
        return matchingPatterns.first?.commands ?? []
    }
    
    func getPreferredApp(for category: AppCategory) -> String? {
        let categoryApps = appPreferences.filter { key, value in
            // This is simplified - in reality, you'd want to map apps to categories
            return value > 0.7
        }
        
        return categoryApps.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Window Adjustment Tracking
    func recordWindowArrangement(windows: [WindowInfo], arrangedBounds: [String: CGRect], context: String) {
        let arrangement = ArrangementRecord(
            windows: windows,
            arrangedBounds: arrangedBounds,
            context: context
        )
        
        activeArrangements.append(arrangement)
        
        // Start monitoring for adjustments
        startMonitoringAdjustments(for: arrangement)
        
        // Clean up old arrangements
        let cutoffTime = Date().addingTimeInterval(-adjustmentDetectionThreshold * 2)
        activeArrangements.removeAll { $0.timestamp < cutoffTime }
    }
    
    func checkForWindowAdjustment(window: WindowInfo, currentBounds: CGRect) {
        // Find recent arrangements that included this window
        let recentCutoff = Date().addingTimeInterval(-adjustmentDetectionThreshold)
        
        for arrangement in activeArrangements where arrangement.timestamp > recentCutoff {
            if let originalBounds = arrangement.arrangedBounds[window.appName] {
                // Check if bounds have changed significantly
                if !boundsAreEffectivelyEqual(originalBounds, currentBounds) {
                    let timeElapsed = Date().timeIntervalSince(arrangement.timestamp)
                    
                    let adjustment = WindowAdjustment(
                        appName: window.appName,
                        originalBounds: originalBounds,
                        adjustedBounds: currentBounds,
                        timeElapsed: timeElapsed,
                        context: arrangement.context
                    )
                    
                    recordWindowAdjustment(adjustment)
                    
                    // Learn from this adjustment
                    learnFromAdjustment(adjustment)
                    
                    // Remove this arrangement from active tracking
                    activeArrangements.removeAll { $0.id == arrangement.id }
                    break
                }
            }
        }
    }
    
    private func recordWindowAdjustment(_ adjustment: WindowAdjustment) {
        windowAdjustments.append(adjustment)
        
        // Limit history size
        if windowAdjustments.count > maxAdjustmentHistory {
            windowAdjustments.removeFirst(windowAdjustments.count - maxAdjustmentHistory)
        }
        
        saveWindowAdjustments()
    }
    
    private func boundsAreEffectivelyEqual(_ bounds1: CGRect, _ bounds2: CGRect) -> Bool {
        let tolerance: CGFloat = 5.0 // 5 pixel tolerance
        return abs(bounds1.origin.x - bounds2.origin.x) < tolerance &&
               abs(bounds1.origin.y - bounds2.origin.y) < tolerance &&
               abs(bounds1.size.width - bounds2.size.width) < tolerance &&
               abs(bounds1.size.height - bounds2.size.height) < tolerance
    }
    
    private func startMonitoringAdjustments(for arrangement: ArrangementRecord) {
        // Schedule periodic checks for window adjustments
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkArrangementForAdjustments(arrangement)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.checkArrangementForAdjustments(arrangement)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.checkArrangementForAdjustments(arrangement)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { [weak self] in
            self?.checkArrangementForAdjustments(arrangement)
        }
    }
    
    private func checkArrangementForAdjustments(_ arrangement: ArrangementRecord) {
        // This would be called by the monitoring system
        // In practice, you'd need to get current window bounds from WindowManager
    }
    
    // MARK: - Learning from Adjustments
    private func learnFromAdjustment(_ adjustment: WindowAdjustment) {
        // Analyze the adjustment pattern
        let deltaPosition = CGPoint(
            x: adjustment.adjustedBounds.origin.x - adjustment.originalBounds.origin.x,
            y: adjustment.adjustedBounds.origin.y - adjustment.originalBounds.origin.y
        )
        
        let deltaSize = CGSize(
            width: adjustment.adjustedBounds.size.width - adjustment.originalBounds.size.width,
            height: adjustment.adjustedBounds.size.height - adjustment.originalBounds.size.height
        )
        
        // Store preference patterns
        let preferenceKey = "\(adjustment.appName)_position_preference"
        if let context = adjustment.context {
            UserLayoutPreferences.shared.setPreference(
                for: adjustment.appName,
                notes: "Prefers position offset (\(Int(deltaPosition.x)), \(Int(deltaPosition.y))) in \(context)"
            )
        }
        
        // Detect repeated patterns
        let similarAdjustments = windowAdjustments.filter { adj in
            adj.appName == adjustment.appName &&
            adj.adjustmentType == adjustment.adjustmentType &&
            abs(adj.timeElapsed - adjustment.timeElapsed) < 5.0
        }
        
        if similarAdjustments.count >= 3 {
            // User consistently makes this adjustment
            let avgDeltaX = similarAdjustments.reduce(0.0) { sum, adj in
                sum + (adj.adjustedBounds.origin.x - adj.originalBounds.origin.x)
            } / Double(similarAdjustments.count)
            
            let avgDeltaY = similarAdjustments.reduce(0.0) { sum, adj in
                sum + (adj.adjustedBounds.origin.y - adj.originalBounds.origin.y)
            } / Double(similarAdjustments.count)
            
            // Create a learned preference
            UserLayoutPreferences.shared.setPreference(
                for: adjustment.appName,
                notes: "Should be offset by (\(Int(avgDeltaX)), \(Int(avgDeltaY))) from default position (learned from \(similarAdjustments.count) adjustments)"
            )
        }
    }
    
    // MARK: - Adjustment Analytics
    func getMostAdjustedApps() -> [(String, Int)] {
        var adjustmentCounts: [String: Int] = [:]
        
        for adjustment in windowAdjustments {
            adjustmentCounts[adjustment.appName, default: 0] += 1
        }
        
        return adjustmentCounts.sorted { $0.value > $1.value }
    }
    
    func getAverageAdjustmentTime() -> TimeInterval {
        guard !windowAdjustments.isEmpty else { return 0 }
        
        let totalTime = windowAdjustments.reduce(0.0) { $0 + $1.timeElapsed }
        return totalTime / Double(windowAdjustments.count)
    }
    
    func getPreferredPositionOffset(for appName: String) -> CGPoint? {
        let appAdjustments = windowAdjustments.filter { $0.appName == appName }
        guard appAdjustments.count >= 3 else { return nil }
        
        let avgX = appAdjustments.reduce(0.0) { sum, adj in
            sum + (adj.adjustedBounds.origin.x - adj.originalBounds.origin.x)
        } / Double(appAdjustments.count)
        
        let avgY = appAdjustments.reduce(0.0) { sum, adj in
            sum + (adj.adjustedBounds.origin.y - adj.originalBounds.origin.y)
        } / Double(appAdjustments.count)
        
        // Only return if adjustment is significant
        if abs(avgX) > 10 || abs(avgY) > 10 {
            return CGPoint(x: avgX, y: avgY)
        }
        
        return nil
    }
    
    // MARK: - Learning Logic
    private func processNewFeedback(_ feedback: UserFeedback) {
        switch feedback.correctionType {
        case .none:
            // Successful command - boost app preferences
            for command in feedback.interpretedCommands {
                adjustAppPreference(for: command.target, delta: 0.1)
                workspaceManager.updateAppUsage(
                    bundleID: command.target, // Would need bundle ID lookup
                    appName: command.target,
                    category: .other // Would need category detection
                )
            }
            
        case .wrongApp:
            // Wrong app chosen - reduce preference for interpreted app, boost corrected app
            if let correction = feedback.userCorrection {
                for (original, corrected) in zip(feedback.interpretedCommands, correction) {
                    adjustAppPreference(for: original.target, delta: -0.2)
                    adjustAppPreference(for: corrected.target, delta: 0.3)
                }
            }
            
        case .missingApp:
            // User wanted additional app - learn this association
            if let correction = feedback.userCorrection {
                let missingApps = correction.filter { corrected in
                    !feedback.interpretedCommands.contains { original in
                        original.target == corrected.target
                    }
                }
                
                for app in missingApps {
                    adjustAppPreference(for: app.target, delta: 0.2)
                }
            }
            
        case .extraApp:
            // User didn't want this app - reduce preference
            if let correction = feedback.userCorrection {
                let extraApps = feedback.interpretedCommands.filter { original in
                    !correction.contains { corrected in
                        corrected.target == original.target
                    }
                }
                
                for app in extraApps {
                    adjustAppPreference(for: app.target, delta: -0.3)
                }
            }
            
        default:
            break
        }
    }
    
    private func updateCommandPatterns(for commandText: String, commands: [WindowCommand], success: Bool) {
        // Extract keywords from command text
        let keywords = extractKeywords(from: commandText)
        
        for keyword in keywords {
            if let existingIndex = commandPatterns.firstIndex(where: { $0.pattern == keyword }) {
                let pattern = commandPatterns[existingIndex]
                let newUsageCount = pattern.usageCount + 1
                let successIncrement = success ? 1.0 : 0.0
                let newSuccessRate = (pattern.successRate * Double(pattern.usageCount) + successIncrement) / Double(newUsageCount)
                
                commandPatterns[existingIndex] = CommandPattern(
                    pattern: pattern.pattern,
                    commands: success ? commands : pattern.commands,
                    confidence: newSuccessRate,
                    usageCount: newUsageCount,
                    successRate: newSuccessRate,
                    lastUsed: Date()
                )
            } else if success {
                // Create new pattern only for successful commands
                commandPatterns.append(CommandPattern(
                    pattern: keyword,
                    commands: commands,
                    confidence: 1.0,
                    usageCount: 1,
                    successRate: 1.0,
                    lastUsed: Date()
                ))
            }
        }
        
        saveCommandPatterns()
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // Filter out common words
        let stopWords = Set(["the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use"])
        
        return words.filter { !stopWords.contains($0) }
    }
    
    private func determineCorrectionType(original: [WindowCommand], corrected: [WindowCommand]) -> CorrectionType {
        if original.count != corrected.count {
            return original.count > corrected.count ? .extraApp : .missingApp
        }
        
        for (orig, corr) in zip(original, corrected) {
            if orig.target != corr.target {
                return .wrongApp
            }
            if orig.position != corr.position {
                return .wrongPosition
            }
            if orig.size != corr.size {
                return .wrongSize
            }
        }
        
        return .none
    }
    
    // MARK: - Persistence
    private func loadFeedbackHistory() {
        // TODO: Load from file
    }
    
    private func saveFeedbackHistory() {
        // TODO: Save to file
    }
    
    private func loadCommandPatterns() {
        // TODO: Load from file
    }
    
    private func saveCommandPatterns() {
        // TODO: Save to file
    }
    
    private func loadAppPreferences() {
        // TODO: Load from file
    }
    
    private func saveAppPreferences() {
        // TODO: Save to file
    }
    
    private func loadWindowAdjustments() {
        // TODO: Load from file
    }
    
    private func saveWindowAdjustments() {
        // TODO: Save to file
    }
    
    // MARK: - Analytics
    func getOverallAccuracy() -> Double {
        guard !userFeedbacks.isEmpty else { return 0.0 }
        
        let successfulCommands = userFeedbacks.filter { $0.correctionType == .none }.count
        return Double(successfulCommands) / Double(userFeedbacks.count)
    }
    
    func getMostCommonErrors() -> [CorrectionType: Int] {
        var errorCounts: [CorrectionType: Int] = [:]
        
        for feedback in userFeedbacks {
            if feedback.correctionType != .none {
                errorCounts[feedback.correctionType, default: 0] += 1
            }
        }
        
        return errorCounts
    }
    
    func getMostUsedApps() -> [(String, Int)] {
        var appCounts: [String: Int] = [:]
        
        for feedback in userFeedbacks {
            for command in feedback.interpretedCommands {
                appCounts[command.target, default: 0] += 1
            }
        }
        
        return appCounts.sorted { $0.value > $1.value }
    }
}