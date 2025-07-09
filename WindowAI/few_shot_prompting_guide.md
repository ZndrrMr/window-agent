# Few-Shot Prompting Guide for WindowAI

## Overview
Few-shot prompting teaches the LLM spatial awareness and consistent layouts by showing it examples of successful window arrangements.

## Optimal Structure for Gemini 2.0 Flash

### System Prompt Enhancement
Add this section to your Gemini system prompt:

```
## Few-Shot Learning Examples

Here are examples of successful window arrangements:

[INSERT YOUR EXAMPLES HERE]

Based on these examples, you should:
1. Use similar spatial relationships for similar commands
2. Maintain consistent layer ordering (3=primary focus, 2=cascade, 1=side, 0=background)
3. Create peek zones where cascaded windows show ~20% visibility
4. Keep windows fully on-screen with clickable areas
5. Use percentage coordinates consistently

## Current Context
```

### Example Format
Each captured layout should be formatted as:

```json
{
    "user_command": "I want to code",
    "tool_calls": [
        "flexible_position(app_name: \"Cursor\", x_position: \"0.0\", y_position: \"0.0\", width: \"55.0\", height: \"85.0\", layer: \"3\", focus: \"true\")",
        "flexible_position(app_name: \"Terminal\", x_position: \"75.0\", y_position: \"0.0\", width: \"25.0\", height: \"100.0\", layer: \"1\", focus: \"false\")",
        "flexible_position(app_name: \"Arc\", x_position: \"35.0\", y_position: \"15.0\", width: \"45.0\", height: \"70.0\", layer: \"2\", focus: \"false\")"
    ]
}
```

### Building Your Training Dataset

1. **Arrange windows manually** to your ideal layout
2. **Use "Capture Current Layout"** from menu bar
3. **Edit the JSON file** to add meaningful user_command
4. **Collect 5-10 examples** covering different use cases:
   - "I want to code" (terminal, editor, browser)
   - "Set up for research" (browser, notes, references)
   - "Focus mode" (single app, maximized)
   - "Compare documents" (two apps side by side)
   - "Video call setup" (video app, chat, notes)

### Integration Steps

1. **Collect Examples**: Use the capture tool to gather 5-10 layouts
2. **Edit User Commands**: Add meaningful descriptions to each capture
3. **Format for Gemini**: Use the `toFewShotExample()` method output
4. **Update System Prompt**: Add examples to your Gemini system prompt
5. **Test Consistency**: Same commands should produce similar layouts

### Performance Tips

- **Quality over Quantity**: 5 high-quality examples beats 20 poor ones
- **Diverse Scenarios**: Cover different app combinations and use cases
- **Consistent Vocabulary**: Use similar language patterns in user commands
- **Validate Results**: Test that LLM reproduces similar layouts

### Example Training Set Structure

```
Few-Shot Examples:
[
  {
    "user_command": "I want to code",
    "tool_calls": [/* coding layout */]
  },
  {
    "user_command": "set up for research", 
    "tool_calls": [/* research layout */]
  },
  {
    "user_command": "focus mode",
    "tool_calls": [/* single app layout */]
  }
]
```

This approach will teach Gemini your preferred spatial relationships and create consistent, intelligent window arrangements.