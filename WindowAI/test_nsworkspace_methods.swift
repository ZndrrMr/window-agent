import Cocoa

// Test NSWorkspace methods available for app launching
let workspace = NSWorkspace.shared

print("Available NSWorkspace methods for launching:")
print("1. launchApplication(withBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifier:)")
print("2. open(_:) - with URL")
print("3. openApplication(at:configuration:completionHandler:)")

// Test launching Music app with different methods
let musicBundleID = "com.apple.Music"
let musicURL = URL(fileURLWithPath: "/System/Applications/Music.app")

print("\n=== Testing Music app launching ===")

// Method 1: Bundle ID
print("Method 1: Bundle ID")
let result1 = workspace.launchApplication(withBundleIdentifier: musicBundleID, 
                                        options: [], 
                                        additionalEventParamDescriptor: nil, 
                                        launchIdentifier: nil)
print("Result: \(result1)")

// Method 2: URL
print("\nMethod 2: URL")
let result2 = workspace.open(musicURL)
print("Result: \(result2)")

// Method 3: openApplication (macOS 10.15+)
print("\nMethod 3: openApplication")
let config = NSWorkspace.OpenConfiguration()
workspace.openApplication(at: musicURL, configuration: config) { app, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Success: \(app?.localizedName ?? "Unknown")")
    }
}

// Also check what the running application shows for Music
let runningApps = workspace.runningApplications
if let musicApp = runningApps.first(where: { $0.bundleIdentifier == musicBundleID }) {
    print("\nRunning Music app:")
    print("  Bundle ID: \(musicApp.bundleIdentifier ?? "nil")")
    print("  Localized Name: \(musicApp.localizedName ?? "nil")")
    print("  Is Running: \(musicApp.isActive)")
} else {
    print("\nMusic app not found in running applications")
    
    // Try to find it by name
    if let musicAppByName = runningApps.first(where: { $0.localizedName?.lowercased() == "music" }) {
        print("Found app by name 'music':")
        print("  Bundle ID: \(musicAppByName.bundleIdentifier ?? "nil")")
        print("  Localized Name: \(musicAppByName.localizedName ?? "nil")")
    }
}