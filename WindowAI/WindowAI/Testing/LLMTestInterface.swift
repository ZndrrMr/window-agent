import Foundation
import Cocoa

// MARK: - Simple Test Interface for LLM Integration
class LLMTestInterface {
    
    private let windowManager: WindowManager
    private let commandExecutor: CommandExecutor
    private let appLauncher: AppLauncher
    private var claudeService: ClaudeLLMService?
    
    init() {
        self.windowManager = WindowManager.shared
        self.appLauncher = AppLauncher()
        self.commandExecutor = CommandExecutor(windowManager: windowManager, appLauncher: appLauncher)
    }
    
    // MARK: - Setup
    func setupWithAPIKey(_ apiKey: String) {
        claudeService = ClaudeLLMService(apiKey: apiKey)
        print("✅ Claude LLM Service configured")
    }
    
    // MARK: - Test Commands
    func testCommand(_ userInput: String) async {
        guard let claude = claudeService else {
            print("❌ No API key configured. Use setupWithAPIKey() first.")
            return
        }
        
        print("\n🎯 Testing command: \"\(userInput)\"")
        print("📊 Building system context...")
        
        let context = claude.buildCurrentContext(windowManager: windowManager)
        print("   • Running apps: \(context.runningApps.count)")
        print("   • Visible windows: \(context.visibleWindows.count)")
        print("   • Displays: \(context.displayCount)")
        
        do {
            print("🤖 Sending to Claude Sonnet 4...")
            print("🔍 First tool schema:", WindowManagementTools.allTools.first?.input_schema ?? "No tools")
            let commands = try await claude.processCommand(userInput, context: context)
            
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
        guard claudeService != nil else {
            print("❌ No API key configured. Use setupWithAPIKey() first.")
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

// Example usage (you can call this from anywhere):
/*
Task {
    await quickTestLLM(
        apiKey: "your-anthropic-api-key-here",
        command: "Open Safari and put it on the left half of the screen"
    )
}
*/