import Foundation
import CoreGraphics

// MARK: - Command Types
enum CommandAction: String, Codable, CaseIterable {
    case open = "open"
    case move = "move"
    case resize = "resize"
    case focus = "focus"
    case arrange = "arrange"
    case close = "close"
    case minimize = "minimize"
    case maximize = "maximize"
    case restore = "restore"
    case snap = "snap"           // Smart positioning
    case tile = "tile"           // Tiling layout
    case stack = "stack"         // Stack windows
}

// MARK: - Position Types
enum WindowPosition: String, Codable, CaseIterable {
    case left = "left"
    case right = "right"
    case top = "top"
    case bottom = "bottom"
    case center = "center"
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"
    case leftThird = "left-third"
    case middleThird = "middle-third"
    case rightThird = "right-third"
    case topThird = "top-third"
    case bottomThird = "bottom-third"
    case precise = "precise" // For custom coordinates
}

// MARK: - Size Types
enum WindowSize: String, Codable, CaseIterable {
    case tiny = "tiny"           // 25% of screen
    case small = "small"         // 33% of screen
    case medium = "medium"       // 50% of screen
    case large = "large"         // 67% of screen
    case huge = "huge"           // 80% of screen
    case half = "half"           // 50% of screen (alias for medium)
    case quarter = "quarter"     // 25% of screen
    case third = "third"         // 33% of screen
    case twoThirds = "two-thirds" // 67% of screen
    case threeQuarters = "three-quarters" // 75% of screen
    case full = "full"           // Maximize to visible screen
    case fit = "fit"             // Fit content (app determines size)
    case optimal = "optimal"     // Use app's preferred size
    case precise = "precise"     // Use exact custom dimensions
}

// MARK: - Window Command
struct WindowCommand: Codable {
    let action: CommandAction
    let target: String
    let position: WindowPosition?
    let size: WindowSize?
    let customSize: CGSize?
    let customPosition: CGPoint?
    let display: Int?             // Which display (0 = main, 1 = secondary, etc.)
    let animated: Bool            // Should the change be animated
    let respectConstraints: Bool  // Whether to respect app constraints
    let workspace: String?        // Target workspace/space
    let parameters: [String: String]?
    
    init(action: CommandAction, 
         target: String, 
         position: WindowPosition? = nil, 
         size: WindowSize? = nil,
         customSize: CGSize? = nil,
         customPosition: CGPoint? = nil,
         display: Int? = nil,
         animated: Bool = true,
         respectConstraints: Bool = true,
         workspace: String? = nil,
         parameters: [String: String]? = nil) {
        self.action = action
        self.target = target
        self.position = position
        self.size = size
        self.customSize = customSize
        self.customPosition = customPosition
        self.display = display
        self.animated = animated
        self.respectConstraints = respectConstraints
        self.workspace = workspace
        self.parameters = parameters
    }
}

// MARK: - Command Result
struct CommandResult: Codable {
    let success: Bool
    let message: String
    let timestamp: Date
    let command: WindowCommand?
    
    init(success: Bool, message: String, command: WindowCommand? = nil) {
        self.success = success
        self.message = message
        self.timestamp = Date()
        self.command = command
    }
}

// MARK: - LLM Request/Response
struct LLMRequest: Codable {
    let userInput: String
    let context: LLMContext?
    let maxTokens: Int
    let temperature: Double
    
    init(userInput: String, context: LLMContext? = nil, maxTokens: Int = 500, temperature: Double = 0.3) {
        self.userInput = userInput
        self.context = context
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

struct LLMResponse: Codable {
    let commands: [WindowCommand]
    let explanation: String?
    let confidence: Double?
    let processingTime: TimeInterval?
}

struct LLMContext: Codable {
    let runningApps: [String]
    let visibleWindows: [WindowSummary]
    let screenResolutions: [CGSize]
    let currentWorkspace: String?
    let displayCount: Int
    let userPreferences: [String: String]?
    
    struct WindowSummary: Codable {
        let title: String
        let appName: String
        let bounds: CGRect
        let isMinimized: Bool
        let displayIndex: Int
    }
}

// MARK: - Predefined Command Templates
extension WindowCommand {
    static func openApp(_ appName: String, at position: WindowPosition? = nil, size: WindowSize? = nil) -> WindowCommand {
        return WindowCommand(action: .open, target: appName, position: position, size: size)
    }
    
    static func moveWindow(_ appName: String, to position: WindowPosition, on display: Int? = nil) -> WindowCommand {
        return WindowCommand(action: .move, target: appName, position: position, display: display)
    }
    
    static func resizeWindow(_ appName: String, to size: WindowSize) -> WindowCommand {
        return WindowCommand(action: .resize, target: appName, size: size)
    }
    
    static func snapWindow(_ appName: String, to position: WindowPosition, size: WindowSize = .medium) -> WindowCommand {
        return WindowCommand(action: .snap, target: appName, position: position, size: size)
    }
    
    static func precisePosition(_ appName: String, at point: CGPoint, size: CGSize) -> WindowCommand {
        return WindowCommand(action: .move, target: appName, position: .precise, size: .precise, 
                           customSize: size, customPosition: point)
    }
    
    static func optimalSize(_ appName: String, at position: WindowPosition? = nil) -> WindowCommand {
        return WindowCommand(action: .resize, target: appName, position: position, size: .optimal)
    }
    
    static func arrangeForContext(_ context: String) -> WindowCommand {
        return WindowCommand(action: .arrange, target: context)
    }
    
    static func focusApp(_ appName: String) -> WindowCommand {
        return WindowCommand(action: .focus, target: appName)
    }
    
    static func minimizeApp(_ appName: String) -> WindowCommand {
        return WindowCommand(action: .minimize, target: appName)
    }
    
    static func maximizeApp(_ appName: String, on display: Int? = nil) -> WindowCommand {
        return WindowCommand(action: .maximize, target: appName, display: display)
    }
}