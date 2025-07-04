import Cocoa
import Foundation

class CommandExecutor {
    private let windowManager: WindowManager
    private let appLauncher: AppLauncher
    private let windowPositioner: WindowPositioner
    private let animationSelector = AnimationSelector.shared
    
    init(windowManager: WindowManager, appLauncher: AppLauncher) {
        self.windowManager = windowManager
        self.appLauncher = appLauncher
        self.windowPositioner = WindowPositioner(windowManager: windowManager)
    }
    
    // MARK: - Animated Command Execution
    func executeCommandsAnimated(_ commands: [WindowCommand]) async -> [CommandResult] {
        var results: [CommandResult] = []
        
        print("\n🎬 ANIMATED COMMAND EXECUTOR:")
        print("  Received \(commands.count) command(s) to execute with animations")
        
        // Determine if this is a coordinated workspace operation
        let isWorkspaceOperation = commands.count > 1 && commands.allSatisfy { 
            $0.action == .move || $0.action == .resize || $0.action == .snap 
        }
        
        if isWorkspaceOperation {
            // Execute as coordinated workspace transition
            results = await executeCoordinatedWorkspaceTransition(commands)
        } else {
            // Execute commands individually with animations
            for (index, command) in commands.enumerated() {
                print("\n  Executing animated command \(index + 1)/\(commands.count): \(command.action.rawValue) \(command.target)")
                
                let result = await executeCommandAnimated(command)
                results.append(result)
                
                print("    Result: \(result.success ? "✅" : "❌") \(result.message)")
                
                // If a command fails and it's critical, stop execution
                if !result.success && (command.action == .open || command.action == .focus) {
                    print("⚠️ Critical command failed, stopping execution: \(result.message)")
                    break
                }
            }
        }
        
        print("\n  Animated execution complete: \(results.count) results")
        return results
    }
    
    func executeCommandAnimated(_ command: WindowCommand) async -> CommandResult {
        return await withCheckedContinuation { continuation in
            windowPositioner.executeCommandAnimated(command) { result in
                continuation.resume(returning: result)
            }
        }
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
    
    // MARK: - Coordinated Workspace Transitions
    
    private func executeCoordinatedWorkspaceTransition(_ commands: [WindowCommand]) async -> [CommandResult] {
        print("🎭 Executing coordinated workspace transition with \(commands.count) commands")
        
        // Execute positioning immediately (non-animated) to get windows in place
        var results: [CommandResult] = []
        
        for command in commands {
            let result = windowPositioner.executeCommand(command)
            results.append(result)
        }
        
        // Don't block on animations - just trigger them and return immediately
        Task { @MainActor in
            // Build context from commands
            let context = buildAnimationContext(from: commands)
            
            // Get windows that were positioned and add subtle animation effects
            var windowOperations: [(WindowInfo, CGRect)] = []
            
            for command in commands {
                if let windows = getTargetWindows(command.target), let window = windows.first {
                    // Use current bounds (already positioned) for subtle animation
                    windowOperations.append((window, window.bounds))
                }
            }
            
            // Add very brief visual feedback animation (optional)
            if !windowOperations.isEmpty && windowOperations.count <= 3 {
                // Only animate if it's a small number of windows to avoid blocking
                await self.animateWorkspaceTransition(windowOperations, context: context)
            }
        }
        
        return results
    }
    
    private func animateWorkspaceTransition(_ operations: [(WindowInfo, CGRect)], context: AnimationContext) async {
        return await withCheckedContinuation { continuation in
            // Select optimal configuration for this workspace transition
            let windowCount = operations.count
            let config = animationSelector.selectConfiguration(
                for: operations.map { _ in .move }, // All are essentially move operations
                windows: operations.map { $0.0 },
                context: context
            )
            
            print("🎬 Starting workspace transition animation:")
            print("  Windows: \(windowCount)")
            print("  Preset: \(config.preset.name)")
            print("  Stagger: \(config.staggerDelay)s")
            
            windowManager.animateWindowsCoordinated(operations, configuration: config) {
                print("✨ Workspace transition animation completed")
                continuation.resume()
            }
        }
    }
    
    private func buildAnimationContext(from commands: [WindowCommand]) -> AnimationContext {
        // Analyze commands to determine workspace type
        let workspaceType = determineWorkspaceType(from: commands)
        
        // Calculate confidence based on command specificity
        let confidence = commands.allSatisfy { $0.position != nil || $0.customPosition != nil } ? 0.9 : 0.6
        
        return AnimationContext(
            workspaceType: workspaceType,
            confidence: confidence,
            performanceMode: commands.count > 8, // Performance mode for many windows
            isFocusMode: workspaceType.lowercased().contains("focus"),
            isPresentationMode: workspaceType.lowercased().contains("presentation"),
            userPresent: true
        )
    }
    
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
    
    private func calculateFinalBounds(for command: WindowCommand, window: WindowInfo) -> CGRect {
        let displayIndex = command.display ?? 0
        
        // Calculate position
        var position: CGPoint
        if let customPosition = command.customPosition {
            position = customPosition
        } else if let windowPosition = command.position {
            let size = command.customSize ?? window.bounds.size
            position = windowPositioner.calculatePosition(windowPosition, size: size, on: displayIndex)
        } else {
            position = window.bounds.origin
        }
        
        // Calculate size
        var size: CGSize
        if let customSize = command.customSize {
            size = customSize
        } else if let windowSize = command.size {
            size = windowPositioner.calculateSize(windowSize, for: window.appName, on: displayIndex)
        } else {
            size = window.bounds.size
        }
        
        return CGRect(origin: position, size: size)
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