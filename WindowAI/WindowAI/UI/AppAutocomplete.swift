import Cocoa
import Foundation

// MARK: - App Suggestion Data
struct AppSuggestion {
    let name: String
    let bundleID: String
    let icon: NSImage?
    let path: String
    let score: Double // Relevance score for ranking
}

// MARK: - App Discovery and Autocomplete
class AppAutocomplete {
    static let shared = AppAutocomplete()
    
    private var installedApps: [AppSuggestion] = []
    private var isLoaded = false
    
    private init() {
        loadInstalledApps()
    }
    
    // MARK: - App Discovery
    private func loadInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps: [AppSuggestion] = []
            
            // Get apps from /Applications
            apps.append(contentsOf: self.getAppsFromDirectory("/Applications"))
            
            // Get apps from /System/Applications
            apps.append(contentsOf: self.getAppsFromDirectory("/System/Applications"))
            
            // Get apps from ~/Applications
            let homeApps = self.getAppsFromDirectory(NSHomeDirectory() + "/Applications")
            apps.append(contentsOf: homeApps)
            
            // Get running applications (in case some are not in standard directories)
            apps.append(contentsOf: self.getRunningApps())
            
            // Remove duplicates and sort
            let uniqueApps = self.removeDuplicates(apps)
            
            DispatchQueue.main.async {
                self.installedApps = uniqueApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
                self.isLoaded = true
                // Loaded applications for autocomplete
            }
        }
    }
    
    private func getAppsFromDirectory(_ directory: String) -> [AppSuggestion] {
        var apps: [AppSuggestion] = []
        
        guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: directory),
                                                            includingPropertiesForKeys: [.isApplicationKey],
                                                            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) else {
            return apps
        }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "app" else { continue }
            
            if let app = createAppSuggestion(from: fileURL) {
                apps.append(app)
            }
        }
        
        return apps
    }
    
    private func getRunningApps() -> [AppSuggestion] {
        var apps: [AppSuggestion] = []
        
        for runningApp in NSWorkspace.shared.runningApplications {
            guard let bundleID = runningApp.bundleIdentifier,
                  let bundleURL = runningApp.bundleURL,
                  let name = runningApp.localizedName else { continue }
            
            let icon = runningApp.icon
            let app = AppSuggestion(
                name: name,
                bundleID: bundleID,
                icon: icon,
                path: bundleURL.path,
                score: 1.0
            )
            apps.append(app)
        }
        
        return apps
    }
    
    private func createAppSuggestion(from url: URL) -> AppSuggestion? {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return nil }
        
        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                   bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                   url.deletingPathExtension().lastPathComponent
        
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        return AppSuggestion(
            name: name,
            bundleID: bundleID,
            icon: icon,
            path: url.path,
            score: 1.0
        )
    }
    
    private func removeDuplicates(_ apps: [AppSuggestion]) -> [AppSuggestion] {
        var seen = Set<String>()
        var uniqueApps: [AppSuggestion] = []
        
        for app in apps {
            if !seen.contains(app.bundleID) {
                seen.insert(app.bundleID)
                uniqueApps.append(app)
            }
        }
        
        return uniqueApps
    }
    
    // MARK: - Public API
    func getSuggestions(for query: String, maxResults: Int = 5) -> [AppSuggestion] {
        guard !query.isEmpty, isLoaded else { return [] }
        
        let queryLower = query.lowercased()
        var scoredApps: [(app: AppSuggestion, score: Double)] = []
        
        for app in installedApps {
            let nameLower = app.name.lowercased()
            var score: Double = 0
            
            // Exact match gets highest score
            if nameLower == queryLower {
                score = 100
            }
            // Starts with query gets high score
            else if nameLower.hasPrefix(queryLower) {
                score = 90
            }
            // Contains query gets medium score
            else if nameLower.contains(queryLower) {
                score = 70
            }
            // Fuzzy match (all characters of query appear in order)
            else if fuzzyMatch(query: queryLower, target: nameLower) {
                score = 50
            }
            
            if score > 0 {
                // Boost score for shorter names (more likely to be what user wants)
                let lengthBonus = max(0, 20 - Double(app.name.count))
                scoredApps.append((app: app, score: score + lengthBonus))
            }
        }
        
        // Sort by score descending, then by name
        scoredApps.sort { first, second in
            if first.score != second.score {
                return first.score > second.score
            }
            return first.app.name < second.app.name
        }
        
        return Array(scoredApps.prefix(maxResults).map { $0.app })
    }
    
    private func fuzzyMatch(query: String, target: String) -> Bool {
        var queryIndex = query.startIndex
        
        for char in target {
            if queryIndex < query.endIndex && char == query[queryIndex] {
                queryIndex = query.index(after: queryIndex)
            }
        }
        
        return queryIndex == query.endIndex
    }
    
    func getTopSuggestion(for query: String) -> AppSuggestion? {
        return getSuggestions(for: query, maxResults: 1).first
    }
    
    func reloadApps() {
        isLoaded = false
        loadInstalledApps()
    }
}