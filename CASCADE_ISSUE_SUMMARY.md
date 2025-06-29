# CASCADE LAYOUT SYSTEM - ISSUE SUMMARY FOR NEXT DEVELOPER

## Core Problem
The user wants an intelligent cascade window layout system where windows are layered on top of each other (like a cascade of cards) rather than tiled side-by-side. The system should:

1. **Layer windows with strategic overlaps** - not tile them
2. **Keep all windows partially visible and clickable**
3. **Automatically determine which app should be focused** based on context
4. **Work with ANY app combination** - no hardcoding specific app names
5. **Size windows appropriately by type** (Terminal ≤30% width, browsers ≥35% width)

## What's Been Attempted

### 1. Created Archetype System
- Apps are classified into archetypes: `codeWorkspace`, `contentCanvas`, `textStream`, `glanceableMonitor`
- This allows the system to work with any app, not just hardcoded names
- Files: `/WindowAI/Models/AppArchetypes.swift`

### 2. Rewrote Layout Engine
- Removed hardcoded app names from `FlexibleLayoutEngine.generateRealisticFocusLayout()`
- Made it fully archetype-based
- Files: `/WindowAI/Models/FlexiblePositioning.swift`

### 3. Updated LLM Integration
- Fixed size philosophy mismatch in prompt
- Added context detection improvements
- Files: `/WindowAI/Services/ClaudeLLMService.swift`

### 4. Enhanced Focus Resolution
- Added `intelligentlySelectFocusedApp()` to determine focus by context
- Context-aware priorities (coding context: IDE > Browser > Terminal)
- Files: `/WindowAI/Core/WindowPositioner.swift`

## Current Status - IT'S NOT WORKING

Despite all these changes, when the user tests with "i want to code":
- The cascade layout is not being applied correctly
- Windows might still be tiling instead of cascading
- Focus might be going to the wrong app
- The LLM might not be calling the cascade_windows tool properly

## Key Files to Investigate

1. **`/WindowAI/WindowAI/Core/WindowPositioner.swift`** - Line 861-1003
   - The `cascadeWindows()` function that handles cascade commands
   - Check if it's actually using the FlexibleLayoutEngine properly

2. **`/WindowAI/WindowAI/Models/FlexiblePositioning.swift`** - Line 283-539
   - The `generateRealisticFocusLayout()` function
   - This is supposed to create the cascade layout but might not be working

3. **`/WindowAI/WindowAI/Services/ClaudeLLMService.swift`** - Line 244
   - The prompt that tells the LLM to "ALWAYS use cascade_windows when multiple apps are involved"
   - The LLM might not be following this instruction

4. **`/WindowAI/WindowAI/Models/LLMTools.swift`** - Line 303-333
   - The `cascade_windows` tool definition
   - Check if parameters are being passed correctly

## Test Driven Development Approach

Create actual tests that:
1. **Test the LLM is calling cascade_windows** (not snap_window individually)
2. **Test the cascade layout produces overlapping windows** (not side-by-side)
3. **Test focus goes to the correct app** based on archetype priority
4. **Test with different app combinations** to ensure no hardcoding

## Debug Output to Look For

When running "i want to code", you should see:
```
🎯 ARCHETYPE-BASED CASCADE LAYOUT:
  📱 Apps: Terminal, Arc, Xcode
  📱 Terminal → Text Stream
  📱 Arc → Content Canvas
  📱 Xcode → Code Workspace
  🎯 Focused archetype: Code Workspace
```

If you don't see this, the cascade system isn't being invoked properly.

## The Real Issue Might Be

1. **The LLM is not calling cascade_windows** - it might be calling snap_window multiple times instead
2. **The cascade layout math is wrong** - windows might be positioned without proper overlap
3. **The tool conversion is broken** - cascade_windows might not be converting to the right WindowCommand
4. **The FlexibleLayoutEngine is not being invoked** - the system might be using a different code path

## Next Steps for TDD

1. Write a test that captures the actual LLM response for "i want to code"
2. Verify it's calling cascade_windows, not multiple snap_window calls
3. Test the actual window positions are cascading (overlapping), not tiling
4. Test with multiple app combinations to ensure no hardcoding remains

## Project State
- All changes have been made to the codebase
- The app builds successfully
- Test files created: `test_cascade_system.swift`, `validate_cascade_improvements.swift`
- Ready for test-driven debugging to find why it's not working in practice

Good luck!