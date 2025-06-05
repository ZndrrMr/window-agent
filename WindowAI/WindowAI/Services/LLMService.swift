import Foundation

protocol LLMServiceDelegate: AnyObject {
    func llmService(_ service: LLMService, didReceiveResponse response: LLMResponse)
    func llmService(_ service: LLMService, didFailWithError error: Error)
}

class LLMService {
    weak var delegate: LLMServiceDelegate?
    private let preferences = UserPreferences.shared
    private var urlSession: URLSession
    private var claudeService: ClaudeLLMService?
    private let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
        
        setupClaudeService()
    }
    
    private func setupClaudeService() {
        // Hardcode API key for testing
        let apiKey = "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"
        claudeService = ClaudeLLMService(apiKey: apiKey)
        
        // Also update preferences
        preferences.anthropicAPIKey = apiKey
    }
    
    // MARK: - Public API
    func processCommand(_ userInput: String) async throws -> LLMResponse {
        // Always use Claude for now since it's the most capable
        return try await processWithClaude(userInput)
    }
    
    private func processWithClaude(_ userInput: String) async throws -> LLMResponse {
        guard let claude = claudeService else {
            throw LLMServiceError.invalidAPIKey
        }
        
        let context = claude.buildCurrentContext(windowManager: windowManager)
        let commands = try await claude.processCommand(userInput, context: context)
        
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
        // This method is now deprecated - use processWithClaude instead
        return try await processWithClaude(request.userInput)
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
        
        Available actions: open, move, resize, focus, arrange, close
        Available positions: left, right, top, bottom, center, top-left, top-right, bottom-left, bottom-right
        Available sizes: small, medium, large, half, quarter, three-quarters, full
        
        Response format:
        {
            "commands": [
                {"action": "open", "target": "Safari"},
                {"action": "move", "target": "Safari", "position": "right"},
                {"action": "resize", "target": "Safari", "size": "half"}
            ],
            "explanation": "Opening Safari and positioning it on the right half of the screen"
        }
        
        Context arrangements:
        - "coding": IDE, terminal, browser for docs
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
        // Always return true since we hardcoded the API key
        return true
    }
    
    func updateAPIKey(_ apiKey: String) {
        claudeService = ClaudeLLMService(apiKey: apiKey)
    }
    
    func isConfigured() -> Bool {
        return claudeService != nil
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