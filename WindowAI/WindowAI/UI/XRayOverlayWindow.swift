import Cocoa
import QuartzCore

// MARK: - X-Ray Overlay Window
class XRayOverlayWindow: NSWindow {
    
    private var windowOutlines: [NSView] = []
    private var numberLabels: [NSTextField] = []
    private var backgroundView: NSView!
    private let displayIndex: Int
    private let targetScreen: NSScreen
    
    init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool, screen: NSScreen, displayIndex: Int) {
        self.displayIndex = displayIndex
        self.targetScreen = screen
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        
        setupWindow()
        setupBackgroundView()
    }
    
    // Legacy init for backwards compatibility
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        self.displayIndex = 0
        self.targetScreen = NSScreen.main ?? NSScreen.screens.first!
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        
        setupWindow()
        setupBackgroundView()
    }
    
    private func setupWindow() {
        // Make window transparent and overlay everything
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Cover the specific target screen
        self.setFrame(targetScreen.frame, display: true)
        
        print("🖥️ X-Ray overlay window created for display \(displayIndex): \(targetScreen.frame)")
    }
    
    // Prevent overlay window from becoming key window to avoid focus stealing
    override var canBecomeKey: Bool {
        return false
    }
    
    // Prevent overlay window from becoming main window
    override var canBecomeMain: Bool {
        return false
    }
    
    private func setupBackgroundView() {
        backgroundView = XRayBackgroundView(frame: self.contentView!.bounds)
        self.contentView = backgroundView
    }
    
    func showWithWindows(_ windows: [WindowInfo]) {
        // Filter windows for this display only
        let displayWindows = filterWindowsForDisplay(windows)
        
        // Clear existing outlines
        clearOutlines()
        
        // Use target screen frame for coordinate conversion
        let screenFrame = targetScreen.frame
        
        // Create outlines for each window on this display
        var outlineViews: [WindowOutlineView] = []
        outlineViews.reserveCapacity(displayWindows.count)
        
        for (index, windowInfo) in displayWindows.enumerated() {
            let outlineView = WindowOutlineView(windowInfo: windowInfo, index: index + 1)
            
            // Convert from Accessibility coordinates (top-left origin) to Cocoa coordinates (bottom-left origin)
            // Adjust for this display's coordinate system
            
            // Step 1: Convert global coordinates to display-local coordinates
            let localX = windowInfo.bounds.origin.x - screenFrame.origin.x
            let localY = windowInfo.bounds.origin.y - screenFrame.origin.y
            
            // DEBUG: Log coordinate conversion details
            print("🔍 X-Ray Coordinate Debug - \(windowInfo.appName)")
            print("   Window bounds: \(windowInfo.bounds)")
            print("   Display frame: \(screenFrame)")
            print("   Local coords: (\(localX), \(localY))")
            
            // Step 2: Convert from Accessibility coordinates (top-left origin) to Cocoa coordinates (bottom-left origin)
            let convertedX = localX
            // All displays use the same coordinate conversion formula
            let convertedY = screenFrame.height - localY - windowInfo.bounds.height
            print("   Using standard coordinate conversion formula (all displays)")
            
            print("   Converted: (\(convertedX), \(convertedY))")
            print("   Position from bottom: \((screenFrame.height - convertedY) / screenFrame.height * 100)%")
            
            // Step 3: Handle edge cases where coordinates might be outside screen bounds
            let clampedX = max(0, min(convertedX, screenFrame.width - windowInfo.bounds.width))
            let clampedY = max(0, min(convertedY, screenFrame.height - windowInfo.bounds.height))
            
            let convertedBounds = CGRect(
                x: clampedX,
                y: clampedY,
                width: windowInfo.bounds.width,
                height: windowInfo.bounds.height
            )
            
            // Position the outline view using converted coordinates
            outlineView.frame = convertedBounds
            outlineViews.append(outlineView)
        }
        
        windowOutlines = outlineViews
        
        // Add subviews in batch
        for outlineView in windowOutlines {
            backgroundView.addSubview(outlineView)
        }
        
        // Show window INSTANTLY (no animation for performance)
        self.alphaValue = 1.0
        self.orderFront(nil)
        
        print("🖥️ Display \(displayIndex): Showing \(displayWindows.count) windows")
    }
    
    // OPTIMIZED VERSION - Truly instant performance
    func showWithWindowsOptimized(_ windows: [WindowInfo]) {
        // Filter windows for this display only
        let displayWindows = filterWindowsForDisplay(windows)
        
        // Clear existing outlines instantly
        clearOutlines()
        
        // Use target screen frame for coordinate conversion
        let screenFrame = targetScreen.frame
        
        // Create optimized outlines for each window on this display
        var outlineViews: [OptimizedWindowOutlineView] = []
        outlineViews.reserveCapacity(displayWindows.count)
        
        // Batch coordinate conversion
        var convertedFrames: [CGRect] = []
        convertedFrames.reserveCapacity(displayWindows.count)
        
        for windowInfo in displayWindows {
            // Step 1: Convert global coordinates to display-local coordinates
            let localX = windowInfo.bounds.origin.x - screenFrame.origin.x
            let localY = windowInfo.bounds.origin.y - screenFrame.origin.y
            
            // Step 2: Convert from Accessibility coordinates (top-left origin) to Cocoa coordinates (bottom-left origin)
            let convertedX = localX
            // All displays use the same coordinate conversion formula
            let convertedY = screenFrame.height - localY - windowInfo.bounds.height
            
            // Step 3: Handle edge cases where coordinates might be outside screen bounds
            let clampedX = max(0, min(convertedX, screenFrame.width - windowInfo.bounds.width))
            let clampedY = max(0, min(convertedY, screenFrame.height - windowInfo.bounds.height))
            
            let convertedBounds = CGRect(
                x: clampedX,
                y: clampedY,
                width: windowInfo.bounds.width,
                height: windowInfo.bounds.height
            )
            convertedFrames.append(convertedBounds)
        }
        
        // Create views with pre-calculated frames
        for (index, windowInfo) in displayWindows.enumerated() {
            let outlineView = OptimizedWindowOutlineView(windowInfo: windowInfo, index: index + 1)
            outlineView.frame = convertedFrames[index]
            outlineViews.append(outlineView)
        }
        
        windowOutlines = outlineViews
        
        // Add subviews in batch with CATransaction for instant rendering
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for outlineView in windowOutlines {
            backgroundView.addSubview(outlineView)
        }
        CATransaction.commit()
        
        // Show window INSTANTLY (no animation for performance)
        self.alphaValue = 1.0
        self.orderFront(nil)
    }
    
    func hideOverlay() {
        // Hide window INSTANTLY (no animation for performance)
        self.orderOut(nil)
        self.clearOutlines()
    }
    
    private func clearOutlines() {
        windowOutlines.forEach { $0.removeFromSuperview() }
        windowOutlines.removeAll()
        numberLabels.forEach { $0.removeFromSuperview() }
        numberLabels.removeAll()
    }
    
    // Enable optimized mode - call this to use the faster version
    func enableOptimizedMode() {
        // Replace the standard showWithWindows method with the optimized version
        
        // Switch to optimized background view
        let optimizedBackground = OptimizedXRayBackgroundView(frame: self.contentView!.bounds)
        self.contentView = optimizedBackground
        self.backgroundView = optimizedBackground
    }
    
    // Method to use optimized version directly
    func showWithWindowsFast(_ windows: [WindowInfo]) {
        showWithWindowsOptimized(windows)
    }
    
    // Handle number key selection
    override func keyDown(with event: NSEvent) {
        guard let chars = event.charactersIgnoringModifiers,
              let firstChar = chars.first,
              firstChar.isNumber else {
            super.keyDown(with: event)
            return
        }
        
        let number = Int(String(firstChar)) ?? 0
        if number >= 1 && number <= windowOutlines.count {
            selectWindow(at: number - 1)
        }
    }
    
    private func selectWindow(at index: Int) {
        guard index < windowOutlines.count else { return }
        
        let selectedOutline = windowOutlines[index]
        
        // Get window info based on the view type
        var windowInfo: WindowInfo?
        var appName: String = "Unknown"
        
        if let windowOutline = selectedOutline as? WindowOutlineView {
            windowInfo = windowOutline.windowInfo
            appName = windowOutline.windowInfo.appName
            windowOutline.highlightSelection()
        } else if let optimizedOutline = selectedOutline as? OptimizedWindowOutlineView {
            windowInfo = optimizedOutline.windowInfo
            appName = optimizedOutline.windowInfo.appName
            optimizedOutline.highlightSelection()
        }
        
        
        // Focus the window after a brief delay
        if let windowInfo = windowInfo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                _ = WindowManager.shared.focusWindow(windowInfo)
                self.hideOverlay()
            }
        }
    }
    
    // MARK: - Multi-Display Support
    
    /// Filter windows to only show those on this display
    private func filterWindowsForDisplay(_ windows: [WindowInfo]) -> [WindowInfo] {
        let screenFrame = targetScreen.frame
        
        return windows.filter { window in
            let windowCenter = CGPoint(
                x: window.bounds.midX,
                y: window.bounds.midY
            )
            
            // Check if window center is within this display's bounds
            return screenFrame.contains(windowCenter)
        }
    }
}

