import Cocoa
import SwiftUI

@main
class WindowAIApp: NSApplication {
    
    // MARK: - Core Components
    private let hotkeyManager = HotkeyManager()
    private let windowManager = WindowManager()
    private let appLauncher = AppLauncher()
    private let llmService = LLMService()
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
    
    override init() {
        super.init()
        
        setupApplication()
        setupComponents()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Application Setup
    private func setupApplication() {
        // Hide dock icon (we'll show in menu bar instead)
        NSApp.setActivationPolicy(.accessory)
        
        // Create app delegate
        self.delegate = AppDelegate(app: self)
        
        // Track app launch
        analyticsService.trackAppLaunched()
    }
    
    private func setupComponents() {
        // Setup command window
        commandWindow = CommandWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 90),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        
        // Setup hotkey manager
        hotkeyManager.delegate = self
        if preferences.hotkeyEnabled {
            _ = hotkeyManager.registerHotkey(
                keyCode: preferences.hotkeyKeyCode,
                modifiers: preferences.hotkeyModifiers
            )
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
        commandWindow.showWindow()
    }
    
    func hideCommandWindow() {
        commandWindow.hideWindow()
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
extension WindowAIApp: HotkeyManagerDelegate {
    func hotkeyPressed() {
        if commandWindow.isVisible {
            hideCommandWindow()
        } else {
            showCommandWindow()
        }
    }
}

// MARK: - LLMServiceDelegate
extension WindowAIApp: LLMServiceDelegate {
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

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private let app: WindowAIApp
    private var statusItem: NSStatusItem?
    
    init(app: WindowAIApp) {
        self.app = app
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        app.checkAndShowOnboarding()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save any pending data
        UserPreferences.shared.savePreferences()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            app.showCommandWindow()
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
        app.showCommandWindow()
    }
    
    @objc private func showSettings() {
        app.showSettings()
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}