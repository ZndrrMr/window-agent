import Foundation

protocol LLMServiceDelegate: AnyObject {
    func llmService(_ service: LLMService, didReceiveResponse response: LLMResponse)
    func llmService(_ service: LLMService, didFailWithError error: Error)
}

class LLMService {
    weak var delegate: LLMServiceDelegate?
    private let preferences = UserPreferences.shared
    private var urlSession: URLSession
    private var geminiService: GeminiLLMService?
    private let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
        
        setupGeminiService()
    }
    
    private func setupGeminiService() {
        // Use provided API key
        let apiKey = "YOUR_GEMINI_API_KEY_HERE"
        geminiService = GeminiLLMService(apiKey: apiKey)
        
        // Also update preferences
        preferences.geminiAPIKey = apiKey
    }
    
    // MARK: - Public API
    func processCommand(_ userInput: String, context: LLMContext? = nil) async throws -> LLMResponse {
        // Use Gemini 2.0 Flash for fastest responses
        return try await processWithGemini(userInput, context: context)
    }
    
    private func processWithGemini(_ userInput: String, context: LLMContext? = nil) async throws -> LLMResponse {
        guard let gemini = geminiService else {
            throw LLMServiceError.invalidAPIKey
        }
        
        let commands = try await gemini.processCommand(userInput, context: context)
        
        return LLMResponse(
            commands: commands,
            explanation: "Processed \(commands.count) window management command(s)",
            confidence: 0.95,
            processingTime: nil
        )
    }
    
    
    // MARK: - Provider-Specific Implementations
    private func processWithOpenAI(_ request: LLMRequest) async throws -> LLMResponse {
        _ = URL(string: "https://api.openai.com/v1/chat/completions")!
        _ = buildOpenAIPayload(request)
        
        // TODO: Implement OpenAI API call
        throw LLMServiceError.notImplemented
    }
    
    private func processWithAnthropic(_ request: LLMRequest) async throws -> LLMResponse {
        // This method is now deprecated - use processWithGemini instead
        return try await processWithGemini(request.userInput)
    }
    
    private func processWithLocalModel(_ request: LLMRequest) async throws -> LLMResponse {
        // TODO: Implement local model processing
        throw LLMServiceError.notImplemented
    }
    
    // MARK: - Payload Building
    private func buildOpenAIPayload(_ request: LLMRequest) -> [String: Any] {
        return [
            "model": preferences.model,
            "messages": [
                ["role": "system", "content": getSystemPrompt()],
                ["role": "user", "content": buildUserPrompt(request)]
            ],
            "max_tokens": preferences.maxTokens,
            "temperature": preferences.temperature,
            "response_format": ["type": "json_object"]
        ]
    }
    
    private func buildAnthropicPayload(_ request: LLMRequest) -> [String: Any] {
        return [
            "model": preferences.model,
            "max_tokens": preferences.maxTokens,
            "temperature": preferences.temperature,
            "system": getSystemPrompt(),
            "messages": [
                ["role": "user", "content": buildUserPrompt(request)]
            ]
        ]
    }
    
    // MARK: - Prompt Engineering
    private func getSystemPrompt() -> String {
        return """
        You are a macOS window management assistant. Convert natural language commands into JSON arrays of WindowCommand objects.
        
        Available actions: open, move, resize, focus, arrange, close, stack
        Available positions: left, right, top, bottom, center, top-left, top-right, bottom-left, bottom-right
        Available sizes: small, medium, large, half, full
        
        For general window arrangement commands like "arrange my windows", "organize windows", "tidy up", or "arrange everything":
        - Use action "arrange" with target "intelligent" and parameters: {"style": "smart"}
        - This triggers the FlexibleLayoutEngine for intelligent proportional layout with 100% screen coverage
        - Windows are sized based on app archetypes with intelligent proportional sizing
        
        For workspace commands like "i want to code", "set up coding environment", or "arrange for development":
        - Use action "stack" with target "all" and parameters: {"context": "coding", "style": "smart"}
        - This creates a focus-aware layout where apps are intelligently positioned based on their role
        - The system automatically detects the primary app and arranges others as functional peek areas
        
        Response format examples:
        
        For "arrange my windows":
        {
            "commands": [
                {"action": "arrange", "target": "intelligent", "parameters": {"style": "smart"}}
            ],
            "explanation": "Arranging all windows with intelligent proportional layout"
        }
        
        For "set up coding environment":
        {
            "commands": [
                {"action": "open", "target": "Xcode"},
                {"action": "open", "target": "Terminal"},
                {"action": "open", "target": "Arc"},
                {"action": "stack", "target": "all", "parameters": {"context": "coding", "style": "smart"}}
            ],
            "explanation": "Setting up coding environment with focus-aware layout"
        }
        
        Context arrangements:
        - "coding": Uses focus-aware layout for IDE, terminal, browser
        - "writing": text editor, reference browser
        - "research": browser, notes, documents
        - "communication": messages, email, calendar
        """
    }
    
    private func buildUserPrompt(_ request: LLMRequest) -> String {
        var prompt = "User command: \(request.userInput)\n"
        
        if let context = request.context {
            prompt += "\nCurrent context:\n"
            prompt += "Running apps: \(context.runningApps.joined(separator: ", "))\n"
            let windowDescriptions = context.visibleWindows.map { "\($0.appName): \($0.title)" }
            prompt += "Visible windows: \(windowDescriptions.joined(separator: ", "))\n"
            if let firstScreen = context.screenResolutions.first {
                prompt += "Screen resolution: \(Int(firstScreen.width))x\(Int(firstScreen.height))\n"
            }
        }
        
        return prompt
    }
    
    // MARK: - Context Building
    private func buildContext() async -> LLMContext {
        // TODO: Gather current system state
        return LLMContext(
            runningApps: [],
            visibleWindows: [],
            screenResolutions: [CGSize.zero],
            currentWorkspace: nil,
            displayCount: 1,
            userPreferences: nil
        )
    }
    
    // MARK: - Response Parsing
    private func parseOpenAIResponse(_ data: Data) throws -> LLMResponse {
        // TODO: Parse OpenAI response format
        throw LLMServiceError.parsingFailed
    }
    
    private func parseAnthropicResponse(_ data: Data) throws -> LLMResponse {
        // TODO: Parse Anthropic response format
        throw LLMServiceError.parsingFailed
    }
    
    // MARK: - Validation
    func validateConfiguration() -> Bool {
        return geminiService?.validateConfiguration() ?? false
    }
    
    func updateAPIKey(_ apiKey: String) {
        preferences.geminiAPIKey = apiKey
        geminiService = GeminiLLMService(apiKey: apiKey)
    }
    
    func isConfigured() -> Bool {
        return geminiService != nil
    }
}

// MARK: - Error Types
enum LLMServiceError: Error, LocalizedError {
    case notImplemented
    case invalidAPIKey
    case parsingFailed
    case networkError(Error)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .parsingFailed:
            return "Failed to parse LLM response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Invalid response from LLM service"
        }
    }
}
