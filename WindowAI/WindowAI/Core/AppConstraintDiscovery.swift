import Foundation
import Cocoa

// MARK: - App Constraint Discovery System

/// Discovers and caches app-specific window size constraints
class AppConstraintDiscovery {
    static let shared = AppConstraintDiscovery()
    
    private init() {}
    
    // MARK: - Constraint Storage
    
    /// Cache of discovered constraints, keyed by app name
    private var constraintCache: [String: DiscoveredConstraints] = [:]
    
    /// Time when each constraint was discovered (for cache invalidation)
    private var discoveryTime: [String: Date] = [:]
    
    /// Cache expiry time (24 hours)
    private let cacheExpiryInterval: TimeInterval = 24 * 60 * 60
    
    // MARK: - Public API
    
    /// Get constraints for an app, discovering them if not cached
    func getConstraints(for appName: String, windowManager: WindowManager) -> DiscoveredConstraints? {
        let key = appName.lowercased()
        
        // Check if we have valid cached constraints
        if let cached = constraintCache[key],
           let discoveryDate = discoveryTime[key],
           Date().timeIntervalSince(discoveryDate) < cacheExpiryInterval {
            print("📋 Using cached constraints for \(appName): \(cached)")
            return cached
        }
        
        // Discover constraints dynamically
        print("🔍 Discovering constraints for \(appName)...")
        return discoverConstraints(for: appName, windowManager: windowManager)
    }
    
    /// Check if a layout is feasible given app constraints
    func validateLayoutFeasibility(
        _ layout: Layout, 
        for windows: [WindowInfo], 
        windowManager: WindowManager,
        screenResolution: CGSize
    ) -> LayoutFeasibilityResult {
        var violations: [AppConstraintViolation] = []
        var feasibleApps: [String] = []
        
        print("\n🔬 VALIDATING LAYOUT FEASIBILITY")
        print("📐 Layout: \(layout.name) on \(Int(screenResolution.width))x\(Int(screenResolution.height))")
        
        // Check each position slot against available windows
        for (index, position) in layout.positions.enumerated() {
            guard index < windows.count else { break }
            
            let window = windows[index]
            let appName = window.appName
            
            // Calculate target size in pixels
            let targetWidth = position.width * screenResolution.width
            let targetHeight = position.height * screenResolution.height
            let targetSize = CGSize(width: targetWidth, height: targetHeight)
            
            print("  📱 Slot \(index + 1) (\(position.role)): \(appName)")
            print("     Target: \(Int(targetWidth))x\(Int(targetHeight))")
            
            // Get constraints for this app
            guard let constraints = getConstraints(for: appName, windowManager: windowManager) else {
                print("     ⚠️  No constraints available - assuming feasible")
                feasibleApps.append(appName)
                continue
            }
            
            // Check if target size violates constraints
            let widthOK = targetWidth >= constraints.minSize.width
            let heightOK = targetHeight >= constraints.minSize.height
            
            if widthOK && heightOK {
                print("     ✅ Feasible (min: \(Int(constraints.minSize.width))x\(Int(constraints.minSize.height)))")
                feasibleApps.append(appName)
            } else {
                let violation = AppConstraintViolation(
                    appName: appName,
                    role: position.role,
                    targetSize: targetSize,
                    minSize: constraints.minSize,
                    violationType: !widthOK && !heightOK ? .both : (!widthOK ? .width : .height)
                )
                violations.append(violation)
                
                let violationText = violation.violationType == .both ? "width & height" : 
                                  violation.violationType == .width ? "width" : "height"
                print("     ❌ VIOLATION (\(violationText)): needs \(Int(constraints.minSize.width))x\(Int(constraints.minSize.height))")
            }
        }
        
        let isFeasible = violations.isEmpty
        print("🎯 FEASIBILITY RESULT: \(isFeasible ? "✅ FEASIBLE" : "❌ INFEASIBLE") - \(violations.count) violations")
        
        return LayoutFeasibilityResult(
            isFeasible: isFeasible,
            violations: violations,
            feasibleApps: feasibleApps
        )
    }
    
    // MARK: - Constraint Discovery
    
