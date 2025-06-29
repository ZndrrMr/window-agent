# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WindowAI is an AI-powered window management tool for macOS that allows users to control their windows using natural language commands. The app integrates with cloud-based LLMs to interpret user intent and executes window management operations using macOS Accessibility APIs.

### Core Vision
- **Alfred/Spotlight-style interface**: Hotkey-activated floating command box for natural language input
- **Intelligent window management**: Context-aware app control and workspace arrangement
- **Learning system**: Adapts to user preferences and habits over time
- **Cloud-based AI**: Leverages powerful LLMs for natural language understanding

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

## Development Roadmap

### Phase 1: Core Window Management (Week 1-2)
Implement basic window control functionality without LLM integration.

#### 1.1 Window Operations
- **Open/Close Apps**: Launch applications by name or bundle ID
- **Window States**: Minimize, maximize, restore, fullscreen
- **Window Positioning**: Move windows to specific coordinates
- **Window Sizing**: Resize with awareness of app-specific constraints
- **Display Awareness**: Handle multiple monitors correctly

#### 1.2 App-Specific Constraints
```swift
// Example: Messages app has different minimum size than Arc browser
struct AppConstraints {
    let bundleID: String
    let minWidth: CGFloat
    let minHeight: CGFloat
    let supportsFullscreen: Bool
}
```

#### 1.3 Implementation Priority
1. Get WindowManager.swift working with real Accessibility API calls
2. Test with common apps (Safari, Messages, Finder, Terminal)
3. Build constraint database for popular apps
4. Create unit tests for each window operation

### Phase 2: LLM Integration (Week 3-4)
Connect natural language processing to window management actions.

#### 2.1 LLM Selection
**Recommended for Testing**: Claude 3.5 Haiku
- Cost-effective for development ($0.80/1M input tokens)
- Fast response times (< 1 second)
- Strong function calling capabilities
- Easy migration to Sonnet/Opus for production

**Alternative**: GPT-4o-mini
- Similar pricing ($0.15/1M input)
- Good function calling
- Wider ecosystem support

#### 2.2 Agent Framework Architecture
```swift
// Structured approach using function calling
struct WindowCommand {
    let action: CommandAction
    let target: CommandTarget
    let parameters: CommandParameters
}

// LLM prompt structure
let systemPrompt = """
You are a window management assistant. Convert natural language to structured commands.
Available actions: open, close, minimize, maximize, move, resize, arrange
Return JSON with action, target app, and parameters.
"""
```

#### 2.3 Implementation Steps
1. Create structured command schema
2. Implement LLM prompt engineering
3. Build command parser and validator
4. Add fallback handling for ambiguous commands
5. Implement command confirmation for destructive actions

### Phase 3: Advanced Context Awareness (Week 5-6)
Build the intelligent, learning window management system.

#### 3.1 App Context Database
```swift
// Track user's app preferences and usage
struct AppContext {
    let category: String // "code_editor", "browser", "communication"
    let preferredApp: String // "Cursor", "Arc", "Slack"
    let alternatives: [String] // ["VSCode", "Xcode"]
    let usageCount: Int
    let lastUsed: Date
}
```

#### 3.2 Workspace Definitions
```swift
// Pre-defined and learned workspace layouts
struct Workspace {
    let name: String // "coding environment"
    let requiredApps: [AppContext]
    let optionalApps: [AppContext]
    let excludedApps: [String] // User feedback: "don't open Xcode"
    let layout: LayoutConfiguration
}
```

#### 3.3 Learning System
1. **Usage Tracking**: Monitor which apps user opens together
2. **Preference Learning**: Track corrections and adjustments
3. **Feedback Loop**: Store user corrections persistently
4. **Context Inference**: Detect patterns in app usage

#### 3.4 Advanced Commands
- "Open my coding environment" → Opens Cursor, Terminal, Arc (learned preferences)
- "Coding setup but no browser" → Conditional workspace opening
- "Arrange for video call" → Minimize distractions, position camera app
- "Focus mode" → Hide all but active app

