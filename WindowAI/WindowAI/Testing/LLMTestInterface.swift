import Foundation
import Cocoa

// MARK: - Simple Test Interface for LLM Integration
class LLMTestInterface {
    
    private let windowManager: WindowManager
    private let commandExecutor: CommandExecutor
    // ClaudeLLMService removed - using Gemini via LLMService
    private var llmService: LLMService?
    
    init() {
        self.windowManager = WindowManager.shared
        self.commandExecutor = CommandExecutor(windowManager: windowManager)
        
        // Set up Gemini service (it has built-in API key)
        self.llmService = LLMService(windowManager: windowManager)
    }
    
    // MARK: - Setup
    func setupWithAPIKey(_ apiKey: String) {
        // Claude service removed - now using Gemini via LLMService
        print("✅ Using Gemini LLM Service (built-in API key)")
    }
    
    // MARK: - Test Commands
    func testCommand(_ userInput: String) async {
        guard let llmService = llmService else {
            print("❌ LLM Service not configured.")
            return
        }
        
        print("\n🎯 Testing command: \"\(userInput)\"")
        
        do {
            print("🤖 Sending to Gemini 2.0 Flash...")
            let response = try await llmService.processCommand(userInput)
            let commands = response.commands
            
            print("✨ Received \(commands.count) command(s):")
            for (index, command) in commands.enumerated() {
                print("   \(index + 1). \(command.action.rawValue) \(command.target)")
                if let position = command.position {
                    print("      Position: \(position.rawValue)")
                }
                if let size = command.size {
                    print("      Size: \(size.rawValue)")
                }
            }
            
            print("🔧 Executing commands...")
            for command in commands {
                let result = await commandExecutor.executeCommand(command)
                let status = result.success ? "✅" : "❌"
                print("   \(status) \(result.message)")
            }
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Cases
    func runTestSuite() async {
        guard llmService != nil else {
            print("❌ LLM Service not configured.")
            return
        }
        
        print("\n🧪 Running LLM Integration Test Suite")
        print("=====================================")
        
        let testCases = [
            "Open Safari and put it on the left half",
            "Move Terminal to the right side",
            "Arrange my windows for coding",
            "Minimize all distracting apps",
            "Open Finder and make it small in the top right",
            "Set up a research workspace"
        ]
        
        for testCase in testCases {
            await testCommand(testCase)
            print("\n⏱️  Waiting 2 seconds...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        print("\n🎉 Test suite completed!")
    }
    
    // MARK: - MINIMAL GEMINI FUNCTION CALLING TEST
    func testMinimalGeminiFunctionCalling(_ command: String = "move terminal to the left") async {
        guard let llmService = llmService else {
            print("❌ LLM Service not configured")
            return
        }
        
        print("\n🧪 MINIMAL GEMINI FUNCTION CALLING TEST")
        print(String(repeating: "=", count: 70))
        print("📋 Purpose: Isolate and debug function calling issues with Gemini 2.0 Flash")
        print("🎯 Command: \"\(command)\"")
        print("🔧 Tools: Only snap_window with minimal parameters")
        print("📡 API: Direct Gemini API with toolConfig.mode = ANY")
        print("")
        
        do {
            let response = try await llmService.processCommand(command)
            let commands = response.commands
            
            print("\n🎉 SUCCESS: Minimal test completed!")
            print("Generated \(commands.count) command(s)")
            
            if commands.isEmpty {
                print("⚠️  No commands generated - this indicates a function calling issue")
            } else {
                print("✅ Function calling is working!")
                for (index, cmd) in commands.enumerated() {
                    print("  \(index + 1). \(cmd.action.rawValue) \(cmd.target) → \(cmd.position?.rawValue ?? "no position")")
                }
            }
            
        } catch {
            print("\n❌ MINIMAL TEST FAILED:")
            print("Error: \(error)")
            
            if let geminiError = error as? GeminiLLMError {
                print("\nGemini Error Details:")
                switch geminiError {
                case .noToolsUsed(let response):
                    print("🔍 DIAGNOSIS: Model generated text instead of function calls")
                    print("📝 Response: \(response)")
                    print("💡 FIX: Check tool_config.function_calling_config.mode = 'ANY'")
                    
                case .apiError(let message):
                    print("🔍 DIAGNOSIS: API error from Gemini")
                    print("📝 Message: \(message)")
                    print("💡 FIX: Check API key, model name, or request format")
                    
                case .networkError(let networkError):
                    print("🔍 DIAGNOSIS: Network connectivity issue")
                    print("📝 Error: \(networkError)")
                    print("💡 FIX: Check internet connection and API endpoint")
                    
                case .noCommandsGenerated:
                    print("🔍 DIAGNOSIS: No function calls or text in response")
                    print("💡 FIX: Check if response parsing is working correctly")
                    
                default:
                    print("🔍 DIAGNOSIS: Other Gemini error")
                    print("💡 FIX: Check full error details above")
                }
            }
        }
        
        print(String(repeating: "=", count: 70))
    }
    
    // MARK: - System Information
    func printSystemInfo() {
        print("\n📱 System Information")
        print("===================")
        
        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName }
            .filter { !["Dock", "SystemUIServer", "WindowServer"].contains($0) }
        
        print("Running Apps (\(runningApps.count)):")
        for app in runningApps.prefix(10) {
            print("  • \(app)")
        }
        if runningApps.count > 10 {
            print("  ... and \(runningApps.count - 10) more")
        }
        
        print("\nDisplays (\(NSScreen.screens.count)):")
        for (index, screen) in NSScreen.screens.enumerated() {
            let size = screen.frame.size
            print("  \(index): \(Int(size.width))x\(Int(size.height))")
        }
        
        let allWindows = windowManager.getAllWindows()
        print("\nVisible Windows (\(allWindows.count)):")
        for window in allWindows.prefix(5) {
            print("  • \(window.appName): \(window.title)")
        }
        if allWindows.count > 5 {
            print("  ... and \(allWindows.count - 5) more")
        }
    }
}

// MARK: - Quick Test Function
func quickTestLLM(apiKey: String, command: String) async {
    let tester = LLMTestInterface()
    tester.setupWithAPIKey(apiKey)
    tester.printSystemInfo()
    await tester.testCommand(command)
}

// MARK: - Full Test Suite Function  
func runFullLLMTestSuite(apiKey: String) async {
    let tester = LLMTestInterface()
    tester.setupWithAPIKey(apiKey)
    tester.printSystemInfo()
    await tester.runTestSuite()
}

// MARK: - MINIMAL GEMINI FUNCTION CALLING TEST
func testMinimalGemini(_ command: String = "move terminal to the left") async {
    let tester = LLMTestInterface()
    await tester.testMinimalGeminiFunctionCalling(command)
}

// Example usage (you can call this from anywhere):
/*

// Test with Gemini (no API key needed - built-in):
Task {
    await quickTestLLM(
        apiKey: "", // Not used anymore
        command: "Open Safari and put it on the left half of the screen"
    )
}

// Test Gemini minimal function calling (no API key needed - built-in):
Task {
    await testMinimalGemini("move terminal to the left")
}

// Test different commands:
Task {
    await testMinimalGemini("move arc to the right")
    await testMinimalGemini("move finder to the center")
    await testMinimalGemini("snap terminal left")
}

*/