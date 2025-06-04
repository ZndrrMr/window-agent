import Foundation

protocol LLMServiceDelegate: AnyObject {
    func llmService(_ service: LLMService, didReceiveResponse response: LLMResponse)
    func llmService(_ service: LLMService, didFailWithError error: Error)
}

class LLMService {
    weak var delegate: LLMServiceDelegate?
    private let preferences = UserPreferences.shared
    private var urlSession: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    func processCommand(_ userInput: String) async throws -> LLMResponse {
        let context = await buildContext()
        let request = LLMRequest(userInput: userInput, context: context)
        
        switch preferences.llmProvider {
        case .openAI:
            return try await processWithOpenAI(request)
        case .anthropic:
            return try await processWithAnthropic(request)
        case .local:
            return try await processWithLocalModel(request)
        }
    }
    
    // MARK: - Provider-Specific Implementations
    private func processWithOpenAI(_ request: LLMRequest) async throws -> LLMResponse {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let payload = buildOpenAIPayload(request)
        
        // TODO: Implement OpenAI API call
        throw LLMServiceError.notImplemented
    }
    
    private func processWithAnthropic(_ request: LLMRequest) async throws -> LLMResponse {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        let payload = buildAnthropicPayload(request)
        
        // TODO: Implement Anthropic API call
        throw LLMServiceError.notImplemented
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
            prompt += "Visible windows: \(context.visibleWindows.joined(separator: ", "))\n"
            prompt += "Screen resolution: \(Int(context.screenResolution.width))x\(Int(context.screenResolution.height))\n"
        }
        
        return prompt
    }
    
    // MARK: - Context Building
    private func buildContext() async -> LLMContext {
        // TODO: Gather current system state
        return LLMContext(
            runningApps: [],
            visibleWindows: [],
            screenResolution: .zero,
            currentWorkspace: nil
        )
    }
    
    // MARK: - Response Parsing
    private func parseOpenAIResponse(_ data: Data) throws -> LLMResponse {
        // TODO: Parse OpenAI response format
        throw LLMServiceError.parsingFailed
    }
    
    private func parseAnthropicResponse(_ data: Data) throws -> LLMResponse {
        // TODO: Parse Anthropic response format
        throw LLMServiceError.parssingFailed
    }
    
    // MARK: - Validation
    func validateConfiguration() -> Bool {
        switch preferences.llmProvider {
        case .openAI:
            return !preferences.openAIAPIKey.isEmpty
        case .anthropic:
            return !preferences.anthropicAPIKey.isEmpty
        case .local:
            return true // TODO: Check if local model is available
        }
    }
}

// MARK: - Error Types
enum LLMServiceError: Error, LocalizedError {
    case notImplemented
    case invalidAPIKey
    case parssingFailed
    case networkError(Error)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .parssingFailed:
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