// MARK: - X-Ray Background View
class XRayBackgroundView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupGlassEffect()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGlassEffect() {
        // Create subtle glass background
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        
        // Add blur effect
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(10.0, forKey: kCIInputRadiusKey)
        self.layer?.backgroundFilters = [blurFilter].compactMap { $0 }
        
        // Add subtle noise/grain for glass texture
        self.layer?.compositingFilter = CIFilter(name: "CIColorMatrix")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw subtle grid pattern for x-ray effect
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.05).cgColor)
        context.setLineWidth(1.0)
        
        let gridSize: CGFloat = 50.0
        
        // Vertical lines
        var x: CGFloat = 0
        while x <= bounds.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
            x += gridSize
        }
        
        // Horizontal lines
        var y: CGFloat = 0
        while y <= bounds.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
            y += gridSize
        }
        
        context.strokePath()
    }
}

// MARK: - Optimized Background View
// Lightweight version without expensive blur and drawing operations
class OptimizedXRayBackgroundView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupOptimizedBackground()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOptimizedBackground() {
        // OPTIMIZED: Simple background without expensive filters
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        
        // REMOVED: Expensive blur filters and compositing filters
        // REMOVED: Custom drawing operations
    }
    
    // OPTIMIZED: No custom drawing - just use simple background color
}

