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
    private var userDefinedConstraints: [String: AppConstraints] = [:]
    
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
        userDefinedConstraints[constraints.bundleID] = constraints
        saveUserConstraints()
    }
    
    func removeUserConstraints(for bundleID: String) {
        userDefinedConstraints.removeValue(forKey: bundleID)
        saveUserConstraints()
    }
    
    func getAllConstraints() -> [AppConstraints] {
        var allConstraints = Array(constraints.values)
        allConstraints.append(contentsOf: userDefinedConstraints.values)
        return allConstraints
    }
    
    func getConstraintsByCategory(_ category: AppCategory) -> [AppConstraints] {
        return getAllConstraints().filter { $0.category == category }
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
        
        // Apply aspect ratio if required
        if constraints.prefersFixedAspectRatio, let aspectRatio = constraints.aspectRatio {
            let currentRatio = validatedSize.width / validatedSize.height
            if abs(currentRatio - aspectRatio) > 0.1 {
                // Adjust height to maintain aspect ratio
                validatedSize.height = validatedSize.width / aspectRatio
                
                // Re-check height constraints
                validatedSize.height = max(constraints.minHeight, validatedSize.height)
                if let maxHeight = constraints.maxHeight {
                    validatedSize.height = min(maxHeight, validatedSize.height)
                    // If height was clamped, adjust width accordingly
                    validatedSize.width = validatedSize.height * aspectRatio
                }
            }
        }
        
        return validatedSize
    }
    
    func validateWindowBounds(_ bounds: CGRect, for bundleID: String, screenBounds: CGRect) -> CGRect {
        let validatedSize = validateWindowSize(bounds.size, for: bundleID)
        
        var validatedBounds = bounds
        validatedBounds.size = validatedSize
        
        // Ensure window fits within screen bounds
        if validatedBounds.maxX > screenBounds.maxX {
            validatedBounds.origin.x = screenBounds.maxX - validatedBounds.width
        }
        if validatedBounds.maxY > screenBounds.maxY {
            validatedBounds.origin.y = screenBounds.maxY - validatedBounds.height
        }
        if validatedBounds.minX < screenBounds.minX {
            validatedBounds.origin.x = screenBounds.minX
        }
        if validatedBounds.minY < screenBounds.minY {
            validatedBounds.origin.y = screenBounds.minY
        }
        
        return validatedBounds
    }
    
    func canFullscreen(for bundleID: String) -> Bool {
        return getConstraints(for: bundleID)?.supportsFullscreen ?? true
    }
    
    func getOptimalSize(for bundleID: String, screenSize: CGSize) -> CGSize {
        guard let constraints = getConstraints(for: bundleID) else {
            return CGSize(width: screenSize.width * 0.6, height: screenSize.height * 0.7)
        }
        
        // Start with category-based optimal size
        var optimalSize: CGSize
        
        switch constraints.category {
        case .codeEditor:
            optimalSize = CGSize(width: screenSize.width * 0.75, height: screenSize.height * 0.85)
        case .browser:
            optimalSize = CGSize(width: screenSize.width * 0.7, height: screenSize.height * 0.8)
        case .communication:
            optimalSize = CGSize(width: min(900, screenSize.width * 0.45), height: screenSize.height * 0.7)
        case .terminal:
            optimalSize = CGSize(width: screenSize.width * 0.6, height: screenSize.height * 0.65)
        case .design:
            optimalSize = CGSize(width: screenSize.width * 0.85, height: screenSize.height * 0.9)
        case .productivity:
            optimalSize = CGSize(width: screenSize.width * 0.65, height: screenSize.height * 0.75)
        case .media:
            optimalSize = CGSize(width: screenSize.width * 0.8, height: screenSize.height * 0.8)
        case .database:
            optimalSize = CGSize(width: screenSize.width * 0.8, height: screenSize.height * 0.85)
        case .other:
            optimalSize = CGSize(width: screenSize.width * 0.6, height: screenSize.height * 0.7)
        }
        
        // Apply constraints
        return validateWindowSize(optimalSize, for: bundleID)
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
            
            // Communication - prefer narrow for auxiliary use
            AppConstraints(bundleID: "com.apple.MobileSMS", appName: "Messages", 
                          minWidth: 320, minHeight: 400, maxWidth: 600,
                          prefersFixedAspectRatio: true, aspectRatio: 0.7,
                          category: .communication, notes: "Messages works well as narrow auxiliary window"),
            AppConstraints(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", 
                          minWidth: 400, minHeight: 300, maxWidth: 800,
                          category: .communication),
            AppConstraints(bundleID: "com.hnc.Discord", appName: "Discord", 
                          minWidth: 940, minHeight: 500, category: .communication),
            
            // Terminal Apps - prefer tall and narrow
            AppConstraints(bundleID: "com.apple.Terminal", appName: "Terminal", 
                          minWidth: 480, minHeight: 300, maxWidth: 800,
                          prefersFixedAspectRatio: true, aspectRatio: 0.6,
                          category: .terminal, notes: "Terminal prefers tall/narrow layout"),
            AppConstraints(bundleID: "com.googlecode.iterm2", appName: "iTerm2", 
                          minWidth: 480, minHeight: 300, maxWidth: 800,
                          prefersFixedAspectRatio: true, aspectRatio: 0.6,
                          category: .terminal, notes: "iTerm2 prefers tall/narrow layout"),
            
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
                          minWidth: 400, minHeight: 300, category: .productivity),
            AppConstraints(bundleID: "com.apple.systempreferences", appName: "System Preferences", 
                          minWidth: 600, minHeight: 400, maxWidth: 900, maxHeight: 700, category: .productivity),
            AppConstraints(bundleID: "com.apple.ActivityMonitor", appName: "Activity Monitor", 
                          minWidth: 500, minHeight: 400, category: .productivity),
            
            // Additional Popular Apps
            AppConstraints(bundleID: "com.spotify.client", appName: "Spotify", 
                          minWidth: 600, minHeight: 400, category: .media),
            AppConstraints(bundleID: "com.adobe.Photoshop", appName: "Adobe Photoshop", 
                          minWidth: 800, minHeight: 600, category: .design),
            AppConstraints(bundleID: "notion.id", appName: "Notion", 
                          minWidth: 500, minHeight: 400, category: .productivity),
            AppConstraints(bundleID: "com.linear", appName: "Linear", 
                          minWidth: 600, minHeight: 500, category: .productivity),
            AppConstraints(bundleID: "com.1password.1password-macos", appName: "1Password 7", 
                          minWidth: 400, minHeight: 500, maxWidth: 600, category: .productivity)
        ]
        
        for app in builtInApps {
            constraints[app.bundleID] = app
        }
    }
    
    private func loadUserConstraints() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let constraintsURL = documentsPath.appendingPathComponent("WindowAI_UserConstraints.json")
        
        do {
            let data = try Data(contentsOf: constraintsURL)
            let decoded = try JSONDecoder().decode([String: AppConstraints].self, from: data)
            self.userDefinedConstraints = decoded
        } catch {
            // File doesn't exist or can't be decoded, start with empty constraints
            print("Could not load user constraints: \(error)")
        }
    }
    
    func saveUserConstraints() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let constraintsURL = documentsPath.appendingPathComponent("WindowAI_UserConstraints.json")
        
        do {
            let data = try JSONEncoder().encode(userDefinedConstraints)
            try data.write(to: constraintsURL)
        } catch {
            print("Could not save user constraints: \(error)")
        }
    }
}