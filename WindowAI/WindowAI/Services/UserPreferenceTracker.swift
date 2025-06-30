import Foundation
import CoreGraphics

// MARK: - User Preference Tracker
/// Tracks user window positioning preferences using simple statistical counting
class UserPreferenceTracker {
    static let shared = UserPreferenceTracker()
    
    // MARK: - Data Structures
    
    struct PreferenceCorrection: Codable {
        let app: String
        let context: String
        let appCombination: [String]
        let timestamp: Date
        
        // Position correction data
        let oldPosition: CGPoint?
        let newPosition: CGPoint?
        let screenSize: CGSize?
        
        // Size correction data
        let oldSize: CGSize?
        let newSize: CGSize?
        
        // Focus correction data
        let chosenFocus: String?
        
        enum CorrectionType: String, Codable {
            case position, size, focus
        }
        let type: CorrectionType
    }
    
    // MARK: - Storage
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "WindowAI.UserPreferenceCorrections"
    private var corrections: [PreferenceCorrection] = []
    
    private init() {
        loadCorrections()
    }
    
    // MARK: - Public API
    
    func clearAllPreferences() {
        corrections.removeAll()
        saveCorrections()
    }
    
    func recordPositionCorrection(app: String, context: String, apps: [String], 
                                oldPosition: CGPoint, newPosition: CGPoint, screenSize: CGSize) {
        let correction = PreferenceCorrection(
            app: app,
            context: context,
            appCombination: apps.sorted(),
            timestamp: Date(),
            oldPosition: oldPosition,
            newPosition: newPosition,
            screenSize: screenSize,
            oldSize: nil,
            newSize: nil,
            chosenFocus: nil,
            type: .position
        )
        
        corrections.append(correction)
        saveCorrections()
        
        print("📊 PREFERENCE: \(app) moved from \(oldPosition) to \(newPosition) in \(context) context")
    }
    
    func recordSizeCorrection(app: String, context: String, apps: [String],
                            oldSize: CGSize, newSize: CGSize, screenSize: CGSize) {
        let correction = PreferenceCorrection(
            app: app,
            context: context,
            appCombination: apps.sorted(),
            timestamp: Date(),
            oldPosition: nil,
            newPosition: nil,
            screenSize: screenSize,
            oldSize: oldSize,
            newSize: newSize,
            chosenFocus: nil,
            type: .size
        )
        
        corrections.append(correction)
        saveCorrections()
        
        let oldPercent = Int(oldSize.width / screenSize.width * 100)
        let newPercent = Int(newSize.width / screenSize.width * 100)
        print("📊 PREFERENCE: \(app) resized from \(oldPercent)% to \(newPercent)% width in \(context) context")
    }
    
    func recordFocusCorrection(context: String, apps: [String], chosenFocus: String) {
        let correction = PreferenceCorrection(
            app: chosenFocus,
            context: context,
            appCombination: apps.sorted(),
            timestamp: Date(),
            oldPosition: nil,
            newPosition: nil,
            screenSize: nil,
            oldSize: nil,
            newSize: nil,
            chosenFocus: chosenFocus,
            type: .focus
        )
        
        corrections.append(correction)
        saveCorrections()
        
        print("📊 PREFERENCE: \(chosenFocus) chosen as focus in \(context) context")
    }
    
    // MARK: - Preference Analysis
    
    func getPositionPreference(app: String, context: String) -> PositionPreference {
        let relevantCorrections = corrections.filter { 
            $0.app == app && 
            $0.context == context && 
            $0.type == .position &&
            $0.newPosition != nil &&
            $0.screenSize != nil
        }
        
        guard !relevantCorrections.isEmpty else {
            return PositionPreference(preferredSide: .center, confidence: 0.0)
        }
        
        // Classify positions into left/center/right zones
        var leftCount = 0
        var centerCount = 0
        var rightCount = 0
        
        for correction in relevantCorrections {
            let position = correction.newPosition!
            let screenWidth = correction.screenSize!.width
            let xPercent = position.x / screenWidth
            
            if xPercent < 0.33 {
                leftCount += 1
            } else if xPercent > 0.67 {
                rightCount += 1
            } else {
                centerCount += 1
            }
        }
        
        let total = relevantCorrections.count
        let preferredSide: PositionPreference.Side
        let confidence: Double
        
        if rightCount > leftCount && rightCount > centerCount {
            preferredSide = .right
            confidence = Double(rightCount) / Double(total)
        } else if leftCount > centerCount {
            preferredSide = .left
            confidence = Double(leftCount) / Double(total)
        } else {
            preferredSide = .center
            confidence = Double(centerCount) / Double(total)
        }
        
        return PositionPreference(preferredSide: preferredSide, confidence: confidence)
    }
    
