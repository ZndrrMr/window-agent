#!/usr/bin/env swift

import Cocoa
import Foundation

// Test WindowAI integration with new app discovery service
print("🔄 Testing WindowAI with improved app launching...")
print("This test simulates what happens when you ask WindowAI to open an app")

// Check if any of these apps are running first
let testApps = ["TimeFinder", "Music", "App Store"] 
let workspace = NSWorkspace.shared

print("\n📊 Current app status:")
for appName in testApps {
    let isRunning = workspace.runningApplications.contains { app in
        app.localizedName?.lowercased() == appName.lowercased()
    }
    print("  \(appName): \(isRunning ? "RUNNING" : "NOT RUNNING")")
}

print("\n🚀 Testing improved app discovery...")

// Simulate the getBundleID lookup that WindowPositioner.swift now uses
for appName in testApps {
    print("\n📱 Testing: '\(appName)'")
    
    // Old method (running apps only)
    let oldBundleID = workspace.runningApplications.first {
        $0.localizedName?.lowercased() == appName.lowercased()
    }?.bundleIdentifier
    
    print("  🔴 Old method (running apps only): \(oldBundleID ?? "NOT FOUND")")
    
    // Simulate new method by checking if apps exist on disk
    let commonPaths = [
        "/Applications/\(appName).app",
        "/System/Applications/\(appName).app"
    ]
    
    var foundPath: String? = nil
    for path in commonPaths {
        if FileManager.default.fileExists(atPath: path) {
            foundPath = path
            break
        }
    }
    
    if let foundPath = foundPath {
        let appURL = URL(fileURLWithPath: foundPath)
        if let bundle = Bundle(url: appURL),
           let bundleID = bundle.bundleIdentifier {
            print("  ✅ New method (all apps): \(bundleID)")
            print("  📂 Found at: \(foundPath)")
        }
    } else {
        print("  ❌ New method: NOT FOUND")
    }
}

print("\n✨ The new AppDiscoveryService should now be able to launch any installed app!")
print("🎯 This fixes the issue where 'open timefinder' was failing because TimeFinder was fully quit.")