# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WindowAI is an AI-powered window management tool for macOS that allows users to control their windows using natural language commands. The app integrates with cloud-based LLMs to interpret user intent and executes window management operations using macOS Accessibility APIs.

## Architecture Overview

The project follows a clean, layered architecture:

```
WindowAI/
├── Core/           # Core functionality and system integration
├── Services/       # External services and business logic
├── UI/            # User interface components
├── Models/        # Data structures and models
├── Utils/         # Helper utilities and extensions
└── Resources/     # Assets, Info.plist, etc.
```

### Core Layer
- **HotkeyManager**: Global hotkey registration using Carbon APIs
- **WindowManager**: Window manipulation using Accessibility APIs  
- **AppLauncher**: Application launching using NSWorkspace
- **CommandExecutor**: Orchestrates command execution across components

### Services Layer
- **LLMService**: Cloud LLM integration (OpenAI/Anthropic APIs)
- **SubscriptionService**: License validation and usage tracking
- **AnalyticsService**: Privacy-first usage analytics

### UI Layer
- **CommandWindow**: Floating input window (Alfred-style)
- **SettingsWindow**: SwiftUI-based preferences interface
- **OnboardingFlow**: First-run setup experience

### Models
- **Commands**: Data structures for window commands and results
- **UserPreferences**: App settings and user configuration

## Development Commands

Since this is a macOS app built with Swift and Xcode:

### Building and Running
```bash
# Build the app
xcodebuild -project WindowAI.xcodeproj -scheme WindowAI -configuration Debug build

# Run from Xcode or build and run
open WindowAI.app
```

### Testing
```bash
# Run unit tests
xcodebuild test -project WindowAI.xcodeproj -scheme WindowAI -destination 'platform=macOS'

# Run specific test
xcodebuild test -project WindowAI.xcodeproj -scheme WindowAI -only-testing:WindowAITests/LLMServiceTests
```

### Code Quality
```bash
# SwiftLint (if configured)
swiftlint

# Swift format (if configured)  
swift-format --in-place --recursive .
```

## Key Technical Details

### Permissions Required
- **Accessibility**: Required for window management (AXIsProcessTrusted)
- **Network**: For LLM API calls (OpenAI/Anthropic)

### Distribution
- Non-App Store distribution (like Alfred, Rectangle)
- Developer ID signing and notarization required
- Uses Sparkle framework for auto-updates

### Dependencies
- **Carbon**: For global hotkey registration
- **ApplicationServices**: For Accessibility APIs
- **SwiftUI/AppKit**: For user interface
- **Foundation**: For networking and data handling

## Command Flow

1. User presses global hotkey (⌘+Space by default)
2. CommandWindow appears with text input
3. User types natural language command
4. LLMService processes command via cloud API
5. CommandExecutor interprets structured response
6. Core components execute window operations
7. Results displayed to user

## Development Guidelines

### Code Patterns
- Use async/await for API calls and long-running operations
- Delegate pattern for component communication
- NotificationCenter for loose coupling between UI and business logic
- UserDefaults through UserPreferences for persistence

### Error Handling
- LLMServiceError for API-related failures
- SubscriptionServiceError for licensing issues
- Graceful degradation when services unavailable

### Privacy & Analytics
- All analytics are opt-in and anonymized
- No window content or personal data collected
- API keys stored securely in Keychain (TODO: implement)

### Testing Strategy
- Unit tests for Core and Services layers
- UI tests for critical user flows
- Mock LLM responses for reliable testing
- Permission mocking for automated testing

## Implementation Status

### Completed ✅
- Project structure and architecture
- All major components with function signatures
- SwiftUI settings interface
- Onboarding flow
- Basic app lifecycle management

### TODO 🚧
- Implement actual function bodies (all marked with TODO)
- Add proper error handling and validation
- Implement Accessibility API calls
- Add LLM API integration
- Add comprehensive test suite
- Add app icons and assets
- Implement Sparkle auto-updater
- Add Keychain integration for API keys

## Common Issues

### Development
- Accessibility permissions must be granted for testing
- SIP does NOT need to be disabled (unlike yabai)
- Global hotkeys may conflict with system shortcuts

### Deployment
- Code signing required for distribution
- Notarization needed to avoid Gatekeeper warnings
- Consider creating installer package for easy setup

## File Locations

Important files for future development:
- App entry point: `WindowAI/App.swift`
- Main models: `WindowAI/Models/`
- Core window management: `WindowAI/Core/WindowManager.swift`
- LLM integration: `WindowAI/Services/LLMService.swift`
- UI components: `WindowAI/UI/`
- App configuration: `WindowAI/Info.plist`