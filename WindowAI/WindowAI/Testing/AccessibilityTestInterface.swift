import Foundation
import Cocoa

// MARK: - Direct Accessibility Test (No LLM)
class AccessibilityTestInterface {
    
    private let windowManager: WindowManager
    private let windowPositioner: WindowPositioner
    
    init() {
        self.windowManager = WindowManager.shared
        self.windowPositioner = WindowPositioner(windowManager: windowManager)
    }
    
    // MARK: - Direct Window Management Tests
    func testMoveXcodeToLeft() {
        print("\n🧪 Testing Direct Window Management")
        print("=====================================")
        
        // Check accessibility permissions first
        if !windowManager.checkAccessibilityPermissions() {
            print("❌ No accessibility permissions - requesting...")
            windowManager.requestAccessibilityPermissions()
            return
        }
        
        print("✅ Accessibility permissions granted")
        
        // Try to find Xcode
        print("🔍 Looking for Xcode...")
        let xcodeWindows = windowManager.getWindowsForApp(named: "Xcode")
        
        if xcodeWindows.isEmpty {
            print("❌ No Xcode windows found")
            print("💡 Make sure Xcode is running")
            return
        }
        
        print("✅ Found \(xcodeWindows.count) Xcode window(s)")
        
        // Get the first Xcode window
        let xcodeWindow = xcodeWindows[0]
        print("📱 Window: \(xcodeWindow.title)")
        print("📍 Current bounds: \(xcodeWindow.bounds)")
        
        // Test 1: Create a command to move Xcode to left half
        let moveCommand = WindowCommand(
            action: .snap,
            target: "Xcode",
            position: .left,
            size: .half
        )
        
        print("🎯 Executing command: Move Xcode to left half")
        let result = windowPositioner.executeCommand(moveCommand)
        
        if result.success {
            print("✅ SUCCESS: \(result.message)")
            
            // Verify the move worked
            let updatedWindows = windowManager.getWindowsForApp(named: "Xcode")
            if let updatedWindow = updatedWindows.first {
                print("📍 New bounds: \(updatedWindow.bounds)")
            }
        } else {
            print("❌ FAILED: \(result.message)")
        }
    }
    
    func testMoveAnyAppToRight() {
        print("\n🧪 Testing Move Any Visible App to Right")
        print("=======================================")
        
        // Check accessibility permissions first
        if !windowManager.checkAccessibilityPermissions() {
            print("❌ No accessibility permissions")
            return
        }
        
        // Get all windows
        let allWindows = windowManager.getAllWindows()
        print("🔍 Found \(allWindows.count) total windows")
        
        // Find the first non-system window
        let appWindows = allWindows.filter { window in
            !["Dock", "SystemUIServer", "WindowServer", "Spotlight"].contains(window.appName) &&
            !window.title.isEmpty
        }
        
        if let firstWindow = appWindows.first {
            print("🎯 Testing with: \(firstWindow.appName) - \(firstWindow.title)")
            print("📍 Current bounds: \(firstWindow.bounds)")
            
            let moveCommand = WindowCommand(
                action: .snap,
                target: firstWindow.appName,
                position: .right,
                size: .half
            )
            
            print("▶️ Moving to right half...")
            let result = windowPositioner.executeCommand(moveCommand)
            
            if result.success {
                print("✅ SUCCESS: Window moved!")
            } else {
                print("❌ FAILED: \(result.message)")
            }
        } else {
            print("❌ No suitable windows found for testing")
        }
    }
    
    func testBasicAccessibilityAPI() {
        print("\n🧪 Testing Basic Accessibility API")
        print("==================================")
        
        // Test 1: Check if we have permissions
        let hasPermissions = windowManager.checkAccessibilityPermissions()
        print("🔐 Has accessibility permissions: \(hasPermissions ? "✅ YES" : "❌ NO")")
        
        if !hasPermissions {
            print("🚨 Requesting permissions...")
            windowManager.requestAccessibilityPermissions()
            return
        }
        
        // Test 2: Try to get running apps
        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName }
            .filter { !["Dock", "SystemUIServer", "WindowServer"].contains($0) }
        
        print("📱 Running apps (\(runningApps.count)):")
        for (index, app) in runningApps.prefix(10).enumerated() {
            print("   \(index + 1). \(app)")
        }
        
        // Test 3: Try to get all windows
        let allWindows = windowManager.getAllWindows()
        print("🪟 Visible windows (\(allWindows.count)):")
        for (index, window) in allWindows.prefix(5).enumerated() {
            print("   \(index + 1). \(window.appName): \(window.title)")
        }
        
        if allWindows.isEmpty {
            print("⚠️ No windows found - this suggests accessibility API isn't working")
        }
    }
    
    func testScreenInfo() {
        print("\n🧪 Testing Screen Information")
        print("============================")
        
        let screens = NSScreen.screens
        print("🖥️ Screens (\(screens.count)):")
        for (index, screen) in screens.enumerated() {
            let frame = screen.frame
            print("   \(index): \(Int(frame.width))x\(Int(frame.height)) at (\(Int(frame.origin.x)), \(Int(frame.origin.y)))")
        }
        
        let mainBounds = windowManager.getScreenBounds()
        print("📏 Main screen bounds: \(mainBounds)")
    }
    
    // MARK: - Run All Tests
    func runAllTests() {
        print("🚀 Starting Accessibility Tests")
        print("==============================")
        
        // Run the direct low-level test first
        DirectAccessibilityTest.runDetailedTest()
        
        // Then run our higher-level tests
        testBasicAccessibilityAPI()
        testScreenInfo()
        testMoveAnyAppToRight()
        
        print("\n✅ All tests completed!")
        print("💡 If windows didn't move, accessibility permissions may not be working")
    }
}