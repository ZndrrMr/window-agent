import Cocoa
import SwiftUI
import Foundation

class SettingsWindow: NSWindow {
    private let preferences = UserPreferences.shared
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 600, height: 500), 
                   styleMask: [.titled, .closable, .resizable], 
                   backing: backingStoreType, 
                   defer: flag)
        
        setupWindow()
        setupUI()
    }
    
    private func setupWindow() {
        self.title = "WindowAI Settings"
        self.isReleasedWhenClosed = false
        self.center()
        
        // Set minimum size
        self.minSize = NSSize(width: 550, height: 450)
    }
    
    private func setupUI() {
        // Use SwiftUI for settings interface
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        self.contentView = hostingView
    }
}

// MARK: - SwiftUI Settings View
struct SettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            HotkeySettingsView()
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
                .tag(1)
            
            LLMSettingsView()
                .tabItem {
                    Label("AI Settings", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            WindowSettingsView()
                .tabItem {
                    Label("Windows", systemImage: "macwindow")
                }
                .tag(3)
            
            SubscriptionView()
                .tabItem {
                    Label("Subscription", systemImage: "creditcard")
                }
                .tag(4)
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
                .tag(5)
        }
        .padding()
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show onboarding on next launch", isOn: $preferences.showOnboarding)
                
                Toggle("Show command suggestions", isOn: $preferences.showCommandSuggestions)
                
                HStack {
                    Text("Auto-hide delay:")
                    Slider(value: $preferences.autoHideDelay, in: 1...10, step: 0.5)
                    Text("\(preferences.autoHideDelay, specifier: "%.1f")s")
                        .frame(width: 30, alignment: .leading)
                }
                
                HStack {
                    Text("Window opacity:")
                    Slider(value: $preferences.commandWindowOpacity, in: 0.7...1.0, step: 0.05)
                    Text("\(Int(preferences.commandWindowOpacity * 100))%")
                        .frame(width: 40, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Hotkey Settings
struct HotkeySettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    @State private var isRecordingHotkey = false
    @State private var recordedKeyCode: UInt32?
    @State private var recordedModifiers: UInt32?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Hotkey Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable global hotkey", isOn: $preferences.hotkeyEnabled)
                    .onChange(of: preferences.hotkeyEnabled) { _, enabled in
                        if enabled {
                            // Re-register hotkey when enabled
                            registerCurrentHotkey()
                        } else {
                            // Unregister when disabled
                            unregisterHotkey()
                        }
                    }
                
                HStack {
                    Text("Current hotkey:")
                    Text(currentHotkeyDescription)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                .foregroundColor(.secondary)
                
                if isRecordingHotkey {
                    HStack {
                        Text("Press your desired hotkey combination...")
                            .foregroundColor(.blue)
                        Button("Cancel") {
                            isRecordingHotkey = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Button("Change Hotkey") {
                        startRecordingHotkey()
                    }
                    .disabled(!preferences.hotkeyEnabled)
                }
                
                Text("Note: Avoid using hotkeys that conflict with system shortcuts like ⌘+Space (Spotlight) or ⌘+Tab (App Switcher).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            setupHotkeyRecorder()
        }
    }
    
    private var currentHotkeyDescription: String {
        return keyDescription(keyCode: preferences.hotkeyKeyCode, 
                            modifiers: preferences.hotkeyModifiers)
    }
    
    private func keyDescription(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        
        // Add modifiers
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 {
            parts.append("⌘")
        }
        
        // Add key
        let keyName = keyCodeToString(keyCode)
        parts.append(keyName)
        
        return parts.joined(separator: " + ")
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Escape"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 115: return "Home"
        case 116: return "Page Up"
        case 117: return "Forward Delete"
        case 119: return "End"
        case 121: return "Page Down"
        case 123: return "Left Arrow"
        case 124: return "Right Arrow"
        case 125: return "Down Arrow"
        case 126: return "Up Arrow"
        default: return "Key \(keyCode)"
        }
    }
    
    private func startRecordingHotkey() {
        isRecordingHotkey = true
        // Remove current hotkey while recording
        unregisterHotkey()
    }
    
    private func setupHotkeyRecorder() {
        // Set up event monitor for recording hotkeys
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isRecordingHotkey {
                // Record the key combination
                self.recordedKeyCode = UInt32(event.keyCode)
                self.recordedModifiers = UInt32(event.modifierFlags.rawValue)
                
                // Update preferences
                self.preferences.hotkeyKeyCode = self.recordedKeyCode!
                self.preferences.hotkeyModifiers = self.recordedModifiers!
                
                // Stop recording
                self.isRecordingHotkey = false
                
                // Register the new hotkey
                self.registerCurrentHotkey()
                
                // Consume the event
                return nil
            }
            return event
        }
    }
    
    private func registerCurrentHotkey() {
        // Get the hotkey manager from the app controller
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let controller = appDelegate.windowAIController {
            controller.updateHotkey()
        }
    }
    
    private func unregisterHotkey() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let controller = appDelegate.windowAIController {
            controller.unregisterHotkey()
        }
    }
}

// MARK: - LLM Settings
struct LLMSettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    @State private var showingAPIKeyAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Picker("LLM Provider:", selection: $preferences.llmProvider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if preferences.llmProvider == .openAI {
                    SecureField("OpenAI API Key", text: $preferences.openAIAPIKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else if preferences.llmProvider == .anthropic {
                    SecureField("Anthropic API Key", text: $preferences.anthropicAPIKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Max tokens:")
                    Slider(value: Binding(
                        get: { Double(preferences.maxTokens) },
                        set: { preferences.maxTokens = Int($0) }
                    ), in: 100...1000, step: 50)
                    Text("\(preferences.maxTokens)")
                        .frame(width: 40, alignment: .leading)
                }
                
                HStack {
                    Text("Temperature:")
                    Slider(value: $preferences.temperature, in: 0...1, step: 0.1)
                    Text("\(preferences.temperature, specifier: "%.1f")")
                        .frame(width: 30, alignment: .leading)
                }
                
                Button("Test Connection") {
                    // TODO: Test API connection
                    showingAPIKeyAlert = true
                }
                .disabled(getCurrentAPIKey().isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .alert("API Test", isPresented: $showingAPIKeyAlert) {
            Button("OK") { }
        } message: {
            Text("API connection test not yet implemented")
        }
    }
    
    private func getCurrentAPIKey() -> String {
        switch preferences.llmProvider {
        case .openAI: return preferences.openAIAPIKey
        case .anthropic: return preferences.anthropicAPIKey
        case .local: return "local"
        }
    }
}

// MARK: - Window Settings
struct WindowSettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Window Management")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Default window gap:")
                    Slider(value: $preferences.defaultWindowGap, in: 0...50, step: 5)
                    Text("\(Int(preferences.defaultWindowGap))px")
                        .frame(width: 40, alignment: .leading)
                }
                
                Toggle("Respect dock size", isOn: $preferences.respectDockSize)
                Toggle("Respect menu bar", isOn: $preferences.respectMenuBar)
                Toggle("Animate window movement", isOn: $preferences.animateWindowMovement)
                
                if preferences.animateWindowMovement {
                    HStack {
                        Text("Animation duration:")
                        Slider(value: $preferences.animationDuration, in: 0.1...1.0, step: 0.1)
                        Text("\(preferences.animationDuration, specifier: "%.1f")s")
                            .frame(width: 40, alignment: .leading)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Subscription View
struct SubscriptionView: View {
    @StateObject private var preferences = UserPreferences.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Subscription")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Current Plan:")
                    Text(preferences.subscriptionStatus.displayName)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                if preferences.subscriptionStatus == .free {
                    Text("Monthly Commands: 0 / 50")
                        .foregroundColor(.secondary)
                    
                    Button("Upgrade to Pro") {
                        // TODO: Open upgrade flow
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let expiryDate = preferences.subscriptionExpiryDate {
                    Text("Expires: \(expiryDate, style: .date)")
                        .foregroundColor(.secondary)
                }
                
                Button("Manage Subscription") {
                    // TODO: Open subscription management
                }
                .disabled(preferences.subscriptionStatus == .free)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    @StateObject private var preferences = UserPreferences.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Privacy & Analytics")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable analytics", isOn: $preferences.enableAnalytics)
                Toggle("Enable crash reporting", isOn: $preferences.enableCrashReporting)
                Toggle("Share usage data", isOn: $preferences.shareUsageData)
                
                Text("Analytics help us improve the app by understanding how features are used. No personal information or window content is collected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Clear Analytics Data") {
                    // TODO: Clear stored analytics
                }
                
                Toggle("Debug mode", isOn: $preferences.debugMode)
                Toggle("Verbose logging", isOn: $preferences.verboseLogging)
            }
            
            Spacer()
        }
        .padding()
    }
}