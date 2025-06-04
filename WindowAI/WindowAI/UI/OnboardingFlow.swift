import Cocoa
import SwiftUI

class OnboardingWindow: NSWindow {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), 
                   styleMask: [.titled, .closable], 
                   backing: backingStoreType, 
                   defer: flag)
        
        setupWindow()
        setupUI()
    }
    
    private func setupWindow() {
        self.title = "Welcome to WindowAI"
        self.isReleasedWhenClosed = false
        self.center()
        self.isMovableByWindowBackground = true
        
        // Non-resizable
        self.styleMask.remove(.resizable)
    }
    
    private func setupUI() {
        let onboardingView = OnboardingFlow()
        let hostingView = NSHostingView(rootView: onboardingView)
        
        self.contentView = hostingView
    }
}

// MARK: - SwiftUI Onboarding Flow
struct OnboardingFlow: View {
    @State private var currentStep = 0
    @State private var isComplete = false
    
    let totalSteps = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal, 40)
                .padding(.top, 20)
            
            // Content area
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)
                
                PermissionsStep()
                    .tag(1)
                
                APISetupStep()
                    .tag(2)
                
                TryItOutStep()
                    .tag(3)
            }
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
    
    private func completeOnboarding() {
        UserPreferences.shared.showOnboarding = false
        UserPreferences.shared.savePreferences()
        
        // Close onboarding window
        NotificationCenter.default.post(
            name: NSNotification.Name("WindowAI.OnboardingComplete"),
            object: nil
        )
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to WindowAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("The AI-powered window management tool for macOS")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "keyboard", title: "Natural Language Commands", description: "Tell your computer what to do in plain English")
                FeatureRow(icon: "square.3.layers.3d", title: "Smart Arrangements", description: "Context-aware window layouts for coding, writing, and more")
                FeatureRow(icon: "bolt.fill", title: "Lightning Fast", description: "Instant response with global hotkey access")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Permissions Step
struct PermissionsStep: View {
    @State private var accessibilityGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 16) {
                Text("Grant Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("WindowAI needs accessibility permissions to manage your windows")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                PermissionCard(
                    icon: "accessibility",
                    title: "Accessibility Access",
                    description: "Required to move and resize windows",
                    isGranted: $accessibilityGranted,
                    action: openAccessibilitySettings
                )
            }
            .padding(.horizontal, 40)
            
            if !accessibilityGranted {
                VStack(spacing: 12) {
                    Text("How to grant permissions:")
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Click 'Open System Settings' below")
                        Text("2. Find WindowAI in the list")
                        Text("3. Toggle the switch to enable access")
                        Text("4. Come back to this window")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            checkAccessibilityPermissions()
        }
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start polling for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            checkAccessibilityPermissions()
            if accessibilityGranted {
                timer.invalidate()
            }
        }
    }
    
    private func checkAccessibilityPermissions() {
        // TODO: Actually check accessibility permissions
        // For now, simulate the check
        accessibilityGranted = false
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Grant Access") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - API Setup Step
struct APISetupStep: View {
    @StateObject private var preferences = UserPreferences.shared
    @State private var selectedProvider: LLMProvider = .openAI
    @State private var tempAPIKey: String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("AI Configuration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose your AI provider and enter your API key")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    SecureField("\(selectedProvider.displayName) API Key", text: $tempAPIKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 40)
                    
                    Button("Get API Key") {
                        openAPIKeyPage()
                    }
                    .foregroundColor(.blue)
                }
                
                Text("Your API key is stored securely on your device and never shared.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .onChange(of: selectedProvider) { provider in
            preferences.llmProvider = provider
        }
        .onChange(of: tempAPIKey) { key in
            switch selectedProvider {
            case .openAI:
                preferences.openAIAPIKey = key
            case .anthropic:
                preferences.anthropicAPIKey = key
            case .local:
                break
            }
        }
    }
    
    private func openAPIKeyPage() {
        let url: URL
        switch selectedProvider {
        case .openAI:
            url = URL(string: "https://platform.openai.com/api-keys")!
        case .anthropic:
            url = URL(string: "https://console.anthropic.com/")!
        case .local:
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Try It Out Step
struct TryItOutStep: View {
    @State private var showingDemo = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's try your first command")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Press ⌘ + Space to open the command window")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Then try saying:")
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ExampleCommand(text: "\"make safari bigger\"")
                        ExampleCommand(text: "\"open messages and put it in the corner\"")
                        ExampleCommand(text: "\"arrange for coding\"")
                    }
                }
                
                Button("Try It Now") {
                    showDemo()
                }
                .buttonStyle(.borderedProminent)
                .font(.title3)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private func showDemo() {
        // TODO: Trigger demo command window
        NotificationCenter.default.post(
            name: NSNotification.Name("WindowAI.ShowDemo"),
            object: nil
        )
    }
}

struct ExampleCommand: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
    }
}