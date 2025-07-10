 import Cocoa
import Carbon

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
    func xrayOverlayRequested()
    func rearrangeWindowsRequested()
}

class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var globalEventMonitor: Any?
    fileprivate static var sharedInstance: HotkeyManager?
    
    // Double-tap Command key detection
    private var commandKeyTapTimes: [Date] = []
    private let doubleTapThreshold: TimeInterval = 0.5
    private let commandKeyCode: UInt16 = 55 // Left Command key
    
    // Debouncing to prevent rapid triggers
    private var lastDoubleTapTime: Date = Date.distantPast
    private let doubleTapCooldown: TimeInterval = 0.2 // 200ms cooldown
    
    // Hotkey refs for multiple hotkeys
    private var xrayHotKeyRef: EventHotKeyRef?
    
    // Unique ID for our hotkeys
    fileprivate let hotKeyID = EventHotKeyID(signature: OSType("WNDW".utf8.reduce(0) { $0 << 8 + OSType($1) }), 
                                         id: 1)
    fileprivate let xrayHotKeyID = EventHotKeyID(signature: OSType("XRAY".utf8.reduce(0) { $0 << 8 + OSType($1) }), 
                                             id: 2)
    
    init() {
        HotkeyManager.sharedInstance = self
        setupHotkeyHandler()
        _ = registerRearrangeHotkey()  // Command+Shift+X for "rearrange my windows"
    }
    
    deinit {
        unregisterHotkey()
        unregisterXRayHotkey()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func registerHotkey(keyCode: UInt32, modifiers: UInt32) -> Bool {
        // First unregister any existing hotkey
        unregisterHotkey()
        
        // Convert modifier flags from Cocoa to Carbon format
        var carbonModifiers: UInt32 = 0
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 {
            carbonModifiers |= UInt32(controlKey)
        }
        
        // Register the hotkey
        let status = RegisterEventHotKey(keyCode, 
                                       carbonModifiers, 
                                       hotKeyID, 
                                       GetApplicationEventTarget(), 
                                       0, 
                                       &hotKeyRef)
        
        if status == noErr {
            print("✅ Hotkey registered: ⌘+⇧+Space")
            return true
        } else {
            print("❌ HotkeyManager: Failed to register hotkey. Error: \(status)")
            return false
        }
    }
    
    func unregisterHotkey() {
        guard let hotKey = hotKeyRef else { return }
        
        let status = UnregisterEventHotKey(hotKey)
        if status != noErr {
            print("❌ HotkeyManager: Failed to unregister hotkey. Error: \(status)")
        }
        hotKeyRef = nil
    }
    
    func registerRearrangeHotkey() -> Bool {
        // Register Command+Shift+X for "rearrange my windows"
        let keyCode: UInt32 = 7 // X key
        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        
        let status = RegisterEventHotKey(keyCode,
                                       modifiers,
                                       xrayHotKeyID,
                                       GetApplicationEventTarget(),
                                       0,
                                       &xrayHotKeyRef)
        
        if status == noErr {
            print("✅ Rearrange hotkey registered: ⌘+⇧+X")
            return true
        } else {
            print("❌ HotkeyManager: Failed to register rearrange hotkey. Error: \(status)")
            return false
        }
    }
    
    func registerXRayHotkey() -> Bool {
        // Register Command+Shift+X for X-Ray overlay
        let keyCode: UInt32 = 7 // X key
        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        
        let status = RegisterEventHotKey(keyCode,
                                       modifiers,
                                       xrayHotKeyID,
                                       GetApplicationEventTarget(),
                                       0,
                                       &xrayHotKeyRef)
        
        if status == noErr {
            print("✅ X-Ray hotkey registered: ⌘+⇧+X")
            return true
        } else {
            print("❌ HotkeyManager: Failed to register X-Ray hotkey. Error: \(status)")
            return false
        }
    }
    
    func unregisterXRayHotkey() {
        guard let hotKey = xrayHotKeyRef else { return }
        
        let status = UnregisterEventHotKey(hotKey)
        if status != noErr {
            print("❌ HotkeyManager: Failed to unregister X-Ray hotkey. Error: \(status)")
        }
        xrayHotKeyRef = nil
    }
    
    private func setupHotkeyHandler() {
        // Define the event spec for hotkey events
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), 
                                      eventKind: UInt32(kEventHotKeyPressed))
        
        // Install the event handler
        let status = InstallEventHandler(GetApplicationEventTarget(),
                                       hotKeyEventHandler,
                                       1,
                                       &eventSpec,
                                       nil,
                                       &eventHandler)
        
        if status != noErr {
            print("❌ HotkeyManager: Failed to install event handler. Error: \(status)")
        }
    }
    
    fileprivate func handleHotkeyEvent() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.hotkeyPressed()
        }
    }
    
    fileprivate func handleXRayHotkeyEvent() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.rearrangeWindowsRequested()
        }
    }
    
    // MARK: - Command Key Monitoring
    
    private func setupCommandKeyMonitoring() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
        
        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
            return event
        }
    }
    
    private func handleGlobalKeyEvent(_ event: NSEvent) {
        // Check if this is a Command key event
        guard event.keyCode == commandKeyCode else { return }
        
        if event.type == .keyUp {
            // Command key released - record tap time
            handleCommandKeyTap()
        }
    }
    
    private func handleCommandKeyTap() {
        let now = Date()
        
        // Check cooldown period to prevent rapid triggers
        let timeSinceLastDoubleTap = now.timeIntervalSince(lastDoubleTapTime)
        if timeSinceLastDoubleTap < doubleTapCooldown {
            print("🔍 Command key tap ignored - within cooldown period (\(String(format: "%.2f", timeSinceLastDoubleTap))s)")
            return
        }
        
        // Clean up old tap times (older than threshold)
        commandKeyTapTimes = commandKeyTapTimes.filter { 
            now.timeIntervalSince($0) <= doubleTapThreshold 
        }
        
        // Add current tap
        commandKeyTapTimes.append(now)
        
        print("🔍 Command key tap detected. Recent taps: \(commandKeyTapTimes.count)")
        
        // Check for double tap
        if commandKeyTapTimes.count >= 2 {
            let timeBetweenTaps = commandKeyTapTimes.last!.timeIntervalSince(commandKeyTapTimes[commandKeyTapTimes.count - 2])
            
            if timeBetweenTaps <= doubleTapThreshold {
                print("🔍 Double-tap Command key detected! Activating X-Ray overlay")
                lastDoubleTapTime = now // Record successful double-tap time
                handleDoubleTapCommand()
                commandKeyTapTimes.removeAll() // Reset after successful double-tap
            }
        }
    }
    
    private func handleDoubleTapCommand() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.xrayOverlayRequested()
        }
    }
}

