import XCTest
@testable import WindowAI

class LearningSystemTests: XCTestCase {
    
    var learningService: LearningService!
    
    override func setUp() {
        super.setUp()
        learningService = LearningService.shared
        // Clear any existing learning data for clean tests
        learningService.clearAllLearningData()
    }
    
    override func tearDown() {
        learningService.clearAllLearningData()
        super.tearDown()
    }
    
    // MARK: - Basic Learning Tests
    
    func testTrackWindowAdjustment() {
        let originalBounds = CGRect(x: 100, y: 100, width: 800, height: 600)
        let adjustedBounds = CGRect(x: 200, y: 100, width: 800, height: 600)
        
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: originalBounds,
            adjustedBounds: adjustedBounds,
            adjustmentType: .position,
            context: "coding"
        )
        
        print("🧪 WINDOW ADJUSTMENT TRACKING TEST:")
        print("  📱 App: Terminal")
        print("  📊 Original: \(originalBounds)")
        print("  📊 Adjusted: \(adjustedBounds)")
        print("  🔄 Type: position")
        
        // Should store the adjustment
        XCTAssertTrue(learningService.hasLearningData(for: "Terminal"), "Should have learning data for Terminal")
        
        // Should recognize this as a position preference
        let preference = learningService.getPositionPreference(for: "Terminal", context: "coding")
        XCTAssertNotNil(preference, "Should have position preference")
        XCTAssertEqual(preference?.x, 200, accuracy: 10, "Should prefer X position around 200")
    }
    
    func testMultipleAdjustmentsPattern() {
        // Simulate user consistently moving Terminal to right side
        let adjustments = [
            (original: CGRect(x: 0, y: 0, width: 600, height: 800), 
             adjusted: CGRect(x: 840, y: 0, width: 600, height: 800)),
            (original: CGRect(x: 100, y: 50, width: 600, height: 800), 
             adjusted: CGRect(x: 840, y: 50, width: 600, height: 800)),
            (original: CGRect(x: 200, y: 100, width: 600, height: 800), 
             adjusted: CGRect(x: 840, y: 100, width: 600, height: 800))
        ]
        
        print("🧪 MULTIPLE ADJUSTMENTS PATTERN TEST:")
        
        for (index, adjustment) in adjustments.enumerated() {
            learningService.trackWindowAdjustment(
                appName: "Terminal",
                originalBounds: adjustment.original,
                adjustedBounds: adjustment.adjusted,
                adjustmentType: .position,
                context: "coding"
            )
            
            print("  📊 Adjustment \(index + 1): \(adjustment.original) → \(adjustment.adjusted)")
        }
        
        // Should recognize the pattern: user prefers Terminal on right side
        let preference = learningService.getPositionPreference(for: "Terminal", context: "coding")
        XCTAssertNotNil(preference, "Should have learned position preference")
        XCTAssertGreaterThan(preference?.x ?? 0, 800, "Should prefer right side positioning")
        
        // Should have high confidence after multiple consistent adjustments
        let confidence = learningService.getPreferenceConfidence(for: "Terminal", context: "coding")
        XCTAssertGreaterThan(confidence, 0.7, "Should have high confidence after consistent adjustments")
    }
    
    func testSizePreferenceLearning() {
        // User consistently makes Terminal narrower
        let sizeAdjustments = [
            (original: CGRect(x: 0, y: 0, width: 800, height: 900), 
             adjusted: CGRect(x: 0, y: 0, width: 400, height: 900)),
            (original: CGRect(x: 100, y: 0, width: 800, height: 900), 
             adjusted: CGRect(x: 100, y: 0, width: 350, height: 900)),
            (original: CGRect(x: 200, y: 0, width: 800, height: 900), 
             adjusted: CGRect(x: 200, y: 0, width: 380, height: 900))
        ]
        
        print("🧪 SIZE PREFERENCE LEARNING TEST:")
        
        for adjustment in sizeAdjustments {
            learningService.trackWindowAdjustment(
                appName: "Terminal",
                originalBounds: adjustment.original,
                adjustedBounds: adjustment.adjusted,
                adjustmentType: .size,
                context: "coding"
            )
        }
        
        let sizePreference = learningService.getSizePreference(for: "Terminal", context: "coding")
        XCTAssertNotNil(sizePreference, "Should have learned size preference")
        XCTAssertLessThan(sizePreference?.width ?? 800, 450, "Should prefer narrower width")
        
        print("  ✅ Learned preference: \(sizePreference?.width ?? 0)x\(sizePreference?.height ?? 0)")
    }
    
    func testContextSpecificLearning() {
        // User has different preferences for Terminal in different contexts
        
        // Coding context: narrow right column
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 0, y: 0, width: 800, height: 900),
            adjustedBounds: CGRect(x: 1080, y: 0, width: 360, height: 900),
            adjustmentType: .both,
            context: "coding"
        )
        
        // General context: larger centered window
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 0, y: 0, width: 400, height: 500),
            adjustedBounds: CGRect(x: 500, y: 200, width: 600, height: 700),
            adjustmentType: .both,
            context: "general"
        )
        
        print("🧪 CONTEXT-SPECIFIC LEARNING TEST:")
        
        let codingPreference = learningService.getPositionPreference(for: "Terminal", context: "coding")
        let generalPreference = learningService.getPositionPreference(for: "Terminal", context: "general")
        
        print("  🔧 Coding preference: \(codingPreference?.x ?? 0), \(codingPreference?.y ?? 0)")
        print("  🌐 General preference: \(generalPreference?.x ?? 0), \(generalPreference?.y ?? 0)")
        
        XCTAssertNotNil(codingPreference, "Should have coding-specific preference")
        XCTAssertNotNil(generalPreference, "Should have general-specific preference")
        
        // Preferences should be different for different contexts
        XCTAssertNotEqual(codingPreference?.x, generalPreference?.x, accuracy: 100, 
                         "Should have different X preferences for different contexts")
    }
    
    // MARK: - App Relationship Learning
    
    func testAppPairLearning() {
        // Simulate user frequently using Cursor and Terminal together
        for _ in 0..<5 {
            learningService.trackAppPairUsage(app1: "Cursor", app2: "Terminal", context: "coding")
        }
        
        // Less frequent pairing with Arc
        for _ in 0..<2 {
            learningService.trackAppPairUsage(app1: "Cursor", app2: "Arc", context: "coding")
        }
        
        print("🧪 APP PAIR LEARNING TEST:")
        
        let strongPairs = learningService.getStrongAppPairs(for: "Cursor", context: "coding")
        print("  🔗 Strong pairs for Cursor: \(strongPairs.joined(separator: ", "))")
        
        XCTAssertTrue(strongPairs.contains("Terminal"), "Should recognize Cursor-Terminal as strong pair")
        
        let pairStrength = learningService.getAppPairStrength(app1: "Cursor", app2: "Terminal", context: "coding")
        XCTAssertGreaterThan(pairStrength, 0.8, "Should have high pair strength for frequently used together")
    }
    
    func testWorkspacePattern() {
        // Simulate user creating consistent coding workspace
        let codingWorkspace = ["Cursor", "Terminal", "Arc"]
        
        for _ in 0..<3 {
            learningService.trackWorkspaceUsage(apps: codingWorkspace, context: "coding")
        }
        
        print("🧪 WORKSPACE PATTERN TEST:")
        
        let suggestedWorkspace = learningService.getSuggestedWorkspace(for: "coding")
        print("  🏗️ Suggested workspace: \(suggestedWorkspace.joined(separator: ", "))")
        
        XCTAssertTrue(suggestedWorkspace.contains("Cursor"), "Should suggest Cursor for coding")
        XCTAssertTrue(suggestedWorkspace.contains("Terminal"), "Should suggest Terminal for coding")
        XCTAssertEqual(suggestedWorkspace.count, 3, "Should suggest appropriate number of apps")
    }
    
    // MARK: - Preference Application Tests
    
    func testApplyLearnedPreferences() {
        // Set up learned preferences
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 0, y: 0, width: 800, height: 900),
            adjustedBounds: CGRect(x: 1080, y: 0, width: 360, height: 900),
            adjustmentType: .both,
            context: "coding"
        )
        
        // Test applying preferences to new arrangement
        let baseArrangement = FlexibleWindowArrangement(
            window: "Terminal",
            position: .percentage(x: 0.0, y: 0.0),
            size: .percentage(width: 0.5, height: 1.0),
            layer: 1,
            visibility: .full
        )
        
        let adjustedArrangement = learningService.applyLearnedPreferences(
            to: baseArrangement,
            context: "coding",
            screenSize: CGSize(width: 1440, height: 900)
        )
        
        print("🧪 PREFERENCE APPLICATION TEST:")
        print("  📊 Base: \(baseArrangement.position), \(baseArrangement.size)")
        print("  📊 Adjusted: \(adjustedArrangement.position), \(adjustedArrangement.size)")
        
        // Should adjust position based on learned preferences
        let adjustedX = adjustedArrangement.position.x.toPixels(for: 1440)
        XCTAssertGreaterThan(adjustedX, 1000, "Should apply learned right-side preference")
        
        // Should adjust size based on learned preferences
        let adjustedW = adjustedArrangement.size.width.toPixels(for: 1440) ?? 0
        XCTAssertLessThan(adjustedW, 400, "Should apply learned narrow width preference")
    }
    
    // MARK: - Learning Decay and Adaptation
    
    func testPreferenceDecay() {
        // Old preference
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 0, y: 0, width: 800, height: 900),
            adjustedBounds: CGRect(x: 1080, y: 0, width: 360, height: 900),
            adjustmentType: .both,
            context: "coding",
            timestamp: Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
        )
        
        // Recent preference (different)
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 1080, y: 0, width: 360, height: 900),
            adjustedBounds: CGRect(x: 0, y: 0, width: 600, height: 900),
            adjustmentType: .both,
            context: "coding"
        )
        
        print("🧪 PREFERENCE DECAY TEST:")
        
        let currentPreference = learningService.getPositionPreference(for: "Terminal", context: "coding")
        print("  📊 Current preference: \(currentPreference?.x ?? 0)")
        
        // Should prioritize recent adjustments over old ones
        XCTAssertLessThan(currentPreference?.x ?? 1000, 500, "Should prioritize recent left-side preference")
    }
    
    func testConflictingPreferences() {
        // User makes conflicting adjustments
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 0, y: 0, width: 400, height: 900),
            adjustedBounds: CGRect(x: 1000, y: 0, width: 400, height: 900), // Right side
            adjustmentType: .position,
            context: "coding"
        )
        
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 1000, y: 0, width: 400, height: 900),
            adjustedBounds: CGRect(x: 100, y: 0, width: 400, height: 900), // Left side
            adjustmentType: .position,
            context: "coding"
        )
        
        print("🧪 CONFLICTING PREFERENCES TEST:")
        
        let confidence = learningService.getPreferenceConfidence(for: "Terminal", context: "coding")
        print("  📊 Confidence after conflict: \(confidence)")
        
        // Should have lower confidence when preferences conflict
        XCTAssertLessThan(confidence, 0.6, "Should have lower confidence with conflicting adjustments")
    }
    
    // MARK: - Performance and Memory Tests
    
    func testLearningDataPersistence() {
        learningService.trackWindowAdjustment(
            appName: "TestApp",
            originalBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            adjustedBounds: CGRect(x: 200, y: 100, width: 800, height: 600),
            adjustmentType: .position,
            context: "test"
        )
        
        // Simulate app restart by creating new service instance
        let newService = LearningService()
        
        // Should maintain learned data across restarts
        XCTAssertTrue(newService.hasLearningData(for: "TestApp"), "Should persist learning data")
    }
    
    func testMemoryLimiting() {
        // Add many adjustments to test memory limiting
        for i in 0..<1000 {
            learningService.trackWindowAdjustment(
                appName: "TestApp\(i % 10)", // 10 different apps
                originalBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
                adjustedBounds: CGRect(x: Double(i % 1440), y: 0, width: 800, height: 600),
                adjustmentType: .position,
                context: "test"
            )
        }
        
        print("🧪 MEMORY LIMITING TEST:")
        
        // Should not consume unlimited memory
        let memoryUsage = learningService.getApproximateMemoryUsage()
        print("  💾 Memory usage: \(memoryUsage) bytes")
        
        // Should be reasonable (less than 1MB for this test)
        XCTAssertLessThan(memoryUsage, 1024 * 1024, "Should limit memory usage")
    }
    
    // MARK: - Integration Tests
    
    func testLearningIntegrationWithCascade() {
        // Set up learned preferences
        learningService.trackWindowAdjustment(
            appName: "Terminal",
            originalBounds: CGRect(x: 100, y: 0, width: 500, height: 900),
            adjustedBounds: CGRect(x: 1080, y: 0, width: 360, height: 900),
            adjustmentType: .both,
            context: "coding"
        )
        
        // Generate cascade layout
        var layout = FlexibleLayoutEngine.generateCascadeLayout(
            for: ["Cursor", "Terminal", "Arc"],
            screenSize: CGSize(width: 1440, height: 900),
            context: "coding"
        )
        
        print("🧪 LEARNING-CASCADE INTEGRATION TEST:")
        print("  📊 Before learning application:")
        for arrangement in layout {
            let x = arrangement.position.x.toPixels(for: 1440)
            let w = arrangement.size.width.toPixels(for: 1440) ?? 0
            if arrangement.window == "Terminal" {
                print("    📱 Terminal: x=\(Int(x)), width=\(Int(w))")
            }
        }
        
        // Apply learned preferences
        layout = layout.map { arrangement in
            return learningService.applyLearnedPreferences(
                to: arrangement,
                context: "coding",
                screenSize: CGSize(width: 1440, height: 900)
            )
        }
        
        print("  📊 After learning application:")
        for arrangement in layout {
            let x = arrangement.position.x.toPixels(for: 1440)
            let w = arrangement.size.width.toPixels(for: 1440) ?? 0
            if arrangement.window == "Terminal" {
                print("    📱 Terminal: x=\(Int(x)), width=\(Int(w))")
            }
        }
        
        // Terminal should be positioned according to learned preferences
        let terminalArrangement = layout.first { $0.window == "Terminal" }!
        let terminalX = terminalArrangement.position.x.toPixels(for: 1440)
        XCTAssertGreaterThan(terminalX, 1000, "Should apply learned right-side preference")
    }
}

