#!/usr/bin/env swift

import Foundation

// Test what WindowAI actually sends to Gemini

// First let me try to import the actual WindowAI models
print("=== WINDOWAI GEMINI REQUEST ANALYSIS ===")
print("")

print("1. TOOLS BEING SENT:")
print("   WindowAI sends 9 tools with complex parameter structures:")
print("   - resize_window: 7 parameters (2 required)")
print("   - open_app: 4 parameters (1 required)")
print("   - close_app: 1 parameter (1 required)")
print("   - focus_window: 1 parameter (1 required)")
print("   - snap_window: 8 parameters (2 required)")
print("   - minimize_window: 1 parameter (1 required)")
print("   - maximize_window: 2 parameters (1 required)")
print("   - tile_windows: 3 parameters (1 required)")
print("   - flexible_position: 8 parameters (6 required)")
print("")

print("2. PARAMETER COMPLEXITY:")
print("   snap_window alone has these options:")
print("   - position: 16 enum values")
print("   - size: 11 enum values")
print("   - custom_x, custom_y, custom_width, custom_height")
print("   - display: integer")
print("")

print("3. SYSTEM PROMPT:")
print("   WindowAI sends a 6000+ character system prompt including:")
print("   - App archetype classifications")
print("   - Window layout analysis")
print("   - Complex positioning rules")
print("   - Multiple examples and constraints")
print("")

print("4. TOOL CONFIG:")
print("   WindowAI uses:")
print("   - toolConfig.mode = 'ANY' (forces function calls only)")
print("   - temperature = 0.0 (deterministic)")
print("   - Dynamic token limits (2000-8000)")
print("")

print("5. HYPOTHESIS:")
print("   Gemini 2.0 Flash gets overwhelmed by:")
print("   - Too many tool choices (9 tools)")
print("   - Too many parameter options (100+ total parameters)")
print("   - Complex enum values (16 position options)")
print("   - Long system prompt competing with tool selection")
print("")

print("6. COMPARISON WITH WORKING TEST:")
print("   Working test:")
print("   - 1 tool with 2 simple parameters")
print("   - 5 enum values total")
print("   - Minimal or no system prompt")
print("   - Simple request structure")
print("")

print("7. SOLUTION APPROACH:")
print("   Test progressively:")
print("   - Start with 1 tool (snap_window)")
print("   - Reduce parameter options")
print("   - Use minimal system prompt")
print("   - Add tools one by one until it breaks")
print("")

print("To test this theory, run WindowAI with debug output enabled")
print("and compare the request size/complexity to the working test.")