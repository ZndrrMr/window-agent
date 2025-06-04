import Cocoa
import SwiftUI

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Hotkey Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable global hotkey", isOn: $preferences.hotkeyEnabled)
                
                Text("Current hotkey: ⌘ + Space")
                    .foregroundColor(.secondary)
                
                Button("Change Hotkey") {
                    // TODO: Show hotkey recorder
                }
                .disabled(true) // TODO: Implement hotkey recording
                
                Text("Note: You can change the hotkey combination to avoid conflicts with other applications.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
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