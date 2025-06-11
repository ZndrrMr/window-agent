import Foundation
import Cocoa

/// Test harness for LLM command processing
class LLMCommandTester {
    
    private let llmService: ClaudeLLMService
    private let windowManager: WindowManager
    private let commandExecutor: CommandExecutor
    
    init() {
        self.windowManager = WindowManager.shared
        // Get API key from environment or use placeholder
        let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "test-key"
        self.llmService = ClaudeLLMService(apiKey: apiKey)
        
        let appLauncher = AppLauncher()
        self.commandExecutor = CommandExecutor(windowManager: windowManager, appLauncher: appLauncher)
    }
    
    /// Test a command and return the results
    func testCommand(_ prompt: String, execute: Bool = false) async throws -> TestResult {
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 TESTING COMMAND: \"\(prompt)\"")
        print(String(repeating: "=", count: 80))
        
        // Build context
        let context = llmService.buildCurrentContext(windowManager: windowManager)
        
        // Process through LLM
        let startTime = Date()
        let commands = try await llmService.processCommand(prompt, context: context)
        let llmDuration = Date().timeIntervalSince(startTime)
        
        print("\n📊 LLM RESPONSE:")
        print("  ⏱️  Duration: \(String(format: "%.2f", llmDuration))s")
        print("  📦 Commands generated: \(commands.count)")
        
        // Print each command
        for (index, command) in commands.enumerated() {
            print("\n  Command \(index + 1):")
            print("    Action: \(command.action.rawValue)")
            print("    Target: \(command.target)")
            if let position = command.position {
                print("    Position: \(position.rawValue)")
            }
            if let size = command.size {
                print("    Size: \(size.rawValue)")
            }
            if let customPosition = command.customPosition {
                print("    Custom Position: \(customPosition)")
            }
            if let customSize = command.customSize {
                print("    Custom Size: \(customSize)")
            }
        }
        
        var executionResults: [CommandResult] = []
        
        // Optionally execute commands
        if execute {
            print("\n🚀 EXECUTING COMMANDS:")
            executionResults = await commandExecutor.executeCommands(commands)
            
            for (index, result) in executionResults.enumerated() {
                let statusIcon = result.success ? "✅" : "❌"
                print("  Command \(index + 1): \(statusIcon) \(result.message)")
            }
        }
        
        let result = TestResult(
            prompt: prompt,
            commands: commands,
            executionResults: executionResults,
            llmDuration: llmDuration,
            totalCommands: commands.count,
            successfulCommands: executionResults.filter { $0.success }.count
        )
        
        print("\n📈 SUMMARY:")
        print("  Total commands: \(result.totalCommands)")
        if execute {
            print("  Successful: \(result.successfulCommands)")
            print("  Failed: \(result.totalCommands - result.successfulCommands)")
        }
        print(String(repeating: "=", count: 80))
        
        return result
    }
    
    /// Run multiple test cases
    func runTestSuite() async {
        let testCases = [
            // Single commands
            "Open Safari",
            "Put Messages in the top right corner",
            "Make Terminal tall and narrow",
            
            // Multiple commands - the problematic ones
            "put messages in the top right at the same size. make the terminal super tall, but don't change its width. make arc browser take up the middle third from top to bottom.",
            "Open Xcode on the left half and Safari on the right half",
            "Set up my coding environment with Cursor, Terminal, and Arc",
            
            // Complex arrangements
            "I want to code with Cursor taking up most of the screen but Terminal visible at the bottom",
            "Cascade all my windows intelligently",
            "Arrange windows for research with browser prominent and notes on the side"
        ]
        
        var results: [TestResult] = []
        
        for testCase in testCases {
            do {
                let result = try await testCommand(testCase, execute: false)
                results.append(result)
                
                // Add delay between tests
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            } catch {
                print("❌ Test failed for '\(testCase)': \(error)")
            }
        }
        
        // Print summary
        print("\n\n" + String(repeating: "=", count: 80))
        print("📊 TEST SUITE SUMMARY")
        print(String(repeating: "=", count: 80))
        
        for result in results {
            let _ = String(format: "%.1f", Double(result.totalCommands))
            print("\n\"\(result.prompt)\"")
            print("  → \(result.totalCommands) command(s) generated")
        }
        
        let totalCommands = results.reduce(0) { $0 + $1.totalCommands }
        let avgCommands = Double(totalCommands) / Double(results.count)
        print("\n📈 OVERALL STATS:")
        print("  Test cases: \(results.count)")
        print("  Total commands: \(totalCommands)")
        print("  Average commands per prompt: \(String(format: "%.1f", avgCommands))")
    }
}

// MARK: - Test Result
struct TestResult {
    let prompt: String
    let commands: [WindowCommand]
    let executionResults: [CommandResult]
    let llmDuration: TimeInterval
    let totalCommands: Int
    let successfulCommands: Int
}

// MARK: - Standalone Test Runner
@available(macOS 12.0, *)
func runLLMTests() async {
    let tester = LLMCommandTester()
    
    // Check if we have API key
    guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] else {
        print("❌ Error: ANTHROPIC_API_KEY environment variable not set")
        print("Set it with: export ANTHROPIC_API_KEY=your_key_here")
        return
    }
    
    print("🔑 Using API key: \(String(apiKey.prefix(10)))...")
    
    // Run the test suite
    await tester.runTestSuite()
}