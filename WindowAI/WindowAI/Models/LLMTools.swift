import Foundation
import CoreGraphics

// MARK: - LLM Tool Definitions
struct LLMTool: Codable {
    let name: String
    let description: String
    let input_schema: ToolInputSchema
    
    struct ToolInputSchema: Codable {
        let type: String = "object"
        let properties: [String: PropertyDefinition]
        let required: [String]
        
        struct PropertyDefinition: Codable {
            let type: String
            let description: String
            let `enum`: [String]?
            
            init(type: String, description: String, options: [String]? = nil) {
                self.type = type
                self.description = description
                self.`enum` = options
            }
        }
    }
}

// MARK: - Tool Use Response
struct LLMToolUse: Codable {
    let type: String = "tool_use"
    let id: String
    let name: String
    let input: [String: AnyCodable]
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Unsupported type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            throw EncodingError.invalidValue(value, 
                EncodingError.Context(codingPath: encoder.codingPath, 
                                    debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Window Management Tools
class WindowManagementTools {
    
    static let allTools: [LLMTool] = [
        moveWindowTool,
        resizeWindowTool,
        openAppTool,
        closeAppTool,
        focusWindowTool,
        arrangeWorkspaceTool,
        snapWindowTool,
        minimizeWindowTool,
        maximizeWindowTool
    ]
    
    // Move window to specific position
    static let moveWindowTool = LLMTool(
        name: "move_window",
        description: "Move a window to a specific position on the screen",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to move"
                ),
                "position": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Position where to move the window",
                    options: ["left", "right", "top", "bottom", "center", "top-left", "top-right", "bottom-left", "bottom-right", "left-third", "middle-third", "right-third"]
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index (0 for main display, 1 for secondary, etc.). Optional."
                )
            ],
            required: ["app_name", "position"]
        )
    )
    
    // Resize window to specific size
    static let resizeWindowTool = LLMTool(
        name: "resize_window",
        description: "Resize a window to a specific size",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to resize"
                ),
                "size": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Size to resize the window to",
                    options: ["tiny", "small", "medium", "large", "huge", "half", "quarter", "third", "two-thirds", "three-quarters", "full", "optimal"]
                )
            ],
            required: ["app_name", "size"]
        )
    )
    
    // Open application
    static let openAppTool = LLMTool(
        name: "open_app",
        description: "Open an application, optionally at a specific position and size",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application to open (e.g., 'Safari', 'Terminal', 'Visual Studio Code')"
                ),
                "position": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Optional position where to place the window after opening",
                    options: ["left", "right", "top", "bottom", "center", "top-left", "top-right", "bottom-left", "bottom-right"]
                ),
                "size": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Optional size for the window after opening",
                    options: ["small", "medium", "large", "half", "quarter", "full", "optimal"]
                )
            ],
            required: ["app_name"]
        )
    )
    
    // Close application
    static let closeAppTool = LLMTool(
        name: "close_app",
        description: "Close an application or specific window",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application to close"
                )
            ],
            required: ["app_name"]
        )
    )
    
    // Focus window
    static let focusWindowTool = LLMTool(
        name: "focus_window",
        description: "Bring a window to the front and focus it",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to focus"
                )
            ],
            required: ["app_name"]
        )
    )
    
    // Arrange workspace for specific context
    static let arrangeWorkspaceTool = LLMTool(
        name: "arrange_workspace",
        description: "Arrange windows for a specific workflow or context",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "context": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "The workflow context to arrange for",
                    options: ["coding", "writing", "research", "communication", "design", "focus", "presentation", "cleanup"]
                )
            ],
            required: ["context"]
        )
    )
    
    // Snap window (move and resize in one operation)
    static let snapWindowTool = LLMTool(
        name: "snap_window",
        description: "Snap a window to a position with automatic sizing (combines move and resize)",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to snap"
                ),
                "position": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Position to snap the window to",
                    options: ["left", "right", "top", "bottom", "top-left", "top-right", "bottom-left", "bottom-right", "left-third", "middle-third", "right-third"]
                ),
                "size": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Size for the snapped window",
                    options: ["small", "medium", "large", "half", "third", "two-thirds"]
                )
            ],
            required: ["app_name", "position"]
        )
    )
    
    // Minimize window
    static let minimizeWindowTool = LLMTool(
        name: "minimize_window",
        description: "Minimize a window to the dock",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to minimize"
                )
            ],
            required: ["app_name"]
        )
    )
    
    // Maximize window
    static let maximizeWindowTool = LLMTool(
        name: "maximize_window",
        description: "Maximize a window to fill the screen",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to maximize"
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index to maximize on (0 for main display). Optional."
                )
            ],
            required: ["app_name"]
        )
    )
}

// MARK: - Tool to Command Converter
class ToolToCommandConverter {
    
    static func convertToolUse(_ toolUse: LLMToolUse) -> WindowCommand? {
        // Convert AnyCodable values to regular Swift types
        var input: [String: Any] = [:]
        for (key, anyCodable) in toolUse.input {
            input[key] = anyCodable.value
        }
        
        switch toolUse.name {
        case "move_window":
            return convertMoveWindow(input)
        case "resize_window":
            return convertResizeWindow(input)
        case "open_app":
            return convertOpenApp(input)
        case "close_app":
            return convertCloseApp(input)
        case "focus_window":
            return convertFocusWindow(input)
        case "arrange_workspace":
            return convertArrangeWorkspace(input)
        case "snap_window":
            return convertSnapWindow(input)
        case "minimize_window":
            return convertMinimizeWindow(input)
        case "maximize_window":
            return convertMaximizeWindow(input)
        default:
            return nil
        }
    }
    
    private static func convertMoveWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String,
              let positionStr = input["position"] as? String,
              let position = WindowPosition(rawValue: positionStr) else {
            return nil
        }
        
        let display = input["display"] as? Int
        
        return WindowCommand(
            action: .move,
            target: appName,
            position: position,
            display: display
        )
    }
    
    private static func convertResizeWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String,
              let sizeStr = input["size"] as? String,
              let size = WindowSize(rawValue: sizeStr) else {
            return nil
        }
        
        return WindowCommand(
            action: .resize,
            target: appName,
            size: size
        )
    }
    
    private static func convertOpenApp(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        let position = (input["position"] as? String).flatMap { WindowPosition(rawValue: $0) }
        let size = (input["size"] as? String).flatMap { WindowSize(rawValue: $0) }
        
        return WindowCommand(
            action: .open,
            target: appName,
            position: position,
            size: size
        )
    }
    
    private static func convertCloseApp(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .close,
            target: appName
        )
    }
    
    private static func convertFocusWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .focus,
            target: appName
        )
    }
    
    private static func convertArrangeWorkspace(_ input: [String: Any]) -> WindowCommand? {
        guard let context = input["context"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .arrange,
            target: context
        )
    }
    
    private static func convertSnapWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String,
              let positionStr = input["position"] as? String,
              let position = WindowPosition(rawValue: positionStr) else {
            return nil
        }
        
        let size = (input["size"] as? String).flatMap { WindowSize(rawValue: $0) } ?? .medium
        
        return WindowCommand(
            action: .snap,
            target: appName,
            position: position,
            size: size
        )
    }
    
    private static func convertMinimizeWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .minimize,
            target: appName
        )
    }
    
    private static func convertMaximizeWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        let display = input["display"] as? Int
        
        return WindowCommand(
            action: .maximize,
            target: appName,
            display: display
        )
    }
}