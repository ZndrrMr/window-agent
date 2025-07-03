#!/usr/bin/env swift

import Foundation
import Cocoa

// This is a minimal test script to isolate Gemini function calling issues
// Run with: swift test_minimal_gemini.swift

print("🧪 MINIMAL GEMINI FUNCTION CALLING TEST")
print("=====================================")

// Create a minimal test that doesn't require the full WindowAI app
class MinimalGeminiTest {
    
    func runTest() async {
        print("📋 Test Instructions:")
        print("1. This test sends a minimal request to Gemini 2.0 Flash")
        print("2. Uses only snap_window tool with app_name and position parameters") 
        print("3. Forces function calling with toolConfig.mode = ANY")
        print("4. Shows full request/response JSON for debugging")
        print("5. Command: 'move terminal to the left'")
        print("")
        
        // Note: The actual test needs to be run from within the WindowAI app context
        // because it depends on the LLMService and GeminiLLMService classes
        
        print("⚠️  To run the actual test:")
        print("1. Open the WindowAI app in Xcode")
        print("2. Add this code to a breakpoint or test method:")
        print("")
        print("Task {")
        print("    let windowManager = WindowManager.shared")
        print("    let llmService = LLMService(windowManager: windowManager)")
        print("    do {")
        print("        let commands = try await llmService.testMinimalFunctionCalling()")
        print("        print(\"✅ Test completed with \\(commands.count) commands\")")
        print("    } catch {")
        print("        print(\"❌ Test failed: \\(error)\")")
        print("    }")
        print("}")
        print("")
        
        print("🔍 What to look for in the output:")
        print("- REQUEST JSON: Should show snap_window tool definition")
        print("- RESPONSE JSON: Should contain functionCall, not text")
        print("- Function name should be 'snap_window'")
        print("- Args should contain app_name='Terminal', position='left'")
        print("")
        
        print("🐛 Common failure modes:")
        print("1. Model returns text instead of function call")
        print("2. Function call has wrong parameter names")
        print("3. Tool config not properly enforcing function calls")
        print("4. Tool schema has invalid format")
        print("")
        
        print("💡 Progressive debugging steps:")
        print("1. If no function calls → check tool_config.function_calling_config.mode")
        print("2. If wrong function → check tool name and description")
        print("3. If wrong params → check parameter schema and required fields")
        print("4. If parsing fails → check JSON structure matches GeminiResponse")
    }
}

// Run the instructions
Task {
    let test = MinimalGeminiTest()
    await test.runTest()
}

// Keep the script alive briefly
RunLoop.main.run(until: Date().addingTimeInterval(1))