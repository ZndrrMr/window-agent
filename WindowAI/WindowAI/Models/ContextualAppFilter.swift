import Foundation

// MARK: - Context-Based App Filtering and Prioritization
class ContextualAppFilter {
    static let shared = ContextualAppFilter()
    
    private init() {}
    
    // MARK: - Smart App Selection
    func selectRelevantApps(
        from allApps: [String],
        for context: String,
        maxApps: Int = 4
    ) -> [String] {
        
        let normalizedContext = context.lowercased()
        let classifier = AppArchetypeClassifier.shared
        let instructionParser = UserInstructionParser.shared
        
        // Filter out apps that user never wants to use
        let allowedApps = allApps.filter { app in
            !instructionParser.shouldNeverUse(app, context: normalizedContext)
        }
        
        // Classify all apps
        let appData = allowedApps.map { app in
            (
                name: app,
                archetype: classifier.classifyApp(app),
                relevanceScore: calculateRelevanceScore(app: app, context: normalizedContext),
                priority: getContextPriority(app: app, context: normalizedContext)
            )
        }
        
        // Sort by relevance and priority
        let sortedApps = appData.sorted { first, second in
            if first.relevanceScore != second.relevanceScore {
                return first.relevanceScore > second.relevanceScore
            }
            return first.priority > second.priority
        }
        
        // Select best apps with archetype diversity
        return selectDiverseApps(from: sortedApps, maxCount: maxApps)
    }
    
    private func calculateRelevanceScore(app: String, context: String) -> Double {
        let appLower = app.lowercased()
        
        switch context {
        case let ctx where ctx.contains("cod"):
            // Coding context - prefer modern workflow over legacy tools
            if appLower.contains("cursor") {
                return 10.0 // Modern primary editor
            }
            if appLower.contains("terminal") || appLower.contains("iterm") {
                return 9.0 // Essential for coding
            }
            if appLower.contains("arc") || appLower.contains("safari") || appLower.contains("chrome") {
                return 8.0 // Essential for documentation/research
            }
            if appLower.contains("xcode") {
                return 7.0 // Legacy IDE, lower priority than modern tools
            }
            if appLower.contains("vscode") || appLower.contains("code") {
                return 8.5 // Other modern editors
            }
            if appLower.contains("finder") || appLower.contains("spotify") {
                return 2.0 // Peripheral
            }
            return 1.0 // Irrelevant
            
        case let ctx where ctx.contains("research") || ctx.contains("browse"):
            if appLower.contains("arc") || appLower.contains("safari") || appLower.contains("chrome") {
                return 10.0 // Primary browsers
            }
            if appLower.contains("notes") || appLower.contains("notion") || appLower.contains("obsidian") {
                return 8.0 // Note taking
            }
            if appLower.contains("preview") || appLower.contains("pdf") {
                return 6.0 // Document viewing
            }
            return 3.0
            
        case let ctx where ctx.contains("design"):
            if appLower.contains("figma") || appLower.contains("sketch") || appLower.contains("photoshop") {
                return 10.0 // Design tools
            }
            if appLower.contains("arc") || appLower.contains("safari") {
                return 6.0 // Reference
            }
            return 2.0
            
        default:
            return 5.0 // Neutral relevance
        }
    }
    
    private func getContextPriority(app: String, context: String) -> Int {
        let appLower = app.lowercased()
        let archetype = AppArchetypeClassifier.shared.classifyApp(app)
        
        switch context {
        case let ctx where ctx.contains("cod"):
            // Coding: Prefer Cursor over Xcode, Terminal essential
            if appLower.contains("cursor") { return 100 }
            if appLower.contains("terminal") { return 90 }
            if appLower.contains("arc") { return 80 }
            if appLower.contains("xcode") { return 70 } // Lower than Cursor
            if archetype == .codeWorkspace { return 60 }
            if archetype == .textStream { return 50 }
            if archetype == .contentCanvas { return 40 }
            return 10
            
        default:
            // Even for general contexts, prefer modern tools
            if appLower.contains("cursor") { return 65 } // Higher than Xcode even in general
            if appLower.contains("terminal") { return 60 }
            if appLower.contains("arc") { return 55 }
            if appLower.contains("xcode") { return 50 } // Lower priority in general
            if archetype == .codeWorkspace { return 45 }
            if archetype == .textStream { return 40 }
            if archetype == .contentCanvas { return 35 }
            return 30
        }
    }
    
