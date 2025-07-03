# Minimal Gemini Function Calling Test - Implementation Summary

## What Was Created

### 1. **Minimal Test Method in GeminiLLMService**
- Added `testMinimalFunctionCalling()` method to `GeminiLLMService.swift`
- Uses only `snap_window` tool with minimal parameters (`app_name`, `position`)
- Minimal system prompt focusing only on function calling requirements
- Forces function calling with `toolConfig.mode = "ANY"`
- Extensive request/response debugging with full JSON logging

### 2. **Test Interface Integration**
- Updated `LLMTestInterface.swift` to include Gemini test capability
- Added `testMinimalGeminiFunctionCalling()` method with detailed error analysis
- Added global function `testMinimalGemini()` for easy access
- Comprehensive error diagnostics for different failure modes

### 3. **LLMService Integration**
- Added `testMinimalFunctionCalling()` method to `LLMService.swift` 
- Wrapper that calls the Gemini test and provides formatted output
- Uses existing Gemini service instance with built-in API key

### 4. **Documentation and Instructions**
- Created `MINIMAL_GEMINI_TEST.md` with detailed usage instructions
- Created `test_minimal_gemini.swift` script with debugging guidelines
- Updated example usage in `LLMTestInterface.swift`

## Key Features

### **Isolation and Debugging**
- **Minimal Tool Set**: Only `snap_window` with 2 parameters vs 9 complex tools
- **Simple System Prompt**: Removed complex cascade logic and archetype instructions
- **Zero Temperature**: Deterministic responses for consistent testing
- **Full JSON Logging**: Shows exact request/response for analysis
- **Error Categorization**: Specific diagnostics for different failure types

### **Function Calling Enforcement**
- **Tool Config Mode**: Forces function calls with `mode: "ANY"`
- **No Text Responses**: Should never return explanatory text
- **Parameter Validation**: Checks function name and argument structure
- **Conversion Testing**: Verifies tool use converts to WindowCommand correctly

### **Progressive Debugging**
1. **Request Validation**: Verify tool schema is correctly formatted
2. **Response Analysis**: Check for `functionCall` vs `text` content
3. **API Diagnostics**: Validate HTTP status and response structure
4. **Parsing Verification**: Ensure JSON matches expected format

## How to Run the Test

### **Option 1: Manual Code Execution**
Add this anywhere in the app (breakpoint, debug method, etc.):
```swift
Task {
    await testMinimalGemini("move terminal to the left")
}
```

### **Option 2: Enable Automatic Test**
Uncomment lines 43-47 in `App.swift` to run test 3 seconds after app launch.

### **Option 3: Different Commands**
```swift
Task {
    await testMinimalGemini("move arc to the right")
    await testMinimalGemini("move finder to the center") 
    await testMinimalGemini("snap terminal left")
}
```

## Expected Output Analysis

### **✅ Success Pattern**
```
🎯 FUNCTION CALL FOUND!
Function name: snap_window
Arguments count: 2
  app_name: Terminal (type: String)
  position: left (type: String)
✅ Successfully converted to WindowCommand
```

### **❌ Common Failure Patterns**

#### **Text Response Instead of Function Call**
```
📝 TEXT FOUND (this is the problem!):
  "I'll help you move the terminal to the left side of the screen."
🔍 DIAGNOSIS: Model generated text instead of function calls
💡 FIX: Check tool_config.function_calling_config.mode = 'ANY'
```

#### **API Errors**
```
🔍 DIAGNOSIS: API error from Gemini
📝 Message: "Invalid API key" or "Model not found"
💡 FIX: Check API key, model name, or request format
```

#### **Network Issues**
```
🔍 DIAGNOSIS: Network connectivity issue
💡 FIX: Check internet connection and API endpoint
```

## Debugging Workflow

### **Step 1: Check Request JSON**
Look for:
- Tool schema with correct `snap_window` definition
- `tool_config.function_calling_config.mode = "ANY"`
- Minimal system instruction
- Simple user message

### **Step 2: Check Response JSON**
Look for:
- `candidates[0].content.parts[0].functionCall` (not `text`)
- Function name matches `snap_window`
- Arguments contain `app_name` and `position`

### **Step 3: Analyze Failure Point**
- **No function calls**: Tool config issue
- **Wrong function**: Tool schema mismatch  
- **Wrong parameters**: Parameter definition issue
- **Parsing errors**: JSON structure mismatch

## Files Modified

1. **WindowAI/Services/GeminiLLMService.swift** - Added minimal test method
2. **WindowAI/Services/LLMService.swift** - Added test wrapper method
3. **WindowAI/Testing/LLMTestInterface.swift** - Added test interface and error analysis
4. **WindowAI/App.swift** - Added optional automatic test trigger
5. **MINIMAL_GEMINI_TEST.md** - Detailed usage documentation
6. **test_minimal_gemini.swift** - Standalone test script
7. **IMPLEMENTATION_SUMMARY.md** - This summary

## Build Status

✅ **Project builds successfully** - All code compiles without errors

## Next Steps

1. **Run the test** using one of the three methods above
2. **Analyze the output** to identify the specific failure point
3. **Compare request/response JSON** with expected format
4. **Iterate on fixes** based on diagnostic information
5. **Gradually increase complexity** once basic function calling works

This minimal test isolates the core function calling mechanism and provides detailed diagnostics to identify exactly where and why Gemini function calling might be failing.