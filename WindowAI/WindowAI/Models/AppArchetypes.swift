import Foundation

// MARK: - App Behavior Archetypes
enum AppArchetype: String, CaseIterable {
    case textStream = "text_stream"
    case contentCanvas = "content_canvas"  
    case codeWorkspace = "code_workspace"
    case glanceableMonitor = "glanceable_monitor"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .textStream: return "Text Stream"
        case .contentCanvas: return "Content Canvas"
        case .codeWorkspace: return "Code Workspace"
        case .glanceableMonitor: return "Glanceable Monitor"
        case .unknown: return "Unknown"
        }
    }
    
    var description: String {
        switch self {
        case .textStream:
            return "Display flowing text that users read vertically"
        case .contentCanvas:
            return "Display formatted content designed for specific aspect ratios"
        case .codeWorkspace:
            return "Primary work environment where users spend extended time"
        case .glanceableMonitor:
            return "Persistent visibility for occasional checking, minimal interaction"
        case .unknown:
            return "Unknown app behavior pattern"
        }
    }
    
    var cascadeStrategy: String {
        switch self {
        case .textStream:
            return "Perfect for side columns - give full vertical space, minimal horizontal"
        case .contentCanvas:
            return "Must peek with enough width to remain functional (45%+ screen)"
        case .codeWorkspace:
            return "Should be primary layer, claims remaining space after auxiliaries positioned"
        case .glanceableMonitor:
            return "Perfect for corners or thin strips, just need key info visible"
        case .unknown:
            return "Treat as content canvas by default"
        }
    }
}

// MARK: - App Archetype Classifier
class AppArchetypeClassifier {
    static let shared = AppArchetypeClassifier()
    
    private let archetypeDatabase: [String: AppArchetype] = [
        // Text Stream Tools
        "terminal": .textStream,
        "iterm": .textStream,
        "iterm2": .textStream,
        "console": .textStream,
        "hyper": .textStream,
        "warp": .textStream,
        "slack": .textStream,
        "discord": .textStream,
        "messages": .textStream,
        "telegram": .textStream,
        "whatsapp": .textStream,
        "signal": .textStream,
        "skype": .textStream,
        "zoom": .textStream,
        "microsoft teams": .textStream,
        "log viewer": .textStream,
        "chat": .textStream,
        
        // Content Canvas Tools
        "arc": .contentCanvas,
        "safari": .contentCanvas,
        "chrome": .contentCanvas,
        "firefox": .contentCanvas,
        "edge": .contentCanvas,
        "brave": .contentCanvas,
        "opera": .contentCanvas,
        "webkit": .contentCanvas,
        "preview": .contentCanvas,
        "pdf viewer": .contentCanvas,
        "adobe reader": .contentCanvas,
        "figma": .contentCanvas,
        "sketch": .contentCanvas,
        "photoshop": .contentCanvas,
        "illustrator": .contentCanvas,
        "indesign": .contentCanvas,
        "canva": .contentCanvas,
        "notion": .contentCanvas,
        "obsidian": .contentCanvas,
        "logseq": .contentCanvas,
        "roam research": .contentCanvas,
        "bear": .contentCanvas,
        "notes": .contentCanvas,
        "pages": .contentCanvas,
        "word": .contentCanvas,
        "google docs": .contentCanvas,
        "keynote": .contentCanvas,
        "powerpoint": .contentCanvas,
        "numbers": .contentCanvas,
        "excel": .contentCanvas,
        "sheets": .contentCanvas,
        
        // Code Workspace Tools
        "cursor": .codeWorkspace,
        "xcode": .codeWorkspace,
        "visual studio code": .codeWorkspace,
        "vscode": .codeWorkspace,
        "sublime text": .codeWorkspace,
        "atom": .codeWorkspace,
        "vim": .codeWorkspace,
        "emacs": .codeWorkspace,
        "intellij": .codeWorkspace,
        "pycharm": .codeWorkspace,
        "webstorm": .codeWorkspace,
        "phpstorm": .codeWorkspace,
        "clion": .codeWorkspace,
        "android studio": .codeWorkspace,
        "unity": .codeWorkspace,
        "unreal engine": .codeWorkspace,
        "nova": .codeWorkspace,
        "coderunner": .codeWorkspace,
        "dash": .codeWorkspace,
        "kaleidoscope": .codeWorkspace,
        "sourcetree": .codeWorkspace,
        "github desktop": .codeWorkspace,
        "tower": .codeWorkspace,
        "fork": .codeWorkspace,
        
        // Glanceable Monitors
        "activity monitor": .glanceableMonitor,
        "system monitor": .glanceableMonitor,
        "top": .glanceableMonitor,
        "htop": .glanceableMonitor,
        "spotify": .glanceableMonitor,
        "music": .glanceableMonitor,
        "apple music": .glanceableMonitor,
        "itunes": .glanceableMonitor,
        "soundcloud": .glanceableMonitor,
        "youtube music": .glanceableMonitor,
        "timer": .glanceableMonitor,
        "clock": .glanceableMonitor,
        "stopwatch": .glanceableMonitor,
        "countdown": .glanceableMonitor,
        "system preferences": .glanceableMonitor,
        "settings": .glanceableMonitor,
        "preferences": .glanceableMonitor,
        "menumeters": .glanceableMonitor,
        "istat menus": .glanceableMonitor,
        "network radar": .glanceableMonitor,
        "little snitch": .glanceableMonitor,
        "bartender": .glanceableMonitor,
        "finder": .glanceableMonitor,
        "file browser": .glanceableMonitor,
        "path finder": .glanceableMonitor
    ]
    