// MARK: - Carbon Event Handler
private func hotKeyEventHandler(eventHandlerCall: EventHandlerCallRef?,
                              event: EventRef?,
                              userData: UnsafeMutableRawPointer?) -> OSStatus {
    
    guard let event = event else { return OSStatus(eventNotHandledErr) }
    
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(event,
                                 EventParamName(kEventParamDirectObject),
                                 EventParamType(typeEventHotKeyID),
                                 nil,
                                 MemoryLayout<EventHotKeyID>.size,
                                 nil,
                                 &hotKeyID)
    
    if status == noErr {
        // Check which hotkey was pressed
        if let manager = HotkeyManager.sharedInstance {
            if hotKeyID.signature == manager.hotKeyID.signature && hotKeyID.id == manager.hotKeyID.id {
                // Main hotkey (Command+Shift+Space)
                manager.handleHotkeyEvent()
            } else if hotKeyID.signature == manager.xrayHotKeyID.signature && hotKeyID.id == manager.xrayHotKeyID.id {
                // X-Ray hotkey (Command+Shift+X)
                manager.handleXRayHotkeyEvent()
            }
        }
        return noErr
    }
    
    return OSStatus(eventNotHandledErr)
}

// MARK: - Hotkey Constants
extension HotkeyManager {
    struct DefaultHotkey {
        static let keyCode: UInt32 = 49 // Space key
        static let modifiers: UInt32 = UInt32(cmdKey)
    }
}
