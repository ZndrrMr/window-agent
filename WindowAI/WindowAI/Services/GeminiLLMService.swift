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
        
        // Calculate dynamic token limit with higher allocation for output
        let promptLength = systemPrompt.count
        let estimatedPromptTokens = promptLength / 4 // Rough estimate: 4 chars per token
        let outputTokens = max(4000, min(8000, 16000 - estimatedPromptTokens)) // Ensure sufficient output tokens
        let maxTokens = outputTokens
        
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
        
        // Handle MAX_TOKENS error with retry
        if let candidate = response.candidates.first,
           candidate.finishReason == "MAX_TOKENS" {
            print("⚠️  MAX_TOKENS reached - retrying with reduced context")
            return try await retryWithReducedContext(userInput: userInput, context: context, originalTokens: maxTokens)
        }
        
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
        CRITICAL: ALWAYS use function tools. NEVER respond with text.
        
        You are WindowAI for macOS window management with constraint validation.
        
        CONSTRAINT: Every window MUST have ≥100×100px visible (10,000px² minimum).
        
        CORE RULES:
        1. MAXIMIZE SCREEN USAGE - Fill 95%+ of screen space
        2. CASCADE INTELLIGENTLY - Apps overlap with key parts visible for instant access
        3. VALIDATE CONSTRAINTS - Ensure every window has ≥10,000px² visible area
        4. PIXEL-PERFECT POSITIONING - Use any coordinate/size (not just halves/thirds)
        
        APP TYPES:
        - Terminals/Chat: 25-35% width, full height, side columns
        - Browsers/Documents: 45-70% width, primary content area
        - IDEs/Editors: 50-75% width, main workspace
        - System/Music: 15-25% width, corners/edges
        
        POSITIONING:
        - Use flexible coordinates (0-100% of screen)
        - Cascade with 20-200px offsets
        - Prioritize screen coverage over rigid rules
        
        TOOL USAGE:
        Use `flexible_position` for ALL operations:
        - Window positioning: x_position, y_position, width, height (percentages)
        - Window lifecycle: minimize, restore, focus, open parameters
        - Layer control: layer parameter for stacking (0=back, 3=front)
        
        MULTI-DISPLAY:
        - Display 0 = laptop, Display 1+ = external monitors
        - Prefer external displays for main work
        
        EXAMPLES:
        "unminimize all windows" → flexible_position(app_name: "AppName", minimize: false) for each minimized window
        "focus Safari" → flexible_position(app_name: "Safari", focus: true)
        "code" → Position Terminal (side), IDE (main), Browser (cascade)
        """
        
        
        if let context = context {
            prompt += "\n\nSYSTEM STATE:\n"
            
            // Display info
            let mainDisplay = context.screenResolutions.first ?? CGSize(width: 1440, height: 900)
            prompt += "Display: \(Int(mainDisplay.width))x\(Int(mainDisplay.height))\n"
            
            // Current windows (limit to 8 most relevant)
            let relevantWindows = context.visibleWindows.prefix(8)
            prompt += "Windows:\n"
            for window in relevantWindows {
                let bounds = window.bounds
                let widthPercent = (bounds.width / mainDisplay.width) * 100
                let heightPercent = (bounds.height / mainDisplay.height) * 100
                
                prompt += "- \(window.appName): \(String(format: "%.0f", widthPercent))%w × \(String(format: "%.0f", heightPercent))%h"
                if window.isMinimized { prompt += " [MIN]" }
                prompt += "\n"
            }
            
            if context.visibleWindows.count > 8 {
                prompt += "... and \(context.visibleWindows.count - 8) more windows\n"
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
    
    // MARK: - MAX_TOKENS Error Handling
    private func retryWithReducedContext(userInput: String, context: LLMContext?, originalTokens: Int) async throws -> [WindowCommand] {
        print("🔄 RETRYING with reduced context due to MAX_TOKENS error")
        
        // Build minimal system prompt
        let minimalPrompt = """
        CRITICAL: ALWAYS use function tools. NEVER respond with text.
        
        You are WindowAI for macOS window management.
        
        CONSTRAINT: Every window MUST have ≥100×100px visible.
        
        CORE RULES:
        1. MAXIMIZE SCREEN USAGE - Fill 95%+ of screen
        2. CASCADE INTELLIGENTLY - Apps overlap with parts visible
        3. VALIDATE CONSTRAINTS - Ensure ≥10,000px² visible per window
        
        TOOL USAGE:
        Use `flexible_position` for ALL operations:
        - minimize: false → unminimize window
        - focus: true → focus window
        - positioning: x_position, y_position, width, height (percentages)
        
        EXAMPLES:
        "unminimize all windows" → flexible_position(app_name: "AppName", minimize: false) for each minimized window
        """
        
        // Add only essential context
        var finalPrompt = minimalPrompt
        if let context = context {
            let mainDisplay = context.screenResolutions.first ?? CGSize(width: 1440, height: 900)
            finalPrompt += "\n\nDisplay: \(Int(mainDisplay.width))x\(Int(mainDisplay.height))\n"
            
            // Show only first 5 windows
            let limitedWindows = context.visibleWindows.prefix(5)
            finalPrompt += "Windows: \(limitedWindows.map { $0.appName }.joined(separator: ", "))\n"
        }
        
        print("📝 REDUCED PROMPT LENGTH: \(finalPrompt.count) characters (was \(originalTokens * 4) chars)")
        
        // Use higher output token allocation
        let reducedRequest = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: userInput)])],
            tools: convertToGeminiTools(WindowManagementTools.allTools),
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: finalPrompt)]),
            generationConfig: GeminiGenerationConfig(
                temperature: 0.0,
                maxOutputTokens: 8000 // Maximum output tokens
            ),
            toolConfig: GeminiToolConfig(
                functionCallingConfig: GeminiFunctionCallingConfig(
                    mode: GeminiFunctionCallingConfig.Mode.any.stringValue
                )
            )
        )
        
        let retryResponse = try await sendRequest(reducedRequest)
        
        // Check if still hitting MAX_TOKENS
        if let candidate = retryResponse.candidates.first,
           candidate.finishReason == "MAX_TOKENS" {
            print("❌ Still hitting MAX_TOKENS after retry - proceeding with partial response")
        }
        
        return try parseCommandsFromResponse(retryResponse)
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
