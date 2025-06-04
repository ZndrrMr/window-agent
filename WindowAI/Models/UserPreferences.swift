import Foundation
import CoreGraphics

// MARK: - User Preferences
class UserPreferences: ObservableObject, Codable {
    
    // MARK: - Hotkey Settings
    @Published var hotkeyEnabled: Bool = true
    @Published var hotkeyKeyCode: UInt32 = 49 // Space
    @Published var hotkeyModifiers: UInt32 = 1048576 // Cmd
    
    // MARK: - LLM Settings
    @Published var llmProvider: LLMProvider = .openAI
    @Published var openAIAPIKey: String = ""
    @Published var anthropicAPIKey: String = ""
    @Published var model: String = "gpt-4"
    @Published var maxTokens: Int = 500
    @Published var temperature: Double = 0.3
    
    // MARK: - UI Settings
    @Published var showOnboarding: Bool = true
    @Published var commandWindowOpacity: Double = 0.95
    @Published var commandWindowCornerRadius: Double = 12.0
    @Published var showCommandSuggestions: Bool = true
    @Published var autoHideDelay: Double = 3.0
    
    // MARK: - Window Management Settings
    @Published var defaultWindowGap: Double = 10.0
    @Published var respectDockSize: Bool = true
    @Published var respectMenuBar: Bool = true
    @Published var animateWindowMovement: Bool = true
    @Published var animationDuration: Double = 0.3
    
    // MARK: - Context Arrangements
    @Published var codingApps: [String] = ["Xcode", "Visual Studio Code", "Terminal", "Safari"]
    @Published var writingApps: [String] = ["Pages", "Microsoft Word", "TextEdit", "Safari"]
    @Published var researchApps: [String] = ["Safari", "Chrome", "Notes", "Preview"]
    @Published var communicationApps: [String] = ["Messages", "Mail", "Slack", "Discord"]
    @Published var designApps: [String] = ["Figma", "Sketch", "Adobe Photoshop", "Safari"]
    
    // MARK: - Analytics & Privacy
    @Published var enableAnalytics: Bool = true
    @Published var enableCrashReporting: Bool = true
    @Published var shareUsageData: Bool = false
    
    // MARK: - Subscription
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var subscriptionExpiryDate: Date?
    @Published var lastSubscriptionCheck: Date?
    
    // MARK: - Advanced Settings
    @Published var debugMode: Bool = false
    @Published var verboseLogging: Bool = false
    @Published var useLocalFallback: Bool = false
    
    // MARK: - Coding Keys for Persistence
    enum CodingKeys: String, CodingKey {
        case hotkeyEnabled, hotkeyKeyCode, hotkeyModifiers
        case llmProvider, openAIAPIKey, anthropicAPIKey, model, maxTokens, temperature
        case showOnboarding, commandWindowOpacity, commandWindowCornerRadius
        case showCommandSuggestions, autoHideDelay
        case defaultWindowGap, respectDockSize, respectMenuBar
        case animateWindowMovement, animationDuration
        case codingApps, writingApps, researchApps, communicationApps, designApps
        case enableAnalytics, enableCrashReporting, shareUsageData
        case subscriptionStatus, subscriptionExpiryDate, lastSubscriptionCheck
        case debugMode, verboseLogging, useLocalFallback
    }
    
    // MARK: - Singleton
    static let shared = UserPreferences()
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Persistence
    func savePreferences() {
        // TODO: Save preferences to UserDefaults or file
    }
    
    func loadPreferences() {
        // TODO: Load preferences from UserDefaults or file
    }
    
    func resetToDefaults() {
        // TODO: Reset all preferences to default values
    }
    
    // MARK: - Validation
    func validateAPIKeys() -> Bool {
        // TODO: Validate that at least one API key is set and valid
        return false
    }
    
    func isSubscriptionValid() -> Bool {
        // TODO: Check if subscription is valid and not expired
        return false
    }
}

// MARK: - Supporting Enums
enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case local = "local"
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .local: return "Local Model"
        }
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case enterprise = "enterprise"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .enterprise: return "Enterprise"
        case .expired: return "Expired"
        }
    }
    
    var monthlyLimit: Int {
        switch self {
        case .free: return 50
        case .pro: return -1 // Unlimited
        case .enterprise: return -1 // Unlimited
        case .expired: return 0
        }
    }
}