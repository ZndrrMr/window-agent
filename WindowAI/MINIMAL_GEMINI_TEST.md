# Minimal Gemini Function Calling Test

This is a simplified test to isolate and debug function calling issues with Gemini 2.0 Flash.

## What This Test Does

1. **Sends minimal request** - Only uses `snap_window` tool with `app_name` and `position` parameters
2. **Forces function calling** - Uses `toolConfig.mode = "ANY"` to require function calls
3. **Extensive debugging** - Shows full JSON request/response for analysis
4. **Isolates issues** - Bypasses complex system prompts and tool ecosystems

## Running the Test

### Option 1: Automatic (Current Setup)
The test will automatically run 3 seconds after launching the WindowAI app and output results to the console.

### Option 2: Manual via Code
Add this code anywhere in the app (breakpoint, test method, etc.):

```swift
Task {
    await testMinimalGemini("move terminal to the left")
}
```

### Option 3: Test Different Commands
```swift
Task {
    await testMinimalGemini("move arc to the right")
    await testMinimalGemini("move finder to the center") 
    await testMinimalGemini("snap terminal left")
}
```

## What to Look For in Output

### ✅ Success Indicators
- `🎯 FUNCTION CALL FOUND!`
- `Function name: snap_window`
- `Arguments: app_name="Terminal", position="left"`
- `✅ Successfully converted to WindowCommand`

### ❌ Failure Indicators
- `📝 TEXT FOUND (this is the problem!)`
- `❌ FUNCTION CALLING FAILED - Model generated text instead of function calls`
- `API error` or `Network error`

## Test Structure

### Request Components
- **URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- **Model**: `gemini-2.0-flash`
- **System Prompt**: Minimal (only function calling requirements)
- **Tools**: Only `snap_window` with 2 parameters
- **Tool Config**: `function_calling_config.mode = "ANY"`
- **Temperature**: 0.0 (deterministic)

### Response Analysis
The test will show:
1. **Raw JSON request** being sent to Gemini
2. **Raw JSON response** received from Gemini
3. **Parsed function calls** (or text if function calling failed)
4. **Conversion to WindowCommand** objects

## Troubleshooting

### Problem: Model generates text instead of function calls
**Diagnosis**: `toolConfig.mode` not properly enforcing function calls
**Fix**: Check that `tool_config.function_calling_config.mode = "ANY"`

### Problem: Wrong function name or parameters
**Diagnosis**: Tool schema mismatch
**Fix**: Verify tool name is `snap_window` and parameters are `app_name`, `position`

### Problem: API errors
**Diagnosis**: API key, endpoint, or request format issues
**Fix**: Check API key validity and request structure

### Problem: Parsing errors
**Diagnosis**: JSON structure doesn't match expected format
**Fix**: Compare response JSON with `GeminiResponse` structure

## Progressive Debugging

If the minimal test fails, these steps will help identify the exact issue:

1. **Check Request JSON** - Verify tool schema is correct
2. **Check Response JSON** - Look for `functionCall` vs `text` in parts
3. **Check Tool Config** - Ensure `mode: "ANY"` is present
4. **Check API Response** - Verify HTTP 200 and valid Gemini response format
5. **Check Parsing Logic** - Verify `GeminiFunctionCall` structure matches response

## Expected Output

```
🧪 MINIMAL GEMINI FUNCTION CALLING TEST
======================================================================
📋 Purpose: Isolate and debug function calling issues with Gemini 2.0 Flash
🎯 Command: "move terminal to the left"
🔧 Tools: Only snap_window with minimal parameters
📡 API: Direct Gemini API with toolConfig.mode = ANY

🧪 MINIMAL TEST: "move terminal to the left"
🔧 MINIMAL TOOLS: 1 tool groups
   - snap_window: 2 parameters (app_name, position)
🎯 FORCING FUNCTION CALLS: toolConfig.mode = ANY

📤 MINIMAL REQUEST DEBUG:
Size: 1234 bytes
Full JSON Request:
{...}

🌐 SENDING MINIMAL REQUEST:
URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=...

📥 RECEIVED MINIMAL RESPONSE:
Response Size: 567 bytes
RAW RESPONSE JSON:
{...}

🔍 PARSING MINIMAL RESPONSE:
Candidates count: 1
Finish reason: STOP
Content parts count: 1

Part 1:
  🎯 FUNCTION CALL FOUND!
  Function name: snap_window
  Arguments count: 2
    app_name: Terminal (type: String)
    position: left (type: String)
  ✅ Successfully converted to WindowCommand
    Action: snap
    Target: Terminal
    Position: left

🎉 SUCCESS: Minimal test completed!
Generated 1 command(s)
✅ Function calling is working!
  1. snap Terminal → left
```

This test will help isolate whether the issue is with:
1. Tool complexity (too many tools/parameters)
2. System prompt interference
3. JSON parsing issues
4. API request structure problems
5. Gemini API function calling implementation