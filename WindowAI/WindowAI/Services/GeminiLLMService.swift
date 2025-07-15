import Foundation
import Cocoa

// MARK: - Gemini API Data Structures
struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let functionCall: GeminiFunctionCall?
    
    enum CodingKeys: String, CodingKey {
        case text
        case functionCall = "functionCall"
    }
    
    init(text: String) {
        self.text = text
        self.functionCall = nil
    }
    
    init(functionCall: GeminiFunctionCall) {
        self.text = nil
        self.functionCall = functionCall
    }
}

struct GeminiFunctionCall: Codable {
    let name: String
    let args: [String: GeminiValue]
}

struct GeminiValue: Codable {
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

struct GeminiTool: Codable {
    let functionDeclarations: [GeminiFunctionDeclaration]
    
    enum CodingKeys: String, CodingKey {
        case functionDeclarations = "function_declarations"
    }
}

struct GeminiFunctionDeclaration: Codable {
    let name: String
    let description: String
    let parameters: GeminiParameters
}

struct GeminiParameters: Codable {
    let type: String
    let properties: [String: GeminiProperty]
    let required: [String]
}

struct GeminiProperty: Codable {
    let type: String
    let description: String
    let `enum`: [String]?
    
    init(type: String, description: String, options: [String]? = nil) {
        self.type = type
        self.description = description
        self.`enum` = options
    }
}

struct GeminiToolConfig: Codable {
    let functionCallingConfig: GeminiFunctionCallingConfig
    
    enum CodingKeys: String, CodingKey {
        case functionCallingConfig = "function_calling_config"
    }
}

struct GeminiFunctionCallingConfig: Codable {
    let mode: String
    
    enum Mode {
        case auto
        case any
        case none
        
        var stringValue: String {
            switch self {
            case .auto: return "AUTO"
            case .any: return "ANY"
            case .none: return "NONE"
            }
        }
    }
}

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let tools: [GeminiTool]?
    let systemInstruction: GeminiSystemInstruction?
    let generationConfig: GeminiGenerationConfig
    let toolConfig: GeminiToolConfig?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case tools
        case systemInstruction = "system_instruction"
        case generationConfig = "generation_config"
        case toolConfig = "tool_config"
    }
}

struct GeminiSystemInstruction: Codable {
    let parts: [GeminiPart]
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
    }
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
    
    enum CodingKeys: String, CodingKey {
        case candidates
        case usageMetadata = "usage_metadata"
    }
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason = "finish_reason"
    }
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokenCount = "prompt_token_count"
        case candidatesTokenCount = "candidates_token_count"
        case totalTokenCount = "total_token_count"
    }
}

// MARK: - Gemini LLM Service
class GeminiLLMService {
    