    func getSizePreference(app: String, context: String) -> SizePreference {
        let relevantCorrections = corrections.filter {
            $0.app == app &&
            $0.context == context &&
            $0.type == .size &&
            $0.newSize != nil &&
            $0.screenSize != nil
        }
        
        guard !relevantCorrections.isEmpty else {
            return SizePreference(preferredWidthPercent: 50.0, confidence: 0.0)
        }
        
        // Calculate median width percentage
        let widthPercentages = relevantCorrections.map { correction in
            let newSize = correction.newSize!
            let screenSize = correction.screenSize!
            return newSize.width / screenSize.width * 100.0
        }.sorted()
        
        let medianIndex = widthPercentages.count / 2
        let medianWidth: Double
        
        if widthPercentages.count % 2 == 0 {
            medianWidth = (widthPercentages[medianIndex - 1] + widthPercentages[medianIndex]) / 2.0
        } else {
            medianWidth = widthPercentages[medianIndex]
        }
        
        let confidence = min(1.0, Double(relevantCorrections.count) / 5.0) // Full confidence after 5+ corrections
        
        return SizePreference(preferredWidthPercent: medianWidth, confidence: confidence)
    }
    
    func generatePreferenceSummary(context: String) -> String {
        guard !corrections.isEmpty else {
            return ""
        }
        
        var summary = "USER PREFERENCES (based on corrections):\n"
        
        // Get unique apps for this context
        let contextCorrections = corrections.filter { $0.context == context }
        let uniqueApps = Set(contextCorrections.map { $0.app })
        
        for app in uniqueApps.sorted() {
            var appSummary = "- \(app): "
            
            // Position preference
            let positionPref = getPositionPreference(app: app, context: context)
            if positionPref.confidence > 0.3 {
                let sideString = positionPref.preferredSide == .left ? "left" : 
                               positionPref.preferredSide == .right ? "right" : "center"
                let confidencePercent = Int(positionPref.confidence * 100)
                appSummary += "prefers \(sideString) side (\(confidencePercent)%)"
            }
            
            // Size preference
            let sizePref = getSizePreference(app: app, context: context)
            if sizePref.confidence > 0.3 {
                if appSummary.contains("prefers") {
                    appSummary += ", "
                }
                appSummary += "averages \(Int(sizePref.preferredWidthPercent))% width"
            }
            
            // Focus preference
            let focusCorrections = corrections.filter { 
                $0.context == context && 
                $0.type == .focus && 
                $0.chosenFocus == app
            }
            let totalFocusCorrections = corrections.filter {
                $0.context == context && 
                $0.type == .focus
            }.count
            
            if totalFocusCorrections > 0 {
                let focusPercent = Int(Double(focusCorrections.count) / Double(totalFocusCorrections) * 100)
                if focusPercent > 30 {
                    if appSummary.contains("prefers") || appSummary.contains("averages") {
                        appSummary += ", "
                    }
                    appSummary += "chosen as focus \(focusCorrections.count)/\(totalFocusCorrections) times"
                }
            }
            
            if appSummary != "- \(app): " {
                summary += appSummary + "\n"
            }
        }
        
        return summary.isEmpty ? "" : summary
    }
    
    // MARK: - Persistence
    
    private func saveCorrections() {
        do {
            let data = try JSONEncoder().encode(corrections)
            userDefaults.set(data, forKey: preferencesKey)
        } catch {
            print("Failed to save preference corrections: \(error)")
        }
    }
    
    private func loadCorrections() {
        guard let data = userDefaults.data(forKey: preferencesKey) else { return }
        
        do {
            corrections = try JSONDecoder().decode([PreferenceCorrection].self, from: data)
        } catch {
            print("Failed to load preference corrections: \(error)")
            corrections = []
        }
    }
}

// MARK: - Preference Data Structures

struct PositionPreference {
    enum Side {
        case left, center, right
    }
    let preferredSide: Side
    let confidence: Double
}

struct SizePreference {
    let preferredWidthPercent: Double
    let confidence: Double
}