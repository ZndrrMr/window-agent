#!/usr/bin/env swift

import Foundation

// Create a simple test that mimics what you mentioned worked
struct SimpleGeminiTest {
    // This is the structure that should have worked
    static let workingToolDefinition = """
    {
      "function_declarations": [
        {
          "name": "snap_window",
          "description": "Snap a window to a position",
          "parameters": {
            "type": "object",
            "properties": {
              "app_name": {
                "type": "string",
                "description": "Name of the application"
              },
              "position": {
                "type": "string",
                "description": "Position to snap to",
                "enum": ["left", "right", "top", "bottom", "center"]
              }
            },
            "required": ["app_name", "position"]
          }
        }
      ]
    }
    """
    
    // This is what the working response should have looked like
    static let workingResponse = """
    {
      "candidates": [
        {
          "content": {
            "parts": [
              {
                "function_call": {
                  "name": "snap_window",
                  "args": {
                    "app_name": "terminal",
                    "position": "left"
                  }
                }
              }
            ]
          }
        }
      ]
    }
    """
}

// Test the parsing
print("=== DEBUGGING GEMINI RESPONSE PARSING ===")
print("")

// Test 1: Print the working tool definition
print("1. WORKING TOOL DEFINITION:")
print(SimpleGeminiTest.workingToolDefinition)
print("")

// Test 2: Show what the response should look like
print("2. WORKING RESPONSE STRUCTURE:")
print(SimpleGeminiTest.workingResponse)
print("")

// Test 3: Compare with WindowAI's tools
print("3. COMPARISON POINTS:")
print("   - Working test: Simple tool with basic parameters")
print("   - WindowAI: Complex tools with many optional parameters")
print("   - Key difference: WindowAI uses toolConfig.mode = 'ANY' to force function calls")
print("   - Key difference: WindowAI has very long, complex system prompt")
print("")

// Test 4: Identify potential issues
print("4. POTENTIAL ISSUES:")
print("   a) Tool complexity: WindowAI has 9 tools vs simple test with 1 tool")
print("   b) Parameter overload: WindowAI tools have many optional parameters")
print("   c) System prompt length: WindowAI has ~6000 character system prompt")
print("   d) Temperature: WindowAI uses temperature=0.0 (deterministic)")
print("   e) Token limit: WindowAI calculates dynamic token limits")
print("")

print("5. DEBUGGING STEPS:")
print("   1. Test with single simple tool (snap_window only)")
print("   2. Test with shorter system prompt")
print("   3. Test without toolConfig.mode enforcement")
print("   4. Test with higher temperature (0.1)")
print("   5. Test with fixed token limit")
print("")

print("6. HYPOTHESIS:")
print("   The complexity difference is causing Gemini to respond with text")
print("   instead of function calls. The working test was much simpler.")