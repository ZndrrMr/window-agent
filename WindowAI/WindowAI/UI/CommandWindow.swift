import Cocoa
import SwiftUI

class CommandWindow: NSWindow {
    private let preferences = UserPreferences.shared
    private var commandTextField: NSTextField!
    private var suggestionLabel: NSTextField!
    private var loadingIndicator: NSProgressIndicator!
    private var containerView: NSView!
    private var blurView: NSVisualEffectView!
    private var globalMonitor: Any?
    
    // Animation properties
    private var showTimer: Timer?
    private var hideTimer: Timer?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        
        setupWindow()
        setupUI()
        setupConstraints()
    }
    
    // Override to allow borderless window to become key
    override var canBecomeKey: Bool {
        return true
    }
    
    // MARK: - Window Setup
    private func setupWindow() {
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = false // We'll handle shadows in the blur view
        self.canHide = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        
        // Start invisible for smooth animations
        self.alphaValue = 0.0
        
        // Setup click-outside-to-dismiss monitoring
        setupGlobalClickMonitoring()
    }
    
    private func setupUI() {
        // Create liquid glass blur view
        blurView = NSVisualEffectView()
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        
        // Beautiful rounded corners with subtle shadow
        blurView.layer?.cornerRadius = 20
        blurView.layer?.cornerCurve = .continuous
        blurView.layer?.shadowColor = NSColor.black.cgColor
        blurView.layer?.shadowOpacity = 0.3
        blurView.layer?.shadowOffset = CGSize(width: 0, height: -8)
        blurView.layer?.shadowRadius = 24
        blurView.layer?.borderWidth = 0.5
        blurView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        // Main container 
        containerView = NSView()
        containerView.wantsLayer = true
        
        // Command text field with beautiful styling
        commandTextField = NSTextField()
        commandTextField.isBordered = false
        commandTextField.isEditable = true
        commandTextField.isSelectable = true
        commandTextField.drawsBackground = false
        commandTextField.font = NSFont.systemFont(ofSize: 22, weight: .medium)
        commandTextField.textColor = NSColor.labelColor
        commandTextField.placeholderString = "Tell WindowAI what to do..."
        commandTextField.target = self
        commandTextField.action = #selector(textFieldAction(_:))
        commandTextField.delegate = self
        commandTextField.cell?.sendsActionOnEndEditing = false
        
        // Seamless text field styling - no visible borders
        commandTextField.wantsLayer = true
        commandTextField.layer?.cornerRadius = 0
        commandTextField.layer?.backgroundColor = NSColor.clear.cgColor
        commandTextField.layer?.borderWidth = 0
        commandTextField.layer?.borderColor = NSColor.clear.cgColor
        
        // Configure text field behavior
        if let cell = commandTextField.cell as? NSTextFieldCell {
            cell.sendsActionOnEndEditing = false
            cell.focusRingType = .none // Remove focus ring
        }
        
        // Hidden suggestion label (not displayed)
        suggestionLabel = NSTextField()
        suggestionLabel.isBordered = false
        suggestionLabel.isEditable = false
        suggestionLabel.drawsBackground = false
        suggestionLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        suggestionLabel.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.8)
        suggestionLabel.stringValue = ""
        suggestionLabel.alignment = .center
        suggestionLabel.isHidden = true // Hide suggestion text completely
        
        // Beautiful loading indicator
        loadingIndicator = NSProgressIndicator()
        loadingIndicator.style = .spinning
        loadingIndicator.controlSize = .regular
        loadingIndicator.isHidden = true
        loadingIndicator.wantsLayer = true
        
        // Add multiple subtle gradient overlays for depth
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            NSColor.white.withAlphaComponent(0.15).cgColor,
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.08).cgColor
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.cornerRadius = 20
        gradientLayer.cornerCurve = .continuous
        blurView.layer?.addSublayer(gradientLayer)
        
        // Add inner highlight for glass effect
        let highlightLayer = CAGradientLayer()
        highlightLayer.colors = [
            NSColor.white.withAlphaComponent(0.3).cgColor,
            NSColor.clear.cgColor
        ]
        highlightLayer.locations = [0.0, 0.2]
        highlightLayer.cornerRadius = 20
        highlightLayer.cornerCurve = .continuous
        blurView.layer?.addSublayer(highlightLayer)
        
        // Add to container (suggestion label hidden)
        containerView.addSubview(commandTextField)
        containerView.addSubview(loadingIndicator)
        
        // Add container to blur view
        blurView.addSubview(containerView)
        
        // Set content view
        self.contentView = blurView
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        commandTextField.translatesAutoresizingMaskIntoConstraints = false
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container fills blur view with balanced padding
            containerView.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -24),
            containerView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -20),
            
            // Command text field - centered vertically
            commandTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            commandTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            commandTextField.trailingAnchor.constraint(equalTo: loadingIndicator.leadingAnchor, constant: -16),
            commandTextField.heightAnchor.constraint(equalToConstant: 48),
            
            // Loading indicator
            loadingIndicator.centerYAnchor.constraint(equalTo: commandTextField.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 24),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            // Blur view size - optimized and balanced
            blurView.widthAnchor.constraint(equalToConstant: 720),
            blurView.heightAnchor.constraint(equalToConstant: 88)
        ])
        
        // Update gradient layer frames when layout changes
        DispatchQueue.main.async {
            if let sublayers = self.blurView.layer?.sublayers {
                for layer in sublayers {
                    if let gradientLayer = layer as? CAGradientLayer {
                        gradientLayer.frame = self.blurView.bounds
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func showWindow() {
        // Cancel any pending hide operations
        hideTimer?.invalidate()
        hideTimer = nil
        
        // Center on current screen (in case it changed)
        centerOnScreen()
        
        // Make sure the app is active
        NSApp.activate(ignoringOtherApps: true)
        
        // Beautiful spring animation from below
        let startFrame = NSRect(
            x: self.frame.origin.x,
            y: self.frame.origin.y - 30,
            width: self.frame.size.width,
            height: self.frame.size.height
        )
        let endFrame = NSRect(
            x: self.frame.origin.x,
            y: self.frame.origin.y,
            width: self.frame.size.width,
            height: self.frame.size.height
        )
        
        self.setFrame(startFrame, display: false)
        self.alphaValue = 0.0
        
        // Make window key and order front
        makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
            context.allowsImplicitAnimation = true
            
            self.animator().alphaValue = 1.0
            self.animator().setFrame(endFrame, display: true)
        }) {
            // Focus the text field after animation
            self.focusTextField()
        }
        
        // Also try to focus immediately
        DispatchQueue.main.async {
            self.focusTextField()
        }
    }
    
    func hideWindow() {
        // Cancel any show operations
        showTimer?.invalidate()
        showTimer = nil
        
        // Beautiful fade out animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.animator().alphaValue = 0.0
            self.animator().setFrame(NSRect(
                x: self.frame.origin.x,
                y: self.frame.origin.y - 10,
                width: self.frame.size.width,
                height: self.frame.size.height
            ), display: true)
        }) {
            self.orderOut(nil)
            self.clearInput()
        }
    }
    
    func showLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimation(nil)
        commandTextField.isEnabled = false
    }
    
    func hideLoading() {
        loadingIndicator.stopAnimation(nil)
        loadingIndicator.isHidden = true
        commandTextField.isEnabled = true
    }
    
    func showError(_ message: String) {
        // Show error in console instead of UI
        print("❌ Error: \(message)")
    }
    
    func showSuccess(_ message: String) {
        // Show success in console instead of UI
        print("✅ Success: \(message)")
    }
    
    private func clearInput() {
        commandTextField.stringValue = ""
        resetSuggestionText()
    }
    
    // MARK: - New Methods
    func toggleWindow() {
        if self.isVisible && self.alphaValue > 0 {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    private func setupGlobalClickMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Only dismiss if window is visible
            if self.isVisible && self.alphaValue > 0 {
                // Get the global click location
                let globalClickLocation = NSEvent.mouseLocation
                let windowFrame = self.frame
                
                // Check if click is outside our window
                if !windowFrame.contains(globalClickLocation) {
                    DispatchQueue.main.async {
                        self.hideWindow()
                    }
                }
            }
        }
    }
    
    private func resetSuggestionText() {
        // No suggestion text needed anymore
        suggestionLabel.stringValue = ""
        suggestionLabel.isHidden = true
    }
    
    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2 + 100 // Slightly above center
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func focusTextField() {
        // Multiple attempts to ensure focus
        self.makeKey()
        
        // Clear any existing text and focus
        commandTextField.stringValue = ""
        
        // Make the text field first responder
        if self.makeFirstResponder(commandTextField) {
            commandTextField.selectText(nil)
        }
        
        // Additional focus attempts
        DispatchQueue.main.async {
            self.commandTextField.window?.makeFirstResponder(self.commandTextField)
            self.commandTextField.selectText(nil)
        }
        
        // Final attempt after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.firstResponder != self.commandTextField {
                self.makeFirstResponder(self.commandTextField)
                self.commandTextField.selectText(nil)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldAction(_ sender: NSTextField) {
        let command = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        
        processCommand(command)
    }
    
    private func processCommand(_ command: String) {
        // Send command to main app coordinator
        NotificationCenter.default.post(
            name: NSNotification.Name("WindowAI.CommandEntered"),
            object: nil,
            userInfo: ["command": command]
        )
        
        // Hide window after command execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideWindow()
        }
    }
    
    deinit {
        // Clean up global click monitor
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        // Clean up timers
        showTimer?.invalidate()
        hideTimer?.invalidate()
    }
}

// MARK: - NSTextFieldDelegate
extension CommandWindow: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        let text = textField.stringValue
        if text.isEmpty {
            resetSuggestionText()
        } else {
            updateSuggestions(for: text)
        }
    }
    
    private func updateSuggestions(for text: String) {
        // No suggestions displayed - keep clean minimal UI
    }
}

// MARK: - Key Handling
extension CommandWindow {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            hideWindow()
            return
        }
        super.keyDown(with: event)
    }
    
    // Ensure escape key is handled even when text field has focus
    override func cancelOperation(_ sender: Any?) {
        hideWindow()
    }
}