// MARK: - Optimized Window Outline View
// Lightweight version with minimal graphics operations for instant performance
class OptimizedWindowOutlineView: NSView {
    
    let windowInfo: WindowInfo
    let index: Int
    private var numberLabel: NSTextField!
    private var titleLabel: NSTextField!
    
    init(windowInfo: WindowInfo, index: Int) {
        self.windowInfo = windowInfo
        self.index = index
        super.init(frame: windowInfo.bounds)
        
        setupOptimizedOutlineView()
        setupOptimizedLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOptimizedOutlineView() {
        // OPTIMIZED: Use simpler layer configuration
        self.wantsLayer = true
        
        // Simple border without expensive effects
        self.layer?.borderWidth = 2.0
        self.layer?.borderColor = NSColor.systemBlue.cgColor
        self.layer?.cornerRadius = 4.0
        
        // REMOVED: Expensive shadow, glow, and blur effects
        // Semi-transparent fill - much lighter
        self.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.05).cgColor
    }
    
    private func setupOptimizedLabels() {
        // OPTIMIZED: Simplified number label
        numberLabel = NSTextField(labelWithString: "\(index)")
        numberLabel.font = NSFont.boldSystemFont(ofSize: 18)
        numberLabel.textColor = NSColor.white
        numberLabel.backgroundColor = NSColor.systemBlue
        numberLabel.alignment = .center
        numberLabel.frame = CGRect(x: 8, y: bounds.height - 28, width: 20, height: 20)
        addSubview(numberLabel)
        
        // OPTIMIZED: Simplified title label
        titleLabel = NSTextField(labelWithString: windowInfo.appName)
        titleLabel.font = NSFont.systemFont(ofSize: 14)
        titleLabel.textColor = NSColor.white
        titleLabel.backgroundColor = NSColor.black.withAlphaComponent(0.4)
        titleLabel.alignment = .center
        
        let titleSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (bounds.width - titleSize.width - 16) / 2,
            y: (bounds.height - titleSize.height - 8) / 2,
            width: titleSize.width + 16,
            height: titleSize.height + 8
        )
        addSubview(titleLabel)
    }
    
    func highlightSelection() {
        // OPTIMIZED: Instant highlight without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.layer?.borderColor = NSColor.systemYellow.cgColor
        CATransaction.commit()
        
        // Reset after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.borderColor = NSColor.systemBlue.cgColor
            CATransaction.commit()
        }
    }
    
    // OPTIMIZED: Removed expensive custom drawing - use simple border only
}

