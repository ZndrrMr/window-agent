import Cocoa
import CoreGraphics
import Foundation

// MARK: - Window Positioning Engine
class WindowPositioner {
    
    static let shared = WindowPositioner(windowManager: WindowManager.shared)
    
    private let windowManager: WindowManager
    private let constraintsManager = AppConstraintsManager.shared
    private let cascadePositioner: CascadePositioner
    private let learningService = LearningService.shared
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        self.cascadePositioner = CascadePositioner(windowManager: windowManager)
    }
    
    // MARK: - Animated Command Execution
    func executeCommandAnimated(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        switch command.action {
        case .move:
            executeAnimatedMove(command, completion: completion)
        case .resize:
            executeAnimatedResize(command, completion: completion)
        case .snap:
            executeAnimatedSnap(command, completion: completion)
        case .maximize:
            executeAnimatedMaximize(command, completion: completion)
        case .minimize:
            executeAnimatedMinimize(command, completion: completion)
        case .focus:
            executeAnimatedFocus(command, completion: completion)
        case .restore:
            executeAnimatedRestore(command, completion: completion)
        case .arrange:
            executeAnimatedArrange(command, completion: completion)
        case .tile:
            executeAnimatedTile(command, completion: completion)
        case .stack:
            executeAnimatedCascade(command, completion: completion)
        default:
            // For non-animated commands, execute synchronously
            let result = executeCommand(command)
            completion(result)
        }
    }

    // MARK: - Public API
    func executeCommand(_ command: WindowCommand) -> CommandResult {
        switch command.action {
        case .move:
            return moveWindow(command)
        case .resize:
            return resizeWindow(command)
        case .snap:
            return snapWindow(command)
        case .maximize:
            return maximizeWindow(command)
        case .minimize:
            return minimizeWindow(command)
        case .focus:
            return focusWindow(command)
        case .open:
            return openApp(command)
        case .close:
            return closeWindow(command)
        case .arrange:
            return arrangeWorkspace(command)
        case .tile:
            return tileWindows(command)
        case .stack:
            return cascadeWindows(command)
        case .restore:
            return restoreWindow(command)
        }
    }
    
    // MARK: - Position Calculations
    func calculatePosition(_ position: WindowPosition, size: CGSize, on displayIndex: Int = 0) -> CGPoint {
        let _ = getDisplayBounds(displayIndex)
        let visibleBounds = getVisibleDisplayBounds(displayIndex)
        
        switch position {
        case .left:
            return CGPoint(x: visibleBounds.minX, y: visibleBounds.minY)
        case .right:
            return CGPoint(x: visibleBounds.maxX - size.width, y: visibleBounds.minY)
        case .top:
            return CGPoint(x: visibleBounds.midX - size.width/2, y: visibleBounds.minY)
        case .bottom:
            return CGPoint(x: visibleBounds.midX - size.width/2, y: visibleBounds.maxY - size.height)
        case .center:
            return CGPoint(x: visibleBounds.midX - size.width/2, y: visibleBounds.midY - size.height/2)
        case .topLeft:
            return CGPoint(x: visibleBounds.minX, y: visibleBounds.minY)
        case .topRight:
            return CGPoint(x: visibleBounds.maxX - size.width, y: visibleBounds.minY)
        case .bottomLeft:
            return CGPoint(x: visibleBounds.minX, y: visibleBounds.maxY - size.height)
        case .bottomRight:
            return CGPoint(x: visibleBounds.maxX - size.width, y: visibleBounds.maxY - size.height)
        case .leftThird:
            return CGPoint(x: visibleBounds.minX, y: visibleBounds.minY)
        case .middleThird:
            return CGPoint(x: visibleBounds.minX + visibleBounds.width/3, y: visibleBounds.minY)
        case .rightThird:
            return CGPoint(x: visibleBounds.minX + (visibleBounds.width * 2/3), y: visibleBounds.minY)
        case .topThird:
            return CGPoint(x: visibleBounds.midX - size.width/2, y: visibleBounds.minY)
        case .bottomThird:
            return CGPoint(x: visibleBounds.midX - size.width/2, y: visibleBounds.minY + (visibleBounds.height * 2/3))
        case .precise:
            return CGPoint.zero // Will be overridden by custom position
        }
    }
    
    func calculateSize(_ sizeType: WindowSize, for appName: String, on displayIndex: Int = 0) -> CGSize {
        let _ = getDisplayBounds(displayIndex)
        let visibleBounds = getVisibleDisplayBounds(displayIndex)
        let bundleID = getBundleID(for: appName) ?? ""
        
        var calculatedSize: CGSize
        
        switch sizeType {
        case .tiny:
            calculatedSize = CGSize(width: visibleBounds.width * 0.25, height: visibleBounds.height * 0.25)
        case .small:
            calculatedSize = CGSize(width: visibleBounds.width * 0.33, height: visibleBounds.height * 0.5)
        case .third:
            // Third width, full height - perfect for terminal/auxiliary apps
            calculatedSize = CGSize(width: visibleBounds.width * 0.33, height: visibleBounds.height)
        case .medium, .half:
            calculatedSize = CGSize(width: visibleBounds.width * 0.5, height: visibleBounds.height * 0.7)
        case .large:
            calculatedSize = CGSize(width: visibleBounds.width * 0.67, height: visibleBounds.height * 0.8)
        case .twoThirds:
            // Two-thirds width, full height - perfect for primary apps like code editors
            calculatedSize = CGSize(width: visibleBounds.width * 0.67, height: visibleBounds.height)
        case .huge:
            calculatedSize = CGSize(width: visibleBounds.width * 0.8, height: visibleBounds.height * 0.9)
        case .full:
            calculatedSize = visibleBounds.size
        case .fit:
            // Use app's current size or fall back to medium
            calculatedSize = getCurrentWindowSize(for: appName) ?? CGSize(width: visibleBounds.width * 0.5, height: visibleBounds.height * 0.7)
        case .optimal:
            // Use app-specific optimal size based on constraints
            calculatedSize = getOptimalSize(for: bundleID, screenSize: visibleBounds.size)
        case .precise:
            calculatedSize = CGSize.zero // Will be overridden by custom size
        }
        
        // DYNAMIC SYSTEM: No constraint validation - return calculated size
        return calculatedSize
    }
    
    // MARK: - Command Implementations
    private func moveWindow(_ command: WindowCommand) -> CommandResult {
        // Handle lifecycle operations first
        if let parameters = command.parameters {
            // Handle opening app if needed
            if let openParam = parameters["open"], openParam.lowercased() == "true" {
                let openResult = openApp(command)
                if !openResult.success {
                    return openResult
                }
                // Wait for app to launch before continuing
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        // Handle lifecycle operations on existing window
        if let parameters = command.parameters {
            // Handle restore/unminimize before positioning
            if let restoreParam = parameters["restore"], restoreParam.lowercased() == "true" {
                if windowManager.isWindowMinimized(window) {
                    print("🔄 Restoring \(command.target) before positioning")
                    _ = windowManager.restoreWindow(window)
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            // Handle minimize operation
            if let minimizeParam = parameters["minimize"] {
                if minimizeParam.lowercased() == "true" {
                    print("📦 Minimizing \(command.target)")
                    let success = windowManager.minimizeWindow(window)
                    let message = success ? "Minimized \(command.target)" : "Failed to minimize \(command.target)"
                    return CommandResult(success: success, message: message, command: command)
                } else if minimizeParam.lowercased() == "false" {
                    // Ensure window is not minimized
                    if windowManager.isWindowMinimized(window) {
                        print("🔄 Unminimizing \(command.target)")
                        _ = windowManager.restoreWindow(window)
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                }
            }
        }
        
        let displayIndex = command.display ?? 0
        var position: CGPoint
        
        // Check if this is a flexible position command
        if command.position == .precise, let customPosition = command.customPosition {
            position = customPosition
        } else if let customPosition = command.customPosition {
            position = customPosition
        } else if let windowPosition = command.position {
            let size = command.customSize ?? window.bounds.size
            position = calculatePosition(windowPosition, size: size, on: displayIndex)
        } else {
            // If no positioning specified, this might be a focus-only or lifecycle-only command
            if let parameters = command.parameters {
                if let focusParam = parameters["focus"], focusParam.lowercased() == "true" {
                    // Focus-only command
                    let success = windowManager.focusWindow(window)
                    let message = success ? "Focused \(command.target)" : "Failed to focus \(command.target)"
                    return CommandResult(success: success, message: message, command: command)
                }
            }
            return CommandResult(success: false, message: "No position specified", command: command)
        }
        
        // Apply learned position offset if available
        if let preferredOffset = learningService.getPreferredPositionOffset(for: window.appName) {
            position.x += preferredOffset.x
            position.y += preferredOffset.y
            print("📚 Applying learned position offset for \(window.appName): (\(Int(preferredOffset.x)), \(Int(preferredOffset.y)))")
        }
        
        // Apply flexible positioning if we have both position and size
        if command.position == .precise, let customSize = command.customSize {
            let bounds = CGRect(origin: position, size: customSize)
            
            // Record this arrangement for learning
            learningService.recordWindowArrangement(
                windows: [window],
                arrangedBounds: [window.appName: bounds],
                context: "flexible_position"
            )
            
            let success = windowManager.setWindowBounds(window, bounds: bounds)
            
            // Handle focus after positioning
            if let parameters = command.parameters,
               let focusParam = parameters["focus"],
               focusParam.lowercased() == "true" {
                // Small delay to ensure positioning is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let focusSuccess = self.windowManager.focusWindow(window)
                    print("🎯 Focus \(focusSuccess ? "set" : "failed") for \(command.target)")
                }
            }
            
            let message = success ? "Positioned \(command.target) at (\(Int(position.x)), \(Int(position.y))) with size \(Int(customSize.width))x\(Int(customSize.height))" : "Failed to position \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        }
        
        // Record the arrangement for learning
        let currentBounds = window.bounds
        let newBounds = CGRect(origin: position, size: currentBounds.size)
        learningService.recordWindowArrangement(
            windows: [window],
            arrangedBounds: [window.appName: newBounds],
            context: "move_\(command.position?.rawValue ?? "custom")"
        )
        
        let success = windowManager.moveWindow(window, to: position)
        
        // Handle focus after positioning
        if let parameters = command.parameters,
           let focusParam = parameters["focus"],
           focusParam.lowercased() == "true" {
            // Small delay to ensure positioning is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let focusSuccess = self.windowManager.focusWindow(window)
                print("🎯 Focus \(focusSuccess ? "set" : "failed") for \(command.target)")
            }
        }
        
        let message = success ? "Moved \(command.target) to \(position)" : "Failed to move \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func resizeWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let displayIndex = command.display ?? 0
        var size: CGSize
        
        // Get current window size for preserve operations
        let currentBounds = window.bounds
        
        if let customSize = command.customSize {
            size = customSize
            
            // Handle preserve width/height
            if let preserveWidth = command.parameters?["preserve_width"], preserveWidth == "true" {
                size.width = currentBounds.width
            }
            if let preserveHeight = command.parameters?["preserve_height"], preserveHeight == "true" {
                size.height = currentBounds.height
            }
        } else if let windowSize = command.size {
            size = calculateSize(windowSize, for: window.appName, on: displayIndex)
        } else {
            return CommandResult(success: false, message: "No size specified", command: command)
        }
        
        // For resize, we keep the current position and just change size
        let newBounds = CGRect(origin: currentBounds.origin, size: size)
        let success = windowManager.setWindowBounds(window, bounds: newBounds)
        
        let message = success ? "Resized \(command.target) to \(size)" : "Failed to resize \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func snapWindow(_ command: WindowCommand) -> CommandResult {
        print("\n🎯 SNAPPING: \(command.target)")
        
        // Log display information
        if let displayIndex = command.display {
            if let displayInfo = windowManager.getDisplayInfo(at: displayIndex) {
                print("  📱 Target Display: \(displayIndex) - \(displayInfo.name)")
                print("  📐 Display bounds: \(displayInfo.visibleFrame)")
            } else {
                print("  ⚠️ Invalid display index: \(displayIndex)")
            }
        }
        
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            print("  ❌ Could not find window")
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        guard let position = command.position else {
            return CommandResult(success: false, message: "No snap position specified", command: command)
        }
        
        let displayIndex = command.display ?? 0
        let sizeType = command.size ?? .medium
        let size = calculateSize(sizeType, for: window.appName, on: displayIndex)
        let calculatedPosition = calculatePosition(position, size: size, on: displayIndex)
        
        print("  📐 Position: \(position.rawValue), Size: \(sizeType.rawValue)")
        print("  📏 Calculated bounds: \(calculatedPosition) size: \(size)")
        
        let bounds = CGRect(origin: calculatedPosition, size: size)
        
        // Record the snap arrangement for learning
        learningService.recordWindowArrangement(
            windows: [window],
            arrangedBounds: [window.appName: bounds],
            context: "snap_\(position.rawValue)_\(sizeType.rawValue)"
        )
        
        let success = windowManager.setWindowBounds(window, bounds: bounds)
        
        if success {
            print("  ✅ Successfully snapped \(command.target)")
        } else {
            print("  ❌ Failed to snap \(command.target)")
        }
        
        let message = success ? "Snapped \(command.target) to \(position.rawValue)" : "Failed to snap \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func maximizeWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        // If display is specified, maximize on that display
        if let displayIndex = command.display {
            print("\n🖥️ MAXIMIZING: \(command.target) on display \(displayIndex)")
            
            // Get display info
            if let displayInfo = windowManager.getDisplayInfo(at: displayIndex) {
                print("  📱 Display \(displayIndex): \(displayInfo.name)")
                print("  📐 Full bounds: \(displayInfo.frame)")
                print("  📐 Visible bounds: \(displayInfo.visibleFrame)")
            }
            
            let displayBounds = getVisibleDisplayBounds(displayIndex)
            print("  🎯 Setting window bounds to: \(displayBounds)")
            print("     Origin: (\(displayBounds.origin.x), \(displayBounds.origin.y))")
            print("     Size: \(displayBounds.size.width) x \(displayBounds.size.height)")
            
            // Also log current window position for comparison
            print("  📍 Current window bounds: \(window.bounds)")
            
            // Manual maximize only - never use zoom button
            let position = CGPoint(x: displayBounds.minX, y: displayBounds.minY)
            let size = displayBounds.size
            
            print("  📍 Setting position to: \(position) for \(command.target)")
            print("  📐 Setting size to: \(size) for \(command.target)")
            
            // CRITICAL: Unminimize window before maximizing it
            if windowManager.isWindowMinimized(window) {
                print("🔄 Unminimizing \(command.target) before maximizing")
                _ = windowManager.restoreWindow(window)
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Create a window-sized rect at the correct position
            let targetBounds = CGRect(origin: position, size: size)
            let success = windowManager.setWindowBounds(window, bounds: targetBounds, validate: false)
            
            let message = success ? "Maximized \(command.target) on display \(displayIndex)" : "Failed to maximize \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        } else {
            // CRITICAL: Unminimize window before maximizing it
            if windowManager.isWindowMinimized(window) {
                print("🔄 Unminimizing \(command.target) before maximizing")
                _ = windowManager.restoreWindow(window)
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Use default maximize which uses window's current display
            let success = windowManager.maximizeWindow(window)
            let message = success ? "Maximized \(command.target)" : "Failed to maximize \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        }
    }
    
    private func minimizeWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let success = windowManager.minimizeWindow(window)
        let message = success ? "Minimized \(command.target)" : "Failed to minimize \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func focusWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        // CRITICAL: Unminimize window before focusing it
        if windowManager.isWindowMinimized(window) {
            print("🔄 Unminimizing \(command.target) before focusing")
            _ = windowManager.restoreWindow(window)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        let success = windowManager.focusWindow(window)
        let message = success ? "Focused \(command.target)" : "Failed to focus \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func openApp(_ command: WindowCommand) -> CommandResult {
        print("\n🚀 OPENING: \(command.target)")
        
        // This will be handled by AppLauncher, but we can set initial position/size
        let bundleID = getBundleID(for: command.target)
        
        if let bundleID = bundleID {
            print("  📦 Found bundle ID: \(bundleID)")
            let success = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, 
                                                             options: [], 
                                                             additionalEventParamDescriptor: nil, 
                                                             launchIdentifier: nil)
            
            if success {
                print("  ✅ App launched successfully")
                if (command.position != nil || command.size != nil) {
                    print("  ⏳ Waiting to position window...")
                    // Wait a moment for the app to launch, then position it
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if let window = self.windowManager.getWindowsForApp(named: command.target).first {
                            if let position = command.position, let size = command.size {
                                let displayIndex = command.display ?? 0
                                let calculatedSize = self.calculateSize(size, for: command.target, on: displayIndex)
                                let calculatedPosition = self.calculatePosition(position, size: calculatedSize, on: displayIndex)
                                let bounds = CGRect(origin: calculatedPosition, size: calculatedSize)
                                let result = self.windowManager.setWindowBounds(window, bounds: bounds)
                                print("  📍 Positioned window: \(result ? "✅" : "❌")")
                            }
                        }
                    }
                }
            } else {
                print("  ❌ Failed to launch app")
            }
            
            let message = success ? "Opened \(command.target)" : "Failed to open \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        } else {
            print("  ❌ Could not find bundle ID for '\(command.target)'")
            return CommandResult(success: false, message: "Could not find app '\(command.target)'", command: command)
        }
    }
    
    private func closeWindow(_ command: WindowCommand) -> CommandResult {
        // Check if we should quit the app entirely or just close a window
        let shouldQuitApp = command.parameters?["quit"] == "true"
        
        if shouldQuitApp {
            let success = windowManager.quitApp(command.target)
            let message = success ? "Quit \(command.target)" : "Failed to quit \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        } else {
            // Close just the frontmost window
            guard let windows = getTargetWindows(command.target), let window = windows.first else {
                return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
            }
            
            let success = windowManager.closeWindow(window)
            let message = success ? "Closed window for \(command.target)" : "Failed to close window for \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        }
    }
    
    private func arrangeWorkspace(_ command: WindowCommand) -> CommandResult {
        // For intelligent cascade arrangements
        if command.target.lowercased() == "cascade" || command.target.lowercased() == "intelligent" {
            let allWindows = windowManager.getAllWindows()
            
            // PHASE 1: Unminimize ALL windows first (same as cascadeWindows)
            print("\n🔄 PHASE 1: Unminimizing all windows")
            print("===================================")
            for window in allWindows {
                if windowManager.isWindowMinimized(window) {
                    print("🔄 Unminimizing \(window.appName)...")
                    let restoreSuccess = windowManager.restoreWindow(window)
                    print("  Result: \(restoreSuccess ? "✅ Success" : "❌ Failed")")
                } else {
                    print("✅ \(window.appName) already visible")
                }
            }
            
            // Wait for all unminimize operations to complete
            print("⏳ Waiting for unminimize operations to complete...")
            Thread.sleep(forTimeInterval: 1.0)
            
            // PHASE 2: Use NEW FlexibleLayoutEngine instead of old cascade positioner
            print("\n📐 PHASE 2: Intelligent FlexibleLayoutEngine positioning")
            print("====================================================")
            
            let displayIndex = command.display ?? 0
            let screenBounds = getFullDisplayBounds(displayIndex)
            let windowNames = allWindows.map { $0.appName }
            
            // Extract context from command parameters
            let context = command.parameters?["context"] ?? extractContextFromTarget(command.target, userIntent: command.parameters?["user_intent"])
            
            // Determine focused app
            let focusedApp = intelligentlySelectFocusedApp(
                windows: windowNames,
                context: context,
                userIntent: command.parameters?["user_intent"]
            )
            
            // Generate intelligent proportional layout using NEW FlexibleLayoutEngine
            let flexibleArrangements = FlexibleLayoutEngine.generateFocusAwareLayout(
                for: windowNames,
                screenSize: screenBounds.size,
                focusedApp: focusedApp,
                context: context
            )
            
            var results: [String] = []
            for arrangement in flexibleArrangements {
                guard let window = allWindows.first(where: { $0.appName == arrangement.window }) else {
                    print("⚠️ Could not find window for arrangement: \(arrangement.window)")
                    continue
                }
                
                // Convert flexible position/size to pixels
                let position = CGPoint(
                    x: arrangement.position.x.toPixels(for: screenBounds.width) + screenBounds.origin.x,
                    y: arrangement.position.y.toPixels(for: screenBounds.height) + screenBounds.origin.y
                )
                
                let size = CGSize(
                    width: arrangement.size.width.toPixels(for: screenBounds.width, otherDimension: nil) ?? screenBounds.width * 0.5,
                    height: arrangement.size.height.toPixels(for: screenBounds.height, otherDimension: nil) ?? screenBounds.height * 0.5
                )
                
                let bounds = CGRect(origin: position, size: size)
                
                print("📍 Positioning \(window.appName) to \(bounds)")
                
                // Disable validation since we're using full screen bounds for 100% coverage
                if windowManager.setWindowBounds(window, bounds: bounds, validate: false) {
                    results.append("Arranged \(window.appName) (\(arrangement.visibility.rawValue) visibility)")
                }
            }
            
            let success = !results.isEmpty
            return CommandResult(success: success, message: results.joined(separator: ", "), command: command)
        }
        
        let workspaceManager = WorkspaceManager.shared
        
        // Try to find a matching workspace
        guard let workspace = workspaceManager.getWorkspace(named: command.target) else {
            // If no exact match, try to match by category
            switch command.target.lowercased() {
            case "coding", "development", "dev":
                return arrangeCodingWorkspace()
            case "writing", "document", "docs":
                return arrangeWritingWorkspace()
            case "research", "browse", "browsing":
                return arrangeResearchWorkspace()
            case "communication", "chat", "messaging":
                return arrangeCommunicationWorkspace()
            default:
                return CommandResult(success: false, message: "Unknown workspace: '\(command.target)'", command: command)
            }
        }
        
        // Execute the workspace arrangement
        return executeWorkspaceArrangement(workspace)
    }
    
    private func executeWorkspaceArrangement(_ workspace: Workspace) -> CommandResult {
        var results: [String] = []
        var errors: [String] = []
        
        print("\n📊 WORKSPACE ARRANGEMENT DETAILS:")
        print("  📋 Required apps: \(workspace.requiredApps.map { $0.appName }.joined(separator: ", "))")
        print("  📋 Optional apps: \(workspace.optionalApps.map { $0.appName }.joined(separator: ", "))")
        
        // First, handle excluded apps by minimizing them
        for excludedApp in workspace.excludedApps {
            let windows = windowManager.getWindowsForApp(named: excludedApp)
            for window in windows {
                if windowManager.minimizeWindow(window) {
                    results.append("Minimized \(excludedApp)")
                }
            }
        }
        
        // Get screen bounds for layout - use FULL bounds for 100% coverage
        let screenBounds = getFullDisplayBounds(0)
        
        // Launch required apps if not running
        print("\n🚀 CHECKING APP STATUS:")
        for appContext in workspace.requiredApps {
            let windows = windowManager.getWindowsForApp(named: appContext.appName)
            if windows.isEmpty {
                print("  🚀 \(appContext.appName) not running - launching...")
                // App not running, launch it
                let bundleID = appContext.bundleID
                if NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, 
                                                       options: [], 
                                                       additionalEventParamDescriptor: nil, 
                                                       launchIdentifier: nil) {
                    results.append("Launched \(appContext.appName)")
                    print("    ✅ Launched successfully")
                    // Wait a bit for the app to launch
                    Thread.sleep(forTimeInterval: 1.0)
                } else {
                    print("    ❌ Failed to launch")
                    errors.append("Failed to launch \(appContext.appName)")
                }
            } else {
                print("  ✓ \(appContext.appName) already running (\(windows.count) window(s))")
            }
        }
        
        // Now arrange windows based on layout configuration
        let layout = workspace.layout
        let gap = layout.gapSize
        
        switch layout.screenDivision {
        case .leftRight:
            print("  🖼️ Using left-right layout")
            arrangeLeftRightLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results, errors: &errors)
        case .topBottom:
            print("  🖼️ Using top-bottom layout")
            arrangeTopBottomLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results, errors: &errors)
        case .intelligent:
            // Use FlexibleLayoutEngine for intelligent proportional layout
            print("  🖼️ Using intelligent FlexibleLayoutEngine layout")
            return executeIntelligentArrangement(workspace, screenBounds: screenBounds)
        case .automatic:
            // Choose based on number of apps
            let totalApps = workspace.requiredApps.count + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }.count
            print("  🖼️ Automatic layout for \(totalApps) apps")
            if totalApps <= 2 {
                print("    → Using left-right layout")
                arrangeLeftRightLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results, errors: &errors)
            } else if totalApps <= 4 {
                print("    → Using intelligent FlexibleLayoutEngine layout")
                return executeIntelligentArrangement(workspace, screenBounds: screenBounds)
            } else {
                print("    → Using tiled layout")
                arrangeTiledLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results, errors: &errors)
            }
        case .custom:
            results.append("Custom layouts not yet implemented")
        }
        
        let success = errors.isEmpty
        let message: String
        if success {
            if results.isEmpty {
                message = "Workspace arranged successfully"
            } else {
                message = results.joined(separator: ", ")
            }
            print("\n✅ WORKSPACE ARRANGEMENT COMPLETE")
        } else {
            message = errors.joined(separator: ", ")
            print("\n❌ WORKSPACE ARRANGEMENT FAILED: \(message)")
        }
        return CommandResult(success: success, message: message)
    }
    
    private func arrangeLeftRightLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String], errors: inout [String]) {
        let halfWidth = (screenBounds.width - gap) / 2
        let height = screenBounds.height
        
        let leftX = screenBounds.origin.x
        let rightX = screenBounds.origin.x + halfWidth + gap
        let y = screenBounds.origin.y
        
        var appIndex = 0
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        
        for appContext in allApps {
            if let window = windowManager.getWindowsForApp(named: appContext.appName).first {
                let isLeftSide = appIndex % 2 == 0
                let bounds = CGRect(
                    x: isLeftSide ? leftX : rightX,
                    y: y,
                    width: halfWidth,
                    height: height
                )
                
                print("    📍 Positioning \(appContext.appName) to \(isLeftSide ? "left" : "right") half")
                print("      📐 Bounds: x=\(Int(bounds.origin.x)), y=\(Int(bounds.origin.y)), w=\(Int(bounds.width)), h=\(Int(bounds.height))")
                if windowManager.setWindowBounds(window, bounds: bounds) {
                    results.append("Positioned \(appContext.appName) on \(isLeftSide ? "left" : "right")")
                    print("      ✅ Success")
                } else {
                    errors.append("Failed to position \(appContext.appName)")
                    print("      ❌ Failed")
                }
                appIndex += 1
            } else {
                print("    ⚠️ No window found for \(appContext.appName)")
            }
        }
    }
    
    private func arrangeTopBottomLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String], errors: inout [String]) {
        let width = screenBounds.width
        let halfHeight = (screenBounds.height - gap) / 2
        
        let x = screenBounds.origin.x
        let topY = screenBounds.origin.y
        let bottomY = screenBounds.origin.y + halfHeight + gap
        
        var appIndex = 0
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        
        for appContext in allApps {
            if let window = windowManager.getWindowsForApp(named: appContext.appName).first {
                let isTop = appIndex % 2 == 0
                let bounds = CGRect(
                    x: x,
                    y: isTop ? topY : bottomY,
                    width: width,
                    height: halfHeight
                )
                
                if windowManager.setWindowBounds(window, bounds: bounds) {
                    results.append("Positioned \(appContext.appName) on \(isTop ? "top" : "bottom")")
                }
                appIndex += 1
            }
        }
    }
    
    private func executeIntelligentArrangement(_ workspace: Workspace, screenBounds: CGRect) -> CommandResult {
        // Get all windows from workspace apps
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        let windowNames = allApps.map { $0.appName }
        
        guard !windowNames.isEmpty else {
            return CommandResult(success: false, message: "No windows found in workspace")
        }
        
        print("🎯 INTELLIGENT ARRANGEMENT: Using FlexibleLayoutEngine")
        print("   Apps: \(windowNames.joined(separator: ", "))")
        
        // Use FlexibleLayoutEngine for intelligent proportional layout
        let flexibleArrangements = FlexibleLayoutEngine.generateFocusAwareLayout(
            for: windowNames,
            screenSize: screenBounds.size,
            focusedApp: windowNames.first,
            context: "workspace"
        )
        
        var results: [String] = []
        for arrangement in flexibleArrangements {
            // Find the actual window
            guard let appContext = allApps.first(where: { $0.appName == arrangement.window }),
                  let window = windowManager.getWindowsForApp(named: appContext.appName).first else {
                print("⚠️ Could not find window for: \(arrangement.window)")
                continue
            }
            
            // Convert flexible position/size to pixels
            let position = CGPoint(
                x: arrangement.position.x.toPixels(for: screenBounds.width) + screenBounds.origin.x,
                y: arrangement.position.y.toPixels(for: screenBounds.height) + screenBounds.origin.y
            )
            
            let size = CGSize(
                width: arrangement.size.width.toPixels(for: screenBounds.width, otherDimension: nil) ?? screenBounds.width * 0.5,
                height: arrangement.size.height.toPixels(for: screenBounds.height, otherDimension: nil) ?? screenBounds.height * 0.5
            )
            
            let bounds = CGRect(origin: position, size: size)
            
            print("📍 Intelligent positioning \(appContext.appName) to \(bounds)")
            
            // Disable validation since we're using full screen bounds for 100% coverage
            if windowManager.setWindowBounds(window, bounds: bounds, validate: false) {
                results.append("Intelligently positioned \(appContext.appName)")
            }
        }
        
        let success = !results.isEmpty
        return CommandResult(success: success, message: results.joined(separator: ", "))
    }
    
    private func arrangeTiledLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String], errors: inout [String]) {
        // For more than 4 apps, use a grid layout
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        let appCount = allApps.count
        
        // Calculate grid dimensions
        let cols = Int(ceil(sqrt(Double(appCount))))
        let rows = Int(ceil(Double(appCount) / Double(cols)))
        
        let tileWidth = (screenBounds.width - CGFloat(cols - 1) * gap) / CGFloat(cols)
        let tileHeight = (screenBounds.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
        
        for (index, appContext) in allApps.enumerated() {
            if let window = windowManager.getWindowsForApp(named: appContext.appName).first {
                let col = index % cols
                let row = index / cols
                
                let bounds = CGRect(
                    x: screenBounds.origin.x + CGFloat(col) * (tileWidth + gap),
                    y: screenBounds.origin.y + CGFloat(row) * (tileHeight + gap),
                    width: tileWidth,
                    height: tileHeight
                )
                
                if windowManager.setWindowBounds(window, bounds: bounds) {
                    results.append("Tiled \(appContext.appName)")
                }
            }
        }
    }
    
    // Specific workspace arrangements
    private func arrangeCodingWorkspace() -> CommandResult {
        print("\n🖥️ ARRANGING CODING WORKSPACE")
        print("  📱 Creating workspace with:")
        print("    - Cursor (code editor)")
        print("    - Terminal")
        print("    - Arc (optional browser)")
        
        let workspace = Workspace(
            name: "Coding",
            category: .coding,
            requiredApps: [
                AppContext(bundleID: "com.todesktop.230313mzl4w4u92", appName: "Cursor", category: .codeEditor),
                AppContext(bundleID: "com.apple.Terminal", appName: "Terminal", category: .terminal)
            ],
            optionalApps: [
                AppContext(bundleID: "company.thebrowser.Browser", appName: "Arc", category: .browser)
            ],
            layout: LayoutConfiguration(screenDivision: .automatic)  // Let intelligent layout decide
        )
        return executeWorkspaceArrangement(workspace)
    }
    
    private func arrangeWritingWorkspace() -> CommandResult {
        let workspace = Workspace(
            name: "Writing",
            category: .writing,
            requiredApps: [
                AppContext(bundleID: "com.apple.Notes", appName: "Notes", category: .productivity)
            ],
            optionalApps: [
                AppContext(bundleID: "com.apple.Safari", appName: "Safari", category: .browser),
                AppContext(bundleID: "com.apple.Dictionary", appName: "Dictionary", category: .productivity)
            ],
            layout: LayoutConfiguration(screenDivision: .leftRight)
        )
        return executeWorkspaceArrangement(workspace)
    }
    
    private func arrangeResearchWorkspace() -> CommandResult {
        let workspace = Workspace(
            name: "Research",
            category: .research,
            requiredApps: [
                AppContext(bundleID: "company.thebrowser.Browser", appName: "Arc", category: .browser),
                AppContext(bundleID: "com.apple.Notes", appName: "Notes", category: .productivity)
            ],
            optionalApps: [
                AppContext(bundleID: "com.apple.Preview", appName: "Preview", category: .productivity)
            ],
            layout: LayoutConfiguration(screenDivision: .intelligent)
        )
        return executeWorkspaceArrangement(workspace)
    }
    
    private func arrangeCommunicationWorkspace() -> CommandResult {
        let workspace = Workspace(
            name: "Communication",
            category: .communication,
            requiredApps: [
                AppContext(bundleID: "com.apple.MobileSMS", appName: "Messages", category: .communication),
                AppContext(bundleID: "com.apple.mail", appName: "Mail", category: .communication)
            ],
            optionalApps: [
                AppContext(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", category: .communication)
            ],
            layout: LayoutConfiguration(screenDivision: .topBottom)
        )
        return executeWorkspaceArrangement(workspace)
    }
    
    private func tileWindows(_ command: WindowCommand) -> CommandResult {
        // Tile windows for specific app or all visible windows
        let windows: [WindowInfo]
        
        if command.target.lowercased() == "all" || command.target.lowercased() == "visible" {
            // Tile ALL windows (including minimized ones - we'll unminimize them)
            windows = windowManager.getAllWindows()
        } else {
            // Tile windows for specific app (including minimized ones)
            windows = windowManager.getWindowsForApp(named: command.target)
        }
        
        guard !windows.isEmpty else {
            return CommandResult(success: false, message: "No windows found to tile", command: command)
        }
        
        let displayIndex = command.display ?? 0
        let screenBounds = getVisibleDisplayBounds(displayIndex)
        let gap: CGFloat = 10.0
        
        // PHASE 1: Unminimize ALL windows first (same as cascade)
        print("\n🔄 PHASE 1: Unminimizing all windows")
        print("===================================")
        for window in windows {
            if windowManager.isWindowMinimized(window) {
                print("🔄 Unminimizing \(window.appName)...")
                let restoreSuccess = windowManager.restoreWindow(window)
                print("  Result: \(restoreSuccess ? "✅ Success" : "❌ Failed")")
            } else {
                print("✅ \(window.appName) already visible")
            }
        }
        
        // Wait for all unminimize operations to complete
        print("⏳ Waiting for unminimize operations to complete...")
        Thread.sleep(forTimeInterval: 1.0)
        
        print("\n📐 PHASE 2: Positioning all windows")
        print("==================================")
        
        // Determine tiling pattern based on window count
        let windowCount = windows.count
        var results: [String] = []
        
        switch windowCount {
        case 1:
            // Single window - maximize it
            if windowManager.setWindowBounds(windows[0], bounds: screenBounds) {
                results.append("Maximized \(windows[0].appName)")
            }
        case 2:
            // Two windows - side by side
            let halfWidth = (screenBounds.width - gap) / 2
            let leftBounds = CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y, 
                                  width: halfWidth, height: screenBounds.height)
            let rightBounds = CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y,
                                   width: halfWidth, height: screenBounds.height)
            
            if windowManager.setWindowBounds(windows[0], bounds: leftBounds) {
                results.append("Tiled \(windows[0].appName) to left")
            }
            if windowManager.setWindowBounds(windows[1], bounds: rightBounds) {
                results.append("Tiled \(windows[1].appName) to right")
            }
        case 3:
            // Three windows - one left, two right stacked
            let halfWidth = (screenBounds.width - gap) / 2
            let halfHeight = (screenBounds.height - gap) / 2
            
            let leftBounds = CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y,
                                  width: halfWidth, height: screenBounds.height)
            let topRightBounds = CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y,
                                      width: halfWidth, height: halfHeight)
            let bottomRightBounds = CGRect(x: screenBounds.origin.x + halfWidth + gap, 
                                         y: screenBounds.origin.y + halfHeight + gap,
                                         width: halfWidth, height: halfHeight)
            
            if windowManager.setWindowBounds(windows[0], bounds: leftBounds) {
                results.append("Tiled \(windows[0].appName) to left")
            }
            if windowManager.setWindowBounds(windows[1], bounds: topRightBounds) {
                results.append("Tiled \(windows[1].appName) to top-right")
            }
            if windowManager.setWindowBounds(windows[2], bounds: bottomRightBounds) {
                results.append("Tiled \(windows[2].appName) to bottom-right")
            }
        case 4:
            // Four windows - 2x2 grid layout
            let halfWidth = (screenBounds.width - gap) / 2
            let halfHeight = (screenBounds.height - gap) / 2
            
            let positions = [
                CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y, width: halfWidth, height: halfHeight),
                CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y, width: halfWidth, height: halfHeight),
                CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + halfHeight + gap, width: halfWidth, height: halfHeight),
                CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y + halfHeight + gap, width: halfWidth, height: halfHeight)
            ]
            
            for (index, window) in windows.prefix(4).enumerated() {
                if windowManager.setWindowBounds(window, bounds: positions[index]) {
                    let positionName = ["top-left", "top-right", "bottom-left", "bottom-right"][index]
                    results.append("Tiled \(window.appName) to \(positionName)")
                }
            }
        default:
            // More than 4 windows - use grid
            let cols = Int(ceil(sqrt(Double(windowCount))))
            let rows = Int(ceil(Double(windowCount) / Double(cols)))
            
            let tileWidth = (screenBounds.width - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let tileHeight = (screenBounds.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
            
            for (index, window) in windows.enumerated() {
                let col = index % cols
                let row = index / cols
                
                let bounds = CGRect(
                    x: screenBounds.origin.x + CGFloat(col) * (tileWidth + gap),
                    y: screenBounds.origin.y + CGFloat(row) * (tileHeight + gap),
                    width: tileWidth,
                    height: tileHeight
                )
                
                if windowManager.setWindowBounds(window, bounds: bounds) {
                    results.append("Tiled \(window.appName)")
                }
            }
        }
        
        let success = !results.isEmpty
        let message = success ? results.joined(separator: ", ") : "Failed to tile windows"
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func cascadeWindows(_ command: WindowCommand) -> CommandResult {
        // Cascade windows for specific app or all visible windows
        let windows: [WindowInfo]
        
        if command.target.lowercased() == "all" || command.target.lowercased() == "visible" {
            // Cascade ALL windows (including minimized ones - we'll unminimize them)
            windows = windowManager.getAllWindows()
        } else {
            // Cascade windows for specific app (including minimized ones)
            windows = windowManager.getWindowsForApp(named: command.target)
        }
        
        guard !windows.isEmpty else {
            return CommandResult(success: false, message: "No windows found to cascade", command: command)
        }
        
        let displayIndex = command.display ?? 0
        // Use FULL screen bounds for 100% coverage (including menu bar area)
        let screenBounds = getFullDisplayBounds(displayIndex)
        print("🖥️ Using FULL screen bounds: \(screenBounds.size) for 100% coverage")
        
        // Determine cascade style from parameters
        let cascadeStyle: CascadeConfiguration.CascadeStyle
        switch command.parameters?["style"] {
        case "intelligent", "smart":
            cascadeStyle = .smart
        case "compact", "tight":
            cascadeStyle = .tight
        case "spread":
            cascadeStyle = .spread
        case "diagonal":
            cascadeStyle = .diagonal
        case "fan":
            cascadeStyle = .fan
        default:
            cascadeStyle = .smart
        }
        
        // Create cascade configuration
        let cascadeConfig = CascadeConfiguration(
            style: cascadeStyle,
            offset: cascadeStyle == .tight ? .tight : .standard,
            priority: command.parameters?["focus"] == "true" ? .primary : .balanced
        )
        
        // Use FlexibleLayoutEngine to generate focus-aware layout
        let windowNames = windows.map { $0.appName }
        
        print("\n🎯 FOCUS-AWARE LAYOUT:")
        for appName in windowNames {
            let archetype = AppArchetypeClassifier.shared.classifyApp(appName)
            print("  📱 \(appName) → \(archetype.displayName)")
        }
        
        // Extract context from command parameters with intelligent detection
        let context = command.parameters?["context"] ?? extractContextFromTarget(command.target, userIntent: command.parameters?["user_intent"])
        
        print("  📝 Context: '\(context)'")
        print("  🎯 User intent: '\(command.parameters?["user_intent"] ?? "none")'")
        
        // Determine focused app from command parameters or auto-detect based on context
        let focusedApp: String?
        if let explicitFocus = command.parameters?["focus_app"] {
            focusedApp = explicitFocus
        } else {
            // Smart focus detection based on context and archetype priorities
            focusedApp = intelligentlySelectFocusedApp(
                windows: windowNames,
                context: context,
                userIntent: command.parameters?["user_intent"]
            )
        }
        
        let flexibleArrangements = FlexibleLayoutEngine.generateFocusAwareLayout(
            for: windowNames,
            screenSize: screenBounds.size,
            focusedApp: focusedApp,
            context: context
        )
        
        var results: [String] = []
        var arrangedBounds: [String: CGRect] = [:]
        
        // PHASE 1: Unminimize ALL windows first
        print("\n🔄 PHASE 1: Unminimizing all windows")
        print("===================================")
        for arrangement in flexibleArrangements {
            guard let window = windows.first(where: { $0.appName == arrangement.window }) else {
                print("⚠️ Could not find window for arrangement: \(arrangement.window)")
                continue
            }
            
            if windowManager.isWindowMinimized(window) {
                print("🔄 Unminimizing \(window.appName)...")
                let restoreSuccess = windowManager.restoreWindow(window)
                print("  Result: \(restoreSuccess ? "✅ Success" : "❌ Failed")")
            } else {
                print("✅ \(window.appName) already visible")
            }
        }
        
        // Wait for all unminimize operations to complete
        print("⏳ Waiting for unminimize operations to complete...")
        Thread.sleep(forTimeInterval: 1.0)
        
        // PHASE 2: Position ALL windows
        print("\n📐 PHASE 2: Positioning all windows")
        print("==================================")
        for arrangement in flexibleArrangements {
            guard let window = windows.first(where: { $0.appName == arrangement.window }) else {
                print("⚠️ Could not find window for arrangement: \(arrangement.window)")
                continue
            }
            
            // Convert flexible position/size to pixels
            let position = CGPoint(
                x: arrangement.position.x.toPixels(for: screenBounds.width) + screenBounds.origin.x,
                y: arrangement.position.y.toPixels(for: screenBounds.height) + screenBounds.origin.y
            )
            
            let size = CGSize(
                width: arrangement.size.width.toPixels(for: screenBounds.width, otherDimension: nil) ?? screenBounds.width * 0.5,
                height: arrangement.size.height.toPixels(for: screenBounds.height, otherDimension: nil) ?? screenBounds.height * 0.5
            )
            
            let bounds = CGRect(origin: position, size: size)
            arrangedBounds[window.appName] = bounds
            
            print("📍 Positioning \(window.appName) to \(bounds)")
            
            // Disable validation since we're using full screen bounds for 100% coverage
            if windowManager.setWindowBounds(window, bounds: bounds, validate: false) {
                results.append("Cascaded \(window.appName) (\(arrangement.visibility.rawValue) visibility)")
                
                // Focus windows based on layer (highest layer = most visible = focus last)
                if arrangement.layer == flexibleArrangements.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        _ = self.windowManager.focusWindow(window)
                    }
                }
            }
        }
        
        // Record the cascade arrangement for learning
        if !arrangedBounds.isEmpty {
            learningService.recordWindowArrangement(
                windows: windows,
                arrangedBounds: arrangedBounds,
                context: "cascade_\(cascadeStyle.rawValue)"
            )
        }
        
        // If we used existing cascade positioner as fallback
        if results.isEmpty {
            let userContext = UserContext(
                activity: command.parameters?["activity"],
                focusMode: command.parameters?["focus"] == "true"
            )
            
            let style: CascadeStyle = command.parameters?["style"] == "compact" ? .compact : .intelligent
            let arrangements = cascadePositioner.arrangeCascade(
                windows: windows,
                style: style,
                context: userContext,
                screenBounds: screenBounds,
                displayIndex: displayIndex
            )
            
            for arrangement in arrangements {
                if windowManager.setWindowBounds(arrangement.window, bounds: arrangement.targetBounds) {
                    results.append("Cascaded \(arrangement.window.appName) as \(arrangement.role.rawValue)")
                    
                    if arrangement.layerIndex == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            _ = self.windowManager.focusWindow(arrangement.window)
                        }
                    }
                }
            }
        }
        
        let success = !results.isEmpty
        let message = success ? results.joined(separator: ", ") : "Failed to cascade windows"
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func restoreWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let success = windowManager.restoreWindow(window)
        let message = success ? "Restored \(command.target)" : "Failed to restore \(command.target)"
        return CommandResult(success: success, message: message, command: command)
    }
    
    // MARK: - Helper Methods
    private func getTargetWindows(_ target: String) -> [WindowInfo]? {
        let windows = windowManager.getWindowsForApp(named: target)
        return windows.isEmpty ? nil : windows
    }
    
    private func getDisplayBounds(_ displayIndex: Int) -> CGRect {
        let screens = NSScreen.screens
        guard displayIndex < screens.count else {
            return NSScreen.main?.frame ?? .zero
        }
        return screens[displayIndex].frame
    }
    
    private func getVisibleDisplayBounds(_ displayIndex: Int) -> CGRect {
        let screens = NSScreen.screens
        guard displayIndex < screens.count else {
            return NSScreen.main?.visibleFrame ?? .zero
        }
        return screens[displayIndex].visibleFrame
    }
    
    // NEW: Get full screen bounds for 100% coverage (including menu bar area)
    private func getFullDisplayBounds(_ displayIndex: Int) -> CGRect {
        let screens = NSScreen.screens
        guard displayIndex < screens.count else {
            return NSScreen.main?.frame ?? .zero
        }
        return screens[displayIndex].frame
    }
    
    private func getBundleID(for appName: String) -> String? {
        return NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.lowercased() == appName.lowercased()
        }?.bundleIdentifier
    }
    
    private func getCurrentWindowSize(for appName: String) -> CGSize? {
        let windows = windowManager.getWindowsForApp(named: appName)
        return windows.first?.bounds.size
    }
    
    private func getOptimalSize(for bundleID: String, screenSize: CGSize) -> CGSize {
        guard let constraints = constraintsManager.getConstraints(for: bundleID) else {
            // Default to medium size
            return CGSize(width: screenSize.width * 0.5, height: screenSize.height * 0.7)
        }
        
        // Calculate optimal size based on app category and constraints
        switch constraints.category {
        case .codeEditor:
            return CGSize(width: screenSize.width * 0.7, height: screenSize.height * 0.8)
        case .browser:
            return CGSize(width: screenSize.width * 0.6, height: screenSize.height * 0.8)
        case .communication:
            return CGSize(width: min(800, screenSize.width * 0.4), height: screenSize.height * 0.7)
        case .terminal:
            return CGSize(width: screenSize.width * 0.5, height: screenSize.height * 0.6)
        case .design:
            return CGSize(width: screenSize.width * 0.8, height: screenSize.height * 0.9)
        case .productivity:
            return CGSize(width: screenSize.width * 0.6, height: screenSize.height * 0.7)
        case .media:
            return CGSize(width: screenSize.width * 0.7, height: screenSize.height * 0.7)
        case .database:
            return CGSize(width: screenSize.width * 0.8, height: screenSize.height * 0.8)
        case .other:
            return CGSize(width: screenSize.width * 0.5, height: screenSize.height * 0.7)
        }
    }
    
    // MARK: - Intelligent Focus Selection
    private func intelligentlySelectFocusedApp(windows: [String], context: String, userIntent: String?) -> String? {
        let classifier = AppArchetypeClassifier.shared
        
        // Map each app to its archetype
        let appArchetypes = windows.map { app in
            (app: app, archetype: classifier.classifyApp(app))
        }
        
        print("  🔍 Focus resolution for context '\(context)':")
        
        // Sort apps by context-specific priority
        let sortedApps = appArchetypes.sorted { (app1, app2) in
            let priority1 = getContextSpecificPriority(app1.archetype, context: context)
            let priority2 = getContextSpecificPriority(app2.archetype, context: context)
            
            print("    📱 \(app1.app): \(app1.archetype.rawValue) (priority \(priority1))")
            print("    📱 \(app2.app): \(app2.archetype.rawValue) (priority \(priority2))")
            
            return priority1 < priority2 // Lower number = higher priority
        }
        
        let focusedApp = sortedApps.first?.app
        print("  🎯 Focus resolved to: \(focusedApp ?? "none")")
        
        return focusedApp
    }
    
    private func getContextSpecificPriority(_ archetype: AppArchetype, context: String) -> Int {
        switch context {
        case "coding", "develop", "program":
            switch archetype {
            case .codeWorkspace: return 1    // Highest priority for coding
            case .contentCanvas: return 2    // Documentation/browsers
            case .textStream: return 3       // Terminal support
            case .glanceableMonitor: return 4
            case .unknown: return 5
            }
            
        case "design", "create":
            switch archetype {
            case .contentCanvas: return 1    // Design tools priority
            case .codeWorkspace: return 2
            case .textStream: return 3
            case .glanceableMonitor: return 4
            case .unknown: return 5
            }
            
        case "research", "browse", "study":
            switch archetype {
            case .contentCanvas: return 1    // Browsers priority
            case .textStream: return 2       // Note-taking
            case .codeWorkspace: return 3
            case .glanceableMonitor: return 4
            case .unknown: return 5
            }
            
        case "communication", "chat", "meeting":
            switch archetype {
            case .textStream: return 1       // Chat apps priority
            case .contentCanvas: return 2
            case .glanceableMonitor: return 3
            case .codeWorkspace: return 4
            case .unknown: return 5
            }
            
        default: // "general" or unknown contexts
            switch archetype {
            case .contentCanvas: return 1
            case .codeWorkspace: return 2
            case .textStream: return 3
            case .glanceableMonitor: return 4
            case .unknown: return 5
            }
        }
    }
    
    // MARK: - Context Extraction
    private func extractContextFromTarget(_ target: String, userIntent: String?) -> String {
        // First check if there's a user intent that gives context clues
        if let intent = userIntent?.lowercased() {
            if intent.contains("code") || intent.contains("coding") || intent.contains("develop") || intent.contains("program") {
                return "coding"
            } else if intent.contains("design") || intent.contains("create") || intent.contains("art") {
                return "design"
            } else if intent.contains("research") || intent.contains("browse") || intent.contains("read") || intent.contains("study") {
                return "research"
            } else if intent.contains("write") || intent.contains("document") || intent.contains("note") {
                return "writing"
            } else if intent.contains("meet") || intent.contains("call") || intent.contains("video") {
                return "meeting"
            }
        }
        
        // Fallback to target analysis
        let targetLower = target.lowercased()
        if targetLower.contains("cod") || targetLower.contains("develop") {
            return "coding"
        } else if targetLower.contains("design") {
            return "design"
        } else if targetLower.contains("research") || targetLower.contains("browse") {
            return "research"
        }
        
        // Default fallback
        return "general"
    }
    
    // MARK: - Coordinated LLM Control
    
    func executeFlexiblePosition(_ command: WindowCommand, windowInfo: WindowInfo, screenSize: CGSize) -> Bool {
        print("🎯 EXECUTING FLEXIBLE POSITION:")
        print("  App: \(command.target)")
        print("  Position: \(command.customPosition ?? CGPoint.zero)")
        print("  Size: \(command.customSize ?? CGSize.zero)")
        print("  Layer: \(command.parameters?["layer"] ?? "none")")
        print("  Focus: \(command.parameters?["focus"] ?? "false")")
        
        // Validate bounds
        guard let position = command.customPosition,
              let size = command.customSize else {
            print("❌ Missing custom position or size")
            return false
        }
        
        // Ensure window stays within screen bounds
        let adjustedPosition = CGPoint(
            x: max(0, min(position.x, screenSize.width - size.width)),
            y: max(0, min(position.y, screenSize.height - size.height))
        )
        
        let adjustedSize = CGSize(
            width: max(200, min(size.width, screenSize.width)), // Minimum 200px wide
            height: max(150, min(size.height, screenSize.height)) // Minimum 150px tall
        )
        
        // Set window bounds
        let newBounds = CGRect(origin: adjustedPosition, size: adjustedSize)
        let success = windowManager.setWindowBounds(windowInfo, bounds: newBounds)
        
        if success {
            print("✅ Window positioned successfully")
            
            // Handle focus if requested
            if let focusParam = command.parameters?["focus"],
               focusParam.lowercased() == "true" {
                let focusSuccess = windowManager.focusWindow(windowInfo)
                print("🎯 Focus \(focusSuccess ? "set" : "failed")")
            }
            
            // Handle layer/stacking (simulated for now - would need additional window manager APIs)
            if let layerParam = command.parameters?["layer"] {
                print("📚 Layer \(layerParam) (stacking order)")
                // In a full implementation, this would control z-order
                // For now, we just log it
            }
        } else {
            print("❌ Failed to position window")
        }
        
        return success
    }
    
    // MARK: - Animated Command Implementations
    
    private func executeAnimatedMove(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        let displayIndex = command.display ?? 0
        var position: CGPoint
        
        if command.position == .precise, let customPosition = command.customPosition {
            position = customPosition
        } else if let customPosition = command.customPosition {
            position = customPosition
        } else if let windowPosition = command.position {
            let size = command.customSize ?? window.bounds.size
            position = calculatePosition(windowPosition, size: size, on: displayIndex)
        } else {
            completion(CommandResult(success: false, message: "No position specified", command: command))
            return
        }
        
        // Apply learned position offset if available
        if let preferredOffset = learningService.getPreferredPositionOffset(for: window.appName) {
            position.x += preferredOffset.x
            position.y += preferredOffset.y
        }
        
        let preset = AnimationPresets.presetForOperation(.move)
        windowManager.moveWindowAnimated(window, to: position, preset: preset) {
            // Record this arrangement for learning
            let newBounds = CGRect(origin: position, size: window.bounds.size)
            self.learningService.recordWindowArrangement(
                windows: [window],
                arrangedBounds: [window.appName: newBounds],
                context: "animated_move_\(command.position?.rawValue ?? "custom")"
            )
            
            let message = "Animated move of \(command.target) to \(position)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedResize(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        let displayIndex = command.display ?? 0
        var size: CGSize
        
        if let customSize = command.customSize {
            size = customSize
        } else if let windowSize = command.size {
            size = calculateSize(windowSize, for: window.appName, on: displayIndex)
        } else {
            completion(CommandResult(success: false, message: "No size specified", command: command))
            return
        }
        
        let preset = AnimationPresets.presetForOperation(.resize)
        windowManager.resizeWindowAnimated(window, to: size, preset: preset) {
            let message = "Animated resize of \(command.target) to \(size)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedSnap(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        guard let position = command.position else {
            completion(CommandResult(success: false, message: "No snap position specified", command: command))
            return
        }
        
        let displayIndex = command.display ?? 0
        let sizeType = command.size ?? .medium
        let size = calculateSize(sizeType, for: window.appName, on: displayIndex)
        let snapPosition = calculatePosition(position, size: size, on: displayIndex)
        let bounds = CGRect(origin: snapPosition, size: size)
        
        windowManager.snapWindowAnimated(window, to: bounds) {
            let message = "Snapped \(command.target) to \(position.rawValue)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedMaximize(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        windowManager.maximizeWindowAnimated(window) {
            let message = "Maximized \(command.target)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedMinimize(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        // Use instant animation for minimize (it's handled by system)
        let success = windowManager.minimizeWindow(window)
        let message = success ? "Minimized \(command.target)" : "Failed to minimize \(command.target)"
        completion(CommandResult(success: success, message: message, command: command))
    }
    
    private func executeAnimatedFocus(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        windowManager.focusWindowAnimated(window) {
            let message = "Focused \(command.target)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedRestore(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            completion(CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command))
            return
        }
        
        windowManager.restoreWindowAnimated(window) {
            let message = "Restored \(command.target)"
            completion(CommandResult(success: true, message: message, command: command))
        }
    }
    
    private func executeAnimatedArrange(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        // For arrange commands, we need to handle multiple windows
        let result = arrangeWorkspace(command)
        
        // If the synchronous version succeeded, we'll add animation
        if result.success {
            // Get all windows that were arranged
            let allWindows = windowManager.getAllWindows()
            let targetWindows = allWindows.filter { window in
                // Filter based on workspace context
                return true // For now, animate all visible windows
            }
            
            // Create animated arrangement with staggered timing
            let configuration = AnimationConfiguration(
                preset: AnimationPresets.presetForContext(command.target),
                staggerDelay: 0.1,
                coordinatedExecution: true,
                respectsReducedMotion: true
            )
            
            // Apply the current positions as animated transitions
            let operations = targetWindows.map { window in
                (window, window.bounds)
            }
            
            windowManager.animateWindowsCoordinated(operations, configuration: configuration) {
                completion(result)
            }
        } else {
            completion(result)
        }
    }
    
    private func executeAnimatedTile(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        // Execute tiling and then add animations
        let result = tileWindows(command)
        
        if result.success {
            // Animate the tiling result
            let allWindows = windowManager.getAllWindows()
            let operations = allWindows.map { window in
                (window, window.bounds)
            }
            
            windowManager.animateWindowsCoordinated(operations, configuration: .performance) {
                completion(result)
            }
        } else {
            completion(result)
        }
    }
    
    private func executeAnimatedCascade(_ command: WindowCommand, completion: @escaping (CommandResult) -> Void) {
        // Execute cascade and then add staggered animations
        let result = cascadeWindows(command)
        
        if result.success {
            let allWindows = windowManager.getAllWindows()
            let cascadeOrigin = CGPoint(x: 100, y: 100)
            
            let defaultCascade = CascadeConfiguration(
                style: .standard,
                offset: .standard,
                priority: .balanced
            )
            windowManager.cascadeWindowsAnimated(allWindows, startingAt: cascadeOrigin, cascade: defaultCascade) {
                completion(result)
            }
        } else {
            completion(result)
        }
    }
}