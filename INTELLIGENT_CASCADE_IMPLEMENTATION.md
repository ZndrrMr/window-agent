# Intelligent Cascade Window Management Implementation

## Overview

This implementation introduces an intelligent cascade window management system that adapts to user behavior, screen size, and context. Unlike rigid workspace systems, it uses machine learning patterns to provide hints to the LLM while maintaining flexibility.

## Key Components

### 1. **IntelligentWindowPatterns.swift** (New)
- **WindowUsagePattern**: Records user window arrangements with rich context
- **PatternMatch**: Finds similar historical patterns based on multiple factors
- **IntelligentPatternManager**: Manages pattern storage and retrieval
- Context includes: time of day, session duration, screen configuration, user activity

### 2. **CascadePositioner.swift** (New)
- **Intelligent Cascade Algorithm**: Adapts offset and sizing based on:
  - Screen size (ultrawide vs laptop)
  - Window count
  - App importance scores
  - User preferences
- **Window Importance Scoring**: Prioritizes windows based on:
  - App category (code editors > browsers > communication)
  - User preference history
  - Current window size
  - Recent usage
- **Cascade Styles**:
  - `intelligent`: Adaptive based on context
  - `classic`: Traditional fixed offset
  - `compact`: Minimal offset for small screens
  - `spread`: Larger offset for better access

### 3. **Enhanced ClaudeLLMService.swift**
- Added pattern hint generation in system prompt
- Provides historical behavior hints without enforcing rules
- Example hints:
  ```
  Pattern 1 (confidence: 85%):
  - Time: afternoon
  - Active apps: Cursor, Terminal, Arc
  - Primary focus: Cursor
  - Supporting apps: Terminal
  - Layout style: Cascade with primary window prominent
  ```

### 4. **Updated WindowPositioner.swift**
- Integrated CascadePositioner for intelligent layouts
- Support for both cascade and tiled layouts
- Automatic selection based on window count and screen type

### 5. **New LLM Tools**
- `cascade_windows`: Intelligent cascade with style options
- `tile_windows`: Traditional tiling for maximum visibility
- Enhanced parameters for user intent capture

## Intelligent Features

### 1. **Adaptive Cascade Parameters**
```swift
// Ultrawide screens
offsetX = screenWidth * 0.04  // More horizontal space
offsetY = screenHeight * 0.02  // Less vertical offset

// Laptop screens
offsetX = screenWidth * 0.02  // Compact horizontal
offsetY = screenHeight * 0.025 // Balanced vertical

// Many windows (>5)
offset *= 0.7  // Reduce to fit more
```

### 2. **Window Role Assignment**
- **Primary**: Main focus window (60-80% visible)
- **Secondary**: Supporting content (50-70% visible)
- **Auxiliary**: Tools and utilities (40-60% visible)
- **Peripheral**: Background apps (minimal visibility)

### 3. **Pattern Learning**
- Records window arrangements with context
- Matches patterns based on:
  - Time similarity (20% weight)
  - App overlap (30% weight)
  - Screen configuration (20% weight)
  - User context (20% weight)
  - Day of week (10% weight)

### 4. **Context-Aware Decisions**
- Automatically chooses cascade vs tiled based on:
  - Number of windows (≤2 always tile)
  - Screen type (ultrawide can tile more)
  - Historical patterns
  - User intent

## Usage Examples

### Basic Cascade
```
"cascade all my windows"
→ Intelligently arranges all visible windows with smart overlapping
```

### Style-Specific Cascade
```
"cascade windows in compact style"
→ Uses minimal offsets for laptop screens
```

### Context-Aware Arrangement
```
"I want to code with Cursor and Terminal"
→ Cursor gets 60% left, Terminal gets 40% right (tiled)
→ Or cascaded with Cursor prominent if more windows
```

### Focus Mode
```
"cascade for focused work"
→ Primary window gets 80% visibility, others minimally visible
```

## Benefits Over Rigid Workspaces

1. **Flexibility**: Adapts to actual window content, not predefined layouts
2. **Learning**: Improves over time based on user corrections
3. **Context-Aware**: Considers time, screen size, and activity
4. **Natural Language**: Users describe intent, not specific layouts
5. **Graceful Degradation**: Works well even without historical data

## Future Enhancements

1. **Session Tracking**: Record full work sessions for better patterns
2. **Correction Learning**: Learn from user manual adjustments
3. **App Pairing**: Detect which apps work well together
4. **Energy-Aware**: Adjust layouts based on user energy levels
5. **Project Context**: Different layouts for different projects

## Testing

Run the cascade demo:
```bash
./test_cascade_demo.sh
```

This will demonstrate:
- Basic cascade with all windows
- Compact cascade for laptops
- Intelligent coding layouts
- Focus mode cascading
- Mixed app arrangements
- Comparison with tiled layouts