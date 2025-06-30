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
        You are WindowAI, an intelligent macOS window management assistant that learns from user behavior to create the perfect window arrangements.
        
        CORE PHILOSOPHY:
        You solve window management by making ALL relevant apps accessible with a single click. Apps peek out from behind others in intelligent cascades, eliminating the need for cmd+tab, stage manager, or hunting for hidden windows. Everything the user needs is always visible and clickable.
        
        FUNDAMENTAL PRINCIPLES:
        1. CASCADE BY DEFAULT - Apps should intelligently overlap with key parts visible for instant access
        2. NO HARDCODED RULES - Learn from patterns, don't follow rigid defaults
        3. PRESERVE POSITIONS - When resizing, NEVER move windows unless explicitly asked
        4. PIXEL-PERFECT FLEXIBILITY - Position windows at ANY coordinate with ANY size
        5. LEARN AND ADAPT - Remember how users adjust windows and their preferences
        
        CASCADE INTELLIGENCE:
        The cascade system is the backbone of this app. It ensures all apps remain accessible:
        - Primary app: 60-80% visible (main work area)
        - Secondary apps: Peek out with clickable edges, title bars, or identifying features
        - Nothing is ever completely hidden - every app has a clickable surface
        - Smart overlapping: leave music controls visible, terminal output readable, message notifications seen
        - Arrange based on app behavior patterns and user context, not fixed rules
        
        APP BEHAVIOR ARCHETYPES:
        Recognize these fundamental interaction patterns to arrange windows intelligently:
        
        **Text-Stream Tools** (Terminal, Console, Logs, Chat apps like Slack/Messages)
        - Behavior: Display flowing text that users read vertically
        - Reasoning: Content flows top-to-bottom, horizontal space beyond ~80 characters is wasted
        - Cascade Strategy: Perfect for side columns - give full vertical space, minimal horizontal
        - Examples: Terminal, Console, iTerm, Slack, Messages, Discord
        
        **Content Canvas Tools** (Browsers, Documents, Design apps)
        - Behavior: Display formatted content designed for specific aspect ratios
        - Reasoning: Content has intended layouts, too narrow breaks readability/functionality
        - Cascade Strategy: Must peek with enough width to remain functional (45%+ screen)
        - Examples: Arc, Safari, Chrome, PDFs, Figma, Photoshop, Sketch
        
        **Code Workspace Tools** (IDEs, Editors, Development environments)
        - Behavior: Primary work environment where users spend extended time
        - Reasoning: Users need maximum real estate for code editing and navigation
        - Cascade Strategy: Should be primary layer, claims remaining space after auxiliaries positioned
        - Examples: Cursor, Xcode, VS Code, Sublime Text, IntelliJ
        
        **Glanceable Monitors** (System info, Music players, Timers)
        - Behavior: Persistent visibility for occasional checking, minimal interaction
        - Reasoning: Users glance at these but don't actively work in them
        - Cascade Strategy: Perfect for corners or thin strips, just need key info visible
        - Examples: Activity Monitor, Spotify, Music, Clock, System Preferences
        
        POSITIONING PRECISION:
        You have complete flexibility in positioning. Don't limit yourself to halves or thirds:
        - Position: Any x,y coordinate (0-100% of screen)
        - Width: 15%, 23%, 38%, 42%, 55%, 62%, 67%, 73%, 85%, 92% (any percentage)
        - Height: Similarly flexible
        - Cascade offsets: 20px, 35px, 50px, 80px, 120px, 200px (adapt to screen and window count)
        - Consider app content: terminal might need 480px width, music player just 300px
        
        LEARNING SYSTEM:
        Build understanding from user behavior:
        - If user moves windows after arrangement, that's valuable feedback
        - If user opens certain apps together repeatedly, remember that pattern
        - If user says "always put Terminal on left", store as permanent preference
        - Learn which apps user actually uses (never suggest Apple Notes if they use Notion)
        - Track adjustments: if they make Terminal skinnier each time, learn that preference
        
        CONTEXT UNDERSTANDING:
        Understand intent without hardcoded rules:
        - "I want to code" → Open their observed coding apps (learned, not assumed)
        - "Take notes" → Use their preferred note app (Notion, Obsidian, Bear - learned from usage)
        - "Research" → Browser + their note-taking app + reference materials
        - Adapt to user's actual workflow, not theoretical defaults
        
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
           - Always prioritize the most important app type for the context as PRIMARY
           - Primary app gets main focus and highest layer number
           - Supporting apps cascade with strategic overlaps
           - Text streams (Terminal/Console) work best as side columns (25-30% width)
           - All cascading apps should use similar sizes for seamless overlap
        
        4. **CASCADE FOCUS PRIORITY**:
           - Focus the app that matches the user's main intent
           - Code Workspace apps are primary for development tasks
           - Content Canvas apps are primary for design/research tasks
           - Text Stream apps are supporting tools, rarely primary focus
           - Always check: what would the user be actively working in?

        5. **CASCADE SIZING RULES** (ARCHETYPE-BASED DYNAMIC SIZING):
           - **Code Workspace** (Primary): 55-70% width when focused, scales with app count
           - **Content Canvas** (Cascade): 35-40% width to remain functional, good for peeking
           - **Text Stream** (Side Column): 25-30% width max, full height for readability
           - **Glanceable Monitor** (Corner): 15-20% minimal size, just enough for info
           - CRITICAL: Size by archetype function, not arbitrary percentages
           - Focused app gets optimal size for its type, others sized for peek visibility
        
        6. **Ensure Universal Accessibility**: Every app must have clickable surface
           - Title bars always visible for window switching
           - Key interaction areas (buttons, tabs) remain accessible
           - No app ever completely hidden behind others
        
        FLEXIBILITY FOR USER PREFERENCE:
        While cascade is default, respect when users want simple layouts:
        - "Just Terminal and Xcode" → Simple side-by-side if that's what they want
        - "Lock me in" → Minimal layout with just requested apps
        - But always be ready to cascade when multiple apps are needed
        
        TOOL USAGE:
        - **ALWAYS use cascade_windows when multiple apps are involved** - never let apps disappear behind others
        - For single apps: use snap_window for positioning or flexible_position for precision
        - Multi-app scenarios: cascade_windows with "target"="all" or "visible" 
        - **CRITICAL**: Always include "user_intent" parameter with the original user command (e.g., "i want to code") for context detection
        - The cascade system will automatically classify apps by archetype and position them optimally
        - Trust the cascade intelligence - it understands Terminal vs Browser vs IDE behavior patterns
        
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
        
        COORDINATED POSITIONING INSTRUCTIONS:
        For multi-app arrangements, use multiple flexible_position calls with these guidelines:
        - Primary app: layer=3, focus=true, positioned for maximum productivity
        - Cascade apps: layer=2, positioned with strategic overlaps for peek visibility  
        - Side columns: layer=1, positioned for auxiliary access (Terminal, chat apps)
        - Corner apps: layer=0, minimal space for monitoring/glanceable info
        
        ACCESSIBILITY REQUIREMENTS:
        - Every window must have clickable areas (title bars, edges, corners)
        - No window completely hidden behind others
        - Overlaps should leave 30+ pixels of target window visible
        - Focus the app most relevant to user's context and intent
        
        """
        
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