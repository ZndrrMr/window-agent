import Cocoa
import SwiftUI

// MARK: - Layout Capture Data Structure
struct CaptureData: Codable {
    let timestamp: Date
    let windowCount: Int
    let toolCalls: [String]
    var userCommand: String
    
    // Generate few-shot prompting format
    func toFewShotExample() -> String {
        return """
        {
            "user_command": "\(userCommand)",
            "tool_calls": [
        \(toolCalls.map { "        \($0)" }.joined(separator: ",\n"))
            ]
        }
        """
    }
}

class WindowAIController: HotkeyManagerDelegate, LLMServiceDelegate {
    
    // MARK: - Core Components
    private let hotkeyManager = HotkeyManager()
    private let windowManager = WindowManager.shared
    private let appLauncher = AppLauncher()
    private lazy var llmService = LLMService(windowManager: windowManager)
    private let subscriptionService = SubscriptionService()
    private let analyticsService = AnalyticsService()
    
    // Command executor that coordinates everything
    private lazy var commandExecutor = CommandExecutor(
        windowManager: windowManager,
        appLauncher: appLauncher
    )
    
    // MARK: - UI Components
    private var commandWindow: CommandWindow!
    private var settingsWindow: SettingsWindow?
    private var onboardingWindow: OnboardingWindow?
    
    // MARK: - State
    private let preferences = UserPreferences.shared
    private var isProcessingCommand = false
    
    init() {
        // DEVELOPMENT: Enable debug mode to bypass subscription limits
        preferences.debugMode = true
        subscriptionService.resetUsageForDevelopment()
        print("🔧 DEVELOPMENT MODE ENABLED - No subscription limits")
        
        setupApplication()
        setupComponents()
        setupNotifications()
        
        // Test LLM integration (disabled until permissions are working)
        // testLLMIntegration()
        
        // DEVELOPMENT: Run Finder detection tests and performance tests
        #if DEBUG
        // Disabled automatic tests to prevent interference with normal usage
        // Uncomment these lines if you need to run performance tests manually
        
        // DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        //     FinderDetection.runTests()
        // }
        
        // DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        //     XRayWindowManager.shared.runPerformanceTests()
        // }
        #endif
        
        // DEVELOPMENT: Uncomment to run minimal Gemini test automatically
        // DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        //     Task {
        //         await testMinimalGemini("move terminal to the left")
        //     }
        // }
    }
    
    // MARK: - Application Setup
    private func setupApplication() {
        // Hide dock icon (we'll show in menu bar instead)
        NSApp.setActivationPolicy(.accessory)
        
        // Track app launch
        analyticsService.trackAppLaunched()
    }
    
    private func setupComponents() {
        // Setup command window
        commandWindow = CommandWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 88),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        
        // Setup hotkey manager
        hotkeyManager.delegate = self
        if preferences.hotkeyEnabled {
            hotkeyManager.registerHotkey(
                keyCode: preferences.hotkeyKeyCode,
                modifiers: preferences.hotkeyModifiers
            )
        } else {
            print("⚠️ Hotkey disabled in preferences")
        }
        