### Phase 4: User Experience Polish (Week 7)
Refine the interface and user experience.

#### 4.1 Settings Management
- App preference configuration
- Workspace layout editor
- Hotkey customization
- LLM provider selection
- Usage statistics dashboard

#### 4.2 Command Box Enhancements
- Real-time command suggestions
- Command history with search
- Visual feedback for actions
- Error messages with corrections

#### 4.3 Onboarding Experience
1. Permission setup wizard
2. App discovery and categorization
3. Initial workspace configuration
4. Tutorial with example commands

### Phase 5: Distribution & Deployment (Week 8)
Prepare for public release.

#### 5.1 Code Signing & Notarization
- Developer ID certificate setup
- Automated notarization workflow
- Sparkle auto-updater integration

#### 5.2 Licensing System
- Free tier: Basic commands, limited LLM calls
- Pro tier: Advanced features, unlimited usage
- License validation without server dependency

## Implementation Guidelines

### Window Management Best Practices
1. **Always check AXIsProcessTrusted() before operations**
2. **Handle app-specific quirks** (some apps ignore certain AX calls)
3. **Implement retry logic** for slow-launching apps
4. **Cache window references** for performance
5. **Validate window bounds** against screen dimensions

### LLM Integration Best Practices
1. **Use structured outputs** (JSON mode or function calling)
2. **Implement token limits** to control costs
3. **Cache common commands** to reduce API calls
4. **Add user confirmation** for ambiguous commands
5. **Log all commands** for debugging and learning

### Learning System Implementation
```swift
// Store user feedback in Core Data or SQLite
struct UserFeedback {
    let commandText: String
    let interpretedAction: WindowCommand
    let userCorrection: WindowCommand?
    let timestamp: Date
}

// Update app preferences based on usage
func updateAppPreferences(feedback: UserFeedback) {
    // Increase weight for corrected app choice
    // Decrease weight for rejected app
    // Store exclusion rules
}
```

### Testing Strategy
1. **Unit Tests**: Each window operation in isolation
2. **Integration Tests**: LLM → Command → Window action
3. **UI Tests**: Command box interaction flows
4. **Performance Tests**: Response time benchmarks
5. **Cost Tests**: Monitor LLM token usage

## Next Implementation Steps

1. **Start with WindowManager.swift**
   - Implement real Accessibility API calls
   - Test with 5-10 common macOS apps
   - Build constraint database

2. **Then move to LLMService.swift**
   - Set up Claude/OpenAI API integration
   - Implement structured command parsing
   - Create comprehensive test suite

3. **Build learning system incrementally**
   - Start with simple preference storage
   - Add usage tracking
   - Implement feedback loop

4. **Polish based on testing**
   - Refine command interpretation
   - Optimize performance
   - Enhance error handling

## CRITICAL RULES - NEVER VIOLATE

### NO HARDCODED CONSTRAINTS EVER
**NEVER** use pixel minimums, maximums, or any fixed constraints in window sizing:
- ❌ `min(0.30, max(0.20, 600.0 / screenSize.width))` 
- ❌ `max(0.45, 800.0 / screenSize.width)`
- ❌ Any `minWidth`, `maxWidth`, pixel limits
- ❌ Fixed pixel calculations like "480px minimum"
- ✅ Pure percentage-based dynamic calculations only
- ✅ Window count and screen size adaptation
- ✅ Archetype behavior-based sizing

The system must be **100% dynamic** with **NO hardcoded rules**. Use window count, screen ratios, and archetype behavior to calculate sizes, never fixed pixel constraints.

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
- SwiftUI settings interface skeleton
- Onboarding flow structure
- Basic app lifecycle management
- Comprehensive development roadmap
- **Phase 1**: Core window management (WindowManager with Accessibility APIs)
- **Phase 2**: Full LLM integration with Claude API
- **Hotkey system**: Global hotkey registration with Carbon APIs
- **App autocomplete**: Smart suggestions with fuzzy matching
- **Cascade positioning**: Intelligent window layering system
- **Learning system**: Pattern tracking and user preferences

