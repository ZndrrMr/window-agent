import Cocoa
import SwiftUI

class CommandWindow: NSWindow {
    private let preferences = UserPreferences.shared
    private var commandTextField: NSTextField!
    private var suggestionLabel: NSTextField!
    private var loadingIndicator: NSProgressIndicator!
    private var containerView: NSView!
    
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
        self.hasShadow = true
        self.canHide = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Center on screen
        centerOnScreen()
    }
    
    private func setupUI() {
        // Main container with rounded corners and background
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        containerView.layer?.cornerRadius = preferences.commandWindowCornerRadius
        
        // Command text field
        commandTextField = NSTextField()
        commandTextField.isBordered = false
        commandTextField.isEditable = true
        commandTextField.isSelectable = true
        commandTextField.drawsBackground = false
        commandTextField.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        commandTextField.placeholderString = "Tell WindowAI what to do..."
        commandTextField.target = self
        commandTextField.action = #selector(textFieldAction(_:))
        
        // Suggestion label
        suggestionLabel = NSTextField()
        suggestionLabel.isBordered = false
        suggestionLabel.isEditable = false
        suggestionLabel.drawsBackground = false
        suggestionLabel.font = NSFont.systemFont(ofSize: 12)
        suggestionLabel.textColor = NSColor.secondaryLabelColor
        suggestionLabel.stringValue = "Try: 'make safari bigger' or 'arrange for coding'"
        
        // Loading indicator
        loadingIndicator = NSProgressIndicator()
        loadingIndicator.style = .spinning
        loadingIndicator.controlSize = .small
        loadingIndicator.isHidden = true
        
        // Add to container
        containerView.addSubview(commandTextField)
        containerView.addSubview(suggestionLabel)
        containerView.addSubview(loadingIndicator)
        
        // Set content view
        self.contentView = containerView
    }
    
    private func setupConstraints() {
        commandTextField.translatesAutoresizingMaskIntoConstraints = false
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Command text field
            commandTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            commandTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            commandTextField.trailingAnchor.constraint(equalTo: loadingIndicator.leadingAnchor, constant: -10),
            commandTextField.heightAnchor.constraint(equalToConstant: 30),
            
            // Loading indicator
            loadingIndicator.centerYAnchor.constraint(equalTo: commandTextField.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 20),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            // Suggestion label
            suggestionLabel.topAnchor.constraint(equalTo: commandTextField.bottomAnchor, constant: 8),
            suggestionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            suggestionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            suggestionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
            
            // Container size
            containerView.widthAnchor.constraint(equalToConstant: 500),
            containerView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    // MARK: - Public Methods
    func showWindow() {
        // Make sure the app is active
        NSApp.activate(ignoringOtherApps: true)
        
        // Make window key and order front
        makeKeyAndOrderFront(nil)
        self.makeKey()
        
        // Animate in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        }) {
            // Focus the text field after animation completes
            DispatchQueue.main.async {
                self.commandTextField.window?.makeFirstResponder(self.commandTextField)
                self.commandTextField.selectText(nil)
            }
        }
    }
    
    func hideWindow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 0.0
        }) {
            self.orderOut(nil)
        }
        
        clearInput()
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
        suggestionLabel.stringValue = "Error: \(message)"
        suggestionLabel.textColor = NSColor.systemRed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.resetSuggestionText()
        }
    }
    
    func showSuccess(_ message: String) {
        suggestionLabel.stringValue = message
        suggestionLabel.textColor = NSColor.systemGreen
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.resetSuggestionText()
        }
    }
    
    private func clearInput() {
        commandTextField.stringValue = ""
        resetSuggestionText()
    }
    
    private func resetSuggestionText() {
        suggestionLabel.stringValue = "Try: 'make safari bigger' or 'arrange for coding'"
        suggestionLabel.textColor = NSColor.secondaryLabelColor
    }
    
    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // MARK: - Actions
    @objc private func textFieldAction(_ sender: NSTextField) {
        let command = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        
        processCommand(command)
    }
    
    private func processCommand(_ command: String) {
        // TODO: Send command to main app coordinator
        NotificationCenter.default.post(
            name: NSNotification.Name("WindowAI.CommandEntered"),
            object: nil,
            userInfo: ["command": command]
        )
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
        // TODO: Show contextual suggestions based on current input
        if text.lowercased().contains("arrange") {
            suggestionLabel.stringValue = "Try: 'arrange for coding', 'arrange for writing', 'arrange for research'"
        } else if text.lowercased().contains("make") {
            suggestionLabel.stringValue = "Try: 'make bigger', 'make smaller', 'make half screen'"
        } else if text.lowercased().contains("open") {
            suggestionLabel.stringValue = "Try: 'open safari', 'open terminal', 'open messages'"
        }
    }
}

// MARK: - Key Handling
extension CommandWindow {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            hideWindow()
        } else {
            super.keyDown(with: event)
        }
    }
}