// MARK: - Window Outline View
class WindowOutlineView: NSView {
    
    let windowInfo: WindowInfo
    let index: Int
    private var numberLabel: NSTextField!
    private var titleLabel: NSTextField!
    
    init(windowInfo: WindowInfo, index: Int) {
        self.windowInfo = windowInfo
        self.index = index
        super.init(frame: windowInfo.bounds)
        
        setupOutlineView()
        setupLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOutlineView() {
        self.wantsLayer = true
        
        // Create glowing border
        self.layer?.borderWidth = 3.0
        self.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        self.layer?.cornerRadius = 8.0
        
        // Add glow effect
        self.layer?.shadowColor = NSColor.systemBlue.cgColor
        self.layer?.shadowOpacity = 0.6
        self.layer?.shadowRadius = 10.0
        self.layer?.shadowOffset = CGSize.zero
        
        // Semi-transparent fill
        self.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
    }
    
    private func setupLabels() {
        // Number label (top-left corner)
        numberLabel = NSTextField(labelWithString: "\(index)")
        numberLabel.font = NSFont.boldSystemFont(ofSize: 24)
        numberLabel.textColor = NSColor.white
        numberLabel.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8)
        numberLabel.layer?.cornerRadius = 15
        numberLabel.alignment = .center
        numberLabel.frame = CGRect(x: 10, y: bounds.height - 40, width: 30, height: 30)
        addSubview(numberLabel)
        
        // Title label (center)
        titleLabel = NSTextField(labelWithString: windowInfo.appName)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = NSColor.white
        titleLabel.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        titleLabel.layer?.cornerRadius = 4
        titleLabel.alignment = .center
        
        let titleSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (bounds.width - titleSize.width - 20) / 2,
            y: (bounds.height - titleSize.height) / 2,
            width: titleSize.width + 20,
            height: titleSize.height + 10
        )
        addSubview(titleLabel)
    }
    
    func highlightSelection() {
        // Brief highlight animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            self.layer?.borderColor = NSColor.systemYellow.cgColor
            self.layer?.shadowColor = NSColor.systemYellow.cgColor
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                self.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
                self.layer?.shadowColor = NSColor.systemBlue.cgColor
            })
        })
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw additional x-ray details
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw corner markers
        let cornerSize: CGFloat = 20.0
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(2.0)
        
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: bounds.width, y: 0),
            CGPoint(x: 0, y: bounds.height),
            CGPoint(x: bounds.width, y: bounds.height)
        ]
        
        for corner in corners {
            let rect = CGRect(
                x: corner.x == 0 ? 5 : corner.x - cornerSize - 5,
                y: corner.y == 0 ? 5 : corner.y - cornerSize - 5,
                width: cornerSize,
                height: cornerSize
            )
            context.stroke(rect)
        }
    }
}