// MARK: - Test Utilities
extension LearningSystemTests {
    
    private func createMockAdjustment(
        app: String,
        from original: CGRect,
        to adjusted: CGRect,
        type: AdjustmentType = .both,
        context: String = "test",
        daysAgo: Int = 0
    ) {
        let timestamp = Date().addingTimeInterval(-Double(daysAgo * 24 * 3600))
        learningService.trackWindowAdjustment(
            appName: app,
            originalBounds: original,
            adjustedBounds: adjusted,
            adjustmentType: type,
            context: context,
            timestamp: timestamp
        )
    }
}

// MARK: - Mock Learning Service Extension
extension LearningService {
    
    func clearAllLearningData() {
        // Clear all stored learning data for testing
        userDefaults.removeObject(forKey: "windowAdjustments")
        userDefaults.removeObject(forKey: "appPairUsage")
        userDefaults.removeObject(forKey: "workspacePatterns")
        userDefaults.removeObject(forKey: "positionPreferences")
        userDefaults.removeObject(forKey: "sizePreferences")
    }
    
    func getApproximateMemoryUsage() -> Int {
        // Rough estimation of memory usage for testing
        let adjustmentsData = userDefaults.data(forKey: "windowAdjustments") ?? Data()
        let pairData = userDefaults.data(forKey: "appPairUsage") ?? Data()
        let workspaceData = userDefaults.data(forKey: "workspacePatterns") ?? Data()
        
        return adjustmentsData.count + pairData.count + workspaceData.count
    }
}