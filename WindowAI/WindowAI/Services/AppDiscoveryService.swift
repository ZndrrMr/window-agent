import Foundation
import Cocoa

// MARK: - Centralized App Discovery Service
class AppDiscoveryService {
    static let shared = AppDiscoveryService()
    
    // Cache bundle IDs for performance
    private var bundleCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "app-discovery-cache", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Public API
    func getBundleID(for appName: String) -> String? {
        let normalizedName = appName.lowercased()
        
        // Check cache first
        if let cachedID = getCachedBundleID(normalizedName) {
            return cachedID
        }
        
        // 1. Try running applications first (fastest path)
        if let bundleID = searchRunningApps(for: normalizedName) {
            cacheBundleID(bundleID, for: normalizedName)
            return bundleID
        }
        
        // 2. Search all installed applications
        if let bundleID = searchInstalledApps(for: normalizedName) {
            cacheBundleID(bundleID, for: normalizedName)
            return bundleID
        }
        
        // 3. Try common app bundle ID patterns
        if let bundleID = tryCommonBundleIDPatterns(for: normalizedName) {
            cacheBundleID(bundleID, for: normalizedName)
            return bundleID
        }
        
        return nil
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.bundleCache.removeAll()
        }
    }
    
    // MARK: - Cache Management
    private func getCachedBundleID(_ appName: String) -> String? {
        return cacheQueue.sync {
            return bundleCache[appName]
        }
    }
    
    private func cacheBundleID(_ bundleID: String, for appName: String) {
        cacheQueue.async(flags: .barrier) {
            self.bundleCache[appName] = bundleID
        }
    }
    
    // MARK: - Search Methods
    private func searchRunningApps(for appName: String) -> String? {
        return NSWorkspace.shared.runningApplications.first { app in
            guard let localizedName = app.localizedName else { return false }
            return localizedName.lowercased() == appName
        }?.bundleIdentifier
    }
    
    private func searchInstalledApps(for appName: String) -> String? {
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Library/CoreServices",
            "/Applications/Utilities",
            "/System/Applications/Utilities"
        ]
        
        for basePath in searchPaths {
            if let bundleID = searchAppsInPath(basePath, for: appName) {
                return bundleID
            }
        }
        
        return nil
    }
    
    private func searchAppsInPath(_ path: String, for appName: String) -> String? {
        let fileManager = FileManager.default
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return nil
        }
        
        for item in contents {
            if item.hasSuffix(".app") {
                let appPath = "\(path)/\(item)"
                
                if let bundleID = getBundleIDFromPath(appPath, targetName: appName) {
                    return bundleID
                }
            }
        }
        
        return nil
    }
    
    private func getBundleIDFromPath(_ appPath: String, targetName: String) -> String? {
        let appURL = URL(fileURLWithPath: appPath)
        
        guard let bundle = Bundle(url: appURL),
              let bundleID = bundle.bundleIdentifier else {
            return nil
        }
        
        // Check various name sources
        let nameSources = [
            bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String,
            bundle.infoDictionary?["CFBundleDisplayName"] as? String,
            bundle.infoDictionary?["CFBundleName"] as? String,
            appURL.deletingPathExtension().lastPathComponent
        ]
        
        for nameSource in nameSources {
            if let name = nameSource, name.lowercased() == targetName {
                return bundleID
            }
        }
        
        return nil
    }
    
    private func tryCommonBundleIDPatterns(for appName: String) -> String? {
        // Common app bundle ID patterns
        let commonPatterns: [String: String] = [
            "music": "com.apple.Music",
            "safari": "com.apple.Safari",
            "chrome": "com.google.Chrome",
            "firefox": "org.mozilla.firefox",
            "terminal": "com.apple.Terminal",
            "finder": "com.apple.finder",
            "mail": "com.apple.mail",
            "calendar": "com.apple.iCal",
            "notes": "com.apple.Notes",
            "messages": "com.apple.MobileSMS",
            "facetime": "com.apple.FaceTime",
            "photos": "com.apple.Photos",
            "maps": "com.apple.Maps",
            "app store": "com.apple.AppStore",
            "appstore": "com.apple.AppStore",
            "system preferences": "com.apple.systempreferences",
            "activity monitor": "com.apple.ActivityMonitor",
            "calculator": "com.apple.Calculator",
            "textedit": "com.apple.TextEdit",
            "preview": "com.apple.Preview",
            "quicktime": "com.apple.QuickTimePlayerX",
            "xcode": "com.apple.dt.Xcode",
            "timefinder": "com.timefinder.TimeFinder",
            "claude": "com.anthropic.Claude",
            "arc": "company.thebrowser.Browser",
            "cursor": "com.todesktop.230313mzl4w4u92",
            "notion": "notion.id",
            "figma": "com.figma.Desktop",
            "slack": "com.tinyspeck.slackmacgap",
            "discord": "com.hnc.Discord",
            "spotify": "com.spotify.client",
            "zoom": "us.zoom.xos",
            "1password": "com.1password.1password",
            "dropbox": "com.getdropbox.dropbox",
            "adobe photoshop": "com.adobe.Photoshop",
            "photoshop": "com.adobe.Photoshop",
            "adobe illustrator": "com.adobe.illustrator",
            "illustrator": "com.adobe.illustrator"
        ]
        
        return commonPatterns[appName]
    }
}

// MARK: - App Launch Helper
extension AppDiscoveryService {
    func launchApp(named appName: String) -> Bool {
        // Try with bundle ID first
        if let bundleID = getBundleID(for: appName) {
            return NSWorkspace.shared.launchApplication(
                withBundleIdentifier: bundleID,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        }
        
        // Fallback to direct path launching
        return launchAppByPath(appName)
    }
    
    private func launchAppByPath(_ appName: String) -> Bool {
        let commonPaths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/Applications/\(appName)/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
            "/Applications/Utilities/\(appName).app"
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                let success = NSWorkspace.shared.open(URL(fileURLWithPath: path))
                if success {
                    return true
                }
            }
        }
        
        return false
    }
}