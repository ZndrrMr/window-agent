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
}

// MARK: - Size Types
enum WindowSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case half = "half"
    case quarter = "quarter"
    case threeQuarters = "three-quarters"
    case full = "full"
    case custom = "custom"
}

// MARK: - Window Command
struct WindowCommand: Codable {
    let action: CommandAction
    let target: String
    let position: WindowPosition?
    let size: WindowSize?
    let customSize: CGSize?
    let customPosition: CGPoint?
    let parameters: [String: String]?
    
    init(action: CommandAction, 
         target: String, 
         position: WindowPosition? = nil, 
         size: WindowSize? = nil,
         customSize: CGSize? = nil,
         customPosition: CGPoint? = nil,
         parameters: [String: String]? = nil) {
        self.action = action
        self.target = target
        self.position = position
        self.size = size
        self.customSize = customSize
        self.customPosition = customPosition
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
    let visibleWindows: [String]
    let screenResolution: CGSize
    let currentWorkspace: String?
}

// MARK: - Predefined Command Templates
extension WindowCommand {
    static func openApp(_ appName: String) -> WindowCommand {
        return WindowCommand(action: .open, target: appName)
    }
    
    static func moveWindow(_ appName: String, to position: WindowPosition) -> WindowCommand {
        return WindowCommand(action: .move, target: appName, position: position)
    }
    
    static func resizeWindow(_ appName: String, to size: WindowSize) -> WindowCommand {
        return WindowCommand(action: .resize, target: appName, size: size)
    }
    
    static func arrangeForContext(_ context: String) -> WindowCommand {
        return WindowCommand(action: .arrange, target: context)
    }
    
    static func focusApp(_ appName: String) -> WindowCommand {
        return WindowCommand(action: .focus, target: appName)
    }
}