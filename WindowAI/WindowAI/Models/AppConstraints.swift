import Foundation
import CoreGraphics

// MARK: - App Constraints Database
struct AppConstraints: Codable {
    let bundleID: String
    let appName: String
    let minWidth: CGFloat
    let minHeight: CGFloat
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    let supportsFullscreen: Bool
    let prefersFixedAspectRatio: Bool
    let aspectRatio: CGFloat?
    let category: AppCategory
    let notes: String?
    
    init(bundleID: String, 
         appName: String,
         minWidth: CGFloat, 
         minHeight: CGFloat,
         maxWidth: CGFloat? = nil,
         maxHeight: CGFloat? = nil,
         supportsFullscreen: Bool = true,
         prefersFixedAspectRatio: Bool = false,
         aspectRatio: CGFloat? = nil,
         category: AppCategory = .other,
         notes: String? = nil) {
        self.bundleID = bundleID
        self.appName = appName
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.supportsFullscreen = supportsFullscreen
        self.prefersFixedAspectRatio = prefersFixedAspectRatio
        self.aspectRatio = aspectRatio
        self.category = category
        self.notes = notes
    }
}

enum AppCategory: String, Codable, CaseIterable {
    case codeEditor = "code_editor"
    case browser = "browser"
    case communication = "communication"
    case design = "design"
    case productivity = "productivity"
    case media = "media"
    case terminal = "terminal"
    case database = "database"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .codeEditor: return "Code Editor"
        case .browser: return "Web Browser"
        case .communication: return "Communication"
        case .design: return "Design"
        case .productivity: return "Productivity"
        case .media: return "Media"
        case .terminal: return "Terminal"
        case .database: return "Database"
        case .other: return "Other"
        }
    }
}

// MARK: - App Constraints Manager
class AppConstraintsManager {
    private var constraints: [String: AppConstraints] = [:]
    private let userDefinedConstraints: [String: AppConstraints] = [:]
    
    static let shared = AppConstraintsManager()
    
    private init() {
        loadBuiltInConstraints()
        loadUserConstraints()
    }
    
    // MARK: - Public API
    func getConstraints(for bundleID: String) -> AppConstraints? {
        return userDefinedConstraints[bundleID] ?? constraints[bundleID]
    }
    
    func getConstraintsByAppName(_ appName: String) -> AppConstraints? {
        // Try to find by app name if bundle ID lookup fails
        return constraints.values.first { $0.appName.lowercased() == appName.lowercased() }
    }
    
    func addUserConstraints(_ constraints: AppConstraints) {
        // TODO: Save user-defined constraints
    }
    
    func validateWindowSize(_ size: CGSize, for bundleID: String) -> CGSize {
        guard let constraints = getConstraints(for: bundleID) else { return size }
        
        var validatedSize = size
        validatedSize.width = max(constraints.minWidth, validatedSize.width)
        validatedSize.height = max(constraints.minHeight, validatedSize.height)
        
        if let maxWidth = constraints.maxWidth {
            validatedSize.width = min(maxWidth, validatedSize.width)
        }
        if let maxHeight = constraints.maxHeight {
            validatedSize.height = min(maxHeight, validatedSize.height)
        }
        
        return validatedSize
    }
    
    // MARK: - Built-in Constraints Database
    private func loadBuiltInConstraints() {
        let builtInApps: [AppConstraints] = [
            // Browsers
            AppConstraints(bundleID: "com.apple.Safari", appName: "Safari", 
                          minWidth: 400, minHeight: 300, category: .browser),
            AppConstraints(bundleID: "com.google.Chrome", appName: "Google Chrome", 
                          minWidth: 500, minHeight: 400, category: .browser),
            AppConstraints(bundleID: "company.thebrowser.Browser", appName: "Arc", 
                          minWidth: 480, minHeight: 360, category: .browser),
            AppConstraints(bundleID: "org.mozilla.firefox", appName: "Firefox", 
                          minWidth: 450, minHeight: 350, category: .browser),
            
            // Code Editors
            AppConstraints(bundleID: "com.apple.dt.Xcode", appName: "Xcode", 
                          minWidth: 800, minHeight: 600, category: .codeEditor),
            AppConstraints(bundleID: "com.microsoft.VSCode", appName: "Visual Studio Code", 
                          minWidth: 600, minHeight: 400, category: .codeEditor),
            AppConstraints(bundleID: "com.todesktop.230313mzl4w4u92", appName: "Cursor", 
                          minWidth: 600, minHeight: 400, category: .codeEditor),
            
            // Communication
            AppConstraints(bundleID: "com.apple.MobileSMS", appName: "Messages", 
                          minWidth: 320, minHeight: 400, maxWidth: 800, category: .communication),
            AppConstraints(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", 
                          minWidth: 400, minHeight: 300, category: .communication),
            AppConstraints(bundleID: "com.hnc.Discord", appName: "Discord", 
                          minWidth: 940, minHeight: 500, category: .communication),
            
            // Terminal Apps
            AppConstraints(bundleID: "com.apple.Terminal", appName: "Terminal", 
                          minWidth: 480, minHeight: 300, category: .terminal),
            AppConstraints(bundleID: "com.googlecode.iterm2", appName: "iTerm2", 
                          minWidth: 480, minHeight: 300, category: .terminal),
            
            // Design Apps
            AppConstraints(bundleID: "com.figma.Desktop", appName: "Figma", 
                          minWidth: 800, minHeight: 600, category: .design),
            AppConstraints(bundleID: "com.bohemiancoding.sketch3", appName: "Sketch", 
                          minWidth: 600, minHeight: 400, category: .design),
            
            // System Apps
            AppConstraints(bundleID: "com.apple.finder", appName: "Finder", 
                          minWidth: 480, minHeight: 300, category: .productivity),
            AppConstraints(bundleID: "com.apple.mail", appName: "Mail", 
                          minWidth: 600, minHeight: 400, category: .communication),
            AppConstraints(bundleID: "com.apple.Notes", appName: "Notes", 
                          minWidth: 400, minHeight: 300, category: .productivity)
        ]
        
        for app in builtInApps {
            constraints[app.bundleID] = app
        }
    }
    
    private func loadUserConstraints() {
        // TODO: Load user-defined constraints from file
    }
    
    func saveUserConstraints() {
        // TODO: Save user-defined constraints to file
    }
}