    private init() {}
    
    // MARK: - Public API
    func classifyApp(_ appName: String) -> AppArchetype {
        let normalizedName = appName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct match
        if let archetype = archetypeDatabase[normalizedName] {
            return archetype
        }
        
        // Fuzzy matching for partial names
        for (knownApp, archetype) in archetypeDatabase {
            if normalizedName.contains(knownApp) || knownApp.contains(normalizedName) {
                return archetype
            }
        }
        
        // Pattern-based classification for unknown apps
        return classifyByPattern(normalizedName)
    }
    
    private func classifyByPattern(_ appName: String) -> AppArchetype {
        // Terminal-like patterns
        if appName.contains("terminal") || appName.contains("console") || 
           appName.contains("shell") || appName.contains("cmd") ||
           appName.contains("bash") || appName.contains("zsh") {
            return .textStream
        }
        
        // Chat/messaging patterns
        if appName.contains("chat") || appName.contains("message") || 
           appName.contains("messenger") || appName.contains("talk") {
            return .textStream
        }
        
        // Browser patterns
        if appName.contains("browser") || appName.contains("web") ||
           appName.hasSuffix("browser") {
            return .contentCanvas
        }
        
        // Code editor patterns
        if appName.contains("code") || appName.contains("editor") ||
           appName.contains("ide") || appName.contains("dev") ||
           appName.contains("studio") {
            return .codeWorkspace
        }
        
        // Design tool patterns
        if appName.contains("design") || appName.contains("photo") ||
           appName.contains("image") || appName.contains("draw") {
            return .contentCanvas
        }
        
        // Music/media patterns
        if appName.contains("music") || appName.contains("audio") ||
           appName.contains("media") || appName.contains("player") {
            return .glanceableMonitor
        }
        
        // System/monitor patterns
        if appName.contains("monitor") || appName.contains("system") ||
           appName.contains("activity") || appName.contains("stats") {
            return .glanceableMonitor
        }
        
        // Default to content canvas for unknown apps
        return .contentCanvas
    }
    
    // MARK: - Archetype Information
    func getOptimalCascadeRole(for archetype: AppArchetype, windowCount: Int) -> CascadeRole {
        switch archetype {
        case .textStream:
            return .sideColumn
        case .codeWorkspace:
            return .primary
        case .contentCanvas:
            return .peekLayer
        case .glanceableMonitor:
            return .corner
        case .unknown:
            return .peekLayer
        }
    }
    