    private let apiKey: String
    private let model: String
    private let urlSession: URLSession
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // Faster timeout for Gemini
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    func processCommand(_ userInput: String, context: LLMContext? = nil) async throws -> [WindowCommand] {
        print("\n🤖 USER COMMAND: \"\(userInput)\"")
        
        // Debug: Log available windows
        let windowCount = context?.visibleWindows.count ?? 0
        print("📊 AVAILABLE WINDOWS: \(windowCount) visible windows for arrangement")
        if let windows = context?.visibleWindows {
            let mainDisplay = context?.screenResolutions.first ?? CGSize(width: 1440, height: 900)
            for window in windows.prefix(10) { // Show first 10 to avoid spam
                let bounds = window.bounds
                let widthPercent = (bounds.width / mainDisplay.width) * 100
                let heightPercent = (bounds.height / mainDisplay.height) * 100
                let xPercent = (bounds.origin.x / mainDisplay.width) * 100
                let yPercent = (bounds.origin.y / mainDisplay.height) * 100
                
                print("  📱 \(window.appName): x=\(String(format: "%.0f", xPercent))% y=\(String(format: "%.0f", yPercent))% w=\(String(format: "%.0f", widthPercent))% h=\(String(format: "%.0f", heightPercent))% (\(Int(window.bounds.width))x\(Int(window.bounds.height)))")
            }
            if windows.count > 10 {
                print("  ... and \(windows.count - 10) more windows")
            }
        }
        
        let systemPrompt = buildSystemPrompt(context: context)
        print("📝 SYSTEM PROMPT LENGTH: \(systemPrompt.count) characters")
        
        // Calculate dynamic token limit based on window count
        let baseTokens = 2000
        let tokensPerWindow = context?.visibleWindows.count ?? 0 > 5 ? 400 : 200
        let calculatedTokens = baseTokens + (tokensPerWindow * (context?.visibleWindows.count ?? 1))
        let maxTokens = min(max(calculatedTokens, 2000), 8000) // Between 2000-8000 tokens
        
        let request = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: userInput)])],
            tools: convertToGeminiTools(WindowManagementTools.allTools),
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(
                temperature: 0.0,  // Zero temperature for deterministic function calling
                maxOutputTokens: maxTokens
            ),
            toolConfig: GeminiToolConfig(
                functionCallingConfig: GeminiFunctionCallingConfig(
                    mode: GeminiFunctionCallingConfig.Mode.any.stringValue
                )
            )
        )
        
        print("🔧 FUNCTION CALLING ENFORCEMENT: toolConfig.mode = ANY (forces function calls only)")
        print("🛠️  TOOL COUNT: \(WindowManagementTools.allTools.count) tools being sent")
        
        // Debug: Show tool names and parameter counts
        for tool in WindowManagementTools.allTools {
            let paramCount = tool.input_schema.properties.count
            let requiredCount = tool.input_schema.required.count
            print("   - \(tool.name): \(paramCount) parameters (\(requiredCount) required)")
        }
        
        let response = try await sendRequest(request)
        let commands = try parseCommandsFromResponse(response)
        
        // Validate command constraints and retry if needed
        if let context = context {
            let validatedCommands = try await enforceConstraints(commands, context: context, userInput: userInput, originalPrompt: systemPrompt)
            
            // Debug: Compare tool calls generated vs windows available
            print("📈 ANALYSIS: Generated \(validatedCommands.count) tool calls for \(windowCount) available windows")
            if validatedCommands.count < windowCount && windowCount > 3 {
                print("⚠️  NOTE: Only \(validatedCommands.count) windows positioned out of \(windowCount) available")
                print("   Consider if all windows should be arranged for comprehensive layout")
            }
            
            return validatedCommands
        }
        
        // Debug: Compare tool calls generated vs windows available
        print("📈 ANALYSIS: Generated \(commands.count) tool calls for \(windowCount) available windows")
        if commands.count < windowCount && windowCount > 3 {
            print("⚠️  NOTE: Only \(commands.count) windows positioned out of \(windowCount) available")
            print("   Consider if all windows should be arranged for comprehensive layout")
        }
        
        return commands
    }
    
    // MARK: - Tool Conversion
    private func convertToGeminiTools(_ tools: [LLMTool]) -> [GeminiTool] {
        let functionDeclarations = tools.map { tool in
            let properties = tool.input_schema.properties.mapValues { prop in
                GeminiProperty(
                    type: prop.type,
                    description: prop.description,
                    options: prop.enum
                )
            }
            
            return GeminiFunctionDeclaration(
                name: tool.name,
                description: tool.description,
                parameters: GeminiParameters(
                    type: "object",
                    properties: properties,
                    required: tool.input_schema.required
                )
            )
        }
        
        return [GeminiTool(functionDeclarations: functionDeclarations)]
    }
    
    // MARK: - System Prompt (Reuse existing logic)
    private func buildSystemPrompt(context: LLMContext?) -> String {
        // Get intelligent pattern hints
        let patternHints = buildPatternHints(context: context)
        var prompt = """
        CRITICAL: You MUST ALWAYS use the provided function tools. NEVER respond with just text explanations.
        
        You are WindowAI, an intelligent macOS window management assistant that uses SYMBOLIC REASONING and MATHEMATICAL VALIDATION for precise constraint satisfaction.
        
        CRITICAL CONSTRAINT: Every window MUST have at least 100x100 pixels visible (not covered by other windows).
        
        SYMBOLIC NOTATION SYSTEM:
        - Window: AppName[x,y,width,height,L#] where L# is layer (higher = front)
        - Overlap: App1∩App2 = [x,y,w,h] (intersection rectangle)
        - Visible calculation: App.visible = (width×height) - Σ(overlap_areas) = result px²
        - Constraint check: visible_area >= 10,000px² (100×100) = ✓ or ✗
        
        MATHEMATICAL VALIDATION REQUIREMENTS (MANDATORY):
        1. For EVERY window placement/movement, calculate ALL overlaps with existing windows
        2. Show visible area calculation: total_area - Σ(occluded_areas) = visible_area
        3. Verify constraint: visible_area >= 10,000px² (100×100 minimum)
        4. If constraint fails, MUST find alternative placement - NO EXCEPTIONS
        5. Layer rules: Higher layer numbers occlude lower numbers only
        6. VALIDATE BEFORE POSITIONING: Check if your intended layout satisfies all constraints
        7. If ANY window violates constraints, REPOSITION until all constraints satisfied
        
        CORE PHILOSOPHY:
        You solve window management by making ALL relevant apps accessible with a single click. Apps peek out from behind others in intelligent cascades, eliminating the need for cmd+tab, stage manager, or hunting for hidden windows. Everything the user needs is always visible and clickable. The visibility for each app when peaking from behind another should be at least 1/10 of the screen height by 1/10 of the screen width.
        
        FUNDAMENTAL PRINCIPLES:
        1. MAXIMIZE SCREEN USAGE - Fill entire screen space unless user explicitly requests minimal layouts
        2. CASCADE BY DEFAULT - Apps should intelligently overlap with key parts visible for instant access unless the user actively requests a tiled layout
        3. NO HARDCODED RULES - Learn from patterns, don't follow rigid defaults
        5. PIXEL-PERFECT FLEXIBILITY - Position windows at ANY coordinate with ANY size
        6. LEARN AND ADAPT - Remember how users adjust windows and their preferences
        
        CASCADE INTELLIGENCE:
        The cascade system is the backbone of this app. It ensures all apps remain accessible:
        - Focus app: Given prominent positioning for current work
        - Other apps: Peek out with clickable edges, title bars, or identifying features
        - Nothing is ever completely hidden - every app has a clickable surface, matter what window is currently selected
        - Smart overlapping: leave music controls visible, terminal output readable, message notifications seen
        - Arrange based on app behavior patterns and user context, not fixed rules
        
        APP BEHAVIOR ARCHETYPES:
        Recognize these fundamental interaction patterns to arrange windows intelligently:
        
        **Text-Stream Tools** (Terminal, Console, Logs, Chat apps like Slack/Messages)
        - Behavior: Display flowing text that users read vertically
        - Reasoning: Content flows top-to-bottom, but should use available space efficiently
        - Cascade Strategy: Excellent for side columns - use full vertical space, optimize horizontal within screen maximization
        - Screen Usage: Can use 25-35% width when maximizing screen coverage, more if needed to fill space
        - Examples: Terminal, Console, iTerm, Slack, Messages, Discord
        
        **Content Canvas Tools** (Browsers, Documents, Design apps)
        - Behavior: Display formatted content designed for specific aspect ratios
        - Reasoning: Content has intended layouts, but should maximize available space
        - Cascade Strategy: Use substantial width for functionality, expand to fill available space when maximizing screen usage
        - Screen Usage: Prefer 45-70% width depending on space availability and other apps present
        - Examples: Arc, Safari, Chrome, PDFs, Figma, Photoshop, Sketch
        
        **Code Workspace Tools** (IDEs, Editors, Development environments)
        - Behavior: Primary work environment where users spend extended time
        - Reasoning: Users need maximum real estate for code editing and navigation
        - Cascade Strategy: Primary layer, maximizes available space while ensuring auxiliaries remain accessible
        - Screen Usage: Claims largest portion (50-75% width) but expands to fill all available space
        - Examples: Cursor, Xcode, VS Code, Sublime Text, IntelliJ
        
        **Glanceable Monitors** (System info, Music players, Timers)
        - Behavior: Persistent visibility for occasional checking, minimal interaction
        - Reasoning: Users glance at these but don't actively work in them
        - Cascade Strategy: Efficient use of corners or edges, expand if space available for screen maximization
        - Screen Usage: Typically 15-25% width, but can use more space if it helps fill the screen completely
        - Examples: Activity Monitor, Spotify, Music, Clock, System Preferences
        
        CONFLICT RESOLUTION:
        When archetype guidance conflicts with screen utilization, ALWAYS prioritize maximizing screen usage:
        - If Browser "needs 45% width" but only 30% remains → give it 30% and ensure total coverage is 95%+
        - Screen utilization is the PRIMARY directive - archetype strategies guide HOW to use maximal space
        - Never leave empty areas unused unless explicitly requested by the user
        
        POSITIONING PRECISION:
        You have complete flexibility in positioning. Don't limit yourself to halves or thirds:
        - Position: Any x,y coordinate (0-100% of screen)
        - Width: 15%, 23%, 38%, 42%, 55%, 62%, 67%, 73%, 85%, 92% (any percentage)
        - Height: Similarly flexible
        - Cascade offsets: 20px, 35px, 50px, 80px, 120px, 200px (adapt to screen and window count)
        - Consider app content: terminal might need 480px width, music player just 300px
        
        CONTEXT UNDERSTANDING:
        Understand intent without hardcoded rules:
        - "I want to code" → Open their observed coding apps
        - "Take notes" → Use their note app
        - "Research" → Browser + their note-taking app + reference materials
        
        MULTI-DISPLAY HANDLING:
        - Display 0 = main/primary, Display 1 = external, etc.
        - Common phrases: "external monitor" → display 1, "laptop screen" → display 0
        - Preserve display when resizing, only move when explicitly requested
        
        DISPLAY-AWARE POSITIONING STRATEGIES:
        Adapt your positioning approach based on display characteristics:
        
        **Small Displays (≤1920x1080):**
        - Use more aggressive cascading (60-70% overlap)
        - Prefer narrower windows (30-40% width for supporting apps)
        - Tighter cascade offsets (20-30px)
        - Focus on essential apps only (2-3 windows max)
        - Example: "i want to code" → Terminal (25% width), Cursor (75% width with 50% overlap)
        
        **Medium Displays (1920x1080 to 2560x1440):**
        - Balanced cascading (40-50% overlap)
        - Standard window widths (35-45% for supporting apps)
        - Medium cascade offsets (40-60px)
        - Support 3-4 windows comfortably
        - Example: "i want to code" → Terminal (35% width), Cursor (65% width with 40% overlap), Arc (50% width peek)
        
        **Large Displays (≥2560x1440):**
        - Minimal cascading (20-30% overlap)
        - Wider windows (40-60% width for supporting apps)
        - Generous cascade offsets (60-100px)
        - Support 4+ windows with breathing room
        - Example: "i want to code" → Terminal (30% width), Cursor (70% width with 25% overlap), Arc (55% width peek), Spotify (25% width corner)
        
        **Ultra-wide Displays (≥3440x1440):**
        - Side-by-side arrangements preferred over cascading
        - Multiple primary zones (left 40%, center 40%, right 20%)
        - Minimal overlaps except for glanceable monitors
        - Support 5+ windows in distinct zones
        - Example: "i want to code" → Terminal (left 30%), Cursor (center 50%), Arc (right 20%), Spotify (corner 15%)
        
        **Multi-Display Strategies:**
        - Primary workspace on EXTERNAL displays (Display 1+) - external monitors are typically larger and better for main work
        - Secondary/utility tools on laptop display (Display 0) - laptop screen is smaller, perfect for auxiliary tools
        - Context-aware distribution:
          - Coding: Main IDE on external display (Display 1), Terminal/monitoring on laptop (Display 0)
          - Research: Browser on external display (Display 1), notes/references on laptop (Display 0)
          - Design: Canvas on external display (Display 1), tools/palettes on laptop (Display 0)
        - Preserve focus on external display for main tasks
        
        **Display Context Examples:**
        ```
        // Small display optimization
        flexible_position(app_name: "Cursor", x_position: "0", y_position: "0", width: "70", height: "100", layer: "3", focus: "true")
        flexible_position(app_name: "Terminal", x_position: "70", y_position: "0", width: "30", height: "100", layer: "2")
        
        // Large display optimization
        flexible_position(app_name: "Cursor", x_position: "0", y_position: "0", width: "55", height: "100", layer: "3", focus: "true")
        flexible_position(app_name: "Terminal", x_position: "55", y_position: "0", width: "25", height: "100", layer: "2")
        flexible_position(app_name: "Arc", x_position: "35", y_position: "15", width: "45", height: "70", layer: "1")
        flexible_position(app_name: "Spotify", x_position: "80", y_position: "80", width: "20", height: "20", layer: "0")
        
        // Multi-display distribution (external monitor primary)
        flexible_position(app_name: "Cursor", x_position: "0", y_position: "0", width: "100", height: "100", layer: "3", focus: "true", display: "1")
        flexible_position(app_name: "Terminal", x_position: "0", y_position: "0", width: "100", height: "50", layer: "2", display: "0")
        flexible_position(app_name: "Activity Monitor", x_position: "0", y_position: "50", width: "100", height: "50", layer: "1", display: "0")
        ```
        
        CASCADE ARRANGEMENT STRATEGY:
        When arranging multiple windows, use archetype-based positioning:
        
        1. **Identify App Archetypes**: Classify each app by its behavior pattern
        2. **Assign Cascade Roles**:
           - Text-Stream Tools → Side columns (full height, minimal width)
           - Code Workspace Tools → Primary layer (most space, but leave peek zones)
           - Content Canvas Tools → Peek layers (enough width to stay functional)
           - Glanceable Monitors → Corners or edges (minimal space, always visible)
        
        3. **Apply Functional Cascade Layout**:
           - Give the focus app appropriate prominence for the current context
           - Focus app gets main positioning and highest layer number
           - Supporting apps cascade with strategic overlaps
           - Text streams (Terminal/Console) work best as side columns (25-30% width)
        
        4. **CASCADE FOCUS PRIORITY**:
           - Focus the app that matches the user's main intent
           - Code Workspace apps are primary for development tasks
           - Content Canvas apps are primary for design/research tasks
           - Text Stream apps are supporting tools, rarely primary focus
           - Always check: what would the user be actively working in?
        
        6. **Ensure Universal Accessibility**: Every app must have clickable surface
           - Key interaction areas (buttons, tabs) remain accessible
           - No app ever completely hidden behind others
        
        LAYOUT ANALYSIS & PROBLEM IDENTIFICATION:
        Before choosing tools, analyze the current window layout:
        
        **Screen Coverage Analysis:**
        - Target: 90-100% screen coverage for maximum efficiency
        - Identify wasted space (large gaps, tiny windows)
        - Look for windows positioned off-screen or overlapping poorly
        
        **Window Sizing Problems:**
        - Windows too narrow (< 30% width) may need expansion
        - Windows too short (< 40% height) may need expansion
        - Oversized windows (> 90% single dimension) may need smart sizing
        
        **Positioning Problems:**
        - Windows clustered in one area leaving empty space
        - Windows positioned at extreme edges (> 90% x/y) may be off-screen
        - Poor cascade/overlap arrangements hiding important content
        
        **Multi-Window Conflicts:**
        - Identify which windows overlap and whether it's efficient
        - Look for windows that could be better positioned relative to each other
        - Find opportunities to create better visual hierarchy
        
        **Solution Strategy:**
        1. Position each app to maximize its utility while coordinating with others
        2. Arrange all windows to be accessible and properly visible
        3. Use precise positioning to eliminate wasted space
        4. Ensure every app has clickable surface area
        
        FLEXIBILITY FOR USER PREFERENCE:
        While cascade is default, respect when users want simple layouts:
        - "Just Terminal and Xcode" → Simple side-by-side if that's what they want
        - "Lock me in" → Minimal layout with just requested apps
        - But always be ready to cascade when multiple apps are needed
        
        COMPREHENSIVE WINDOW MANAGEMENT:
        When users request window arrangement (like "rearrange my windows"), operate on ALL visible windows unless specifically limited:
        - Use `flexible_position` calls for every visible window that needs positioning
        - Create coordinated layouts where each window has its optimal position and size
        - Ensure every window is accessible and properly positioned for its function
        - Don't limit yourself to just a few "key" windows - arrange the complete workspace
        
        UNIFIED TOOL USAGE:
        Use `flexible_position` for ALL window operations:
        
        **For window positioning:**
        - Use `flexible_position` with precise percentage coordinates (e.g., x_position: "25", y_position: "10")
        - Set width and height as percentages (e.g., width: "50", height: "75")
        - Control layer/z-index for proper window stacking (0=back, 3=front)
        - Set focus: true for the primary window the user should be working in
        
        **For window lifecycle (opening, minimizing, focusing):**
        - Use `flexible_position` with lifecycle parameters:
          - open: true → Launch app if not running
          - minimize: true → Minimize window, minimize: false → Ensure not minimized
          - focus: true → Focus window (brings to front, activates app)
          - restore: true → Restore/unminimize window before positioning
        
        **For simple operations like "focus Safari":**
        - Use `flexible_position` with just app_name and focus: true
        - No positioning coordinates needed for focus-only operations
        
        **For complex arrangements:**
        - Use multiple `flexible_position` calls to create coordinated layouts
        - Use archetype behavior patterns to guide intelligent positioning
        - Every window that needs to be arranged should get its own `flexible_position` call
        
        **Decision criteria:**
        - Always use `flexible_position` for any window operation
        - Use coordinates when positioning is needed
        - Use lifecycle parameters when opening/minimizing/focusing is needed
        - Use `close_app` only when user specifically wants to close/quit an app
        - When making sweeping changes (ie. things that you think should take up the whole screen like 'research' or 'open safari in fullscreen' or 'i want to code') -> Minimize everything that wasn't part of your action that is currently open first
        - When making finite changes (ie. things that don't take up the whole screen like 'move terminal to the right 1/3' or 'put claude in the top right quarter and terminal in the bottom right quarter') -> Do not minimize everything that wasn't part of the action

        **EXAMPLES TO BASE ACTIONS OFF OF:**

        Before getting into examples here are some general requirements that you will see in the examples:
        - EVERY window should have at least a 100px by 100px area where no other window is underneath it or covering it
        - 100 percent of the screen must be filled, no matter what
        - If you cannot fit windows into a screen without sacrificing 1 or more of these conditions, minimize windows that don't seem as important until they can fit
        
        User prompt:
        "code"
        
        Expected output:
        "toolCalls":["flexible_position(\n    app_name: \"Terminal\",\n    x_position: \"66.7\",\n    y_position: \"2.8\",\n    width: \"33.3\",\n    height: \"97.2\",\n    layer: \"3\",\n    focus: \"true\"\n)","flexible_position(\n    app_name: \"Xcode\",\n    x_position: \"-0.0\",\n    y_position: \"2.8\",\n    width: \"66.7\",\n    height: \"88.3\",\n    layer: \"2\",\n    focus: \"false\"\n)","flexible_position(\n    app_name: \"Arc\",\n    x_position: \"0.0\",\n    y_position: \"12.6\",\n    width: \"66.7\",\n    height: \"87.4\",\n    layer: \"1\",\n    focus: \"false\"\n)"]
        
        User prompt:
        "research"
        
        Expected output:
        "toolCalls":["flexible_position(\n    app_name: \"Arc\",\n    x_position: \"-0.0\",\n    y_position: \"2.8\",\n    width: \"49.9\",\n    height: \"97.2\",\n    layer: \"2\",\n    focus: \"false\"\n)","flexible_position(\n    app_name: \"Claude\",\n    x_position: \"50.0\",\n    y_position: \"15.8\",\n    width: \"50.0\",\n    height: \"84.2\",\n    layer: \"1\",\n    focus: \"false\"\n)","flexible_position(\n    app_name: \"Notion\",\n    x_position: \"50.0\",\n    y_position: \"2.8\",\n    width: \"50.0\",\n    height: \"84.6\",\n    layer: \"0\",\n    focus: \"false\"\n)"]
        
        User prompt:
        "focus Safari"
        
        Expected output:
        "toolCalls":["flexible_position(\n    app_name: \"Safari\",\n    focus: \"true\"\n)"]
        
        User prompt:
        "minimize all windows"
        
        Expected output:
        "toolCalls":["flexible_position(\n    app_name: \"Terminal\",\n    minimize: \"true\"\n)","flexible_position(\n    app_name: \"Xcode\",\n    minimize: \"true\"\n)","flexible_position(\n    app_name: \"Arc\",\n    minimize: \"true\"\n)"]
        Note for "minimize all windowsm":
        Expected: Only minimize currently visible windows
        WRONG: Don't scan entire system for every possible app"
        
        NEVER:
        - Assume fixed positions for app types
        - Suggest apps the user doesn't use
        - Limit yourself to predetermined layouts
        """
        
        // Add user-specific preferences if any exist
        prompt += UserLayoutPreferences.shared.generatePreferenceString()
        
        // Add user instructions from natural language preferences
        prompt += UserInstructionParser.shared.generateInstructionString()
        
        // Add intelligent pattern hints
        prompt += patternHints
        
        // Add app archetype classifications for current apps
        if let context = context, !context.runningApps.isEmpty {
            prompt += "\n\nAPP ARCHETYPE CLASSIFICATIONS:\n"
            for app in context.runningApps {
                let archetype = AppArchetypeClassifier.shared.classifyApp(app)
                prompt += "- \(app): \(archetype.displayName) (\(archetype.cascadeStrategy))\n"
            }
        }
        
        // Add user preference data from corrections
        let userPrefs = UserPreferenceTracker.shared.generatePreferenceSummary(context: "coding")
        if !userPrefs.isEmpty {
            prompt += "\n\(userPrefs)"
        }
        
        // Add coordinated positioning instructions
        prompt += """
        
        REMEMBER: SCREEN UTILIZATION IS IMPORTANT - expand all windows to achieve 100% coverage!
        
        FUNCTION CALLING REQUIREMENTS:
        - ALWAYS use the provided function tools for ANY window management request
        - NEVER explain what you will do - just use the functions immediately
        - For "move terminal to the left" → call snap_window(app_name: "Terminal", position: "left")
        - For "resize Arc bigger" → call resize_window(app_name: "Arc", size: "large")
        - For positioning commands → use flexible_position for precise control
        - MANDATORY: Every user request MUST result in function calls, not text responses
        
        CONSTRAINT ENFORCEMENT PROTOCOL:
        1. BEFORE making ANY flexible_position calls, perform mathematical validation
        2. If ANY window would violate the 100×100px constraint, REJECT that layout
        3. Find alternative positions that satisfy ALL constraints
        4. NEVER proceed with invalid layouts - constraints are NON-NEGOTIABLE
        5. If no valid layout exists, minimize less important windows until constraints satisfied
        
        VALIDATION EXAMPLES (MANDATORY PROCESS):
        
        Example 1: Valid placement
        Current: Safari[0,0,400,300,L1]
        Action: Place Terminal[350,250,300,200,L2]
        
        VALIDATION STEPS:
        1. Check overlap: Safari∩Terminal = [350,250,50,50]
        2. Calculate visible areas:
           - Safari.visible = (400×300) - (50×50) = 120,000 - 2,500 = 117,500px² ✓
           - Terminal.visible = 300×200 = 60,000px² ✓
        3. Both > 10,000px² → VALID placement
        
        Example 2: Invalid placement requiring correction
        Current: Finder[0,0,150,150,L1]
        Action: Place Chrome[0,0,200,200,L2]
        
        VALIDATION STEPS:
        1. Check overlap: Finder∩Chrome = [0,0,150,150] (complete overlap)
        2. Calculate visible areas:
           - Finder.visible = (150×150) - (150×150) = 22,500 - 22,500 = 0px² ✗
           - Chrome.visible = 200×200 = 40,000px² ✓
        3. Finder has 0px² visible → INVALID placement
        4. ALTERNATIVE: Move Chrome to [100,100,200,200,L2]
           - New overlap: [100,100,50,50]
           - Finder.visible = 22,500 - 2,500 = 20,000px² ✓
        
        Example 3: Multi-window constraint validation
        Current: Arc[0,0,800,600,L1], Terminal[400,300,400,300,L2]
        Action: Place Cursor[200,150,600,450,L3]
        
        VALIDATION STEPS:
        1. Calculate overlaps:
           - Arc∩Cursor = [200,150,600,450] = 270,000px²
           - Terminal∩Cursor = [400,300,400,300] = 120,000px²
        2. Calculate visible areas:
           - Arc.visible = (800×600) - (600×450) = 480,000 - 270,000 = 210,000px² ✓
           - Terminal.visible = (400×300) - (400×300) = 120,000 - 120,000 = 0px² ✗
           - Cursor.visible = 600×450 = 270,000px² ✓
        3. Terminal violates constraint → REPOSITION REQUIRED
        4. ALTERNATIVE: Move Cursor to [200,0,600,400,L3]
           - Arc∩Cursor = [200,0,600,400] = 240,000px²
           - Terminal∩Cursor = [400,300,400,100] = 40,000px²
           - Arc.visible = 480,000 - 240,000 = 240,000px² ✓
           - Terminal.visible = 120,000 - 40,000 = 80,000px² ✓
           - Cursor.visible = 600×400 = 240,000px² ✓
        
        CRITICAL: You MUST perform this validation for EVERY window arrangement. If ANY window violates the 100×100px constraint, you MUST find an alternative layout.
        
        """
        
        if let context = context {
            prompt += "\n\nCURRENT SYSTEM STATE:\n"
            prompt += "Running apps: \(context.runningApps.joined(separator: ", "))\n"
            
            // Display configuration with optimization hints
            prompt += "\nDISPLAY CONFIGURATION:\n"
            for (index, resolution) in context.screenResolutions.enumerated() {
                let isMain = index == 0
                let width = Int(resolution.width)
                let height = Int(resolution.height)
                
                // Add display-specific optimization hints
                var displayHint = ""
                if width <= 1920 && height <= 1080 {
                    displayHint = " → Small display: use aggressive cascading (60-70% overlap), narrow windows (30-40% width)"
                } else if width <= 2560 && height <= 1440 {
                    displayHint = " → Medium display: balanced cascading (40-50% overlap), standard windows (35-45% width)"
                } else if width >= 3440 && height <= 1600 {
                    displayHint = " → Ultra-wide display: prefer side-by-side arrangements, minimal overlaps"
                } else {
                    displayHint = " → Large display: minimal cascading (20-30% overlap), wider windows (40-60% width)"
                }
                
                prompt += "Display \(index): \(width)x\(height)\(isMain ? " (Main)" : "")\(displayHint)\n"
            }
            
            // SYMBOLIC WINDOW LAYOUT ANALYSIS WITH CONSTRAINT VALIDATION
            if !context.visibleWindows.isEmpty {
                prompt += "\nCURRENT WINDOW LAYOUT:\n"
                
                // Convert to WindowState objects for symbolic analysis
                let windowStates = WorkspaceAnalyzer.shared.convertToWindowStates(context.visibleWindows)
                let validator = ConstraintValidator.shared
                let validation = validator.validateConstraints(windows: windowStates)
                
                // Display windows with symbolic notation
                for window in windowStates.sorted(by: { $0.layer > $1.layer }) {
                    let bounds = window.frame
                    let displayIndex = window.displayIndex
                    
                    // Use the correct display for percentage calculations
                    let displayResolution = (displayIndex >= 0 && displayIndex < context.screenResolutions.count) 
                        ? context.screenResolutions[displayIndex] 
                        : (context.screenResolutions.first ?? CGSize(width: 1440, height: 900))
                    
                    let widthPercent = (bounds.width / displayResolution.width) * 100
                    let heightPercent = (bounds.height / displayResolution.height) * 100
                    
                    prompt += "- \(window.symbolicNotation) - \(String(format: "%.0f", widthPercent))%w × \(String(format: "%.0f", heightPercent))%h"
                    
                    if window.isMinimized {
                        prompt += " [MINIMIZED]"
                    }
                    
                    prompt += "\n"
                }
                
                // Add overlap analysis
                if !validation.overlaps.isEmpty {
                    prompt += "\nOVERLAP ANALYSIS:\n"
                    var processedPairs: Set<String> = []
                    
                    for (_, windowOverlaps) in validation.overlaps {
                        for overlap in windowOverlaps {
                            let pairKey = [overlap.window1, overlap.window2].sorted().joined(separator: "-")
                            
                            if !processedPairs.contains(pairKey) {
                                prompt += "- \(overlap.symbolicNotation)\n"
                                processedPairs.insert(pairKey)
                            }
                        }
                    }
                }
                
                // Add constraint validation results
                if !validation.violations.isEmpty {
                    prompt += "\nCONSTRAINT VIOLATIONS:\n"
                    for violation in validation.violations {
                        prompt += "- \(violation.window): \(Int(violation.actualArea))px² visible (need \(Int(violation.requiredArea))px²) - MUST FIX\n"
                    }
                } else {
                    prompt += "\nCONSTRAINT STATUS: ✓ All windows satisfy 100x100px visibility requirement\n"
                }
            }
            
            if context.displayCount > 1 {
                prompt += "\nWindows by display:\n"
                for window in context.visibleWindows {
                    prompt += "- \(window.appName) is on display \(window.displayIndex)\n"
                }
            }
        }
        
        return prompt
    }
    
    // MARK: - Network Request
    private func sendRequest(_ request: GeminiRequest) async throws -> GeminiResponse {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiLLMError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("en", forHTTPHeaderField: "Accept-Language")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
            
            // DEBUG: Print the exact request being sent
            print("\n🔍 GEMINI REQUEST DEBUG:")
            print("URL: \(urlString)")
            print("Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            print("Request Body Size: \(requestData.count) bytes")
            
            if let requestJson = String(data: requestData, encoding: .utf8) {
                print("REQUEST JSON (first 2000 chars):")
                let truncated = requestJson.count > 2000 ? String(requestJson.prefix(2000)) + "..." : requestJson
                print(truncated)
            }
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            // DEBUG: Print the response
            print("\n📥 GEMINI RESPONSE DEBUG:")
            if let responseJson = String(data: data, encoding: .utf8) {
                print("Response Size: \(data.count) bytes")
                print("Response JSON (first 1000 chars):")
                let truncated = responseJson.count > 1000 ? String(responseJson.prefix(1000)) + "..." : responseJson
                print(truncated)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiLLMError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw GeminiLLMError.apiError(message)
                }
                throw GeminiLLMError.httpError(httpResponse.statusCode)
            }
            
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return geminiResponse
            
        } catch let error as GeminiLLMError {
            throw error
        } catch {
            throw GeminiLLMError.networkError(error)
        }
    }
    
    // MARK: - Response Parsing
    private func parseCommandsFromResponse(_ response: GeminiResponse) throws -> [WindowCommand] {
        var commands: [WindowCommand] = []
        
        print("\n📋 GEMINI'S FUNCTION CALLS:")
        print("  Total candidates: \(response.candidates.count)")
        
        guard let firstCandidate = response.candidates.first else {
            throw GeminiLLMError.noCommandsGenerated
        }
        
        for (index, part) in firstCandidate.content.parts.enumerated() {
            print("  Content part \(index + 1): type=\(part.functionCall != nil ? "function_call" : "text")")
            
            if let functionCall = part.functionCall {
                // Print the function call
                var inputStr = "("
                for (key, value) in functionCall.args {
                    if inputStr.count > 1 { inputStr += ", " }
                    inputStr += "\(key): \"\(value.value)\""
                }
                inputStr += ")"
                print("  → \(functionCall.name)\(inputStr)")
                
                // Convert to LLMToolUse format
                let toolUseInput = functionCall.args.mapValues { AnyCodable($0.value) }
                let toolUse = LLMToolUse(
                    id: UUID().uuidString,
                    name: functionCall.name,
                    input: toolUseInput
                )
                
                if let command = ToolToCommandConverter.convertToolUse(toolUse) {
                    commands.append(command)
                    print("    ✓ Command added to list (total: \(commands.count))")
                } else {
                    print("    ✗ Failed to convert function call to command")
                }
            } else if let text = part.text {
                print("    Text: \(text)")
            }
        }
        
        if commands.isEmpty {
            // If no function calls were made, extract any text response
            let textResponses = firstCandidate.content.parts.compactMap { $0.text }.joined(separator: " ")
            if !textResponses.isEmpty {
                print("  ❌ FUNCTION CALLING FAILED: Gemini responded with text instead of using tools")
                print("  📝 Text response: \(textResponses)")
                print("  🔧 HINT: The model should have called snap_window, flexible_position, or other tools")
                throw GeminiLLMError.noToolsUsed("Gemini generated text explanation instead of function calls: \(textResponses)")
            } else {
                print("  ❌ No commands generated")
                throw GeminiLLMError.noCommandsGenerated
            }
        }
        
        return commands
    }
    
    // MARK: - Pattern Hints (Reuse existing logic)
    private func buildPatternHints(context: LLMContext?) -> String {
        guard let context = context else { return "" }
        
        let patternManager = IntelligentPatternManager.shared
        let screenConfig = ScreenConfiguration.current
        let activeApps = context.runningApps
        
        // Create user context from available info
        let userContext = UserContext(
            activity: nil, // Could be inferred from apps
            focusMode: false
        )
        
        // Find similar patterns
        let patterns = patternManager.findSimilarPatterns(
            to: userContext,
            screenConfig: screenConfig,
            activeApps: activeApps,
            limit: 3
        )
        
        return patternManager.generateLLMHints(from: patterns)
    }
    
    // MARK: - Configuration Validation
    func validateConfiguration() -> Bool {
        return !apiKey.isEmpty
    }
    
    // MARK: - Constraint Enforcement and Retry Logic
    private func enforceConstraints(_ commands: [WindowCommand], context: LLMContext, userInput: String, originalPrompt: String) async throws -> [WindowCommand] {
        let maxRetries = 2
        var currentCommands = commands
        
        for attempt in 0..<maxRetries {
            let validationResult = validateCommandConstraints(currentCommands, context: context)
            
            if validationResult.isValid {
                if attempt == 0 {
                    print("✅ CONSTRAINT VALIDATION PASSED: All commands satisfy 100×100px requirement")
                } else {
                    print("✅ CONSTRAINT VALIDATION PASSED: Commands fixed after \(attempt) retries")
                }
                return currentCommands
            }
            
            print("⚠️  CONSTRAINT VALIDATION FAILED (attempt \(attempt + 1)/\(maxRetries)): \(validationResult.violations.count) violations detected")
            for violation in validationResult.violations {
                print("   - \(violation)")
            }
            
            // If this is the last attempt, return the commands anyway
            if attempt == maxRetries - 1 {
                print("❌ CONSTRAINT ENFORCEMENT FAILED: Proceeding with violating commands after \(maxRetries) attempts")
                return currentCommands
            }
            
            // Retry with enhanced constraint enforcement
            print("🔄 RETRYING with enhanced constraint enforcement...")
            
            let retryPrompt = buildRetryPrompt(originalPrompt: originalPrompt, violations: validationResult.violations, context: context)
            let retryRequest = GeminiRequest(
                contents: [GeminiContent(parts: [GeminiPart(text: userInput)])],
                tools: convertToGeminiTools(WindowManagementTools.allTools),
                systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: retryPrompt)]),
                generationConfig: GeminiGenerationConfig(
                    temperature: 0.1,  // Slightly higher temperature for alternative solutions
                    maxOutputTokens: 4000
                ),
                toolConfig: GeminiToolConfig(
                    functionCallingConfig: GeminiFunctionCallingConfig(
                        mode: GeminiFunctionCallingConfig.Mode.any.stringValue
                    )
                )
            )
            
            let retryResponse = try await sendRequest(retryRequest)
            currentCommands = try parseCommandsFromResponse(retryResponse)
        }
        
        // Should not reach here due to the return in the loop
        return currentCommands
    }
    
    // Build retry prompt with specific constraint violations
    private func buildRetryPrompt(originalPrompt: String, violations: [String], context: LLMContext) -> String {
        var retryPrompt = originalPrompt
        
        retryPrompt += "\n\n🚨 CONSTRAINT VIOLATIONS DETECTED - MUST BE FIXED:\n"
        for violation in violations {
            retryPrompt += "- \(violation)\n"
        }
        
        retryPrompt += """
        
        RETRY INSTRUCTIONS:
        1. The previous layout violated the 100×100px visibility constraint
        2. You MUST find alternative positioning that satisfies ALL constraints
        3. Consider these strategies:
           - Reduce window sizes to prevent excessive overlap
           - Adjust positioning to create visible peek areas
           - Use different cascade offsets or layouts
           - Minimize less important windows if necessary
        4. VALIDATE each window's visible area before finalizing positions
        5. NO EXCEPTIONS - every window must have at least 10,000px² visible
        
        REMEMBER: Constraint satisfaction is NON-NEGOTIABLE. Find a layout that works.
        """
        
        return retryPrompt
    }
    
    // MARK: - Command Constraint Validation
    private func validateCommandConstraints(_ commands: [WindowCommand], context: LLMContext) -> CommandValidationResult {
        var violations: [String] = []
        var isValid = true
        
        // Convert current windows to WindowState objects
        let currentWindowStates = WorkspaceAnalyzer.shared.convertToWindowStates(context.visibleWindows)
        
        // Create a working copy of window states to apply commands
        var workingWindowStates = currentWindowStates
        
        // Apply each command to the working window states
        for command in commands {
            workingWindowStates = applyCommandToWindowStates(command, windowStates: workingWindowStates, context: context)
        }
        
        // Validate the final layout
        let validator = ConstraintValidator.shared
        let validation = validator.validateConstraints(windows: workingWindowStates)
        
        // Check for violations
        for violation in validation.violations {
            violations.append("\(violation.window) would have only \(Int(violation.actualArea))px² visible (needs \(Int(violation.requiredArea))px²)")
            isValid = false
        }
        
        return CommandValidationResult(isValid: isValid, violations: violations)
    }
    
    // Helper to apply a command to window states for validation
    private func applyCommandToWindowStates(_ command: WindowCommand, windowStates: [WindowState], context: LLMContext) -> [WindowState] {
        var updatedStates = windowStates
        
        // Find the window to update
        if let windowIndex = updatedStates.firstIndex(where: { $0.app == command.target }) {
            let currentWindow = updatedStates[windowIndex]
            
            // Apply the command based on its type
            switch command.action {
            case .move:
                if let customPosition = command.customPosition, let customSize = command.customSize {
                    // Calculate new frame based on display resolution
                    let displayResolution = context.screenResolutions.first ?? CGSize(width: 1440, height: 900)
                    let newFrame = CGRect(
                        x: (customPosition.x / 100) * displayResolution.width,
                        y: (customPosition.y / 100) * displayResolution.height,
                        width: (customSize.width / 100) * displayResolution.width,
                        height: (customSize.height / 100) * displayResolution.height
                    )
                    
                    // Update the window state
                    let updatedWindow = WindowState(
                        app: currentWindow.app,
                        id: currentWindow.id,
                        frame: newFrame,
                        layer: currentWindow.layer,
                        displayIndex: currentWindow.displayIndex,
                        isMinimized: false
                    )
                    
                    updatedStates[windowIndex] = updatedWindow
                }
            case .minimize:
                let updatedWindow = WindowState(
                    app: currentWindow.app,
                    id: currentWindow.id,
                    frame: currentWindow.frame,
                    layer: currentWindow.layer,
                    displayIndex: currentWindow.displayIndex,
                    isMinimized: true
                )
                updatedStates[windowIndex] = updatedWindow
            case .focus:
                // Focus doesn't change layout, so no changes needed for constraint validation
                break
            case .close:
                // Remove the window from the states
                updatedStates.remove(at: windowIndex)
            default:
                break
            }
        }
        
        return updatedStates
    }
    
    // MARK: - MINIMAL TEST METHOD
    func testMinimalFunctionCalling(_ userInput: String) async throws -> [WindowCommand] {
        print("\n🧪 MINIMAL TEST: \"\(userInput)\"")
        
        // Create minimal system prompt
        let minimalSystemPrompt = """
        You are a window management assistant. You MUST use the provided function tools.
        NEVER respond with text explanations - ONLY use function calls.
        
        For any command to move or position a window, use the snap_window function.
        
        Examples:
        - "move terminal to the left" → snap_window(app_name: "Terminal", position: "left")
        - "move arc to the right" → snap_window(app_name: "Arc", position: "right")
        """
        
        // Create minimal tool set (only snap_window)
        let minimalTool = LLMTool(
            name: "snap_window",
            description: "Snap a window to a position with automatic sizing",
            input_schema: LLMTool.ToolInputSchema(
                properties: [
                    "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                        type: "string",
                        description: "Name of the application whose window to snap"
                    ),
                    "position": LLMTool.ToolInputSchema.PropertyDefinition(
                        type: "string",
                        description: "Position to snap the window to",
                        options: ["left", "right", "top", "bottom", "center"]
                    )
                ],
                required: ["app_name", "position"]
            )
        )
        
        // Convert to Gemini format
        let geminiTools = convertToGeminiTools([minimalTool])
        
        print("🔧 MINIMAL TOOLS: \(geminiTools.count) tool groups")
        print("   - snap_window: 2 parameters (app_name, position)")
        
        // Create minimal request
        let request = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: userInput)])],
            tools: geminiTools,
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: minimalSystemPrompt)]),
            generationConfig: GeminiGenerationConfig(
                temperature: 0.0,
                maxOutputTokens: 1000  // Minimal token limit
            ),
            toolConfig: GeminiToolConfig(
                functionCallingConfig: GeminiFunctionCallingConfig(
                    mode: GeminiFunctionCallingConfig.Mode.any.stringValue
                )
            )
        )
        
        print("🎯 FORCING FUNCTION CALLS: toolConfig.mode = ANY")
        
        // Enhanced request debugging
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(request)
            
            print("\n📤 MINIMAL REQUEST DEBUG:")
            print("Size: \(requestData.count) bytes")
            
            if let requestJson = String(data: requestData, encoding: .utf8) {
                print("Full JSON Request:")
                print(requestJson)
            }
            
            // Send the request
            let response = try await sendMinimalRequest(request)
            
            // Parse response with extensive debugging
            return try parseMinimalResponse(response)
            
        } catch {
            print("❌ ENCODING ERROR: \(error)")
            throw GeminiLLMError.parsingError("Failed to encode request: \(error)")
        }
    }
    
    // MARK: - Minimal Request Sender
    private func sendMinimalRequest(_ request: GeminiRequest) async throws -> GeminiResponse {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiLLMError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("en", forHTTPHeaderField: "Accept-Language")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
            
            print("\n🌐 SENDING MINIMAL REQUEST:")
            print("URL: \(urlString)")
            print("Method: POST")
            print("Content-Type: application/json")
            print("Accept-Language: en")
            print("Body Size: \(requestData.count) bytes")
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            print("\n📥 RECEIVED MINIMAL RESPONSE:")
            print("Response Size: \(data.count) bytes")
            
            // Log raw response
            if let responseJson = String(data: data, encoding: .utf8) {
                print("RAW RESPONSE JSON:")
                print(responseJson)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiLLMError.invalidResponse
            }
            
            print("HTTP Status: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("ERROR RESPONSE: \(errorData)")
                    if let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw GeminiLLMError.apiError(message)
                    }
                }
                throw GeminiLLMError.httpError(httpResponse.statusCode)
            }
            
            // Parse the response
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return geminiResponse
            
        } catch let error as GeminiLLMError {
            throw error
        } catch {
            print("❌ NETWORK/PARSING ERROR: \(error)")
            throw GeminiLLMError.networkError(error)
        }
    }
    
    // MARK: - Minimal Response Parser
    private func parseMinimalResponse(_ response: GeminiResponse) throws -> [WindowCommand] {
        var commands: [WindowCommand] = []
        
        print("\n🔍 PARSING MINIMAL RESPONSE:")
        print("Candidates count: \(response.candidates.count)")
        
        if let usage = response.usageMetadata {
            print("Token usage: \(usage.totalTokenCount ?? 0) total")
        }
        
        guard let firstCandidate = response.candidates.first else {
            throw GeminiLLMError.noCommandsGenerated
        }
        
        print("Finish reason: \(firstCandidate.finishReason ?? "none")")
        print("Content parts count: \(firstCandidate.content.parts.count)")
        
        for (index, part) in firstCandidate.content.parts.enumerated() {
            print("\nPart \(index + 1):")
            
            if let functionCall = part.functionCall {
                print("  🎯 FUNCTION CALL FOUND!")
                print("  Function name: \(functionCall.name)")
                print("  Arguments count: \(functionCall.args.count)")
                
                // Debug each argument
                for (key, value) in functionCall.args {
                    print("    \(key): \(value.value) (type: \(type(of: value.value)))")
                }
                
                // Convert to WindowCommand
                let toolUseInput = functionCall.args.mapValues { AnyCodable($0.value) }
                let toolUse = LLMToolUse(
                    id: UUID().uuidString,
                    name: functionCall.name,
                    input: toolUseInput
                )
                
                if let command = ToolToCommandConverter.convertToolUse(toolUse) {
                    commands.append(command)
                    print("  ✅ Successfully converted to WindowCommand")
                    print("    Action: \(command.action)")
                    print("    Target: \(command.target)")
                    print("    Position: \(command.position?.rawValue ?? "none")")
                } else {
                    print("  ❌ Failed to convert function call to WindowCommand")
                }
                
            } else if let text = part.text {
                print("  📝 TEXT FOUND (this is the problem!):")
                print("    \"\(text)\"")
                print("  ⚠️  Model should have called snap_window instead of generating text")
                
            } else {
                print("  ❓ Unknown part type")
            }
        }
        
        print("\nFinal result: \(commands.count) commands generated")
        
        if commands.isEmpty {
            let textResponses = firstCandidate.content.parts.compactMap { $0.text }
            if !textResponses.isEmpty {
                let fullText = textResponses.joined(separator: " ")
                print("❌ FUNCTION CALLING FAILED - Model generated text instead of function calls")
                print("Text: \(fullText)")
                throw GeminiLLMError.noToolsUsed("Model generated text instead of function calls: \(fullText)")
            } else {
                print("❌ No function calls or text found")
                throw GeminiLLMError.noCommandsGenerated
            }
        }
        
        return commands
    }
}

// MARK: - Error Types
enum GeminiLLMError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case httpError(Int)
    case noToolsUsed(String)
    case noCommandsGenerated
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "Gemini API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noToolsUsed(let response):
            return "Gemini responded with text instead of using tools: \(response)"
        case .noCommandsGenerated:
            return "No window management commands were generated"
        case .parsingError(let message):
            return "Error parsing response: \(message)"
        }
    }
}

// MARK: - Command Validation Result
struct CommandValidationResult {
    let isValid: Bool
    let violations: [String]
}
