# Gemini Function Calling Analysis: Working Test vs WindowAI

## Problem Statement
- **Working Test**: Generated `functionCall: { name: "snap_window", args: { "position": "left", "app_name": "terminal" } }`
- **WindowAI**: Shows `Content part 1: type=text` instead of function calls

## Key Differences Identified

### 1. **Tool Complexity**
**Working Test (Simple)**:
```json
{
  "function_declarations": [
    {
      "name": "snap_window",
      "description": "Snap a window to a position",
      "parameters": {
        "type": "object",
        "properties": {
          "app_name": {"type": "string", "description": "Name of the application"},
          "position": {"type": "string", "description": "Position to snap to", "enum": ["left", "right", "top", "bottom", "center"]}
        },
        "required": ["app_name", "position"]
      }
    }
  ]
}
```

**WindowAI (Complex)**:
- **9 different tools** vs 1 simple tool
- **Many optional parameters** (custom_width, custom_height, preserve_width, etc.)
- **Multiple enum options** (tiny, small, medium, large, huge, half, third, etc.)
- **Complex nested logic** for handling different parameter combinations

### 2. **System Prompt Length**
**Working Test**: Likely minimal or no system prompt

**WindowAI**: ~6000+ character system prompt including:
- Detailed archetype explanations
- Complex positioning rules
- Screen coverage requirements
- Pattern matching instructions
- Multiple examples and constraints

### 3. **Request Configuration**
**WindowAI Configuration**:
```swift
let request = GeminiRequest(
    contents: [GeminiContent(parts: [GeminiPart(text: userInput)])],
    tools: convertToGeminiTools(WindowManagementTools.allTools), // 9 tools
    systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]), // 6000+ chars
    generationConfig: GeminiGenerationConfig(
        temperature: 0.0,  // Zero temperature
        maxOutputTokens: maxTokens // Dynamic: 2000-8000
    ),
    toolConfig: GeminiToolConfig(
        functionCallingConfig: GeminiFunctionCallingConfig(
            mode: "ANY" // Forces function calls only
        )
    )
)
```

### 4. **Tool Parameter Overload**
**Example: snap_window tool in WindowAI**:
```json
{
  "name": "snap_window",
  "properties": {
    "app_name": {"type": "string"},
    "position": {"enum": ["left", "right", "top", "bottom", "center", "top-left", "top-right", "bottom-left", "bottom-right", "left-third", "middle-third", "right-third", "top-third", "bottom-third", "custom"]},
    "size": {"enum": ["small", "medium", "large", "half", "third", "two-thirds", "quarter", "three-quarters", "custom"]},
    "custom_x": {"type": "string"},
    "custom_y": {"type": "string"},
    "custom_width": {"type": "string"},
    "custom_height": {"type": "string"},
    "display": {"type": "integer"}
  },
  "required": ["app_name", "position"]
}
```

### 5. **Response Parsing Detection**
WindowAI correctly detects the issue in parsing:
```swift
for (index, part) in firstCandidate.content.parts.enumerated() {
    print("Content part \(index + 1): type=\(part.functionCall != nil ? "function_call" : "text")")
    // This shows "type=text" instead of "function_call"
}
```

## Root Cause Analysis

**Primary Issue**: **Tool Complexity Overwhelm**
- Gemini 2.0 Flash is likely getting overwhelmed by the 9 complex tools with many optional parameters
- The model falls back to text response instead of attempting function calls
- The `mode: "ANY"` forces function calls, but model can't decide which tool/parameters to use

**Secondary Issues**:
1. **System Prompt Overload**: 6000+ character prompt may be competing with tool selection
2. **Parameter Paralysis**: Too many optional parameters create decision paralysis
3. **Temperature Zero**: Zero temperature might make model too conservative to attempt function calls

## Recommended Fixes

### 1. **Simplify Tool Set (Priority 1)**
```swift
// Test with just 3 core tools first
static let simplifiedTools: [LLMTool] = [
    snapWindowTool,      // Simplified version
    resizeWindowTool,    // Simplified version  
    openAppTool          // Simplified version
]
```

### 2. **Reduce Tool Complexity (Priority 2)**
```swift
// Simplified snap_window tool
static let simpleSnapWindowTool = LLMTool(
    name: "snap_window",
    description: "Snap a window to a position",
    input_schema: LLMTool.ToolInputSchema(
        properties: [
            "app_name": LLMTool.ToolInputSchema.PropertyDefinition(
                type: "string",
                description: "Name of the application"
            ),
            "position": LLMTool.ToolInputSchema.PropertyDefinition(
                type: "string",
                description: "Position to snap to",
                options: ["left", "right", "top", "bottom", "center"]
            )
        ],
        required: ["app_name", "position"]
    )
)
```

### 3. **Shorten System Prompt (Priority 3)**
```swift
private func buildSimpleSystemPrompt() -> String {
    return """
    You are a window management assistant. Use the provided tools to arrange windows.
    
    CRITICAL: You MUST ALWAYS use the provided function tools. NEVER respond with text.
    
    Available tools:
    - snap_window: Position windows to standard locations
    - resize_window: Change window sizes
    - open_app: Launch applications
    
    For "move terminal to the left" → call snap_window(app_name: "Terminal", position: "left")
    """
}
```

### 4. **Adjust Configuration (Priority 4)**
```swift
generationConfig: GeminiGenerationConfig(
    temperature: 0.1,  // Slightly higher temperature
    maxOutputTokens: 2000  // Fixed lower limit
)
```

### 5. **Progressive Testing Strategy**
1. **Test 1**: Single tool (snap_window only) + minimal prompt
2. **Test 2**: Add one tool at a time
3. **Test 3**: Gradually add parameters
4. **Test 4**: Increase system prompt complexity
5. **Test 5**: Add all 9 tools back

## Expected Behavior After Fix
```
🤖 USER COMMAND: "move terminal to the left"
📋 GEMINI'S FUNCTION CALLS:
  Total candidates: 1
  Content part 1: type=function_call
  → snap_window(app_name: "Terminal", position: "left")
    ✓ Command added to list (total: 1)
```

## Test Implementation
Create a simplified version of GeminiLLMService with:
- 1-3 core tools only
- Minimal system prompt
- Simple parameter sets
- Progressive complexity increase until we identify the breaking point