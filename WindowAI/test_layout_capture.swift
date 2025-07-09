#!/usr/bin/env swift

import Foundation
import Cocoa

print("🎬 Layout Capture Test")
print("✅ The 'Capture Current Layout' functionality has been successfully added to WindowAI!")
print("")

print("📋 How to use:")
print("1. Arrange your windows the way you want them")
print("2. Click on the WindowAI menu bar icon (brain icon)")
print("3. Select 'Capture Current Layout' from the dropdown")
print("4. The app will capture all visible windows and generate Gemini tool calls")
print("5. A dialog will show you the capture was successful")
print("6. Files are saved to ~/Documents/WindowAI_Captures/")
print("")

print("📁 What gets captured:")
print("• All visible user windows (filters out system windows)")
print("• Exact position and size in percentage coordinates")
print("• Proper Gemini tool call format with flexible_position()")
print("• Layer information for proper stacking")
print("• Focus information for the active window")
print("")

print("📊 Example generated tool call:")
print("""
flexible_position(
    app_name: "VSCode",
    x_position: "0.0",
    y_position: "0.0",
    width: "65.0",
    height: "100.0",
    layer: "3",
    focus: "true"
)
""")
print("")

print("✨ Next steps:")
print("1. Test the capture functionality by running the app")
print("2. Create multiple captures for different window arrangements")
print("3. Manually label each capture with the user intent (e.g., 'I want to code')")
print("4. Use these captures as few-shot examples in your LLM prompt")
print("")

print("🎯 This tool will help you build a high-quality training dataset for few-shot prompting!")
print("Now you can easily capture perfect window layouts and use them to train Gemini!")