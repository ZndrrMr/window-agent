import Cocoa
import Carbon

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
}

class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    fileprivate static var sharedInstance: HotkeyManager?
    
    // Unique ID for our hotkey
    private let hotKeyID = EventHotKeyID(signature: OSType("WNDW".utf8.reduce(0) { $0 << 8 + OSType($1) }), 
                                         id: 1)
    
    init() {
        HotkeyManager.sharedInstance = self
        setupHotkeyHandler()
    }
    
    deinit {
        unregisterHotkey()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
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
        // Call the shared instance's handler
        HotkeyManager.sharedInstance?.handleHotkeyEvent()
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