    /// Dynamically discover constraints for an app by testing resize limits
    private func discoverConstraints(for appName: String, windowManager: WindowManager) -> DiscoveredConstraints? {
        guard let window = windowManager.getAllWindows().first(where: { 
            $0.appName.lowercased() == appName.lowercased() 
        }) else {
            print("❌ Cannot discover constraints: \(appName) window not found")
            return nil
        }
        
        print("🧪 Testing constraint limits for \(appName)...")
        
        // Store original bounds for restoration
        let originalBounds = window.bounds
        print("   📍 Original: \(Int(originalBounds.width))x\(Int(originalBounds.height))")
        
        // Test minimum width
        let minWidth = discoverMinimumWidth(window: window, windowManager: windowManager, originalBounds: originalBounds)
        
        // Test minimum height  
        let minHeight = discoverMinimumHeight(window: window, windowManager: windowManager, originalBounds: originalBounds)
        
        // Restore original bounds
        _ = windowManager.setWindowBounds(window, bounds: originalBounds, validate: false)
        
        let constraints = DiscoveredConstraints(
            appName: appName,
            minSize: CGSize(width: minWidth, height: minHeight),
            lastUpdated: Date()
        )
        
        // Cache the results
        let key = appName.lowercased()
        constraintCache[key] = constraints
        discoveryTime[key] = Date()
        
        print("   ✅ Discovered constraints: \(Int(minWidth))x\(Int(minHeight))")
        return constraints
    }
    
    private func discoverMinimumWidth(window: WindowInfo, windowManager: WindowManager, originalBounds: CGRect) -> CGFloat {
        let testHeight = originalBounds.height
        var minWidth = originalBounds.width
        
        // Binary search for minimum width
        var low: CGFloat = 100  // Start with 100px minimum
        var high: CGFloat = originalBounds.width
        
        for _ in 0..<8 { // Limit iterations for performance
            let testWidth = (low + high) / 2
            let testBounds = CGRect(x: originalBounds.origin.x, y: originalBounds.origin.y, 
                                   width: testWidth, height: testHeight)
            
            // Try to resize
            _ = windowManager.setWindowBounds(window, bounds: testBounds, validate: false)
            
            // Small delay for system to process
            usleep(50000) // 50ms
            
            // Check actual resulting size
            let updatedWindows = windowManager.getAllWindows()
            guard let updatedWindow = updatedWindows.first(where: { $0.appName == window.appName }) else {
                break
            }
            
            let actualWidth = updatedWindow.bounds.width
            
            if abs(actualWidth - testWidth) < 10 { // Successfully resized to target
                high = testWidth
                minWidth = actualWidth
            } else { // Resize was constrained
                low = testWidth
            }
        }
        
        return minWidth
    }
    
    private func discoverMinimumHeight(window: WindowInfo, windowManager: WindowManager, originalBounds: CGRect) -> CGFloat {
        let testWidth = originalBounds.width
        var minHeight = originalBounds.height
        
        // Binary search for minimum height
        var low: CGFloat = 100  // Start with 100px minimum
        var high: CGFloat = originalBounds.height
        
        for _ in 0..<8 { // Limit iterations for performance
            let testHeight = (low + high) / 2
            let testBounds = CGRect(x: originalBounds.origin.x, y: originalBounds.origin.y, 
                                   width: testWidth, height: testHeight)
            
            // Try to resize
            _ = windowManager.setWindowBounds(window, bounds: testBounds, validate: false)
            
            // Small delay for system to process
            usleep(50000) // 50ms
            
            // Check actual resulting size
            let updatedWindows = windowManager.getAllWindows()
            guard let updatedWindow = updatedWindows.first(where: { $0.appName == window.appName }) else {
                break
            }
            
            let actualHeight = updatedWindow.bounds.height
            
            if abs(actualHeight - testHeight) < 10 { // Successfully resized to target
                high = testHeight
                minHeight = actualHeight
            } else { // Resize was constrained
                low = testHeight
            }
        }
        
        return minHeight
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached constraints
    func clearCache() {
        constraintCache.removeAll()
        discoveryTime.removeAll()
        print("🗑️ Cleared constraint cache")
    }
    
    /// Get cache statistics for debugging
    func getCacheStats() -> (count: Int, oldestAge: TimeInterval?) {
        let count = constraintCache.count
        let oldestAge = discoveryTime.values.map { Date().timeIntervalSince($0) }.max()
        return (count, oldestAge)
    }
}

// MARK: - Data Structures

struct DiscoveredConstraints {
    let appName: String
    let minSize: CGSize
    let lastUpdated: Date
    
    var description: String {
        return "min=\(Int(minSize.width))x\(Int(minSize.height))"
    }
}

struct AppConstraintViolation {
    let appName: String
    let role: String
    let targetSize: CGSize
    let minSize: CGSize
    let violationType: ViolationType
    
    enum ViolationType {
        case width, height, both
    }
    
    var description: String {
        let target = "\(Int(targetSize.width))x\(Int(targetSize.height))"
        let minimum = "\(Int(minSize.width))x\(Int(minSize.height))"
        return "\(appName) (\(role)): target \(target) < min \(minimum)"
    }
}

struct LayoutFeasibilityResult {
    let isFeasible: Bool
    let violations: [AppConstraintViolation]
    let feasibleApps: [String]
    
    var summary: String {
        if isFeasible {
            return "✅ Layout feasible for all \(feasibleApps.count) apps"
        } else {
            return "❌ Layout infeasible: \(violations.count) constraint violations"
        }
    }
}