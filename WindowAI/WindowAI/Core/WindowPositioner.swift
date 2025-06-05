import Cocoa
import CoreGraphics
import Foundation

// MARK: - Window Positioning Engine
class WindowPositioner {
    
    private let windowManager: WindowManager
    private let constraintsManager = AppConstraintsManager.shared
    private let intelligentLayout = IntelligentLayoutEngine.shared
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
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
            return stackWindows(command)
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
        case .small, .quarter, .third:
            calculatedSize = CGSize(width: visibleBounds.width * 0.33, height: visibleBounds.height * 0.5)
        case .medium, .half:
            calculatedSize = CGSize(width: visibleBounds.width * 0.5, height: visibleBounds.height * 0.7)
        case .large, .twoThirds:
            calculatedSize = CGSize(width: visibleBounds.width * 0.67, height: visibleBounds.height * 0.8)
        case .threeQuarters:
            calculatedSize = CGSize(width: visibleBounds.width * 0.75, height: visibleBounds.height * 0.85)
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
        
        // Apply app constraints
        return constraintsManager.validateWindowSize(calculatedSize, for: bundleID)
    }
    
    // MARK: - Command Implementations
    private func moveWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let displayIndex = command.display ?? 0
        var position: CGPoint
        
        if let customPosition = command.customPosition {
            position = customPosition
        } else if let windowPosition = command.position {
            let size = command.customSize ?? window.bounds.size
            position = calculatePosition(windowPosition, size: size, on: displayIndex)
        } else {
            return CommandResult(success: false, message: "No position specified", command: command)
        }
        
        let success = windowManager.moveWindow(window, to: position)
        let message = success ? "Moved \(command.target) to \(position)" : "Failed to move \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func resizeWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let displayIndex = command.display ?? 0
        var size: CGSize
        
        if let customSize = command.customSize {
            size = customSize
        } else if let windowSize = command.size {
            size = calculateSize(windowSize, for: window.appName, on: displayIndex)
        } else {
            return CommandResult(success: false, message: "No size specified", command: command)
        }
        
        let success = windowManager.resizeWindow(window, to: size)
        let message = success ? "Resized \(command.target) to \(size)" : "Failed to resize \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func snapWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        guard let position = command.position else {
            return CommandResult(success: false, message: "No snap position specified", command: command)
        }
        
        let displayIndex = command.display ?? 0
        let sizeType = command.size ?? .medium
        let size = calculateSize(sizeType, for: window.appName, on: displayIndex)
        let calculatedPosition = calculatePosition(position, size: size, on: displayIndex)
        
        let bounds = CGRect(origin: calculatedPosition, size: size)
        let success = windowManager.setWindowBounds(window, bounds: bounds)
        let message = success ? "Snapped \(command.target) to \(position.rawValue)" : "Failed to snap \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func maximizeWindow(_ command: WindowCommand) -> CommandResult {
        guard let windows = getTargetWindows(command.target), let window = windows.first else {
            return CommandResult(success: false, message: "Could not find window for '\(command.target)'", command: command)
        }
        
        let success = windowManager.maximizeWindow(window)
        let message = success ? "Maximized \(command.target)" : "Failed to maximize \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
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
        
        let success = windowManager.focusWindow(window)
        let message = success ? "Focused \(command.target)" : "Failed to focus \(command.target)"
        
        return CommandResult(success: success, message: message, command: command)
    }
    
    private func openApp(_ command: WindowCommand) -> CommandResult {
        // This will be handled by AppLauncher, but we can set initial position/size
        let bundleID = getBundleID(for: command.target)
        
        if let bundleID = bundleID {
            let success = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, 
                                                             options: [], 
                                                             additionalEventParamDescriptor: nil, 
                                                             launchIdentifier: nil)
            
            if success && (command.position != nil || command.size != nil) {
                // Wait a moment for the app to launch, then position it
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let window = self.windowManager.getWindowsForApp(named: command.target).first {
                        if let position = command.position, let size = command.size {
                            let displayIndex = command.display ?? 0
                            let calculatedSize = self.calculateSize(size, for: command.target, on: displayIndex)
                            let calculatedPosition = self.calculatePosition(position, size: calculatedSize, on: displayIndex)
                            let bounds = CGRect(origin: calculatedPosition, size: calculatedSize)
                            _ = self.windowManager.setWindowBounds(window, bounds: bounds)
                        }
                    }
                }
            }
            
            let message = success ? "Opened \(command.target)" : "Failed to open \(command.target)"
            return CommandResult(success: success, message: message, command: command)
        } else {
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
        let errors: [String] = []
        
        // First, handle excluded apps by minimizing them
        for excludedApp in workspace.excludedApps {
            let windows = windowManager.getWindowsForApp(named: excludedApp)
            for window in windows {
                if windowManager.minimizeWindow(window) {
                    results.append("Minimized \(excludedApp)")
                }
            }
        }
        
        // Get screen bounds for layout
        let screenBounds = getVisibleDisplayBounds(0)
        
        // Launch required apps if not running
        for appContext in workspace.requiredApps {
            if windowManager.getWindowsForApp(named: appContext.appName).isEmpty {
                // App not running, launch it
                let bundleID = appContext.bundleID
                if NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, 
                                                       options: [], 
                                                       additionalEventParamDescriptor: nil, 
                                                       launchIdentifier: nil) {
                    results.append("Launched \(appContext.appName)")
                    // Wait a bit for the app to launch
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        // Now arrange windows based on layout configuration
        let layout = workspace.layout
        let gap = layout.gapSize
        
        switch layout.screenDivision {
        case .leftRight:
            arrangeLeftRightLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
        case .topBottom:
            arrangeTopBottomLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
        case .quarters:
            arrangeQuartersLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
        case .automatic:
            // Choose based on number of apps
            let totalApps = workspace.requiredApps.count + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }.count
            if totalApps <= 2 {
                arrangeLeftRightLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
            } else if totalApps <= 4 {
                arrangeQuartersLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
            } else {
                arrangeTiledLayout(workspace: workspace, screenBounds: screenBounds, gap: gap, results: &results)
            }
        case .custom:
            results.append("Custom layouts not yet implemented")
        }
        
        let success = errors.isEmpty
        let message = success ? results.joined(separator: ", ") : errors.joined(separator: ", ")
        return CommandResult(success: success, message: message)
    }
    
    private func arrangeLeftRightLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String]) {
        // Use intelligent layout for better positioning
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        
        // Get all windows for intelligent arrangement
        var windows: [WindowInfo] = []
        for appContext in allApps {
            if let window = windowManager.getWindowsForApp(named: appContext.appName).first {
                windows.append(window)
            }
        }
        
        // Let the intelligent layout engine arrange the windows
        let arrangements = intelligentLayout.arrangeWindows(windows, in: screenBounds)
        
        // Apply the arrangements
        for arrangement in arrangements {
            if windowManager.setWindowBounds(arrangement.window, bounds: arrangement.targetBounds) {
                let roleDescription = arrangement.role == .primary ? "primary focus" : arrangement.role.rawValue
                results.append("Positioned \(arrangement.window.appName) as \(roleDescription) at \(arrangement.targetBounds.origin)")
            }
        }
        
        // If intelligent layout didn't work or no arrangements, fall back to simple split
        if arrangements.isEmpty && windows.count > 0 {
            fallbackLeftRightLayout(windows: windows, screenBounds: screenBounds, gap: gap, results: &results)
        }
    }
    
    private func fallbackLeftRightLayout(windows: [WindowInfo], screenBounds: CGRect, gap: CGFloat, results: inout [String]) {
        let halfWidth = (screenBounds.width - gap) / 2
        let height = screenBounds.height
        
        let leftX = screenBounds.origin.x
        let rightX = screenBounds.origin.x + halfWidth + gap
        let y = screenBounds.origin.y
        
        for (index, window) in windows.enumerated() {
            let isLeftSide = index % 2 == 0
            let bounds = CGRect(
                x: isLeftSide ? leftX : rightX,
                y: y,
                width: halfWidth,
                height: height
            )
            
            if windowManager.setWindowBounds(window, bounds: bounds) {
                results.append("Positioned \(window.appName) on \(isLeftSide ? "left" : "right")")
            }
        }
    }
    
    private func arrangeTopBottomLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String]) {
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
    
    private func arrangeQuartersLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String]) {
        let halfWidth = (screenBounds.width - gap) / 2
        let halfHeight = (screenBounds.height - gap) / 2
        
        let positions = [
            CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y, width: halfWidth, height: halfHeight), // Top-left
            CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y, width: halfWidth, height: halfHeight), // Top-right
            CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + halfHeight + gap, width: halfWidth, height: halfHeight), // Bottom-left
            CGRect(x: screenBounds.origin.x + halfWidth + gap, y: screenBounds.origin.y + halfHeight + gap, width: halfWidth, height: halfHeight) // Bottom-right
        ]
        
        var appIndex = 0
        let allApps = workspace.requiredApps + workspace.optionalApps.filter { windowManager.getWindowsForApp(named: $0.appName).count > 0 }
        
        for appContext in allApps where appIndex < 4 {
            if let window = windowManager.getWindowsForApp(named: appContext.appName).first {
                let bounds = positions[appIndex]
                
                if windowManager.setWindowBounds(window, bounds: bounds) {
                    let positionName = ["top-left", "top-right", "bottom-left", "bottom-right"][appIndex]
                    results.append("Positioned \(appContext.appName) at \(positionName)")
                }
                appIndex += 1
            }
        }
    }
    
    private func arrangeTiledLayout(workspace: Workspace, screenBounds: CGRect, gap: CGFloat, results: inout [String]) {
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
            layout: LayoutConfiguration(screenDivision: .quarters)
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
            // Tile all visible windows
            windows = windowManager.getAllWindows().filter { windowManager.isWindowVisible($0) }
        } else {
            // Tile windows for specific app
            windows = windowManager.getWindowsForApp(named: command.target)
        }
        
        guard !windows.isEmpty else {
            return CommandResult(success: false, message: "No windows found to tile", command: command)
        }
        
        let displayIndex = command.display ?? 0
        let screenBounds = getVisibleDisplayBounds(displayIndex)
        let gap: CGFloat = 10.0
        
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
            // Two windows - use intelligent layout for optimal positioning
            let arrangements = intelligentLayout.arrangeWindows(windows, in: screenBounds)
            
            if !arrangements.isEmpty {
                // Apply intelligent arrangements
                for arrangement in arrangements {
                    if windowManager.setWindowBounds(arrangement.window, bounds: arrangement.targetBounds) {
                        let roleDesc = arrangement.role == .primary ? "primary" : "auxiliary"
                        results.append("Positioned \(arrangement.window.appName) as \(roleDesc)")
                    }
                }
            } else {
                // Fallback to simple side-by-side
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
            // Four windows - quarters
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
    
    private func stackWindows(_ command: WindowCommand) -> CommandResult {
        // Stack windows for specific app or all visible windows
        let windows: [WindowInfo]
        
        if command.target.lowercased() == "all" || command.target.lowercased() == "visible" {
            // Stack all visible windows
            windows = windowManager.getAllWindows().filter { windowManager.isWindowVisible($0) }
        } else {
            // Stack windows for specific app
            windows = windowManager.getWindowsForApp(named: command.target)
        }
        
        guard !windows.isEmpty else {
            return CommandResult(success: false, message: "No windows found to stack", command: command)
        }
        
        let displayIndex = command.display ?? 0
        let screenBounds = getVisibleDisplayBounds(displayIndex)
        
        // Calculate cascade offset
        let cascadeOffset: CGFloat = 30.0
        let maxCascadeSteps = min(windows.count, 10) // Limit cascade to avoid going off screen
        
        // Calculate initial window size (80% of screen)
        let windowWidth = screenBounds.width * 0.6
        let windowHeight = screenBounds.height * 0.7
        
        // Calculate starting position to center the cascade
        let totalCascadeWidth = CGFloat(maxCascadeSteps - 1) * cascadeOffset
        let totalCascadeHeight = CGFloat(maxCascadeSteps - 1) * cascadeOffset
        let startX = screenBounds.origin.x + (screenBounds.width - windowWidth - totalCascadeWidth) / 2
        let startY = screenBounds.origin.y + (screenBounds.height - windowHeight - totalCascadeHeight) / 2
        
        var results: [String] = []
        
        for (index, window) in windows.enumerated() {
            let cascadeStep = min(index, maxCascadeSteps - 1)
            let x = startX + (CGFloat(cascadeStep) * cascadeOffset)
            let y = startY + (CGFloat(cascadeStep) * cascadeOffset)
            
            let bounds = CGRect(x: x, y: y, width: windowWidth, height: windowHeight)
            
            if windowManager.setWindowBounds(window, bounds: bounds) {
                results.append("Stacked \(window.appName) (position \(index + 1))")
                
                // Bring window to front in stacking order
                _ = windowManager.focusWindow(window)
            }
        }
        
        let success = !results.isEmpty
        let message = success ? results.joined(separator: ", ") : "Failed to stack windows"
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
}