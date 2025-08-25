import Cocoa
import Foundation

class CommandExecutor {
    private let windowManager: WindowManager
    private let windowPositioner: WindowPositioner
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        self.windowPositioner = WindowPositioner(windowManager: windowManager)
    }
    
    // MARK: - Command Execution (Simplified - No Animations)
    func executeCommandsAnimated(_ commands: [WindowCommand]) async -> [CommandResult] {
        // Simplified to use instant execution (no animations)
        return await executeCommands(commands)
    }

    // MARK: - Command Execution
    func executeCommands(_ commands: [WindowCommand]) async -> [CommandResult] {
        var results: [CommandResult] = []
        
        print("\n🔧 COMMAND EXECUTOR:")
        print("  Received \(commands.count) command(s) to execute")
        
        for (index, command) in commands.enumerated() {
            print("\n  Executing command \(index + 1)/\(commands.count): \(command.action.rawValue) \(command.target)")
            
            // Add a small delay between commands to ensure they execute properly
            if !results.isEmpty {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            let result = await executeCommand(command)
            results.append(result)
            
            print("    Result: \(result.success ? "✅" : "❌") \(result.message)")
            
            // If a command fails and it's critical (like opening an app), stop execution
            if !result.success && (command.action == .open || command.action == .focus) {
                print("⚠️ Critical command failed, stopping execution: \(result.message)")
                break
            }
        }
        
        print("\n  Execution complete: \(results.count) results")
        return results
    }
    
    func executeCommand(_ command: WindowCommand) async -> CommandResult {
        return windowPositioner.executeCommand(command)
    }
    
    // MARK: - Individual Command Handlers
    private func executeOpenCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Open the specified application
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func executeMoveCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Move window to specified position
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func executeResizeCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Resize window to specified size
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func executeFocusCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Focus the specified window
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func executeArrangeCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Arrange windows for specific context (coding, writing, etc.)
        return await executeContextArrangement(command.target)
    }
    
    private func executeCloseCommand(_ command: WindowCommand) async -> CommandResult {
        // TODO: Close the specified window or app
        return CommandResult(success: false, message: "Not implemented")
    }
    
    // MARK: - Context-Aware Arrangements
    private func executeContextArrangement(_ context: String) async -> CommandResult {
        switch context.lowercased() {
        case "coding", "development", "dev":
            return await arrangeCodingLayout()
        case "writing", "document", "docs":
            return await arrangeWritingLayout()
        case "research", "browse", "browsing":
            return await arrangeResearchLayout()
        case "communication", "chat", "messaging":
            return await arrangeCommunicationLayout()
        case "design", "creative":
            return await arrangeDesignLayout()
        default:
            return CommandResult(success: false, message: "Unknown context: \(context)")
        }
    }
    
    private func arrangeCodingLayout() async -> CommandResult {
        // TODO: Arrange windows for coding (IDE, terminal, browser, etc.)
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func arrangeWritingLayout() async -> CommandResult {
        // TODO: Arrange windows for writing (text editor, reference docs, etc.)
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func arrangeResearchLayout() async -> CommandResult {
        // TODO: Arrange windows for research (browser, notes, PDFs, etc.)
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func arrangeCommunicationLayout() async -> CommandResult {
        // TODO: Arrange windows for communication (messages, email, calendar, etc.)
        return CommandResult(success: false, message: "Not implemented")
    }
    
    private func arrangeDesignLayout() async -> CommandResult {
        // TODO: Arrange windows for design work (design tools, inspiration, assets, etc.)
        return CommandResult(success: false, message: "Not implemented")
    }
    
    // MARK: - Utility Methods
    private func calculatePosition(for position: WindowPosition, screenBounds: CGRect, windowSize: CGSize) -> CGPoint {
        // TODO: Calculate actual position based on relative position and screen bounds
        return .zero
    }
    
    private func calculateSize(for size: WindowSize, screenBounds: CGRect) -> CGSize {
        // TODO: Calculate actual size based on relative size and screen bounds
        return .zero
    }
    
    // MARK: - Simplified Workspace Transitions (No Animation System)
    
    private func determineWorkspaceType(from commands: [WindowCommand]) -> String {
        // Look for common app patterns
        let targets = commands.map { $0.target.lowercased() }
        
        if targets.contains(where: { $0.contains("terminal") || $0.contains("xcode") || $0.contains("code") }) {
            return "coding"
        } else if targets.contains(where: { $0.contains("figma") || $0.contains("sketch") || $0.contains("photoshop") }) {
            return "design"
        } else if targets.contains(where: { $0.contains("pages") || $0.contains("word") || $0.contains("notes") }) {
            return "writing"
        } else if targets.contains(where: { $0.contains("safari") || $0.contains("chrome") || $0.contains("browser") }) {
            return "research"
        } else {
            return "general"
        }
    }
    
    private func getTargetWindows(_ target: String) -> [WindowInfo]? {
        let allWindows = windowManager.getAllWindows()
        
        // Try exact app name match first
        let exactMatches = allWindows.filter { $0.appName.lowercased() == target.lowercased() }
        if !exactMatches.isEmpty {
            return exactMatches
        }
        
        // Try partial match
        let partialMatches = allWindows.filter { $0.appName.lowercased().contains(target.lowercased()) }
        if !partialMatches.isEmpty {
            return partialMatches
        }
        
        // Try window title match
        let titleMatches = allWindows.filter { $0.title.lowercased().contains(target.lowercased()) }
        return titleMatches.isEmpty ? nil : titleMatches
    }
}