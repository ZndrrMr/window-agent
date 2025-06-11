#!/usr/bin/env swift

import Foundation
import Cocoa

// Simple test to check LLM command parsing
// This tests the actual API response parsing without running the full app

struct TestContent: Codable {
    let type: String
    let id: String?
    let name: String?
    let input: [String: String]?
}

struct TestResponse: Codable {
    let content: [TestContent]
}

// Test cases that should generate multiple tool calls
let testPrompts = [
    "put messages in the top right at the same size. make the terminal super tall, but don't change its width. make arc browser take up the middle third from top to bottom.",
    "Open Safari on the left half and Terminal on the right half",
    "I want three windows: Xcode on the left, Safari in the middle, and Terminal on the right"
]

// Simulate what the LLM should return for the first test case
let expectedResponse = """
{
  "content": [
    {
      "type": "tool_use",
      "id": "1",
      "name": "snap_window",
      "input": {
        "app_name": "Messages",
        "position": "top-right",
        "size": "small"
      }
    },
    {
      "type": "tool_use", 
      "id": "2",
      "name": "resize_window",
      "input": {
        "app_name": "Terminal",
        "size": "custom",
        "custom_height": "90"
      }
    },
    {
      "type": "tool_use",
      "id": "3", 
      "name": "snap_window",
      "input": {
        "app_name": "Arc",
        "position": "center",
        "size": "custom",
        "custom_height": "100",
        "custom_width": "33"
      }
    }
  ]
}
"""

// Parse the test response
if let data = expectedResponse.data(using: .utf8) {
    do {
        let response = try JSONDecoder().decode(TestResponse.self, from: data)
        print("✅ Successfully parsed \(response.content.count) tool calls")
        
        for (index, content) in response.content.enumerated() {
            if content.type == "tool_use",
               let name = content.name,
               let input = content.input {
                print("\nTool Call \(index + 1):")
                print("  Name: \(name)")
                print("  Input: \(input)")
            }
        }
    } catch {
        print("❌ Failed to parse response: \(error)")
    }
}

print("\n📝 Test prompts that should generate multiple commands:")
for prompt in testPrompts {
    print("\n• \"\(prompt)\"")
}

print("\n⚠️  To run full LLM tests, use the LLMCommandTester class in the app")