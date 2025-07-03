#!/usr/bin/env swift

import Foundation

// Test a simplified version of the Gemini request to isolate the issue

struct SimpleGeminiRequest: Codable {
    let contents: [SimpleGeminiContent]
    let tools: [SimpleGeminiTool]
    let toolConfig: SimpleGeminiToolConfig
    let generationConfig: SimpleGeminiGenerationConfig
    
    enum CodingKeys: String, CodingKey {
        case contents
        case tools
        case toolConfig = "tool_config"
        case generationConfig = "generation_config"
    }
}

struct SimpleGeminiContent: Codable {
    let parts: [SimpleGeminiPart]
}

struct SimpleGeminiPart: Codable {
    let text: String
}

struct SimpleGeminiTool: Codable {
    let functionDeclarations: [SimpleGeminiFunctionDeclaration]
    
    enum CodingKeys: String, CodingKey {
        case functionDeclarations = "function_declarations"
    }
}

struct SimpleGeminiFunctionDeclaration: Codable {
    let name: String
    let description: String
    let parameters: SimpleGeminiParameters
}

struct SimpleGeminiParameters: Codable {
    let type: String
    let properties: [String: SimpleGeminiProperty]
    let required: [String]
}

struct SimpleGeminiProperty: Codable {
    let type: String
    let description: String
    let `enum`: [String]?
}

struct SimpleGeminiToolConfig: Codable {
    let functionCallingConfig: SimpleGeminiFunctionCallingConfig
    
    enum CodingKeys: String, CodingKey {
        case functionCallingConfig = "function_calling_config"
    }
}

struct SimpleGeminiFunctionCallingConfig: Codable {
    let mode: String
}

struct SimpleGeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
    }
}

// Create a minimal test
func createSimpleRequest() -> SimpleGeminiRequest {
    let snapTool = SimpleGeminiTool(
        functionDeclarations: [
            SimpleGeminiFunctionDeclaration(
                name: "snap_window",
                description: "Snap a window to a position",
                parameters: SimpleGeminiParameters(
                    type: "object",
                    properties: [
                        "app_name": SimpleGeminiProperty(
                            type: "string",
                            description: "Name of the application",
                            enum: nil
                        ),
                        "position": SimpleGeminiProperty(
                            type: "string",
                            description: "Position to snap to",
                            enum: ["left", "right", "top", "bottom", "center"]
                        )
                    ],
                    required: ["app_name", "position"]
                )
            )
        ]
    )
    
    return SimpleGeminiRequest(
        contents: [
            SimpleGeminiContent(
                parts: [
                    SimpleGeminiPart(text: "move terminal to the left")
                ]
            )
        ],
        tools: [snapTool],
        toolConfig: SimpleGeminiToolConfig(
            functionCallingConfig: SimpleGeminiFunctionCallingConfig(mode: "ANY")
        ),
        generationConfig: SimpleGeminiGenerationConfig(
            temperature: 0.0,
            maxOutputTokens: 2000
        )
    )
}

// Test the JSON serialization
let request = createSimpleRequest()
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

do {
    let jsonData = try encoder.encode(request)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("=== SIMPLE GEMINI REQUEST TEST ===")
        print("")
        print("REQUEST JSON:")
        print(jsonString)
        print("")
        print("COMPARISON:")
        print("- Simple request: 1 tool, 2 parameters")
        print("- WindowAI: 9 tools, 20+ parameters each")
        print("- Simple request: ~500 characters")
        print("- WindowAI: ~6000+ character system prompt")
        print("")
        print("This simple request should work with Gemini.")
        print("If WindowAI fails but this works, tool complexity is the issue.")
    }
} catch {
    print("JSON encoding failed: \(error)")
}