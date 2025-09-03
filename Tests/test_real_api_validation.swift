#!/usr/bin/env swift

import Foundation
import CoreGraphics

print("🧪 REAL API VALIDATION TEST")
print("===========================")

// This test demonstrates how to validate the fixed screen utilization with real Claude API calls
// Run this test after setting up Claude API credentials to verify actual LLM behavior

print("\n📋 REAL API TEST INSTRUCTIONS")
print("============================")

print("""
To validate the fixed screen utilization behavior with real Claude API:

1. SETUP:
   - Ensure Claude API key is set in environment or Keychain
   - Build and run the WindowAI app with the updated ClaudeLLMService.swift
   - Have Terminal, Cursor, and Arc apps available

2. TEST COMMANDS TO TRY:
   - "fill the whole screen"
   - "use the entire screen space"
   - "maximize screen coverage"
   - "i want to code" (should still maximize screen)

3. EXPECTED BEHAVIOR (from fixed prompt):
   - Total screen coverage should be 95%+ consistently
   - Terminal should expand beyond 25% width if space available
   - Arc should position to avoid excessive overlap while maintaining functionality
   - All apps should collectively span the entire screen dimensions

4. MEASUREMENTS TO TAKE:
   - Record actual window positions and sizes
   - Calculate total screen coverage percentage
   - Verify no large empty areas remain unused
   - Test multiple screen sizes/resolutions

5. COMPARISON METRICS:
   - Old behavior: Often <90% screen coverage
   - New behavior: Should achieve 95%+ coverage
   - Apps should expand beyond typical archetype limitations
""")

// Mock function to demonstrate what real API validation would measure
func validateRealAPIBehavior() {
    print("\n🔬 REAL API VALIDATION CHECKLIST")
    print("===============================")
    
    let validationSteps = [
        "✓ Send 'fill the whole screen' command to real Claude API",
        "✓ Capture actual flexible_position tool calls returned",
        "✓ Measure total screen coverage from actual window positions",
        "✓ Verify Terminal width > 30% (expanded beyond 'minimal horizontal')",
        "✓ Confirm Arc positioning avoids excessive overlap",
        "✓ Test with different screen resolutions (1440x900, 1920x1080, 2560x1440)",
        "✓ Validate consistency across multiple API calls",
        "✓ Compare coverage percentages before/after prompt fixes"
    ]
    
    for (index, step) in validationSteps.enumerated() {
        print("  \(index + 1). \(step)")
    }
}

validateRealAPIBehavior()

// Function to parse and analyze real API responses
func analyzeRealAPIResponse(_ toolCalls: [(String, [String: Any])]) -> (coverage: Double, analysis: [String]) {
    print("\n📊 REAL API RESPONSE ANALYSIS")
    print("============================")
    
    var analysis: [String] = []
    
    // This would analyze actual Claude API responses
    print("Expected analysis of real API tool calls:")
    print("1. Extract all flexible_position calls")
    print("2. Calculate window bounds from percentage coordinates")
    print("3. Measure total screen coverage")
    print("4. Identify positioning improvements")
    print("5. Verify screen utilization priority over archetype limitations")
    
    // Mock analysis for demonstration
    analysis.append("🎯 Claude API should prioritize screen maximization")
    analysis.append("📐 Window sizes should expand beyond typical archetype limits")
    analysis.append("🎨 Positioning should optimize both coverage and accessibility")
    analysis.append("📊 Total coverage should consistently reach 95%+")
    
    return (coverage: 0.96, analysis: analysis) // Mock 96% coverage
}

// Demo what successful validation would look like
print("\n✅ EXPECTED SUCCESSFUL VALIDATION")
print("=================================")

let mockResults = analyzeRealAPIResponse([])
print("If the prompt fixes work correctly, real API testing should show:")
for result in mockResults.analysis {
    print("  \(result)")
}
print("  📈 Screen coverage: \(Int(mockResults.coverage * 100))% (target: 95%+)")

print("\n🚀 NEXT STEPS FOR REAL VALIDATION")
print("=================================")
print("1. Build WindowAI app with updated prompt")
print("2. Set up Claude API credentials")
print("3. Run commands: 'fill the whole screen', 'maximize screen coverage'")
print("4. Measure actual window positions and screen coverage")
print("5. Compare results with old vs new prompt behavior")

print("\n💡 DEBUGGING TIPS IF API STILL DOESN'T MAXIMIZE SCREEN:")
print("=======================================================")
print("• Check if prompt changes are actually being sent to API")
print("• Verify no other code is overriding LLM tool calls")
print("• Test with simpler commands first ('Terminal full width')")
print("• Log exact API request/response to see LLM reasoning")
print("• Consider further strengthening screen utilization language")

print("\n🎯 SUCCESS CRITERIA")
print("==================")
print("✅ 'fill the whole screen' command results in 95%+ coverage")
print("✅ Terminal expands beyond 25% when space available")
print("✅ Arc positions to minimize counterproductive overlap")
print("✅ All apps collectively span entire screen dimensions")
print("✅ Consistent behavior across multiple API calls")

print("\n📝 VALIDATION SCRIPT TEMPLATE")
print("============================")
print("""
// Add this to your app for real API validation:

func validateScreenUtilization() async {
    let userInput = "fill the whole screen"
    let commands = try await llmService.processCommand(userInput, context: context)
    
    var totalCoverage: Double = 0
    // Calculate coverage from actual window positions...
    
    print("Screen coverage: \\(Int(totalCoverage * 100))%")
    assert(totalCoverage >= 0.95, "Screen utilization should be 95%+")
}
""")