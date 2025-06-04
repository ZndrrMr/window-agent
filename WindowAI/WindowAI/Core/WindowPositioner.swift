import Cocoa
import CoreGraphics
import Foundation

// MARK: - Window Positioning Engine
class WindowPositioner {
    
    private let windowManager: WindowManager
    private let constraintsManager = AppConstraintsManager.shared
    
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
        let screenBounds = getDisplayBounds(displayIndex)
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
        let screenBounds = getDisplayBounds(displayIndex)
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
                            self.windowManager.setWindowBounds(window, bounds: bounds)
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
        // Implementation for closing windows
        return CommandResult(success: false, message: "Close functionality not yet implemented", command: command)
    }
    
    private func arrangeWorkspace(_ command: WindowCommand) -> CommandResult {
        // Implementation for workspace arrangements
        return CommandResult(success: false, message: "Workspace arrangement not yet implemented", command: command)
    }
    
    private func tileWindows(_ command: WindowCommand) -> CommandResult {
        // Implementation for tiling windows
        return CommandResult(success: false, message: "Window tiling not yet implemented", command: command)
    }
    
    private func stackWindows(_ command: WindowCommand) -> CommandResult {
        // Implementation for stacking windows
        return CommandResult(success: false, message: "Window stacking not yet implemented", command: command)
    }
    
    private func restoreWindow(_ command: WindowCommand) -> CommandResult {
        // Implementation for restoring windows
        return CommandResult(success: false, message: "Window restore not yet implemented", command: command)
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