### Current Focus 🎯
**Phase 3**: Advanced Context Awareness & Polish
- [ ] Multi-display support (remaining from Phase 1)
- [ ] User feedback UI for learning system
- [ ] Persist learning patterns between sessions
- [ ] Enhanced workspace layout execution
- [ ] Command history implementation
- [ ] Unit tests for core functionality

### TODO by Phase 🚧

#### Phase 1: Core Window Management
- [x] AXUIElement operations for window control
- [x] App launching with NSWorkspace
- [x] Window state management (min/max/fullscreen)
- [ ] Multi-display support
- [x] App-specific constraint handling

#### Phase 2: LLM Integration  
- [x] Claude API integration (using Sonnet)
- [x] Structured command schema
- [x] Natural language parser
- [x] Command validation layer
- [x] Error handling and fallbacks

#### Phase 3: Context Awareness
- [ ] App categorization system
- [ ] User preference learning
- [ ] Workspace definitions
- [ ] Feedback storage (Core Data/SQLite)
- [ ] Pattern detection algorithms

#### Phase 4: UX Polish
- [ ] Settings UI implementation
- [x] Command suggestions (App autocomplete with fuzzy matching implemented)
- [ ] Visual feedback system
- [ ] Onboarding wizard  
- [ ] Command history
- [x] Fix text highlighting flash when command window opens (completed)

#### Phase 5: Distribution
- [ ] Developer ID certificate
- [ ] Notarization workflow
- [ ] Sparkle integration
- [ ] License validation
- [ ] Distribution package

## Nice-to-Have Features 🌟
Features to consider after core functionality is complete:

### Voice Input
- Microphone integration for hands-free commands
- Speech-to-text using macOS Speech Recognition
- Wake word detection ("Hey Window")

### Visual Enhancements  
- Beautiful animations for window transitions
- Command preview before execution
- Themed command box (light/dark/custom)

### Advanced Integrations
- Shortcuts.app integration
- AppleScript bridge for power users
- REST API for external automation
- iPhone companion app for remote control

## Technical Implementation Notes

### LLM Integration Details
```swift
// Example structured output for Claude/GPT
let functionSchema = """
{
  "name": "execute_window_command",
  "parameters": {
    "action": "open|close|minimize|maximize|move|resize|arrange",
    "target": {
      "appName": "string",
      "bundleId": "string (optional)"
    },
    "parameters": {
      "position": {"x": "number", "y": "number"},
      "size": {"width": "number", "height": "number"},
      "workspace": "string (optional)"
    }
  }
}
"""
```

### Accessibility API Gotchas
1. **Trust Dialog**: Can't be automated, user must manually approve
2. **Sandboxed Apps**: Some apps don't respond to AX calls
3. **Timing Issues**: Apps need time to launch before window manipulation
4. **Electron Apps**: Often have non-standard window behavior
5. **Full Screen Spaces**: Require special handling
6. **NEVER USE ZOOM BUTTON**: Do not use the macOS zoom button (green button) for maximize operations. Always use manual bounds setting instead.

### Performance Optimization
- Cache AXUIElement references (invalidate on app changes)
- Batch window operations when possible
- Use GCD for non-blocking operations
- Implement command debouncing
- Preload common app data

## Common Issues

### Development
- Accessibility permissions must be granted for testing
- SIP does NOT need to be disabled (unlike yabai)
- Global hotkeys may conflict with system shortcuts
- Some apps require specific entitlements to control

### Deployment  
- Code signing required for distribution
- Notarization needed to avoid Gatekeeper warnings
- Consider creating installer package for easy setup
- Plan for accessibility permission onboarding

## File Analysis & Implementation Status

### **App.swift** ✅ **Complete Architecture**
- **Purpose**: Main application coordinator, handles app lifecycle
- **Status**: Well-structured, needs TODO implementations in delegate methods
- **Key Features**: Menu bar integration, hotkey coordination, LLM processing pipeline

### **Core Layer**

