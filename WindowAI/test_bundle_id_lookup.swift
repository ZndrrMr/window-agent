import Cocoa

// Test the exact getBundleID logic from WindowAI
func getBundleID(for appName: String) -> String? {
    return NSWorkspace.shared.runningApplications.first {
        $0.localizedName?.lowercased() == appName.lowercased()
    }?.bundleIdentifier
}

// Test with Music app
let testNames = ["Music", "music", "Apple Music", "iTunes"]

for name in testNames {
    let bundleID = getBundleID(for: name)
    print("App name: '\(name)' -> Bundle ID: \(bundleID ?? "NOT FOUND")")
}

// Show all running applications for debugging
print("\nAll running applications:")
for app in NSWorkspace.shared.runningApplications {
    if let name = app.localizedName {
        print("  \(name) -> \(app.bundleIdentifier ?? "no bundle ID")")
    }
}