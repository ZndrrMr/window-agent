import Foundation
import CoreGraphics
import Cocoa

// MARK: - Window Usage Pattern
struct WindowUsagePattern: Codable {
    let id: UUID
    let timestamp: Date
    let sessionDuration: TimeInterval
    let timeOfDay: TimeOfDay
    let dayOfWeek: Int // 1-7, Sunday = 1
    let activeApps: [String] // App names or bundle IDs
    let windowArrangement: [WindowSnapshot]
    let userContext: UserContext?
    let screenConfiguration: ScreenConfiguration
    
    init(sessionDuration: TimeInterval, 
         activeApps: [String], 
         windowArrangement: [WindowSnapshot],
         userContext: UserContext? = nil,
         screenConfiguration: ScreenConfiguration) {
        self.id = UUID()
        self.timestamp = Date()
        self.sessionDuration = sessionDuration
        self.timeOfDay = TimeOfDay.current
        self.dayOfWeek = Calendar.current.component(.weekday, from: Date())
        self.activeApps = activeApps
        self.windowArrangement = windowArrangement
        self.userContext = userContext
        self.screenConfiguration = screenConfiguration
    }
}

// MARK: - Window Snapshot
struct WindowSnapshot: Codable {
    let appName: String
    let bundleID: String?
    let bounds: CGRect
    let layerIndex: Int // Z-order, 0 = frontmost
    let visibility: WindowVisibility
    let role: WindowRole
    
    init(appName: String, 
         bundleID: String? = nil,
         bounds: CGRect, 
         layerIndex: Int,
         visibility: WindowVisibility = .fullyVisible,
         role: WindowRole = .auxiliary) {
        self.appName = appName
        self.bundleID = bundleID
        self.bounds = bounds
        self.layerIndex = layerIndex
        self.visibility = visibility
        self.role = role
    }
}

enum WindowVisibility: String, Codable {
    case fullyVisible = "fully_visible"
    case mostlyVisible = "mostly_visible" // 60-90% visible
    case partiallyVisible = "partially_visible" // 30-60% visible
    case minimallyVisible = "minimally_visible" // < 30% visible
    case hidden = "hidden"
}

enum WindowRole: String, Codable {
    case primary = "primary" // Main focus window
    case secondary = "secondary" // Supporting content
    case auxiliary = "auxiliary" // Tools, utilities
    case peripheral = "peripheral" // Background apps
    case reference = "reference" // Documentation, notes
}

// MARK: - Time of Day
enum TimeOfDay: String, Codable {
    case earlyMorning = "early_morning" // 5-8 AM
    case morning = "morning" // 8-12 PM
    case afternoon = "afternoon" // 12-5 PM
    case evening = "evening" // 5-9 PM
    case night = "night" // 9 PM-1 AM
    case lateNight = "late_night" // 1-5 AM
    
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8: return .earlyMorning
        case 8..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        case 21...23, 0: return .night
        default: return .lateNight
        }
    }
}

// MARK: - User Context
struct UserContext: Codable {
    let activity: String? // "coding", "researching", "communicating"
    let projectType: String? // "web development", "data analysis", etc.
    let sessionIntent: String? // User's stated goal
    let energyLevel: EnergyLevel?
    let focusMode: Bool
    
    init(activity: String? = nil,
         projectType: String? = nil,
         sessionIntent: String? = nil,
         energyLevel: EnergyLevel? = nil,
         focusMode: Bool = false) {
        self.activity = activity
        self.projectType = projectType
        self.sessionIntent = sessionIntent
        self.energyLevel = energyLevel
        self.focusMode = focusMode
    }
}

enum EnergyLevel: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

// MARK: - Screen Configuration
struct ScreenConfiguration: Codable {
    let screenCount: Int
    let primaryScreenSize: CGSize
    let totalWorkspaceArea: CGFloat
    let isUltrawide: Bool
    let isLaptop: Bool
    
    static var current: ScreenConfiguration {
        let screens = NSScreen.screens
        let primaryScreen = screens.first ?? NSScreen.main!
        let primarySize = primaryScreen.frame.size
        let totalArea = screens.reduce(0) { $0 + ($1.frame.width * $1.frame.height) }
        let aspectRatio = primarySize.width / primarySize.height
        
        return ScreenConfiguration(
            screenCount: screens.count,
            primaryScreenSize: primarySize,
            totalWorkspaceArea: totalArea,
            isUltrawide: aspectRatio > 2.0,
            isLaptop: screens.count == 1 && primarySize.width <= 1920
        )
    }
}

