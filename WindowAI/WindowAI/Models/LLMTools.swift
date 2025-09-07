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
        closeAppTool,
        applyLayoutTool,
        openAppTool,
        minimizeAppTool,
        focusAppTool
    ]
    
    
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
                    options: ["tiny", "small", "medium", "large", "huge", "half", "third", "two-thirds", "full", "optimal", "custom"]
                ),
                "custom_height": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom height as percentage (e.g., '90' for 90% height) or pixels (e.g., '800px'). Supports decimals (e.g., '67.5'). Only used when size='custom'"
                ),
                "custom_width": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom width as percentage (e.g., '50' for 50% width) or pixels (e.g., '1200px'). Supports decimals (e.g., '33.3'). Only used when size='custom'"
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
                    options: ["small", "medium", "large", "half", "full", "optimal"]
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
                    options: ["left", "right", "top", "bottom", "center", "top-left", "top-right", "bottom-left", "bottom-right", "left-third", "middle-third", "right-third", "top-third", "bottom-third", "custom"]
                ),
                "size": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Size for the snapped window",
                    options: ["small", "medium", "large", "half", "third", "two-thirds", "quarter", "three-quarters", "custom"]
                ),
                "custom_x": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom X position as percentage (e.g., '25' for 25% from left). Only used when position='custom'"
                ),
                "custom_y": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string", 
                    description: "Custom Y position as percentage (e.g., '10' for 10% from top). Only used when position='custom'"
                ),
                "custom_width": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom width as percentage (e.g., '50' for 50% width). Only used when size='custom'"
                ),
                "custom_height": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Custom height as percentage (e.g., '75' for 75% height). Only used when size='custom'"
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
    
    // Primary layout tool - applies pre-defined layouts to multiple apps
    static let applyLayoutTool = LLMTool(
        name: "apply_layout",
        description: "Apply a pre-defined window layout to a list of applications. This is the PRIMARY tool for positioning windows - much more reliable than manual positioning.",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "layout": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Layout name to apply",
                    options: [
                        "fullscreen", "centered_large", "centered_medium",
                        "left_right_split", "top_bottom_split", "main_sidebar", "sidebar_main",
                        "three_column", "main_two_side", "two_top_one_bottom",
                        "four_quadrants", "main_three_side"
                    ]
                ),
                "apps": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string", 
                    description: "Comma-separated list of app names to include in layout (e.g., 'Cursor,Terminal,Arc')"
                ),
                "focus_app": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Which app should be focused/active after layout is applied (optional)"
                )
            ],
            required: ["layout", "apps"]
        )
    )
    
    // (openAppTool already defined above)
    
    static let minimizeAppTool = LLMTool(
        name: "minimize_app", 
        description: "Minimize an application's windows",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string",
                    description: "Name of the application to minimize"
                )
            ],
            required: ["app_name"]
        )
    )
    
    static let focusAppTool = LLMTool(
        name: "focus_app",
        description: "Focus/activate an application (brings to front)",
        input_schema: LLMTool.ToolInputSchema(
            properties: [
                "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                    type: "string", 
                    description: "Name of the application to focus"
                )
            ],
            required: ["app_name"]
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
    
    // Helper to parse size value (supports percentages and pixels)
    private static func parseSizeValue(_ value: String, screenSize: CGFloat) -> CGFloat? {
        if value.hasSuffix("px") {
            // Pixel value (e.g., "800px")
            let pixelStr = String(value.dropLast(2))
            return Double(pixelStr).map { CGFloat($0) }
        } else {
            // Percentage value (e.g., "75", "33.5", or "50%")
            let percentage = parsePercentageValue(value)
            return screenSize * CGFloat(percentage / 100.0)
        }
    }
    
    // Helper to parse percentage value (handles both "50%" and "50.0" formats)
    private static func parsePercentageValue(_ value: String) -> Double {
        if value.hasSuffix("%") {
            // Handle "50%" format
            let numberStr = String(value.dropLast(1))
            return Double(numberStr) ?? 0
        } else {
            // Handle "50.0" or "50" format
            return Double(value) ?? 0
        }
    }
    
    static func convertToolUse(_ toolUse: LLMToolUse) -> WindowCommand? {
        // Convert AnyCodable values to regular Swift types
        var input: [String: Any] = [:]
        for (key, anyCodable) in toolUse.input {
            input[key] = anyCodable.value
        }
        
        switch toolUse.name {
        case "close_app":
            return convertCloseApp(input)
        case "apply_layout":
            return convertApplyLayout(input)
        case "open_app":
            return convertOpenApp(input)
        case "minimize_app":
            return convertMinimizeApp(input)
        case "focus_app":
            return convertFocusApp(input)
        // flexible_position removed - use apply_layout tool instead
        default:
            return nil
        }
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
               let height = parseSizeValue(heightStr, screenSize: screenBounds.height) {
                
                if let widthStr = input["custom_width"] as? String,
                   let width = parseSizeValue(widthStr, screenSize: screenBounds.width) {
                    customSize = CGSize(width: width, height: height)
                } else {
                    // Only height specified, preserve width
                    parameters["preserve_width"] = "true"
                    customSize = CGSize(width: 0, height: height) // Width will be preserved
                }
            } else if let widthStr = input["custom_width"] as? String,
                      let width = parseSizeValue(widthStr, screenSize: screenBounds.width) {
                // Only width specified, preserve height
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
    
    
    private static func convertSnapWindow(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String,
              let positionStr = input["position"] as? String else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        
        // Handle custom position
        if positionStr == "custom" {
            if let customX = input["custom_x"] as? String {
                parameters["custom_x"] = customX
            }
            if let customY = input["custom_y"] as? String {
                parameters["custom_y"] = customY
            }
        }
        
        // Handle custom size
        let sizeStr = input["size"] as? String ?? "medium"
        if sizeStr == "custom" {
            if let customWidth = input["custom_width"] as? String {
                parameters["custom_width"] = customWidth
            }
            if let customHeight = input["custom_height"] as? String {
                parameters["custom_height"] = customHeight
            }
        }
        
        let position = WindowPosition(rawValue: positionStr)
        let size = WindowSize(rawValue: sizeStr) ?? .medium
        let display = extractDisplay(from: input)
        
        return WindowCommand(
            action: .snap,
            target: appName,
            position: position,
            size: size,
            display: display,
            parameters: parameters.isEmpty ? nil : parameters
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
    
    private static func convertFlexiblePosition(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        let display = extractDisplay(from: input)
        var parameters: [String: String] = [:]
        
        // Handle lifecycle operations
        if let open = input["open"] as? Bool {
            parameters["open"] = String(open)
        }
        
        if let minimize = input["minimize"] as? Bool {
            parameters["minimize"] = String(minimize)
        }
        
        if let restore = input["restore"] as? Bool {
            parameters["restore"] = String(restore)
        }
        
        if let focus = input["focus"] as? Bool {
            parameters["focus"] = String(focus)
        }
        
        if let layer = input["layer"] as? Int {
            parameters["layer"] = String(layer)
        }
        
        // Check if this is a positioning operation
        if let xPos = input["x_position"] as? String,
           let yPos = input["y_position"] as? String,
           let width = input["width"] as? String,
           let height = input["height"] as? String {
            
            // Get the correct display bounds based on the display parameter
            let screenBounds: CGRect
            if let displayIndex = display, displayIndex >= 0 && displayIndex < NSScreen.screens.count {
                screenBounds = NSScreen.screens[displayIndex].visibleFrame
                print("🖥️ Using display \(displayIndex) bounds: \(screenBounds)")
            } else {
                screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
                print("🖥️ Using main display bounds: \(screenBounds)")
            }
            
            // Parse position values
            let x: Double
            let y: Double
            
            if xPos.hasSuffix("px") {
                x = Double(xPos.dropLast(2)) ?? 0
            } else {
                let percentage = parsePercentageValue(xPos)
                x = screenBounds.width * (percentage / 100.0)
            }
            
            if yPos.hasSuffix("px") {
                y = Double(yPos.dropLast(2)) ?? 0
            } else {
                let percentage = parsePercentageValue(yPos)
                y = screenBounds.height * (percentage / 100.0)
            }
            
            // Parse size values
            let w: Double
            let h: Double
            
            if width.hasSuffix("px") {
                w = Double(width.dropLast(2)) ?? 0
            } else {
                let percentage = parsePercentageValue(width)
                w = screenBounds.width * (percentage / 100.0)
            }
            
            if height.hasSuffix("px") {
                h = Double(height.dropLast(2)) ?? 0
            } else {
                let percentage = parsePercentageValue(height)
                h = screenBounds.height * (percentage / 100.0)
            }
            
            // This is a positioning command with flexible_position parameters
            return WindowCommand(
                action: .move,
                target: appName,
                position: .precise,
                size: .precise,
                customSize: CGSize(width: w, height: h),
                customPosition: CGPoint(x: x, y: y),
                display: display,
                parameters: parameters.isEmpty ? nil : parameters
            )
        } else {
            // This is a non-positioning command (focus, minimize, etc.)
            // Determine action based on parameters
            if let minimizeStr = parameters["minimize"], minimizeStr == "true" {
                return WindowCommand(
                    action: .minimize,
                    target: appName,
                    display: display,
                    parameters: parameters
                )
            } else if let openStr = parameters["open"], openStr == "true" {
                return WindowCommand(
                    action: .open,
                    target: appName,
                    display: display,
                    parameters: parameters
                )
            } else if let focusStr = parameters["focus"], focusStr == "true" {
                return WindowCommand(
                    action: .focus,
                    target: appName,
                    display: display,
                    parameters: parameters
                )
            } else {
                // Default to focus if no specific action specified
                return WindowCommand(
                    action: .focus,
                    target: appName,
                    display: display,
                    parameters: parameters
                )
            }
        }
    }
    
    // MARK: - New Simplified Tool Converters
    
    private static func convertApplyLayout(_ input: [String: Any]) -> WindowCommand? {
        guard let layoutName = input["layout"] as? String,
              let appsString = input["apps"] as? String else {
            return nil
        }
        
        let appList = appsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let focusApp = input["focus_app"] as? String
        
        return WindowCommand(
            action: .arrange,
            target: layoutName, // Use layout name as target
            customSize: nil,
            customPosition: nil,
            parameters: [
                "apps": appList.joined(separator: ","),
                "focus_app": focusApp ?? ""
            ]
        )
    }
    
    // (convertOpenApp already defined above)
    
    private static func convertMinimizeApp(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .minimize,
            target: appName,
            customSize: nil,
            customPosition: nil
        )
    }
    
    private static func convertFocusApp(_ input: [String: Any]) -> WindowCommand? {
        guard let appName = input["app_name"] as? String else {
            return nil
        }
        
        return WindowCommand(
            action: .focus,
            target: appName,
            customSize: nil,
            customPosition: nil
        )
    }
}