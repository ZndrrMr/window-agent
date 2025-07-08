#!/usr/bin/env swift

import Foundation
import Cocoa

print("🧪 Testing X-Ray Hotkey-Only Triggering")
print("⚡ Verifying X-Ray only appears on hotkey activation")
print("")

// Test 1: Verify showPostArrangementOverlay is disabled
func testPostArrangementDisabled() -> Bool {
    print("📊 Test 1: Post-Arrangement Overlay Disabled")
    
    // Check that the method is commented out in source
    let sourceFile = "WindowAI/Core/XRayWindowManager.swift"
    
    do {
        let content = try String(contentsOfFile: sourceFile)
        
        // Look for the commented-out method
        let isCommentedOut = content.contains("// func showPostArrangementOverlay") ||
                           content.contains("// DISABLED: Automatic X-Ray triggers removed")
        
        print("   showPostArrangementOverlay method commented out: \(isCommentedOut ? "✅" : "❌")")
        
        // Look for any remaining calls to showPostArrangementOverlay
        let hasCalls = content.contains("showPostArrangementOverlay(")
        
        print("   No active calls to showPostArrangementOverlay: \(hasCalls ? "❌" : "✅")")
        
        let testPassed = isCommentedOut && !hasCalls
        print("   Result: Post-arrangement overlay disabled - \(testPassed ? "✅ PASS" : "❌ FAIL")")
        
        return testPassed
        
    } catch {
        print("   ❌ Error reading source file: \(error)")
        return false
    }
}

// Test 2: Verify executeCommands no longer triggers X-Ray
func testExecuteCommandsNoTrigger() -> Bool {
    print("📊 Test 2: executeCommands No Longer Triggers X-Ray")
    
    let sourceFile = "WindowAI/App.swift"
    
    do {
        let content = try String(contentsOfFile: sourceFile)
        
        // Check that the showPostArrangementOverlay call is removed
        let hasOldTrigger = content.contains("XRayWindowManager.shared.showPostArrangementOverlay")
        
        print("   Old automatic trigger removed: \(hasOldTrigger ? "❌" : "✅")")
        
        // Check that we still track successful commands but don't trigger X-Ray
        let hasSuccessfulCommandsTracking = content.contains("successfulCommands") &&
                                          content.contains("Completed") &&
                                          content.contains("successful window operations")
        
        print("   Success tracking maintained: \(hasSuccessfulCommandsTracking ? "✅" : "❌")")
        
        let testPassed = !hasOldTrigger && hasSuccessfulCommandsTracking
        print("   Result: executeCommands no longer triggers X-Ray - \(testPassed ? "✅ PASS" : "❌ FAIL")")
        
        return testPassed
        
    } catch {
        print("   ❌ Error reading source file: \(error)")
        return false
    }
}

// Test 3: Verify hotkey trigger still works
func testHotkeyTriggerPreserved() -> Bool {
    print("📊 Test 3: Hotkey Trigger Preserved")
    
    let sourceFile = "WindowAI/App.swift"
    
    do {
        let content = try String(contentsOfFile: sourceFile)
        
        // Check that xrayOverlayRequested method exists
        let hasHotkeyMethod = content.contains("func xrayOverlayRequested()")
        
        print("   xrayOverlayRequested method exists: \(hasHotkeyMethod ? "✅" : "❌")")
        
        // Check that it calls toggleXRayOverlay
        let hasToggleCall = content.contains("XRayWindowManager.shared.toggleXRayOverlay()")
        
        print("   Hotkey method calls toggleXRayOverlay: \(hasToggleCall ? "✅" : "❌")")
        
        // Check that it's triggered by double-tap Command key
        let hasDoubleTapMessage = content.contains("double-tap Command key")
        
        print("   Double-tap Command key message present: \(hasDoubleTapMessage ? "✅" : "❌")")
        
        let testPassed = hasHotkeyMethod && hasToggleCall && hasDoubleTapMessage
        print("   Result: Hotkey trigger preserved - \(testPassed ? "✅ PASS" : "❌ FAIL")")
        
        return testPassed
        
    } catch {
        print("   ❌ Error reading source file: \(error)")
        return false
    }
}

