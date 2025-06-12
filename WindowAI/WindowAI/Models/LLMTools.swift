import Foundation
import CoreGraphics
import Cocoa

// MARK: - LLM Tool Definitions
struct LLMTool: Codable {
    let name: String
    let description: String
    let input_schema: ToolInputSchema
    
    struct ToolInputSchema: Codable {
        var type: String = "object"
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
    var type: String = "tool_use"
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
        maximizeWindowTool,
        cascadeWindowsTool,
        tileWindowsTool
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
        description: "Resize a window to a specific size. Can resize just height or width independently.",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application whose window to resize"
                ),
                "size": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Size to resize the window to. Use 'custom' if specifying custom_height or custom_width",
                    options: ["tiny", "small", "medium", "large", "huge", "half", "quarter", "third", "two-thirds", "three-quarters", "full", "optimal", "custom"]
                ),
                "custom_height": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom height as percentage of screen (e.g., '90' for 90% height). Only used when size='custom'"
                ),
                "custom_width": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom width as percentage of screen (e.g., '50' for 50% width). Only used when size='custom'"
                ),
                "preserve_width": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "boolean",
                    description: "If true, keep current width and only change height"
                ),
                "preserve_height": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "boolean",
                    description: "If true, keep current height and only change width"
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index to calculate size relative to (0 for main display, 1 for second display, etc.). If omitted, uses the display the window is currently on"
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
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index where to open the window (0 for main display, 1 for second display, etc.). If omitted, opens on main display"
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
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index (0 for main display, 1 for second display, etc.). Omit to use current display"
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
    
    // Cascade windows
    static let cascadeWindowsTool = LLMTool(
        name: "cascade_windows",
        description: "Arrange windows in a cascade layout with intelligent overlapping for better visibility",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "target": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Which windows to cascade: 'all', 'visible', or specific app name"
                ),
                "style": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Cascade style to use",
                    options: ["intelligent", "classic", "compact", "spread"]
                ),
                "focus_mode": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "boolean",
                    description: "Whether to optimize for focused work (larger primary window)"
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index to cascade windows on (0 for main display, 1 for second display, etc.). If omitted, cascades on the display with most windows"
                )
            ],
            required: ["target"]
        )
    )
    
    // Tile windows
    static let tileWindowsTool = LLMTool(
        name: "tile_windows",
        description: "Tile windows to show all windows without overlap",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "target": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Which windows to tile: 'all', 'visible', or specific app name"
                ),
                "layout": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Tiling layout to use",
                    options: ["grid", "horizontal", "vertical", "primary-left"]
                ),
                "display": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "integer",
                    description: "Display index to tile windows on (0 for main display, 1 for second display, etc.). If omitted, tiles on the display with most windows"
                )
            ],
            required: ["target"]
        )
    )
}

// MARK: - Tool to Command Converter
class ToolToCommandConverter {
    
    // Helper to extract display parameter (handles both Int and String)
    private static func extractDisplay(from input: [String: Any]) -> Int? {
        if let displayInt = input["display"] as? Int {
            return displayInt
        } else if let displayStr = input["display"] as? String, let displayInt = Int(displayStr) {
            return displayInt
        }
        return nil
    }
    
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
        case "cascade_windows":
            return convertCascadeWindows(input)
        case "tile_windows":
            return convertTileWindows(input)
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
        
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .move,
            target: appName,
            position: position,
            display: display
        )
    }
    
    private static func convertResizeWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String,
              let sizeStr = input["size"] as? String else {
            return nil
        }
        
        let size = WindowSize(rawValue: sizeStr)
        
        // Handle custom size
        var customSize: CGSize?
        var parameters: [String: String] = [:]
        
        if sizeStr == "custom" {
            let screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
            
            if let heightStr = input["custom_height"] as? String,
               let heightPercent = Double(heightStr) {
                let height = screenBounds.height * (heightPercent / 100.0)
                
                if let widthStr = input["custom_width"] as? String,
                   let widthPercent = Double(widthStr) {
                    let width = screenBounds.width * (widthPercent / 100.0)
                    customSize = CGSize(width: width, height: height)
                } else {
                    // Only height specified, preserve width
                    parameters["preserve_width"] = "true"
                    customSize = CGSize(width: 0, height: height) // Width will be preserved
                }
            } else if let widthStr = input["custom_width"] as? String,
                      let widthPercent = Double(widthStr) {
                // Only width specified, preserve height
                let width = screenBounds.width * (widthPercent / 100.0)
                parameters["preserve_height"] = "true"
                customSize = CGSize(width: width, height: 0) // Height will be preserved
            }
        }
        
        // Check preserve flags
        if let preserveWidth = input["preserve_width"] as? Bool, preserveWidth {
            parameters["preserve_width"] = "true"
        }
        if let preserveHeight = input["preserve_height"] as? Bool, preserveHeight {
            parameters["preserve_height"] = "true"
        }
        
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .resize,
            target: appName,
            size: size ?? .medium,
            customSize: customSize,
            display: display,
            parameters: parameters.isEmpty ? nil : parameters
        )
    }
    
    private static func convertOpenApp(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        let position = (input["position"] as? String).flatMap { WindowPosition(rawValue: $0) }
        let size = (input["size"] as? String).flatMap { WindowSize(rawValue: $0) }
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .open,
            target: appName,
            position: position,
            size: size,
            display: display
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
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .snap,
            target: appName,
            position: position,
            size: size,
            display: display
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
        
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .maximize,
            target: appName,
            display: display
        )
    }
    
    private static func convertCascadeWindows(_ input: [String: Any]) -> WindowCommand? {
        guard let target = input["target"] as? String else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        if let style = input["style"] as? String {
            parameters["style"] = style
        }
        if let focusMode = input["focus_mode"] as? Bool {
            parameters["focus"] = focusMode ? "true" : "false"
        }
        
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .stack, // Using stack action for cascade
            target: target,
            display: display,
            parameters: parameters
        )
    }
    
    private static func convertTileWindows(_ input: [String: Any]) -> WindowCommand? {
        guard let target = input["target"] as? String else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        if let layout = input["layout"] as? String {
            parameters["layout"] = layout
        }
        
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .tile,
            target: target,
            display: display,
            parameters: parameters
        )
    }
}