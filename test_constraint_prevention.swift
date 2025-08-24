#!/usr/bin/env swift

/**
 * Test Runner for Constraint Prevention TDD Tests
 * 
 * This script runs the failing tests to establish the RED phase of TDD.
 * After implementation, these tests should turn GREEN.
 */

import Foundation

// Change to the WindowAI directory to access the test files
let windowAIPath = "/Users/zndrr/Documents/GitHub/window-agent/WindowAI/WindowAI"
FileManager.default.changeCurrentDirectoryPath(windowAIPath)

print("🧪 CONSTRAINT PREVENTION TDD TEST RUNNER")
print("Working directory: \(FileManager.default.currentDirectoryPath)")
print("")

print("📋 TDD PHASE: RED (Tests Should Fail)")
print("These tests establish our requirements and should fail before implementation.")
print("")

// Create and run the constraint prevention tests
let tests = ConstraintPreventionTests()
tests.runAllTests()

print("\n🎯 NEXT STEPS:")
print("1. Verify all tests FAIL (this confirms we're testing the right things)")
print("2. Implement minimal fixes to make tests pass (GREEN phase)")
print("3. Refactor while keeping tests green (REFACTOR phase)")
print("\nExpected failures:")
print("- Token limit test (currently 4000, should be 8000)")
print("- Space warning test (no proactive warning logic)")
print("- Retry logic test (currently 2 retries, should be 1)")
print("- Integration test (constraint violations not prevented)")