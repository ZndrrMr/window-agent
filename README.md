# WindowAgent

An AI-powered macOS window management tool that uses large language models to intelligently arrange application windows based on natural language commands.

## Features

- **Natural Language Commands**: Control window layouts using plain English
- **Intelligent Cascading**: Automatically arranges windows to optimize screen space
- **Multi-Display Support**: Works seamlessly across multiple monitors
- **Focus-Aware Layouts**: Prioritizes active applications for optimal workflow
- **LLM Integration**: Leverages Gemini Flash 2.0 to interpret user commands

## Technologies

- Swift
- macOS Accessibility APIs
- LLM API (Gemini Flash 2.0)
- Xcode

## Current Status

Active development - core functionality implemented with ongoing refinements for performance optimization and special macOS window sizing quirks.

## Architecture

The system combines Swift-based window detection and manipulation with LLM-powered decision making to create intelligent window layouts that adapt to user context and screen configurations.

## Project Structure

```
WindowAgent/
├── WindowAI/           # Main application source code
├── Tests/              # Test files and test scripts
├── Debug/              # Debugging and diagnostic utilities
├── Sources/            # Additional source modules
└── Documentation/      # Project documentation
```

## Development

This project requires macOS and Xcode for development. The main application is built using Swift and integrates with macOS Accessibility APIs for window management.