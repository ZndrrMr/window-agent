#!/bin/bash

# Test script for intelligent cascade window management

echo "🎨 WindowAI Intelligent Cascade Demo"
echo "===================================="
echo ""

# Function to send command
send_command() {
    local command="$1"
    echo "📝 Command: \"$command\""
    echo "$command" | ./test_improved_output.sh
    echo ""
    sleep 2
}

echo "1️⃣ Testing basic cascade with all windows"
send_command "cascade all my windows"

echo "2️⃣ Testing compact cascade for laptop"
send_command "cascade all windows in compact style"

echo "3️⃣ Testing intelligent coding layout"
send_command "I want to code with Cursor and Terminal visible"

echo "4️⃣ Testing cascade with focus mode"
send_command "cascade windows for focused coding"

echo "5️⃣ Testing mixed app cascade"
send_command "open Safari, Messages, and Terminal then cascade them intelligently"

echo "6️⃣ Testing tiled layout for comparison"
send_command "tile Cursor and Terminal side by side"

echo "7️⃣ Testing workspace-style cascade"
send_command "arrange my windows for research mode"

echo "8️⃣ Testing cascade with specific apps"
send_command "cascade just my browser windows"

echo "✅ Demo complete!"