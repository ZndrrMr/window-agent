import Foundation
import Cocoa

// MARK: - Claude API Data Structures
struct ClaudeMessage: Codable {
    let role: String
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let type: String
    let text: String?
    let id: String?
    let name: String?
    let input: [String: AnyCodable]?
    
    init(text: String) {
        self.type = "text"
        self.text = text
        self.id = nil
        self.name = nil
        self.input = nil
    }
    
    init(toolUse: LLMToolUse) {
        self.type = "tool_use"
        self.text = nil
        self.id = toolUse.id
        self.name = toolUse.name
        self.input = toolUse.input
    }
}

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let temperature: Double
    let system: String
    let messages: [ClaudeMessage]
    let tools: [LLMTool]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case temperature
        case system
        case messages
        case tools
    }
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Claude LLM Service
class ClaudeLLMService {
    
    private let apiKey: String
    private let model: String
    private let urlSession: URLSession
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String, model: String = "claude-3-5-sonnet-20241022") {
        self.apiKey = apiKey
        self.model = model
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 120.0
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    func processCommand(_ userInput: String, context: LLMContext? = nil) async throws -> [WindowCommand] {
        print("\n🤖 USER COMMAND: \"\(userInput)\"")
        
        let systemPrompt = buildSystemPrompt(context: context)
        let userMessage = ClaudeMessage(role: "user", content: [ClaudeContent(text: userInput)])
        
        let request = ClaudeRequest(
            model: model,
            maxTokens: 1000,
            temperature: 0.1, // Low temperature for more deterministic function calling
            system: systemPrompt,
            messages: [userMessage],
            tools: WindowManagementTools.allTools
        )
        
        let response = try await sendRequest(request)
        return try parseCommandsFromResponse(response)
    }
    
    // MARK: - System Prompt
    private func buildSystemPrompt(context: LLMContext?) -> String {
        // Get intelligent pattern hints
        let patternHints = buildPatternHints(context: context)
        var prompt = """
        You are WindowAI, an intelligent macOS window management assistant. Your job is to help users control their windows using natural language commands.
        
        CAPABILITIES:
        - Move, resize, and position windows with precision
        - Open applications and arrange them optimally
        - Create workspace layouts for different contexts (coding, writing, research, etc.)
        - Focus, minimize, and maximize windows
        - Smart snapping with automatic sizing
        
        GUIDELINES:
        1. Always use the provided tools for window management operations
        2. Be intelligent about app names - "Chrome" maps to "Google Chrome", "VS Code" to "Visual Studio Code", etc.
        3. When users say "left/right half" use snap_window with position "left"/"right" and size "half"
        4. For workspace arrangements, use arrange_workspace with the appropriate context
        5. If an app isn't running, use open_app first, then position it
        6. Default to "optimal" size unless user specifies otherwise
        7. Use multiple tool calls for complex requests (e.g., "open Safari and Terminal side by side")
        8. Consider CASCADE layouts as the default for multiple windows - they provide better visibility and access
        9. CRITICAL: When user requests changes to multiple windows in one command, you MUST generate separate tool calls for each window. For example: "put messages in top right, make terminal tall, center arc browser" requires THREE tool calls, not one.
        
        MULTI-DISPLAY HANDLING:
        - Displays are numbered: 0 = main/primary display, 1 = second display, etc.
        - When users say "external monitor", "second screen", "other display" → use display: 1
        - When users say "main screen", "primary display", "laptop screen" → use display: 0
        - "Move to left display" or "right monitor" → determine based on physical arrangement in context
        - If no display is specified, use the display where the window currently exists
        - For new windows (open_app), default to main display unless specified
        - Users can say things like: "put Safari on my external monitor" → use display: 1
        
        INTELLIGENT WINDOW LAYOUT PRINCIPLES:
        
        CASCADE VS TILED LAYOUTS:
        - CASCADE is often better for 3+ windows, providing partial visibility of all apps
        - TILED works well for 2 windows or when users need maximum workspace
        - On ULTRAWIDE screens, you can fit more tiled windows effectively
        - On LAPTOP screens, cascade helps maximize limited space
        
        CASCADE POSITIONING:
        - Primary window (most important) should be 60-80% visible
        - Secondary windows should have title bars and key controls visible
        - Use intelligent offsets based on screen size and window count
        - Smaller offsets on laptops, larger on desktop displays
        
        1. TERMINAL WINDOWS:
           - Default: Position on the right side, taking up 1/3 of the screen width
           - Terminals benefit from vertical space more than horizontal space
           - Most terminal content (logs, code output) flows vertically
           - Width of 80-100 characters is usually sufficient
           - Example: snap_window with position "right" and size "third"
        
        2. CODE EDITORS (Cursor, VS Code, Xcode):
           - Default: Primary focus window, taking up left 2/3 of screen
           - Need more horizontal space for code + file explorer
           - When paired with terminal, use snap_window with position "left" and size "two_thirds"
        
        3. COMMUNICATION APPS (Messages, Slack, Discord):
           - Default: Right side auxiliary window, narrow layout
           - Can be partially visible - user just needs to see new messages
           - Use smaller widths (1/3 or 1/4 of screen)
        
        4. BROWSERS:
           - Default: Primary focus window for most tasks
           - For development docs: Can share space with code editor
           - Flexible sizing based on content
        
        5. CONTEXT-AWARE ARRANGEMENTS:
           When users express intent to work in a context:
           
           For "I want to code" or similar coding requests:
           - PREFER individual snap_window commands for precise control:
             1. snap_window target="Cursor" position="left" size="two_thirds"
             2. snap_window target="Terminal" position="right" size="third"
           - This gives users visibility into exactly what's happening
           - Only use arrange_workspace("coding") for complex multi-app setups
           
           For other contexts:
           - "Research mode": Browser (primary) + Notes (right auxiliary)
           - "Communication": Messages/Slack (right 1/3) + main work app (left 2/3)
        
        REMEMBER: These are DEFAULT behaviors. Users can override by being specific:
        - "Put terminal on the left taking half the screen" - honor this exactly
        - "I prefer my terminal full screen" - remember this preference
        - Always respect explicit user instructions over defaults
        
        TOOL SELECTION GUIDANCE:
        - Use individual snap_window/open_app commands when:
          • User mentions specific apps and positions
          • Simple 2-3 app arrangements
          • User wants visibility into exact actions
        - Use arrange_workspace only when:
          • User explicitly mentions "workspace" or "environment"
          • Complex multi-app setups (4+ apps)
          • User references a known workspace by name
        
        CONTEXT MEANINGS:
        - "coding": Development environment (IDE + terminal in smart layout)
        - "writing": Focused writing (text editor, minimal distractions)
        - "research": Information gathering (browser, notes, references)
        - "communication": Messages, email, video calls
        - "design": Creative work (design tools, inspiration)
        - "focus": Minimize distractions, one main app
        - "presentation": Large windows, clean layout
        - "cleanup": Organize all windows neatly
        """
        
        // Add user-specific preferences if any exist
        prompt += UserLayoutPreferences.shared.generatePreferenceString()
        
        // Add intelligent pattern hints
        prompt += patternHints
        
        if let context = context {
            prompt += "\n\nCURRENT SYSTEM STATE:\n"
            prompt += "Running apps: \(context.runningApps.joined(separator: ", "))\n"
            
            if !context.visibleWindows.isEmpty {
                let windowList = context.visibleWindows.map { "\($0.appName)" }.joined(separator: ", ")
                prompt += "Visible windows: \(windowList)\n"
            }
            
            // Display configuration
            prompt += "\nDISPLAY CONFIGURATION:\n"
            for (index, resolution) in context.screenResolutions.enumerated() {
                let isMain = index == 0
                prompt += "Display \(index): \(Int(resolution.width))x\(Int(resolution.height))\(isMain ? " (Main)" : "")\n"
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
    private func sendRequest(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        guard let url = URL(string: baseURL) else {
            throw ClaudeLLMError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
            
            // Debug: Print only user message
            if let jsonObj = try? JSONSerialization.jsonObject(with: requestData) as? [String: Any],
               let messages = jsonObj["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let content = firstMessage["content"] as? [[String: Any]],
               let textContent = content.first?["text"] as? String {
                // User input already printed above
            }
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeLLMError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw ClaudeLLMError.apiError(message)
                }
                throw ClaudeLLMError.httpError(httpResponse.statusCode)
            }
            
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return claudeResponse
            
        } catch let error as ClaudeLLMError {
            throw error
        } catch {
            throw ClaudeLLMError.networkError(error)
        }
    }
    
    // MARK: - Response Parsing
    private func parseCommandsFromResponse(_ response: ClaudeResponse) throws -> [WindowCommand] {
        var commands: [WindowCommand] = []
        
        print("\n📋 CLAUDE'S TOOL CALLS:")
        print("  Total content blocks: \(response.content.count)")
        
        for (index, content) in response.content.enumerated() {
            print("  Content block \(index + 1): type=\(content.type)")
            
            if content.type == "tool_use",
               let id = content.id,
               let name = content.name,
               let input = content.input {
                
                // Print the tool call
                var inputStr = "("
                for (key, value) in input {
                    if inputStr.count > 1 { inputStr += ", " }
                    inputStr += "\(key): \"\(value.value)\""
                }
                inputStr += ")"
                print("  → \(name)\(inputStr)")
                
                let toolUse = LLMToolUse(id: id, name: name, input: input)
                
                if let command = ToolToCommandConverter.convertToolUse(toolUse) {
                    commands.append(command)
                    print("    ✓ Command added to list (total: \(commands.count))")
                } else {
                    print("    ✗ Failed to convert tool use to command")
                }
            } else if let text = content.text {
                print("    Text: \(text)")
            }
        }
        
        if commands.isEmpty {
            // If no tool calls were made, extract any text response
            let textResponses = response.content.compactMap { $0.text }.joined(separator: " ")
            if !textResponses.isEmpty {
                print("  ❌ No tool calls, just text: \(textResponses)")
                throw ClaudeLLMError.noToolsUsed(textResponses)
            } else {
                print("  ❌ No commands generated")
                throw ClaudeLLMError.noCommandsGenerated
            }
        }
        
        return commands
    }
    
    // MARK: - Pattern Hints
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
    
    // MARK: - Context Building
    func buildCurrentContext(windowManager: WindowManager) -> LLMContext {
        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName }
            .filter { !["Dock", "SystemUIServer", "WindowServer"].contains($0) }
        
        let allWindows = windowManager.getAllWindows()
        let visibleWindows = allWindows.map { window in
            LLMContext.WindowSummary(
                title: window.title,
                appName: window.appName,
                bounds: window.bounds,
                isMinimized: !windowManager.isWindowVisible(window),
                displayIndex: 0 // TODO: Calculate actual display index
            )
        }
        
        let screenResolutions = NSScreen.screens.map { $0.frame.size }
        
        return LLMContext(
            runningApps: runningApps,
            visibleWindows: visibleWindows,
            screenResolutions: screenResolutions,
            currentWorkspace: nil,
            displayCount: NSScreen.screens.count,
            userPreferences: nil
        )
    }
}

// MARK: - Error Types
enum ClaudeLLMError: Error, LocalizedError {
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
            return "Invalid response from Claude API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "Claude API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noToolsUsed(let response):
            return "Claude responded with text instead of using tools: \(response)"
        case .noCommandsGenerated:
            return "No window management commands were generated"
        case .parsingError(let message):
            return "Error parsing response: \(message)"
        }
    }
}