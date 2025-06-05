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
        
        INTELLIGENT WINDOW LAYOUT PRINCIPLES:
        
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
           - "I want to code": Code editor (left 2/3) + Terminal (right 1/3)
           - "Research mode": Browser (primary) + Notes (right auxiliary)
           - "Communication": Messages/Slack (right 1/3) + main work app (left 2/3)
        
        REMEMBER: These are DEFAULT behaviors. Users can override by being specific:
        - "Put terminal on the left taking half the screen" - honor this exactly
        - "I prefer my terminal full screen" - remember this preference
        - Always respect explicit user instructions over defaults
        
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
        
        if let context = context {
            prompt += "\n\nCURRENT SYSTEM STATE:\n"
            prompt += "Running apps: \(context.runningApps.joined(separator: ", "))\n"
            
            if !context.visibleWindows.isEmpty {
                let windowList = context.visibleWindows.map { "\($0.appName)" }.joined(separator: ", ")
                prompt += "Visible windows: \(windowList)\n"
            }
            
            if context.displayCount > 1 {
                prompt += "Multiple displays available (\(context.displayCount) total)\n"
            }
            
            if let firstScreen = context.screenResolutions.first {
                prompt += "Main screen: \(Int(firstScreen.width))x\(Int(firstScreen.height))\n"
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
        
        for content in response.content {
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
                }
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