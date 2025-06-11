import Cocoa
import SwiftUI

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
        setupApplication()
        setupComponents()
        setupNotifications()
        
        // Test LLM integration (disabled until permissions are working)
        // testLLMIntegration()
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
                let response = try await llmService.processCommand(userInput)
                
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
        let results = await commandExecutor.executeCommands(commands)
        let duration = Date().timeIntervalSince(startTime)
        
        // Track analytics for each command
        for (command, result) in zip(commands, results) {
            analyticsService.trackCommandExecuted(command, success: result.success, duration: duration)
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
    
}