#### **HotkeyManager.swift** ⚠️ **Needs Carbon API Implementation** 
- **Purpose**: Global hotkey registration using Carbon APIs
- **Missing**: Carbon event handler setup, hotkey registration/unregistration
- **Priority**: High - Required for Phase 1

#### **WindowManager.swift** ⚠️ **Critical - Missing Key Features**
- **Purpose**: Window manipulation via Accessibility APIs  
- **Missing**: All Accessibility API calls, multi-display support
- **New Addition Needed**: Integration with AppConstraintsManager
- **Priority**: Critical - Core functionality

#### **AppLauncher.swift** ⚠️ **Missing Advanced Features**
- **Purpose**: App launching and management
- **Missing**: NSWorkspace implementations, app discovery, fuzzy matching
- **Priority**: High - Required for basic commands

#### **CommandExecutor.swift** ⚠️ **Missing Workspace Integration**
- **Purpose**: Orchestrates command execution
- **Missing**: Context-aware arrangements, workspace management integration
- **New Addition Needed**: Integration with WorkspaceManager and LearningService
- **Priority**: Medium - Advanced features

### **Services Layer**

#### **LLMService.swift** ✅ **Good Structure, Needs Implementation**
- **Purpose**: Cloud LLM integration (OpenAI/Anthropic)
- **Status**: Fixed typo, has proper error handling, needs API implementations
- **Priority**: High - Required for Phase 2

#### **LearningService.swift** ✅ **NEW - Learning System**
- **Purpose**: User feedback collection and preference learning
- **Features**: Command pattern recognition, app preference scoring, correction tracking
- **Integration**: Works with WorkspaceManager for usage tracking
- **Priority**: Medium - Phase 3 feature

### **Models Layer**

#### **Commands.swift** ✅ **Complete**
- **Purpose**: Command data structures and types
- **Status**: Well-defined, comprehensive command types

#### **UserPreferences.swift** ✅ **Complete Structure**
- **Purpose**: App settings and user configuration
- **Status**: Comprehensive preferences, needs persistence implementation

#### **AppConstraints.swift** ✅ **NEW - App Database**
- **Purpose**: App-specific size/position constraints
- **Features**: Built-in constraints for popular apps, user customization
- **Integration**: Used by WindowManager for validation
- **Database**: 20+ popular macOS apps with proper constraints

#### **Workspace.swift** ✅ **NEW - Context System** 
- **Purpose**: Workspace definitions and app context learning
- **Features**: Built-in workspaces (coding, research, communication), learning system
- **Integration**: Used by CommandExecutor and LearningService

### **Missing from Current Implementation**

#### Phase 1 Gaps:
1. **Real Accessibility API calls** in WindowManager.swift
2. **Carbon hotkey registration** in HotkeyManager.swift  
3. **NSWorkspace app launching** in AppLauncher.swift
4. **Multi-display support** functions

#### Phase 2 Gaps:
1. **Actual LLM API implementations** (OpenAI/Anthropic)
2. **Structured response parsing** 
3. **Context building** from current system state

#### Phase 3 Implementation Needed:
1. **Workspace layout execution** in CommandExecutor
2. **User feedback UI** components
3. **Preference learning algorithms** (partially implemented)

## File Locations

### Core Files:
- **App entry point**: `WindowAI/App.swift`
- **Core window management**: `WindowAI/Core/WindowManager.swift`
- **Global hotkeys**: `WindowAI/Core/HotkeyManager.swift`
- **Command coordination**: `WindowAI/Core/CommandExecutor.swift`

### Intelligence Layer:
- **LLM integration**: `WindowAI/Services/LLMService.swift`
- **Learning system**: `WindowAI/Services/LearningService.swift`
- **App constraints**: `WindowAI/Models/AppConstraints.swift`
- **Workspace management**: `WindowAI/Models/Workspace.swift`

### Configuration:
- **User preferences**: `WindowAI/Models/UserPreferences.swift`
- **App configuration**: `WindowAI/Info.plist`
- **UI components**: `WindowAI/UI/`