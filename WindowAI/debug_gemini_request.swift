#!/usr/bin/env swift

import Foundation

// Quick test to compare what WindowAI sends vs what worked

print("=== GEMINI REQUEST COMPARISON ===")
print("")

// Run a quick test in WindowAI by opening the app and running:
// "move terminal to the left"
// The debug output will show exactly what's being sent

print("1. TO TEST - Open WindowAI and run: 'move terminal to the left'")
print("   Look for the debug output showing:")
print("   - TOOL COUNT: 9 tools being sent")
print("   - REQUEST JSON (first 2000 chars)")
print("   - GEMINI RESPONSE DEBUG")
print("")

print("2. WORKING TEST STRUCTURE:")
print("   - Simple tool with 2 parameters")
print("   - Clean system prompt")
print("   - No complex configuration")
print("")

print("3. EXPECTED DIFFERENCES:")
print("   - WindowAI: 9 tools with 20+ parameters each")
print("   - WindowAI: 6000+ character system prompt")
print("   - WindowAI: Complex toolConfig with mode=ANY")
print("   - WindowAI: Dynamic token limits")
print("")

print("4. HYPOTHESIS:")
print("   - The large number of tools/parameters overwhelms Gemini")
print("   - System prompt is too long and complex")
print("   - Tool parameter overload causes decision paralysis")
print("")

print("5. NEXT STEPS:")
print("   - Test with just 3 simple tools")
print("   - Test with minimal system prompt")
print("   - Test without toolConfig.mode=ANY")
print("   - Compare exact JSON structures")
print("")

print("Run this test, then examine the debug output to see the exact request structure.")