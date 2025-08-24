#!/usr/bin/env swift

/**
 * Current State Validation for TDD
 * 
 * This validates the current implementation state to confirm our tests should fail.
 */

import Foundation

print("🧪 CONSTRAINT PREVENTION - CURRENT STATE VALIDATION")
print("=" * 60)

// Test 1: Check current token limit in GeminiLLMService.swift
func validateCurrentTokenLimit() {
    print("TEST 1: Checking current constraint retry token limit...")
    
    let servicePath = "/Users/zndrr/Documents/GitHub/window-agent/WindowAI/WindowAI/Services/GeminiLLMService.swift"
    
    do {
        let content = try String(contentsOfFile: servicePath)
        
        // Look for constraint retry token allocation
        if content.contains("maxOutputTokens: 4000") && content.contains("constraint") {
            print("❌ CONFIRMED: Current implementation uses 4000 tokens for constraint retry")
            print("   This SHOULD FAIL our test that expects 8000 tokens")
        } else if content.contains("maxOutputTokens: 8000") && content.contains("constraint") {
            print("✅ UNEXPECTED: Implementation already uses 8000 tokens")
            print("   Test might pass unexpectedly")
        } else {
            print("⚠️  Could not find constraint retry token allocation")
        }
    } catch {
        print("❌ Could not read GeminiLLMService.swift: \(error)")
    }
}

// Test 2: Check for proactive space warning logic
func validateProactiveSpaceWarning() {    
    print("\nTEST 2: Checking for proactive space warning logic...")
    
    let servicePath = "/Users/zndrr/Documents/GitHub/window-agent/WindowAI/WindowAI/Services/GeminiLLMService.swift"
    
    do {
        let content = try String(contentsOfFile: servicePath)
        
        if content.contains("SPACE CONSTRAINT WARNING") {
            print("✅ UNEXPECTED: Proactive space warning already exists")
            print("   Test might pass unexpectedly")
        } else {
            print("❌ CONFIRMED: No proactive space warning logic found")
            print("   This SHOULD FAIL our test that expects space warnings")
        }
    } catch {
        print("❌ Could not read GeminiLLMService.swift: \(error)")
    }
}

// Test 3: Check current retry count
func validateRetryCount() {
    print("\nTEST 3: Checking current constraint retry count...")
    
    let servicePath = "/Users/zndrr/Documents/GitHub/window-agent/WindowAI/WindowAI/Services/GeminiLLMService.swift"
    
    do {
        let content = try String(contentsOfFile: servicePath)
        
        if content.contains("maxRetries = 2") {
            print("❌ CONFIRMED: Current implementation uses 2 retries")
            print("   This SHOULD FAIL our test that expects 1 retry")
        } else if content.contains("maxRetries = 1") {
            print("✅ UNEXPECTED: Implementation already uses 1 retry")
            print("   Test might pass unexpectedly")
        } else {
            print("⚠️  Could not find maxRetries setting")
        }
    } catch {
        print("❌ Could not read GeminiLLMService.swift: \(error)")
    }
}

// Test 4: Check if constraint violations are being detected
func validateConstraintViolations() {
    print("\nTEST 4: Checking constraint validation system...")
    
    let statePath = "/Users/zndrr/Documents/GitHub/window-agent/WindowAI/WindowAI/Core/WindowState.swift"
    
    do {
        let content = try String(contentsOfFile: statePath)
        
        if content.contains("validateConstraints") && content.contains("1600") {
            print("✅ CONFIRMED: Constraint validation system exists (40×40px = 1600px²)")
            print("   System should properly detect constraint violations")
        } else {
            print("❌ Could not find constraint validation logic")
        }
    } catch {
        print("❌ Could not read WindowState.swift: \(error)")
    }
}

// Extension for string repetition
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

// Run validation
validateCurrentTokenLimit()
validateProactiveSpaceWarning()
validateRetryCount()
validateConstraintViolations()

print("\n" + "=" * 60)
print("🎯 TDD VALIDATION COMPLETE")
print("\nIf tests show ❌ CONFIRMED, our TDD tests SHOULD FAIL initially.")
print("This is GOOD - it means we're testing the right behaviors!")
print("\nNext step: Implement fixes to turn ❌ into ✅")