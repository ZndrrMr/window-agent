import Foundation
import CoreGraphics
import Cocoa

// MARK: - Layout Application Service
class LayoutService {
    
    private let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    // MARK: - Main Layout Application Method
    
    /// Apply a layout to a list of applications
    /// - Parameters:
    ///   - layout: The layout to apply
    ///   - appNames: List of app names to position
    ///   - focusApp: Optional app to focus after positioning
    /// - Returns: Success status and any error messages
    func applyLayout(_ layoutName: String, to appNames: [String], focusApp: String? = nil) -> (success: Bool, message: String) {
        
        print("🎯 Applying layout '\(layoutName)' to apps: \(appNames.joined(separator: ", "))")
        
        // Parse layout name
        guard let layout = WindowLayout(rawValue: layoutName) else {
            return (false, "Unknown layout: \(layoutName)")
        }
        
        // Validate app count matches layout
        let config = layout.configuration
        if appNames.count > config.positions.count {
            return (false, "Layout '\(layoutName)' supports max \(config.positions.count) apps, got \(appNames.count)")
        }
        
        // Get screen size for positioning calculations
        guard let screen = NSScreen.main else {
            return (false, "Could not get main screen information")
        }
        let screenSize = screen.visibleFrame.size
        
        var successCount = 0
        var errors: [String] = []
        
        // Position each app according to layout
        for (index, appName) in appNames.enumerated() {
            guard let position = config.position(for: index) else {
                errors.append("No position available for \(appName) at index \(index)")
                continue
            }
            
            // Find windows for this app
            let windows = windowManager.getWindowsForApp(named: appName)
            if windows.isEmpty {
                errors.append("No windows found for \(appName)")
                continue
            }
            
            // Use the first window for the app
            let window = windows[0]
            
            // Calculate actual bounds
            let targetBounds = position.toCGRect(screenSize: screenSize)
            
            // Apply positioning
            let success = windowManager.setWindowBounds(window, bounds: targetBounds)
            if success {
                successCount += 1
                print("  ✅ Positioned \(appName) at \(targetBounds)")
            } else {
                errors.append("Failed to position \(appName)")
            }
        }
        
        // Focus the specified app if requested
        if let focusApp = focusApp, appNames.contains(focusApp) {
            let windows = windowManager.getWindowsForApp(named: focusApp)
            if let window = windows.first {
                windowManager.focusWindow(window)
                print("  🎯 Focused \(focusApp)")
            }
        }
        
        let message = "Applied layout to \(successCount)/\(appNames.count) apps" + 
                     (errors.isEmpty ? "" : ". Errors: \(errors.joined(separator: ", "))")
        
        return (success: successCount > 0, message: message)
    }
    
    // MARK: - Layout Recommendation
    
    /// Recommend a layout based on the apps and context
    func recommendLayout(for appNames: [String], context: String = "general") -> String {
        let recommendedLayout = LayoutRecommender.recommendLayout(appCount: appNames.count, context: context)
        print("💡 Recommended layout for \(appNames.count) apps (\(context)): \(recommendedLayout.rawValue)")
        return recommendedLayout.rawValue
    }
    
    /// Get all available layouts with descriptions
    func getAvailableLayouts() -> [(name: String, description: String, maxApps: Int)] {
        return WindowLayout.allCases.map { layout in
            (
                name: layout.rawValue,
                description: layout.description,
                maxApps: layout.configuration.positions.count
            )
        }
    }
    
    // MARK: - Debugging and Development
    
    /// Print all available layouts for development/debugging
    func printAvailableLayouts() {
        print("\n🎨 AVAILABLE WINDOW LAYOUTS:")
        print(String(repeating: "=", count: 50))
        
        for layout in WindowLayout.allCases {
            let config = layout.configuration
            print("\n📐 \(layout.rawValue.uppercased())")
            print("   Description: \(layout.description)")
            print("   Max Apps: \(config.positions.count)")
            print("   Contexts: \(layout.contextCategories.joined(separator: ", "))")
            
            // Show positions
            for (i, pos) in config.positions.enumerated() {
                let x = Int(pos.x * 100)
                let y = Int(pos.y * 100) 
                let w = Int(pos.width * 100)
                let h = Int(pos.height * 100)
                print("     App \(i+1): x=\(x)%, y=\(y)%, w=\(w)%, h=\(h)%")
            }
        }
        print("\n" + String(repeating: "=", count: 50))
    }
}

// MARK: - String Extension for Formatting (removed to avoid duplicate)
// Note: This extension already exists in ConstraintValidationTest.swift

// MARK: - Layout Testing and Validation
extension LayoutService {
    
    /// Test a layout with mock data (for development)
    func testLayout(_ layoutName: String, mockApps: [String]) {
        print("\n🧪 TESTING LAYOUT: \(layoutName)")
        print("Mock apps: \(mockApps.joined(separator: ", "))")
        
        guard let layout = WindowLayout(rawValue: layoutName) else {
            print("❌ Invalid layout name")
            return
        }
        
        let config = layout.configuration
        print("Layout supports \(config.positions.count) positions")
        
        for (i, app) in mockApps.enumerated() {
            if let pos = config.position(for: i) {
                print("  \(app) would be at: x=\(Int(pos.x*100))%, y=\(Int(pos.y*100))%, w=\(Int(pos.width*100))%, h=\(Int(pos.height*100))%")
            } else {
                print("  \(app) has no position (exceeds layout capacity)")
            }
        }
    }
    
    /// Validate all layouts for consistency
    func validateAllLayouts() -> Bool {
        print("\n✅ VALIDATING ALL LAYOUTS:")
        var allValid = true
        
        for layout in WindowLayout.allCases {
            let config = layout.configuration
            var layoutValid = true
            
            // Check that positions don't exceed screen bounds
            for (i, pos) in config.positions.enumerated() {
                if pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 ||
                   pos.width <= 0 || pos.width > 1 || pos.height <= 0 || pos.height > 1 ||
                   (pos.x + pos.width) > 1.01 || (pos.y + pos.height) > 1.01 { // Allow small rounding
                    print("❌ \(layout.rawValue) position \(i) invalid: \(pos)")
                    layoutValid = false
                }
            }
            
            if layoutValid {
                print("✅ \(layout.rawValue) - valid")
            } else {
                allValid = false
            }
        }
        
        return allValid
    }
}

// TODO: USER CUSTOMIZATION SECTION
// 
// This is where you can easily add your 10-15 custom layout presets:
//
// 1. Add new cases to WindowLayout enum in WindowLayouts.swift
// 2. Implement their configurations in the WindowLayout extension
// 3. LayoutService will automatically pick them up
//
// Example:
// case my_custom_layout = "my_custom_layout"
//
// Then in WindowLayout extension:
// case .my_custom_layout:
//     return LayoutConfiguration(layout: self, positions: [
//         LayoutPosition(x: 0.0, y: 0.0, width: 0.6, height: 1.0),
//         LayoutPosition(x: 0.6, y: 0.0, width: 0.4, height: 0.5),
//         // ... more positions
//     ])