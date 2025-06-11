import Cocoa

class AutocompleteWindow: NSWindow {
    private let dropdown: AutocompleteDropdown
    
    init() {
        dropdown = AutocompleteDropdown()
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 220),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = false
        self.canHide = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        
        // Start hidden
        self.alphaValue = 0.0
        self.orderOut(nil)
        
        // Set dropdown as content
        self.contentView = dropdown
        dropdown.frame = self.contentView?.bounds ?? NSRect.zero
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        // Forward key events to the parent command window
        if let commandWindow = NSApp.windows.first(where: { $0 is CommandWindow }) as? CommandWindow {
            commandWindow.keyDown(with: event)
        } else {
            super.keyDown(with: event)
        }
    }
    
    func positionBelow(_ parentWindow: NSWindow) {
        let parentFrame = parentWindow.frame
        let newOrigin = NSPoint(
            x: parentFrame.origin.x,
            y: parentFrame.origin.y - self.frame.height - 8
        )
        self.setFrameOrigin(newOrigin)
    }
    
    func showWithSuggestions(_ suggestions: [AppSuggestion], below parentWindow: NSWindow) {
        dropdown.updateSuggestions(suggestions)
        
        // Resize window to match dropdown content
        let dropdownHeight = dropdown.frame.height
        let newSize = NSSize(width: 720, height: dropdownHeight)
        self.setContentSize(newSize)
        dropdown.frame = NSRect(x: 0, y: 0, width: 720, height: dropdownHeight)
        
        positionBelow(parentWindow)
        
        self.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        })
    }
    
    func hideDropdown() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }) {
            self.orderOut(nil)
            self.dropdown.hide()
        }
    }
    
    // Delegate access
    var dropdownDelegate: AutocompleteDropdownDelegate? {
        get { dropdown.delegate }
        set { dropdown.delegate = newValue }
    }
    
    func selectNext() {
        dropdown.selectNext()
    }
    
    func selectPrevious() {
        dropdown.selectPrevious()
    }
    
    func getSelectedSuggestion() -> AppSuggestion? {
        return dropdown.getSelectedSuggestion()
    }
}