// MARK: - Pattern Matching Result
struct PatternMatch {
    let pattern: WindowUsagePattern
    let confidence: Double // 0.0 to 1.0
    let matchingFactors: [MatchingFactor]
    
    struct MatchingFactor {
        let factor: String
        let weight: Double
        let score: Double
    }
}

// MARK: - Intelligent Pattern Manager
class IntelligentPatternManager {
    static let shared = IntelligentPatternManager()
    
    private var patterns: [WindowUsagePattern] = []
    private let maxPatterns = 500
    private let patternFileURL: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.patternFileURL = documentsPath.appendingPathComponent("WindowAI_Patterns.json")
        loadPatterns()
    }
    
    // MARK: - Public API
    func recordPattern(_ pattern: WindowUsagePattern) {
        patterns.append(pattern)
        
        // Keep only recent patterns
        if patterns.count > maxPatterns {
            patterns.removeFirst(patterns.count - maxPatterns)
        }
        
        savePatterns()
    }
    
    func findSimilarPatterns(to currentContext: UserContext?, 
                           screenConfig: ScreenConfiguration,
                           activeApps: [String],
                           limit: Int = 5) -> [PatternMatch] {
        let currentTime = TimeOfDay.current
        let currentDay = Calendar.current.component(.weekday, from: Date())
        
        var matches: [PatternMatch] = []
        
        for pattern in patterns {
            var matchingFactors: [PatternMatch.MatchingFactor] = []
            var totalScore = 0.0
            
            // Time similarity (weight: 0.2)
            let timeSimilarity = pattern.timeOfDay == currentTime ? 1.0 : 0.5
            matchingFactors.append(PatternMatch.MatchingFactor(
                factor: "Time of day",
                weight: 0.2,
                score: timeSimilarity
            ))
            totalScore += timeSimilarity * 0.2
            
            // Day similarity (weight: 0.1)
            let daySimilarity = abs(pattern.dayOfWeek - currentDay) <= 1 ? 1.0 : 0.3
            matchingFactors.append(PatternMatch.MatchingFactor(
                factor: "Day of week",
                weight: 0.1,
                score: daySimilarity
            ))
            totalScore += daySimilarity * 0.1
            
            // App overlap (weight: 0.3)
            let appOverlap = calculateAppOverlap(pattern.activeApps, activeApps)
            matchingFactors.append(PatternMatch.MatchingFactor(
                factor: "App overlap",
                weight: 0.3,
                score: appOverlap
            ))
            totalScore += appOverlap * 0.3
            
            // Screen configuration (weight: 0.2)
            let screenSimilarity = calculateScreenSimilarity(pattern.screenConfiguration, screenConfig)
            matchingFactors.append(PatternMatch.MatchingFactor(
                factor: "Screen setup",
                weight: 0.2,
                score: screenSimilarity
            ))
            totalScore += screenSimilarity * 0.2
            
            // Context similarity (weight: 0.2)
            if let patternContext = pattern.userContext, let current = currentContext {
                let contextSimilarity = calculateContextSimilarity(patternContext, current)
                matchingFactors.append(PatternMatch.MatchingFactor(
                    factor: "User context",
                    weight: 0.2,
                    score: contextSimilarity
                ))
                totalScore += contextSimilarity * 0.2
            } else {
                totalScore += 0.1 // Small bonus if no context to match
            }
            
            matches.append(PatternMatch(
                pattern: pattern,
                confidence: totalScore,
                matchingFactors: matchingFactors
            ))
        }
        
        return matches
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0 }
    }
    
    func generateLLMHints(from matches: [PatternMatch]) -> String {
        guard !matches.isEmpty else { return "" }
        
        var hints = "\n\nINTELLIGENT PATTERN HINTS (based on user behavior):\n"
        
        for (index, match) in matches.prefix(3).enumerated() {
            let pattern = match.pattern
            hints += "\nPattern \(index + 1) (confidence: \(Int(match.confidence * 100))%):\n"
            
            // Describe the pattern
            hints += "- Time: \(pattern.timeOfDay.rawValue.replacingOccurrences(of: "_", with: " "))\n"
            hints += "- Active apps: \(pattern.activeApps.joined(separator: ", "))\n"
            
            // Describe the window arrangement
            let primaryWindows = pattern.windowArrangement.filter { $0.role == .primary }
            let secondaryWindows = pattern.windowArrangement.filter { $0.role == .secondary }
            
            if !primaryWindows.isEmpty {
                hints += "- Primary focus: \(primaryWindows.map { $0.appName }.joined(separator: ", "))\n"
            }
            if !secondaryWindows.isEmpty {
                hints += "- Supporting apps: \(secondaryWindows.map { $0.appName }.joined(separator: ", "))\n"
            }
            
            // Add context if available
            if let context = pattern.userContext {
                if let activity = context.activity {
                    hints += "- Typical activity: \(activity)\n"
                }
                if context.focusMode {
                    hints += "- User prefers focus mode\n"
                }
            }
            
            // Add specific layout hints
            if pattern.windowArrangement.count > 1 {
                let visibilityInfo = analyzeVisibilityPattern(pattern.windowArrangement)
                hints += "- Layout style: \(visibilityInfo)\n"
            }
        }
        
        hints += "\nREMEMBER: These are hints based on past behavior, not rigid rules. Adapt based on current user request."
        
        return hints
    }
    
    // MARK: - Helper Methods
    private func calculateAppOverlap(_ apps1: [String], _ apps2: [String]) -> Double {
        let set1 = Set(apps1.map { $0.lowercased() })
        let set2 = Set(apps2.map { $0.lowercased() })
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateScreenSimilarity(_ config1: ScreenConfiguration, _ config2: ScreenConfiguration) -> Double {
        var similarity = 0.0
        
        // Same number of screens
        if config1.screenCount == config2.screenCount {
            similarity += 0.3
        }
        
        // Similar screen type
        if config1.isUltrawide == config2.isUltrawide {
            similarity += 0.3
        }
        if config1.isLaptop == config2.isLaptop {
            similarity += 0.2
        }
        
        // Similar total workspace area (within 20%)
        let areaRatio = min(config1.totalWorkspaceArea, config2.totalWorkspaceArea) / 
                       max(config1.totalWorkspaceArea, config2.totalWorkspaceArea)
        if areaRatio > 0.8 {
            similarity += 0.2
        }
        
        return similarity
    }
    
    private func calculateContextSimilarity(_ context1: UserContext, _ context2: UserContext) -> Double {
        var similarity = 0.0
        var factors = 0
        
        if let activity1 = context1.activity, let activity2 = context2.activity {
            if activity1 == activity2 {
                similarity += 1.0
            }
            factors += 1
        }
        
        if context1.focusMode == context2.focusMode {
            similarity += 0.5
            factors += 1
        }
        
        if let energy1 = context1.energyLevel, let energy2 = context2.energyLevel {
            if energy1 == energy2 {
                similarity += 0.5
            }
            factors += 1
        }
        
        return factors > 0 ? similarity / Double(factors) : 0.5
    }
    
    private func analyzeVisibilityPattern(_ arrangement: [WindowSnapshot]) -> String {
        let fullyVisible = arrangement.filter { $0.visibility == .fullyVisible }.count
        let mostlyVisible = arrangement.filter { $0.visibility == .mostlyVisible }.count
        let _ = arrangement.filter { $0.visibility == .partiallyVisible }.count
        
        if fullyVisible == arrangement.count {
            return "All windows fully visible (tiled layout)"
        } else if fullyVisible == 1 && mostlyVisible >= 1 {
            return "Cascade with primary window prominent"
        } else if mostlyVisible >= 2 {
            return "Overlapping cascade with good visibility"
        } else {
            return "Compact cascade layout"
        }
    }
    
    // MARK: - Persistence
    private func loadPatterns() {
        do {
            let data = try Data(contentsOf: patternFileURL)
            patterns = try JSONDecoder().decode([WindowUsagePattern].self, from: data)
        } catch {
            // No patterns file yet, start fresh
            patterns = []
        }
    }
    
    private func savePatterns() {
        do {
            let data = try JSONEncoder().encode(patterns)
            try data.write(to: patternFileURL)
        } catch {
            print("Failed to save patterns: \(error)")
        }
    }
}