    func getOptimalSizing(for archetype: AppArchetype, screenSize: CGSize, role: CascadeRole, windowCount: Int = 3) -> (width: Double, height: Double) {
        // Dynamic sizing based on archetype behavior and window count
        switch (archetype, role) {
        case (.textStream, .sideColumn):
            // Text streams: ensure minimum readable width while adapting to window count
            let baseWidth = windowCount <= 2 ? 0.35 : windowCount == 3 ? 0.30 : 0.25
            // Ensure minimum 400px width for terminal readability
            let minWidthForScreen = 400.0 / screenSize.width
            let finalWidth = max(baseWidth, minWidthForScreen)
            return (width: finalWidth, height: 1.0)
            
        case (.codeWorkspace, .primary):
            // Code workspace: scale based on number of windows
            let baseWidth = windowCount <= 2 ? 0.80 : windowCount == 3 ? 0.70 : 0.65
            let baseHeight = windowCount <= 2 ? 0.90 : 0.85
            return (width: baseWidth, height: baseHeight)
            
        case (.contentCanvas, .peekLayer):
            // Content canvas: ensure minimum functional area while adapting to window count
            let baseWidth = windowCount <= 2 ? 0.55 : windowCount == 3 ? 0.55 : 0.50
            let baseHeight = windowCount <= 2 ? 0.50 : windowCount == 3 ? 0.50 : 0.45
            
            // Ensure minimum 25% screen area for browser functionality
            let currentArea = baseWidth * baseHeight
            let minRequiredArea = 0.25 // 25% of screen
            
            if currentArea < minRequiredArea {
                // Scale proportionally to reach minimum area
                let scaleFactor = sqrt(minRequiredArea / currentArea)
                let adjustedWidth = min(baseWidth * scaleFactor, 0.65) // Cap at 65% width
                let adjustedHeight = min(baseHeight * scaleFactor, 0.60) // Cap at 60% height
                return (width: adjustedWidth, height: adjustedHeight)
            }
            
            return (width: baseWidth, height: baseHeight)
            
        case (.contentCanvas, .primary):
            // Content as primary: optimize for content consumption
            let baseWidth = windowCount <= 2 ? 0.75 : 0.65
            return (width: baseWidth, height: 0.85)
            
        case (.glanceableMonitor, .corner):
            // Glanceable: just enough for controls/info
            let minSize = max(0.15, 200.0 / min(screenSize.width, screenSize.height))
            return (width: minSize, height: minSize)
            
        case (.textStream, .primary):
            // Text stream as primary: optimize for reading
            let optimalWidth = min(0.75, max(0.60, 1000.0 / screenSize.width))
            return (width: optimalWidth, height: 0.90)
            
        default:
            // Dynamic default based on role and window count
            let defaultWidth = role == .primary ? 0.60 : role == .peekLayer ? 0.45 : 0.30
            let scaleFactor = max(0.8, 1.2 - (Double(windowCount) * 0.1))
            return (width: defaultWidth * scaleFactor, height: 0.70 * scaleFactor)
        }
    }
}

// MARK: - Cascade Roles
enum CascadeRole: String, CaseIterable {
    case primary = "primary"
    case sideColumn = "side_column" 
    case peekLayer = "peek_layer"
    case corner = "corner"
    
    var description: String {
        switch self {
        case .primary:
            return "Main workspace - gets most space but positioned for peek zones"
        case .sideColumn:
            return "Dedicated column - full height, minimal width"
        case .peekLayer:
            return "Peek from under primary - enough width to stay functional"
        case .corner:
            return "Corner position - minimal space, always visible"
        }
    }
    
    var layerPriority: Int {
        switch self {
        case .primary: return 3
        case .peekLayer: return 2
        case .sideColumn: return 1
        case .corner: return 0
        }
    }
}