// Test 4: Verify no other automatic triggers exist
func testNoOtherAutomaticTriggers() -> Bool {
    print("📊 Test 4: No Other Automatic Triggers")
    
    let sourceFiles = [
        "WindowAI/App.swift",
        "WindowAI/Core/XRayWindowManager.swift",
        "WindowAI/Core/CommandExecutor.swift",
        "WindowAI/Core/WindowManager.swift"
    ]
    
    var automaticTriggerCount = 0
    var totalChecked = 0
    
    for sourceFile in sourceFiles {
        do {
            let content = try String(contentsOfFile: sourceFile)
            totalChecked += 1
            
            // Look for automatic triggers (not in test methods or hotkey method)
            let lines = content.components(separatedBy: .newlines)
            
            for (index, line) in lines.enumerated() {
                if line.contains("showXRayOverlay()") && 
                   !line.contains("//") && 
                   !isInTestMethod(lines: lines, lineIndex: index) &&
                   !isInHotkeyMethod(lines: lines, lineIndex: index) {
                    automaticTriggerCount += 1
                    print("   ⚠️ Found potential automatic trigger in \(sourceFile): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }
            
        } catch {
            print("   ⚠️ Could not read \(sourceFile): \(error)")
        }
    }
    
    print("   Files checked: \(totalChecked)")
    print("   Automatic triggers found: \(automaticTriggerCount)")
    
    let testPassed = automaticTriggerCount == 0
    print("   Result: No automatic triggers found - \(testPassed ? "✅ PASS" : "❌ FAIL")")
    
    return testPassed
}

// Helper function to check if a line is in a test method
func isInTestMethod(lines: [String], lineIndex: Int) -> Bool {
    // Look backwards for method declaration
    for i in (0..<lineIndex).reversed() {
        let line = lines[i].trimmingCharacters(in: .whitespaces)
        if line.contains("func test") || line.contains("func runPerformanceTests") {
            return true
        }
        if line.contains("func ") && !line.contains("test") {
            return false
        }
    }
    return false
}

// Helper function to check if a line is in the hotkey method
func isInHotkeyMethod(lines: [String], lineIndex: Int) -> Bool {
    // Look backwards for xrayOverlayRequested method
    for i in (0..<lineIndex).reversed() {
        let line = lines[i].trimmingCharacters(in: .whitespaces)
        if line.contains("func xrayOverlayRequested") {
            return true
        }
        if line.contains("func ") && !line.contains("xrayOverlayRequested") {
            return false
        }
    }
    return false
}

// Test 5: Verify showQuickPreview is also disabled
func testQuickPreviewDisabled() -> Bool {
    print("📊 Test 5: Quick Preview Mode Disabled")
    
    let sourceFile = "WindowAI/Core/XRayWindowManager.swift"
    
    do {
        let content = try String(contentsOfFile: sourceFile)
        
        // Check that showQuickPreview is commented out
        let isCommentedOut = content.contains("// func showQuickPreview") ||
                           content.contains("// /// Quick preview mode")
        
        print("   showQuickPreview method commented out: \(isCommentedOut ? "✅" : "❌")")
        
        // Look for any remaining calls to showQuickPreview
        let hasCalls = content.contains("showQuickPreview(")
        
        print("   No active calls to showQuickPreview: \(hasCalls ? "❌" : "✅")")
        
        let testPassed = isCommentedOut && !hasCalls
        print("   Result: Quick preview mode disabled - \(testPassed ? "✅ PASS" : "❌ FAIL")")
        
        return testPassed
        
    } catch {
        print("   ❌ Error reading source file: \(error)")
        return false
    }
}

// Run all tests
print("🚀 Running X-Ray Hotkey-Only Tests")
print("=" + String(repeating: "=", count: 45))

let test1 = testPostArrangementDisabled()
print("")
let test2 = testExecuteCommandsNoTrigger()
print("")
let test3 = testHotkeyTriggerPreserved()
print("")
let test4 = testNoOtherAutomaticTriggers()
print("")
let test5 = testQuickPreviewDisabled()

print("")
print("📋 X-Ray Hotkey-Only Test Results:")
print("   1. Post-Arrangement Overlay Disabled: \(test1 ? "✅ PASS" : "❌ FAIL")")
print("   2. executeCommands No Longer Triggers: \(test2 ? "✅ PASS" : "❌ FAIL")")
print("   3. Hotkey Trigger Preserved: \(test3 ? "✅ PASS" : "❌ FAIL")")
print("   4. No Other Automatic Triggers: \(test4 ? "✅ PASS" : "❌ FAIL")")
print("   5. Quick Preview Mode Disabled: \(test5 ? "✅ PASS" : "❌ FAIL")")

let allTestsPassed = test1 && test2 && test3 && test4 && test5

print("")
if allTestsPassed {
    print("🎉 ALL X-RAY HOTKEY-ONLY TESTS PASSED!")
    print("✅ X-Ray overlay now only triggers via hotkey (double-tap Command)")
    print("✅ No automatic triggers during command execution")
    print("✅ No post-arrangement overlay triggers")
    print("✅ No quick preview mode triggers")
    print("✅ Hotkey functionality preserved")
} else {
    print("❌ SOME X-RAY HOTKEY-ONLY TESTS FAILED!")
    print("🔧 Review implementation for failing scenarios")
}

print("")
print("💡 Changes Made:")
print("   • Removed showPostArrangementOverlay call from executeCommands")
print("   • Commented out showPostArrangementOverlay method")
print("   • Commented out showQuickPreview method")
print("   • Preserved xrayOverlayRequested hotkey method")
print("   • X-Ray now only appears when you double-tap Command key")
print("")
print("🎯 User Experience:")
print("   • X-Ray will NOT appear while typing commands")
print("   • X-Ray will NOT appear after command execution")
print("   • X-Ray will ONLY appear when you double-tap Command key")
print("   • Perfect for intentional X-Ray usage only!")