    private func selectDiverseApps(
        from sortedApps: [(name: String, archetype: AppArchetype, relevanceScore: Double, priority: Int)],
        maxCount: Int
    ) -> [String] {
        
        var selectedApps: [String] = []
        var usedArchetypes: Set<AppArchetype> = []
        
        // SMART EXCLUSION LOGIC: For coding context, prefer modern workflow over legacy tools
        let hasCursor = sortedApps.contains { $0.name.lowercased().contains("cursor") }
        let hasXcode = sortedApps.contains { $0.name.lowercased().contains("xcode") }
        
        // First pass: Select highest priority apps with smart exclusions
        for appData in sortedApps {
            if selectedApps.count >= maxCount { break }
            
            // SMART EXCLUSION: Skip Xcode if Cursor is available for clean 3-app coding layout
            if hasCursor && hasXcode && appData.name.lowercased().contains("xcode") {
                continue // Skip Xcode to maintain optimal 3-window layout (Cursor + Terminal + Arc)
            }
            
            // Always include high-relevance apps (after exclusion check)
            if appData.relevanceScore >= 8.0 {
                selectedApps.append(appData.name)
                usedArchetypes.insert(appData.archetype)
                continue
            }
            
            // For lower relevance, prefer archetype diversity
            if !usedArchetypes.contains(appData.archetype) || selectedApps.count < 2 {
                selectedApps.append(appData.name)
                usedArchetypes.insert(appData.archetype)
            }
        }
        
        // Second pass: Fill remaining slots with best remaining apps (maintaining exclusions)
        for appData in sortedApps {
            if selectedApps.count >= maxCount { break }
            if !selectedApps.contains(appData.name) {
                // Apply same exclusion logic in second pass
                if hasCursor && hasXcode && appData.name.lowercased().contains("xcode") {
                    continue
                }
                selectedApps.append(appData.name)
            }
        }
        
        return selectedApps
    }
    
    // MARK: - Context-Aware App Ordering
    func orderAppsForCascade(
        apps: [String],
        context: String
    ) -> [(app: String, preferredRole: CascadeRole)] {
        
        let classifier = AppArchetypeClassifier.shared
        var result: [(app: String, preferredRole: CascadeRole)] = []
        
        let normalizedContext = context.lowercased()
        
        // Find the best primary app for this context
        let primaryApp = findBestPrimaryApp(from: apps, context: normalizedContext)
        
        for app in apps {
            let archetype = classifier.classifyApp(app)
            let role: CascadeRole
            
            if app == primaryApp {
                role = .primary
            } else {
                role = classifier.getOptimalCascadeRole(for: archetype, windowCount: apps.count)
            }
            
            result.append((app: app, preferredRole: role))
        }
        
        // Sort by role priority
        result.sort { first, second in
            first.preferredRole.layerPriority > second.preferredRole.layerPriority
        }
        
        return result
    }
    
    private func findBestPrimaryApp(from apps: [String], context: String) -> String? {
        let priorities = apps.map { app -> (app: String, score: Double) in
            let appLower = app.lowercased()
            let score: Double
            
            if context.contains("cod") {
                if appLower.contains("cursor") { score = 100.0 }
                else if appLower.contains("xcode") { score = 80.0 }
                else if appLower.contains("vscode") { score = 90.0 }
                else { score = 0.0 }
            } else if context.contains("design") {
                if appLower.contains("figma") { score = 100.0 }
                else if appLower.contains("sketch") { score = 90.0 }
                else if appLower.contains("photoshop") { score = 85.0 }
                else { score = 0.0 }
            } else {
                // Default: prefer Code Workspace tools
                let archetype = AppArchetypeClassifier.shared.classifyApp(app)
                score = archetype == .codeWorkspace ? 50.0 : 0.0
            }
            
            return (app: app, score: score)
        }
        
        return priorities.max(by: { $0.score < $1.score })?.app
    }
}

// MARK: - Context Patterns
struct ContextPattern {
    let keywords: [String]
    let preferredApps: [String]
    let maxApps: Int
    let minimizeOthers: Bool
    
    static let codingPattern = ContextPattern(
        keywords: ["cod", "develop", "program", "build"],
        preferredApps: ["Cursor", "Terminal", "Arc"],
        maxApps: 3,
        minimizeOthers: true
    )
    
    static let researchPattern = ContextPattern(
        keywords: ["research", "browse", "read", "study"],
        preferredApps: ["Arc", "Safari", "Notes", "Preview"],
        maxApps: 4,
        minimizeOthers: false
    )
    
    static let designPattern = ContextPattern(
        keywords: ["design", "create", "art", "draw"],
        preferredApps: ["Figma", "Sketch", "Photoshop", "Arc"],
        maxApps: 3,
        minimizeOthers: true
    )
}