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
        case functionCall = "function_call"
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

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let tools: [GeminiTool]?
    let systemInstruction: GeminiSystemInstruction?
    let generationConfig: GeminiGenerationConfig
    
    enum CodingKeys: String, CodingKey {
        case contents
        case tools
        case systemInstruction = "system_instruction"
        case generationConfig = "generation_config"
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
    
    init(apiKey: String, model: String = "gemini-2.0-flash-exp") {
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
            )
        )
        
        let response = try await sendRequest(request)
        let commands = try parseCommandsFromResponse(response)
        
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
        
        You are WindowAI, an intelligent macOS window management assistant that learns from user behavior to create the perfect window arrangements.
        
        - Unless the user actively says they only want part of the screen filled, you MUST achieve 100% screen coverage collectively across all windows
        - Windows MUST collectively span entire screen dimensions (width AND height)
        - When user says "fill the whole screen", "maximize coverage", or similar → use 100% of available space
        - Expand ALL window sizes beyond typical preferences to fill screen completely
        - NO large empty areas allowed (>5% of screen unused)
        - Right edge: windows MUST extend to 100% of screen width
        - Bottom edge: windows MUST extend to 100% of screen height
        
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
        
        INTELLIGENT TOOL SELECTION:
        Choose the right tool based on what the user actually needs:
        
        **For precise control and optimization:**
        - Use `flexible_position` when you need exact positioning with specific percentages/pixels
        - Multiple `flexible_position` calls create coordinated layouts with perfect screen coverage
        - Control layer/z-index for proper window stacking (0=back, 3=front)
        
        **For simple operations:**
        - Use `resize_window` for basic sizing
        - Use `snap_window` for standard positions (left/right/corners)
        
        **For complex arrangements:**
        - Use multiple `flexible_position` calls to create coordinated layouts
        - Use archetype behavior patterns to guide intelligent positioning
        
        **Decision criteria:**
        - If layout analysis shows specific problems → use precision tools to fix them
        - If user wants "maximize coverage" → use multiple `flexible_position` calls
        - If user wants specific positions → use `flexible_position`
        - If user wants generic "arrange" → use multiple precision tools for coordinated layouts
        
        **PRECISION TOOL EXAMPLES:**
        
        For maximum screen coverage with intelligent arrangement:
        ```
        flexible_position(app_name: "Xcode", x_position: "0", y_position: "0", width: "65", height: "100", layer: 2, focus: true)
        flexible_position(app_name: "Terminal", x_position: "65", y_position: "0", width: "35", height: "60", layer: 1, focus: false)  
        flexible_position(app_name: "Arc", x_position: "65", y_position: "60", width: "35", height: "40", layer: 1, focus: false)
        ```
        
        For fixing specific layout problems:
        ```
        // If Terminal is too narrow (only 20% width):
        resize_window(app_name: "Terminal", size: "custom", custom_width: "35")
        
        // If Arc is positioned off-screen:
        snap_window(app_name: "Arc", position: "right")
        
        // If windows have poor coverage (only 60%):
        flexible_position(app_name: "MainApp", x_position: "0", y_position: "0", width: "70", height: "100", layer: 3)
        flexible_position(app_name: "SideApp", x_position: "70", y_position: "0", width: "30", height: "100", layer: 2)
        ```
        
        **PREFER PRECISION OVER GENERIC:**
        - When you can calculate exact positions for better coverage → use `flexible_position`
        - When you see specific sizing problems → use `resize_window` with custom percentages
        - When you see positioning problems → use `flexible_position`
        - Use multiple `flexible_position` calls to create intelligent cascaded arrangements
        
        **USER EXAMPLE OUTPUTS:**
        "I want to code"
        Terminal: x=65% y=3% w=34% h=97% (494x875)
        Xcode: x=-0% y=3% w=65% h=76% (940x688)
        Arc: x=0% y=15% w=60% h=85% (864x761)
        Claude: x=44% y=24% w=45% h=76% (643x686)
        
        Expected output:
        ```
        flexible_position(app_name: "Xcode", x_position: "0", y_position: "0", width: "65", height: "100", layer: "3", focus: "true")
        flexible_position(app_name: "Terminal", x_position: "65", y_position: "0", width: "35", height: "50", layer: "2", focus: "false")
        flexible_position(app_name: "Arc", x_position: "15", y_position: "20", width: "60", height: "75", layer: "1", focus: "false")
        flexible_position(app_name: "Claude", x_position: "25", y_position: "25", width: "50", height: "70", layer: "0", focus: "false")
        ```
        
        NEVER:
        - Assume fixed positions for app types
        - Change position when only size is requested
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
        
        """
        
        if let context = context {
            prompt += "\n\nCURRENT SYSTEM STATE:\n"
            prompt += "Running apps: \(context.runningApps.joined(separator: ", "))\n"
            
            // Display configuration
            prompt += "\nDISPLAY CONFIGURATION:\n"
            for (index, resolution) in context.screenResolutions.enumerated() {
                let isMain = index == 0
                prompt += "Display \(index): \(Int(resolution.width))x\(Int(resolution.height))\(isMain ? " (Main)" : "")\n"
            }
            
            // DETAILED WINDOW LAYOUT ANALYSIS
            if !context.visibleWindows.isEmpty {
                prompt += "\nCURRENT WINDOW LAYOUT:\n"
                let mainDisplay = context.screenResolutions.first ?? CGSize(width: 1440, height: 900)
                
                for window in context.visibleWindows {
                    let bounds = window.bounds
                    let widthPercent = (bounds.width / mainDisplay.width) * 100
                    let heightPercent = (bounds.height / mainDisplay.height) * 100
                    let xPercent = (bounds.origin.x / mainDisplay.width) * 100
                    let yPercent = (bounds.origin.y / mainDisplay.height) * 100
                    
                    prompt += "- \(window.appName): position (\(String(format: "%.0f", xPercent))%, \(String(format: "%.0f", yPercent))%) size \(String(format: "%.0f", widthPercent))%w × \(String(format: "%.0f", heightPercent))%h"
                    
                    if window.isMinimized {
                        prompt += " [MINIMIZED]"
                    }
                    
                    prompt += "\n"
                }
                
                // LAYOUT ANALYSIS
                prompt += "\nLAYOUT ANALYSIS:\n"
                
                // Calculate total screen coverage
                var totalCoverage: Double = 0
                var overlaps: [String] = []
                
                for i in 0..<context.visibleWindows.count {
                    let window1 = context.visibleWindows[i]
                    if window1.isMinimized { continue }
                    
                    let area1 = window1.bounds.width * window1.bounds.height
                    totalCoverage += area1
                    
                    // Check for overlaps
                    for j in (i+1)..<context.visibleWindows.count {
                        let window2 = context.visibleWindows[j]
                        if window2.isMinimized { continue }
                        
                        let intersect = window1.bounds.intersection(window2.bounds)
                        if !intersect.isEmpty {
                            overlaps.append("\(window1.appName) overlaps \(window2.appName)")
                        }
                    }
                }
                
                let screenArea = mainDisplay.width * mainDisplay.height
                let coveragePercent = min((totalCoverage / screenArea) * 100, 100)
                
                prompt += "- Screen coverage: \(String(format: "%.0f", coveragePercent))%\n"
                
                if !overlaps.isEmpty {
                    prompt += "- Window overlaps: \(overlaps.joined(separator: ", "))\n"
                }
                
                // Identify layout inefficiencies
                let visibleNonMinimized = context.visibleWindows.filter { !$0.isMinimized }
                if visibleNonMinimized.count > 1 {
                    let avgWidth = visibleNonMinimized.map { $0.bounds.width }.reduce(0, +) / Double(visibleNonMinimized.count)
                    let avgHeight = visibleNonMinimized.map { $0.bounds.height }.reduce(0, +) / Double(visibleNonMinimized.count)
                    
                    if coveragePercent < 85 {
                        prompt += "- INEFFICIENCY: Poor screen utilization (\(String(format: "%.0f", coveragePercent))% coverage)\n"
                    }
                    
                    if avgWidth < mainDisplay.width * 0.3 {
                        prompt += "- INEFFICIENCY: Windows too narrow (avg \(String(format: "%.0f", (avgWidth/mainDisplay.width)*100))% width)\n"
                    }
                    
                    if avgHeight < mainDisplay.height * 0.4 {
                        prompt += "- INEFFICIENCY: Windows too short (avg \(String(format: "%.0f", (avgHeight/mainDisplay.height)*100))% height)\n"
                    }
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
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
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