        // Setup LLM service
        llmService.delegate = self
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommandEntered(_:)),
            name: NSNotification.Name("WindowAI.CommandEntered"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOnboardingComplete(_:)),
            name: NSNotification.Name("WindowAI.OnboardingComplete"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowDemo(_:)),
            name: NSNotification.Name("WindowAI.ShowDemo"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func showCommandWindow() {
        guard !isProcessingCommand else { return }
        
        // Ensure only one command window exists
        hideAllOtherCommandWindows()
        
        commandWindow.showWindow()
    }
    
    func hideCommandWindow() {
        commandWindow.hideWindow()
    }
    
    private func hideAllOtherCommandWindows() {
        // Close any other windows that might be command windows
        for window in NSApp.windows {
            if window != commandWindow && window.className.contains("Command") {
                window.close()
            }
        }
    }
    
    func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showOnboarding() {
        onboardingWindow = OnboardingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func captureCurrentLayout() {
        Task {
            await generateLayoutCapture()
        }
    }
    
    func checkAndShowOnboarding() {
        if preferences.showOnboarding {
            showOnboarding()
        }
    }
    
    func updateHotkey() {
        hotkeyManager.unregisterHotkey()
        if preferences.hotkeyEnabled {
            hotkeyManager.registerHotkey(
                keyCode: preferences.hotkeyKeyCode,
                modifiers: preferences.hotkeyModifiers
            )
        }
    }
    
    func unregisterHotkey() {
        hotkeyManager.unregisterHotkey()
    }
    func testLLMIntegration() {
          Task {
              let tester = LLMTestInterface()
              tester.setupWithAPIKey("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")
              await tester.testCommand("Open Safari and put it on the left half")
          }
      }
    
    // MARK: - Context Building
    private func buildLLMContext() -> LLMContext {
        let windowManager = WindowManager.shared
        let allWindows = windowManager.getAllWindows()
        let displays = windowManager.getAllDisplayInfo()
        
        // Get running apps
        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName }
            .filter { !$0.isEmpty }
            .sorted()
        
        // Build window summaries with display info
        let visibleWindows = allWindows.map { window in
            let isVisible = windowManager.isWindowVisible(window)
            let isMinimized = !isVisible
            
            // Debug: Log window state to verify boolean logic fix
            print("🔍 Window State: \(window.appName) - Visible: \(isVisible), Minimized: \(isMinimized)")
            
            return LLMContext.WindowSummary(
                title: window.title,
                appName: window.appName,
                bounds: window.bounds,
                isMinimized: isMinimized,
                displayIndex: windowManager.getDisplayForWindow(window)
            )
        }
        
        // Get screen resolutions (use visible frame to exclude menu bar)
        let screenResolutions = displays.map { $0.visibleFrame.size }
        
        // Build display descriptions for the prompt (use visible frame)
        let displayDescriptions = displays.enumerated().map { index, display in
            "\(index): \(display.name) (\(Int(display.visibleFrame.width))x\(Int(display.visibleFrame.height)))\(display.isMain ? " - Main" : "")"
        }.joined(separator: ", ")
        
        print("📱 Display Configuration: \(displayDescriptions)")
        
        // Debug: Print current window positions and sizes
        print("\n🪟 CURRENT WINDOW LAYOUT:")
        for window in allWindows {
            let bounds = window.bounds
            let widthPercent = (bounds.width / displays.first!.frame.width) * 100
            let heightPercent = (bounds.height / displays.first!.frame.height) * 100
            print("  📱 \(window.appName): \(Int(bounds.origin.x)),\(Int(bounds.origin.y)) - \(Int(bounds.width))x\(Int(bounds.height)) (\(String(format: "%.0f", widthPercent))%w × \(String(format: "%.0f", heightPercent))%h)")
        }
        print("")
        
        return LLMContext(
            runningApps: runningApps,
            visibleWindows: visibleWindows,
            screenResolutions: screenResolutions,
            currentWorkspace: nil,
            displayCount: displays.count,
            userPreferences: nil
        )
    }
    
    // MARK: - Async Context Building
    private func buildLLMContextAsync() async -> LLMContext {
        let windowManager = WindowManager.shared
        
        // Parallel data gathering
        async let allWindows = windowManager.getAllWindowsAsync()
        async let displays = windowManager.getAllDisplayInfo()
        
        // Wait for core data
        let (windows, displayInfo) = await (allWindows, displays)
        
        // Extract apps that have windows (no need for separate async call)
        let apps = Set(windows.map { $0.appName })
            .filter { !$0.isEmpty }
            .sorted()
        
        print("⚡️ Parallel context building complete: \(windows.count) windows from \(apps.count) apps")
        
        // Parallel window enrichment (visibility, display detection)
        let enrichedWindows = await enrichWindowsWithMetadataAsync(windows, displays: displayInfo)
        
        // Get screen resolutions
        let screenResolutions = displayInfo.map { $0.frame.size }
        
        // Build display descriptions for the prompt
        let displayDescriptions = displayInfo.enumerated().map { index, display in
            "\(index): \(display.name) (\(Int(display.frame.width))x\(Int(display.frame.height)))\(display.isMain ? " - Main" : "")"
        }.joined(separator: ", ")
        
        print("📱 Display Configuration: \(displayDescriptions)")
        
        // Debug: Print current window positions and sizes
        print("\n🪟 CURRENT WINDOW LAYOUT:")
        for window in windows {
            let bounds = window.bounds
            let widthPercent = (bounds.width / displayInfo.first!.frame.width) * 100
            let heightPercent = (bounds.height / displayInfo.first!.frame.height) * 100
            print("  📱 \(window.appName): \(Int(bounds.origin.x)),\(Int(bounds.origin.y)) - \(Int(bounds.width))x\(Int(bounds.height)) (\(String(format: "%.0f", widthPercent))%w × \(String(format: "%.0f", heightPercent))%h)")
        }
        print("")
        
        return LLMContext(
            runningApps: apps,
            visibleWindows: enrichedWindows,
            screenResolutions: screenResolutions,
            currentWorkspace: nil,
            displayCount: displayInfo.count,
            userPreferences: nil
        )
    }
    
    
    private func enrichWindowsWithMetadataAsync(_ windows: [WindowInfo], displays: [DisplayInfo]) async -> [LLMContext.WindowSummary] {
        let windowManager = WindowManager.shared
        
        return await withTaskGroup(of: LLMContext.WindowSummary.self, returning: [LLMContext.WindowSummary].self) { group in
            for window in windows {
                group.addTask {
                    async let isVisible = windowManager.isWindowVisibleAsync(window)
                    async let displayIndex = windowManager.getDisplayForWindow(window)
                    
                    let (visible, display) = await (isVisible, displayIndex)
                    
                    // Debug: Log window state to verify boolean logic fix
                    print("🔍 Window State: \(window.appName) - Visible: \(visible), Minimized: \(!visible)")
                    
                    return LLMContext.WindowSummary(
                        title: window.title,
                        appName: window.appName,
                        bounds: window.bounds,
                        isMinimized: !visible,
                        displayIndex: display
                    )
                }
            }
            
            var summaries: [LLMContext.WindowSummary] = []
            for await summary in group {
                summaries.append(summary)
            }
            return summaries
        }
    }
    
    // MARK: - Command Processing
    @objc private func handleCommandEntered(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let command = userInfo["command"] as? String else { return }
        
        processUserCommand(command)
    }
    
    private func processUserCommand(_ userInput: String) {
        guard !isProcessingCommand else { return }
        
        // Check subscription limits
        guard subscriptionService.canMakeRequest() else {
            commandWindow.showError("Monthly limit reached. Please upgrade your subscription.")
            return
        }
        
        // Validate LLM configuration
        guard llmService.validateConfiguration() else {
            commandWindow.showError("Please configure your AI settings in preferences.")
            return
        }
        
        isProcessingCommand = true
        commandWindow.showLoading()
        subscriptionService.recordRequest()
        
        let startTime = Date()
        
        Task {
            do {
                print("⚡️ Starting parallel context building...")
                let contextStartTime = Date()
                let context = await buildLLMContextAsync()
                let contextDuration = Date().timeIntervalSince(contextStartTime)
                print("⚡️ Context building completed in \(String(format: "%.2f", contextDuration))s (was ~5s before)")
                
                let response = try await llmService.processCommand(userInput, context: context)
                
                let duration = Date().timeIntervalSince(startTime)
                analyticsService.trackLLMRequest(
                    provider: preferences.llmProvider,
                    duration: duration,
                    success: true,
                    tokenCount: nil
                )
                
                await executeCommands(response.commands)
                
                DispatchQueue.main.async {
                    self.commandWindow.hideLoading()
                    self.commandWindow.showSuccess("Commands executed successfully")
                    self.isProcessingCommand = false
                    
                    print("\n✨ DONE! All commands executed.\n")
                    
                    // Auto-hide after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.preferences.autoHideDelay) {
                        self.hideCommandWindow()
                    }
                }
                
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                analyticsService.trackLLMRequest(
                    provider: preferences.llmProvider,
                    duration: duration,
                    success: false,
                    tokenCount: nil
                )
                analyticsService.trackError(error, context: "command_processing")
                
                DispatchQueue.main.async {
                    self.commandWindow.hideLoading()
                    self.commandWindow.showError("Failed to process command: \(error.localizedDescription)")
                    self.isProcessingCommand = false
                }
            }
        }
    }
    
    private func executeCommands(_ commands: [WindowCommand]) async {
        let startTime = Date()
        
        // Use animated commands if animations are enabled and it's a single window operation
        let results: [CommandResult]
        if UserPreferences.shared.animateWindowMovement && commands.count == 1 {
            print("🎬 Executing single command with animation")
            results = await commandExecutor.executeCommandsAnimated(commands)
        } else {
            if commands.count > 1 {
                print("⚡ Executing \(commands.count) commands without animations (multi-window)")
            } else {
                print("⚡ Executing commands without animations")
            }
            results = await commandExecutor.executeCommands(commands)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Track analytics for each command
        for (command, result) in zip(commands, results) {
            analyticsService.trackCommandExecuted(command, success: result.success, duration: duration)
        }
        
        // Track analytics for successful commands
        let successfulCommands = results.filter { $0.success }.count
        if successfulCommands > 1 {
            print("✅ Completed \(successfulCommands) successful window operations")
            // Note: X-Ray overlay removed - only triggered by hotkey now
        }
    }
    
    // MARK: - Notification Handlers
    @objc private func handleOnboardingComplete(_ notification: Notification) {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
    
    @objc private func handleShowDemo(_ notification: Notification) {
        onboardingWindow?.orderOut(nil)
        showCommandWindow()
    }
}

// MARK: - HotkeyManagerDelegate
extension WindowAIController {
    func hotkeyPressed() {
        print("🔥 Hotkey pressed! Window visible: \(commandWindow.isVisible)")
        
        // Cancel any pending animations to ensure UI responsiveness
        AnimationQueue.shared.emergencyReset()
        
        // Prevent multiple rapid hotkey presses
        DispatchQueue.main.async {
            if self.commandWindow.isVisible && self.commandWindow.alphaValue > 0 {
                self.commandWindow.hideWindow()
            } else {
                // Ensure only one window
                self.hideAllOtherCommandWindows()
                self.commandWindow.showWindow()
            }
        }
    }
    
    func xrayOverlayRequested() {
        print("🔍 X-Ray overlay requested via double-tap Command key")
        
        DispatchQueue.main.async {
            // Hide command window if visible
            if self.commandWindow.isVisible {
                self.commandWindow.hideWindow()
            }
            
            // DEVELOPMENT: Debug Finder windows before showing overlay
            #if DEBUG
            XRayWindowManager.shared.debugFinderWindows()
            #endif
            
            // Toggle X-Ray overlay
            XRayWindowManager.shared.toggleXRayOverlay()
        }
    }
    
    // MARK: - Layout Capture
    private func generateLayoutCapture() async {
        print("🎬 Capturing current layout...")
        
        // Ensure X-Ray overlay is hidden before capturing (on main thread)
        await MainActor.run {
            XRayWindowManager.shared.hideXRayOverlay()
        }
        
        // Wait a moment for any X-Ray state to clear
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Get all current windows
        let allWindows = windowManager.getAllWindows()
        let displayInfo = windowManager.getAllDisplayInfo()
        
        // Filter out system windows and focus on user apps
        let userWindows = allWindows.filter { window in
            !window.appName.contains("WindowAI") && 
            !window.appName.contains("System") &&
            !window.appName.contains("Dock") &&
            !window.title.isEmpty
        }
        
        print("📱 Found \(userWindows.count) user windows to capture")
        
        // Generate Gemini tool calls for each window
        var toolCalls: [String] = []
        let mainDisplay = displayInfo.first ?? DisplayInfo(
            index: 0,
            name: "Main Display",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true,
            backingScaleFactor: 1.0
        )
        
        for (index, window) in userWindows.enumerated() {
            // Convert to percentage coordinates
            let xPercent = (window.bounds.origin.x / mainDisplay.frame.width) * 100
            let yPercent = (window.bounds.origin.y / mainDisplay.frame.height) * 100
            let widthPercent = (window.bounds.width / mainDisplay.frame.width) * 100
            let heightPercent = (window.bounds.height / mainDisplay.frame.height) * 100
            
            // Generate tool call
            let toolCall = """
            flexible_position(
                app_name: "\(window.appName)",
                x_position: "\(String(format: "%.1f", xPercent))",
                y_position: "\(String(format: "%.1f", yPercent))",
                width: "\(String(format: "%.1f", widthPercent))",
                height: "\(String(format: "%.1f", heightPercent))",
                layer: "\(3 - index)",
                focus: "\(index == 0 ? "true" : "false")"
            )
            """
            
            toolCalls.append(toolCall)
        }
        
        // Create capture data
        let captureData = CaptureData(
            timestamp: Date(),
            windowCount: userWindows.count,
            toolCalls: toolCalls,
            userCommand: "" // Will be filled in by user
        )
        
        // Save to file
        await saveCaptureData(captureData)
        
        // Show success notification on main thread
        await MainActor.run {
            self.showCaptureNotification(captureData)
        }
        
        // Generate few-shot example format
        print("\n🎯 FEW-SHOT EXAMPLE FORMAT:")
        print("Copy this into your Gemini prompt:")
        print("----------------------------------------")
        print(captureData.toFewShotExample())
        print("----------------------------------------\n")
    }
    
    private func saveCaptureData(_ data: CaptureData) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: data.timestamp)
        
        let filename = "layout_capture_\(timestamp).json"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let capturesFolder = documentsPath.appendingPathComponent("WindowAI_Captures")
        
        // Create captures folder if it doesn't exist
        try? FileManager.default.createDirectory(at: capturesFolder, withIntermediateDirectories: true)
        
        let fileURL = capturesFolder.appendingPathComponent(filename)
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: fileURL)
            print("✅ Layout capture saved to: \(fileURL.path)")
        } catch {
            print("❌ Failed to save layout capture: \(error)")
        }
    }
    
    private func showCaptureNotification(_ data: CaptureData) {
        let alert = NSAlert()
        alert.messageText = "Layout Captured!"
        alert.informativeText = """
        Captured \(data.windowCount) windows successfully.
        
        The layout data has been saved to your Documents/WindowAI_Captures folder.
        
        You can now add a user command to describe what arrangement this represents (e.g., "I want to code", "set up for research", etc.).
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Captures Folder")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Open the captures folder
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let capturesFolder = documentsPath.appendingPathComponent("WindowAI_Captures")
            NSWorkspace.shared.open(capturesFolder)
        }
    }
}

// MARK: - LLMServiceDelegate
extension WindowAIController {
    func llmService(_ service: LLMService, didReceiveResponse response: LLMResponse) {
        // This is handled in the async processUserCommand method
    }
    
    func llmService(_ service: LLMService, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.commandWindow.hideLoading()
            self.commandWindow.showError("AI processing failed: \(error.localizedDescription)")
            self.isProcessingCommand = false
        }
    }
}


// MARK: - Main Entry Point
@main
struct Main {
    static let appDelegate = AppDelegate()
    
    static func main() {
        // Use the shared NSApplication instance
        let app = NSApplication.shared
        
        // Set our custom app as the delegate
        app.delegate = appDelegate
        
        app.run()
    }
}

// MARK: - Custom App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowAIController: WindowAIController?
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permissions
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            let trusted = AXIsProcessTrustedWithOptions(options)
            
            if !trusted {
                DispatchQueue.main.async {
                    // This will trigger the prompt if needed
                    let systemWide = AXUIElementCreateSystemWide()
                    var value: CFTypeRef?
                    let _ = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &value)
                }
            }
        }
        
        print("\n🚀 WindowAI Started!\n")
        
        windowAIController = WindowAIController()
        setupMenuBar()
        windowAIController?.checkAndShowOnboarding()
    }
    
    private func checkPermissions() {
        // Check accessibility permissions first
        if !PermissionManager.hasAccessibilityPermissions() {
            showAccessibilityPermissionDialog()
        }
    }
    
    private func showAccessibilityPermissionDialog() {
        let alert = NSAlert()
        alert.messageText = "WindowAI Needs Accessibility Access"
        alert.informativeText = "WindowAI requires accessibility permissions to control and position windows from other applications.\n\n1. Click 'Open System Preferences'\n2. Find 'WindowAI' in the list\n3. Check the box next to WindowAI\n4. Restart the app if needed"
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // First try the automatic prompt
            PermissionManager.requestAccessibilityPermissions()
            // Then open system preferences manually
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PermissionManager.openAccessibilitySettings()
            }
        } else if response == .alertSecondButtonReturn {
            // Just try the automatic prompt again
            PermissionManager.requestAccessibilityPermissions()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up command window before terminating
        windowAIController?.hideCommandWindow()
        windowAIController?.unregisterHotkey()
        
        // Save preferences
        UserPreferences.shared.savePreferences()
        
        // Give the system a moment to clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Force close all windows
            for window in NSApp.windows {
                window.close()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowAIController?.showCommandWindow()
        }
        return true
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusButton = statusItem?.button else { return }
        statusButton.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "WindowAI")
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Command Window", action: #selector(showCommandWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Capture Current Layout", action: #selector(captureCurrentLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About WindowAI", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WindowAI", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        menu.items.forEach { $0.target = self }
        statusItem?.menu = menu
    }
    
    @objc private func showCommandWindow() {
        windowAIController?.showCommandWindow()
    }
    
    @objc private func showSettings() {
        windowAIController?.showSettings()
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    @objc private func captureCurrentLayout() {
        windowAIController?.captureCurrentLayout()
    }
    
}
