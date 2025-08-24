import Foundation
import CoreGraphics

// MARK: - User Layout Preferences
class UserLayoutPreferences {
    static let shared = UserLayoutPreferences()
    
    private var preferences: [String: AppLayoutPreference] = [:]
    private let preferencesKey = "WindowAI.UserLayoutPreferences"
    
    struct AppLayoutPreference: Codable {
        let appName: String
        let preferredPosition: String?
        let preferredSize: String?
        let preferredRole: String? // primary, auxiliary, peripheral
        let notes: String?
        let lastUpdated: Date
        
        init(appName: String, position: String? = nil, size: String? = nil, role: String? = nil, notes: String? = nil) {
            self.appName = appName
            self.preferredPosition = position
            self.preferredSize = size
            self.preferredRole = role
            self.notes = notes
            self.lastUpdated = Date()
        }
    }
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Public API
    func setPreference(for appName: String, position: String? = nil, size: String? = nil, role: String? = nil, notes: String? = nil) {
        let preference = AppLayoutPreference(
            appName: appName,
            position: position,
            size: size,
            role: role,
            notes: notes
        )
        preferences[appName.lowercased()] = preference
        savePreferences()
    }
    
    func getPreference(for appName: String) -> AppLayoutPreference? {
        return preferences[appName.lowercased()]
    }
    
    func removePreference(for appName: String) {
        preferences.removeValue(forKey: appName.lowercased())
        savePreferences()
    }
    
    func getAllPreferences() -> [AppLayoutPreference] {
        return Array(preferences.values)
    }
    
    // MARK: - Persistence
    private func savePreferences() {
        do {
            let data = try JSONEncoder().encode(preferences)
            UserDefaults.standard.set(data, forKey: preferencesKey)
        } catch {
            print("Failed to save layout preferences: \(error)")
        }
    }
    
    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey) else { return }
        
        do {
            preferences = try JSONDecoder().decode([String: AppLayoutPreference].self, from: data)
        } catch {
            print("Failed to load layout preferences: \(error)")
        }
    }
    
    // MARK: - Preference String Generation
    func generatePreferenceString() -> String {
        guard !preferences.isEmpty else { return "" }
        
        var prefString = "\n\nUSER-SPECIFIC PREFERENCES (Override defaults):\n"
        
        for (_, pref) in preferences {
            prefString += "- \(pref.appName):"
            if let pos = pref.preferredPosition {
                prefString += " position=\(pos)"
            }
            if let size = pref.preferredSize {
                prefString += " size=\(size)"
            }
            if let role = pref.preferredRole {
                prefString += " role=\(role)"
            }
            if let notes = pref.notes {
                prefString += " (\(notes))"
            }
            prefString += "\n"
        }
        
        return prefString
    }
}

// MARK: - Integration with LLM (Updated for LLMService)
// Note: ClaudeLLMService removed - this functionality should be moved to LLMService if needed