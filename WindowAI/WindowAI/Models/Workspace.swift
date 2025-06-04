import Foundation
import CoreGraphics

// MARK: - Workspace Definition
struct Workspace: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: WorkspaceCategory
    let requiredApps: [AppContext]
    let optionalApps: [AppContext]
    let excludedApps: [String] // Bundle IDs or app names to exclude
    let layout: LayoutConfiguration
    let isUserDefined: Bool
    let createdAt: Date
    let lastUsed: Date?
    
    init(name: String, 
         category: WorkspaceCategory, 
         requiredApps: [AppContext] = [],
         optionalApps: [AppContext] = [],
         excludedApps: [String] = [],
         layout: LayoutConfiguration = LayoutConfiguration(),
         isUserDefined: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.requiredApps = requiredApps
        self.optionalApps = optionalApps
        self.excludedApps = excludedApps
        self.layout = layout
        self.isUserDefined = isUserDefined
        self.createdAt = Date()
        self.lastUsed = nil
    }
}

enum WorkspaceCategory: String, Codable, CaseIterable {
    case coding = "coding"
    case writing = "writing"
    case research = "research"
    case communication = "communication"
    case design = "design"
    case media = "media"
    case gaming = "gaming"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .coding: return "Coding"
        case .writing: return "Writing"
        case .research: return "Research"
        case .communication: return "Communication"
        case .design: return "Design"
        case .media: return "Media"
        case .gaming: return "Gaming"
        case .custom: return "Custom"
        }
    }
}

// MARK: - App Context for Learning
struct AppContext: Codable, Identifiable {
    let id: UUID
    let bundleID: String
    let appName: String
    let category: AppCategory
    let preferenceScore: Double // 0.0 to 1.0, higher = more preferred
    let usageCount: Int
    let lastUsed: Date?
    let userNotes: String?
    
    init(bundleID: String, 
         appName: String, 
         category: AppCategory,
         preferenceScore: Double = 0.5,
         usageCount: Int = 0,
         lastUsed: Date? = nil,
         userNotes: String? = nil) {
        self.id = UUID()
        self.bundleID = bundleID
        self.appName = appName
        self.category = category
        self.preferenceScore = preferenceScore
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.userNotes = userNotes
    }
}

// MARK: - Layout Configuration
struct LayoutConfiguration: Codable {
    let screenDivision: ScreenDivision
    let gapSize: CGFloat
    let respectDock: Bool
    let respectMenuBar: Bool
    let animationDuration: Double
    
    init(screenDivision: ScreenDivision = .automatic,
         gapSize: CGFloat = 10.0,
         respectDock: Bool = true,
         respectMenuBar: Bool = true,
         animationDuration: Double = 0.3) {
        self.screenDivision = screenDivision
        self.gapSize = gapSize
        self.respectDock = respectDock
        self.respectMenuBar = respectMenuBar
        self.animationDuration = animationDuration
    }
}

enum ScreenDivision: String, Codable, CaseIterable {
    case automatic = "automatic"
    case leftRight = "left_right"
    case topBottom = "top_bottom"
    case quarters = "quarters"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .leftRight: return "Left/Right Split"
        case .topBottom: return "Top/Bottom Split"
        case .quarters: return "Four Quarters"
        case .custom: return "Custom Layout"
        }
    }
}

// MARK: - Workspace Manager
class WorkspaceManager: ObservableObject {
    @Published private var workspaces: [Workspace] = []
    @Published private var appContexts: [String: AppContext] = [:] // Bundle ID -> AppContext
    
    static let shared = WorkspaceManager()
    
    private init() {
        loadBuiltInWorkspaces()
        loadUserWorkspaces()
        loadAppContexts()
    }
    
    // MARK: - Public API
    func getWorkspace(named name: String) -> Workspace? {
        return workspaces.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getAllWorkspaces() -> [Workspace] {
        return workspaces
    }
    
    func getAppContext(for bundleID: String) -> AppContext? {
        return appContexts[bundleID]
    }
    
    func updateAppUsage(bundleID: String, appName: String, category: AppCategory) {
        if var context = appContexts[bundleID] {
            var updatedContext = context
            updatedContext = AppContext(
                bundleID: context.bundleID,
                appName: context.appName,
                category: context.category,
                preferenceScore: context.preferenceScore,
                usageCount: context.usageCount + 1,
                lastUsed: Date(),
                userNotes: context.userNotes
            )
            appContexts[bundleID] = updatedContext
        } else {
            // Create new context
            appContexts[bundleID] = AppContext(
                bundleID: bundleID,
                appName: appName,
                category: category,
                usageCount: 1,
                lastUsed: Date()
            )
        }
        saveAppContexts()
    }
    
    func adjustPreference(for bundleID: String, delta: Double) {
        guard var context = appContexts[bundleID] else { return }
        
        let newScore = max(0.0, min(1.0, context.preferenceScore + delta))
        let updatedContext = AppContext(
            bundleID: context.bundleID,
            appName: context.appName,
            category: context.category,
            preferenceScore: newScore,
            usageCount: context.usageCount,
            lastUsed: context.lastUsed,
            userNotes: context.userNotes
        )
        appContexts[bundleID] = updatedContext
        saveAppContexts()
    }
    
    func excludeAppFromWorkspace(_ workspace: Workspace, appName: String) {
        // TODO: Update workspace with excluded app
    }
    
    func getPreferredAppsForCategory(_ category: AppCategory, limit: Int = 3) -> [AppContext] {
        return appContexts.values
            .filter { $0.category == category }
            .sorted { $0.preferenceScore > $1.preferenceScore }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Built-in Workspaces
    private func loadBuiltInWorkspaces() {
        let codingApps = [
            AppContext(bundleID: "com.todesktop.230313mzl4w4u92", appName: "Cursor", category: .codeEditor, preferenceScore: 0.9),
            AppContext(bundleID: "com.microsoft.VSCode", appName: "Visual Studio Code", category: .codeEditor, preferenceScore: 0.8),
            AppContext(bundleID: "com.apple.dt.Xcode", appName: "Xcode", category: .codeEditor, preferenceScore: 0.7),
            AppContext(bundleID: "com.apple.Terminal", appName: "Terminal", category: .terminal, preferenceScore: 0.9),
            AppContext(bundleID: "com.googlecode.iterm2", appName: "iTerm2", category: .terminal, preferenceScore: 0.8)
        ]
        
        let browserApps = [
            AppContext(bundleID: "company.thebrowser.Browser", appName: "Arc", category: .browser, preferenceScore: 0.8),
            AppContext(bundleID: "com.apple.Safari", appName: "Safari", category: .browser, preferenceScore: 0.7),
            AppContext(bundleID: "com.google.Chrome", appName: "Google Chrome", category: .browser, preferenceScore: 0.6)
        ]
        
        let builtInWorkspaces: [Workspace] = [
            Workspace(
                name: "Coding Environment",
                category: .coding,
                requiredApps: Array(codingApps.prefix(2)), // Editor + Terminal
                optionalApps: browserApps,
                layout: LayoutConfiguration(screenDivision: .leftRight)
            ),
            
            Workspace(
                name: "Research Setup",
                category: .research,
                requiredApps: browserApps,
                optionalApps: [
                    AppContext(bundleID: "com.apple.Notes", appName: "Notes", category: .productivity),
                    AppContext(bundleID: "com.apple.Preview", appName: "Preview", category: .productivity)
                ],
                layout: LayoutConfiguration(screenDivision: .quarters)
            ),
            
            Workspace(
                name: "Communication Hub",
                category: .communication,
                requiredApps: [
                    AppContext(bundleID: "com.apple.MobileSMS", appName: "Messages", category: .communication),
                    AppContext(bundleID: "com.apple.mail", appName: "Mail", category: .communication)
                ],
                optionalApps: [
                    AppContext(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", category: .communication),
                    AppContext(bundleID: "com.hnc.Discord", appName: "Discord", category: .communication)
                ],
                layout: LayoutConfiguration(screenDivision: .topBottom)
            )
        ]
        
        workspaces.append(contentsOf: builtInWorkspaces)
    }
    
    private func loadUserWorkspaces() {
        // TODO: Load user-defined workspaces from file
    }
    
    private func loadAppContexts() {
        // TODO: Load app usage contexts from file
    }
    
    private func saveAppContexts() {
        // TODO: Save app contexts to file
    }
    
    func saveWorkspaces() {
        // TODO: Save workspaces to file
    }
}