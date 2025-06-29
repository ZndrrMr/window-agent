import XCTest
@testable import WindowAI

class CascadeSystemTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset any shared state
        ContextualAppFilter.shared
        AppArchetypeClassifier.shared
    }
    
    // MARK: - Core Functionality Tests
    
    func testSmartAppFiltering() {
        let allApps = ["Cursor", "Terminal", "Arc", "Xcode", "Finder", "BetterDisplay"]
        let context = "I want to code"
        
        let filteredApps = ContextualAppFilter.shared.selectRelevantApps(
            from: allApps,
            for: context,
            maxApps: 4
        )
        
        print("🧪 SMART FILTERING TEST:")
        print("  📱 Input: \(allApps.joined(separator: ", "))")
        print("  📝 Context: '\(context)'")
        print("  ✅ Filtered: \(filteredApps.joined(separator: ", "))")
        
        // Should prioritize coding-relevant apps
        XCTAssertTrue(filteredApps.contains("Cursor"), "Should include primary code editor")
        XCTAssertTrue(filteredApps.contains("Terminal"), "Should include terminal for coding")
        XCTAssertTrue(filteredApps.contains("Arc"), "Should include browser for documentation")
        
        // Should filter out irrelevant apps
        XCTAssertFalse(filteredApps.contains("BetterDisplay"), "Should filter out display utilities")
        XCTAssertFalse(filteredApps.contains("Finder"), "Should filter out file manager for coding context")
        
        // Should limit to reasonable number
        XCTAssertLessThanOrEqual(filteredApps.count, 4, "Should respect maxApps limit")
    }
    
    func testCascadeLayoutGeneration() {
        let apps = ["Cursor", "Terminal", "Arc"]
        let screenSize = CGSize(width: 1440, height: 900)
        let context = "coding"
        
        let layout = FlexibleLayoutEngine.generateCascadeLayout(
            for: apps,
            screenSize: screenSize,
            context: context
        )
        
        print("🧪 CASCADE LAYOUT TEST:")
        for arrangement in layout {
            let x = arrangement.position.x.toPixels(for: screenSize.width)
            let y = arrangement.position.y.toPixels(for: screenSize.height)
            let w = arrangement.size.width.toPixels(for: screenSize.width) ?? 0
            let h = arrangement.size.height.toPixels(for: screenSize.height) ?? 0
            
            print("  📱 \(arrangement.window): Position: (\(Int(x)), \(Int(y))), Size: \(Int(w))x\(Int(h)), Layer: \(arrangement.layer)")
        }
        
        // Should have exactly the expected number of arrangements
        XCTAssertEqual(layout.count, 3, "Should create arrangement for each app")
        
        // Should have one primary window
        let primaryWindows = layout.filter { $0.layer == 3 }
        XCTAssertEqual(primaryWindows.count, 1, "Should have exactly one primary window")
        
        // Primary should be Cursor for coding context
        let primary = primaryWindows.first!
        XCTAssertEqual(primary.window, "Cursor", "Cursor should be primary for coding")
        
        // Should have proper sizing (70% width for primary)
        if case .percentage(let width) = primary.size.width {
            XCTAssertEqual(width, 0.70, accuracy: 0.01, "Primary should be 70% width")
        } else {
            XCTFail("Primary size should be percentage-based")
        }
        
        // Terminal should be side column (25% width, full height)
        let terminal = layout.first { $0.window == "Terminal" }!
        if case .percentage(let width) = terminal.size.width,
           case .percentage(let height) = terminal.size.height {
            XCTAssertEqual(width, 0.25, accuracy: 0.01, "Terminal should be 25% width")
            XCTAssertEqual(height, 1.0, accuracy: 0.01, "Terminal should be full height")
        } else {
            XCTFail("Terminal size should be percentage-based")
        }
        
        // Arc should be peek layer
        let arc = layout.first { $0.window == "Arc" }!
        XCTAssertEqual(arc.layer, 2, "Arc should be peek layer")
        XCTAssertEqual(arc.visibility, .partial, "Arc should have partial visibility")
    }
    
    func testArchetypeClassification() {
        let classifier = AppArchetypeClassifier.shared
        
        // Test known apps
        XCTAssertEqual(classifier.classifyApp("Cursor"), .codeWorkspace)
        XCTAssertEqual(classifier.classifyApp("Terminal"), .textStream)
        XCTAssertEqual(classifier.classifyApp("Arc"), .contentCanvas)
        XCTAssertEqual(classifier.classifyApp("BetterDisplay"), .glanceableMonitor)
        
        // Test pattern matching for unknown apps
        XCTAssertEqual(classifier.classifyApp("MyCodeEditor"), .codeWorkspace)
        XCTAssertEqual(classifier.classifyApp("CustomTerminal"), .textStream)
        XCTAssertEqual(classifier.classifyApp("NewBrowser"), .contentCanvas)
        
        print("🧪 ARCHETYPE CLASSIFICATION TEST:")
        print("  ✅ Cursor → \(classifier.classifyApp("Cursor").displayName)")
        print("  ✅ Terminal → \(classifier.classifyApp("Terminal").displayName)")
        print("  ✅ Arc → \(classifier.classifyApp("Arc").displayName)")
    }
    
    func testContextPrioritization() {
        let filter = ContextualAppFilter.shared
        let apps = ["Cursor", "Xcode", "Terminal", "Arc"]
        
        let roleAssignments = filter.orderAppsForCascade(
            apps: apps,
            context: "coding"
        )
        
        print("🧪 CONTEXT PRIORITIZATION TEST:")
        for assignment in roleAssignments {
            print("  🎭 \(assignment.app) → \(assignment.preferredRole.rawValue)")
        }
        
        // Cursor should be primary for coding context
        let cursorAssignment = roleAssignments.first { $0.app == "Cursor" }!
        XCTAssertEqual(cursorAssignment.preferredRole, .primary, "Cursor should be primary for coding")
        
        // Terminal should be side column
        let terminalAssignment = roleAssignments.first { $0.app == "Terminal" }!
        XCTAssertEqual(terminalAssignment.preferredRole, .sideColumn, "Terminal should be side column")
        
        // Arc should be peek layer
        let arcAssignment = roleAssignments.first { $0.app == "Arc" }!
        XCTAssertEqual(arcAssignment.preferredRole, .peekLayer, "Arc should be peek layer")
    }
    
    // MARK: - Edge Case Tests
    
    func testSingleAppLayout() {
        let apps = ["Cursor"]
        let screenSize = CGSize(width: 1440, height: 900)
        
        let layout = FlexibleLayoutEngine.generateCascadeLayout(
            for: apps,
            screenSize: screenSize,
            context: "coding"
        )
        
        XCTAssertEqual(layout.count, 1, "Should handle single app")
        
        let arrangement = layout.first!
        XCTAssertEqual(arrangement.layer, 3, "Single app should be primary")
        XCTAssertEqual(arrangement.visibility, .full, "Single app should be fully visible")
    }
    
    func testManyAppsFiltering() {
        let manyApps = [
            "Cursor", "Xcode", "Terminal", "iTerm", "Arc", "Safari", "Chrome",
            "Finder", "BetterDisplay", "Spotify", "Slack", "Messages"
        ]
        
        let filteredApps = ContextualAppFilter.shared.selectRelevantApps(
            from: manyApps,
            for: "I want to code",
            maxApps: 4
        )
        
        print("🧪 MANY APPS FILTERING TEST:")
        print("  📱 Input: \(manyApps.count) apps")
        print("  ✅ Filtered: \(filteredApps.joined(separator: ", "))")
        
        // Should limit to manageable number
        XCTAssertLessThanOrEqual(filteredApps.count, 4, "Should limit to maxApps")
        
        // Should prioritize most relevant
        XCTAssertTrue(filteredApps.contains("Cursor"), "Should keep primary code editor")
        XCTAssertTrue(filteredApps.contains("Terminal"), "Should keep terminal")
        
        // Should filter out completely irrelevant
        XCTAssertFalse(filteredApps.contains("Spotify"), "Should filter out music apps")
        XCTAssertFalse(filteredApps.contains("BetterDisplay"), "Should filter out utilities")
    }
    
    func testConflictResolution() {
        // Test multiple Code Workspace apps
        let conflictingApps = ["Cursor", "Xcode", "VSCode"]
        
        let filteredApps = ContextualAppFilter.shared.selectRelevantApps(
            from: conflictingApps,
            for: "coding",
            maxApps: 3
        )
        
        print("🧪 CONFLICT RESOLUTION TEST:")
        print("  📱 Conflicting: \(conflictingApps.joined(separator: ", "))")
        print("  ✅ Resolved: \(filteredApps.joined(separator: ", "))")
        
        // Should prioritize Cursor over others for coding
        XCTAssertTrue(filteredApps.contains("Cursor"), "Should prioritize Cursor")
        
        // Should handle multiple similar apps gracefully
        XCTAssertLessThanOrEqual(filteredApps.count, 3, "Should respect limits")
    }
    
    // MARK: - Performance Tests
    
    func testLayoutPerformance() {
        let apps = ["App1", "App2", "App3", "App4", "App5"]
        let screenSize = CGSize(width: 1440, height: 900)
        
        measure {
            for _ in 0..<100 {
                _ = FlexibleLayoutEngine.generateCascadeLayout(
                    for: apps,
                    screenSize: screenSize,
                    context: "test"
                )
            }
        }
    }
    
    func testFilteringPerformance() {
        let manyApps = Array(0..<50).map { "App\($0)" }
        
        measure {
            for _ in 0..<100 {
                _ = ContextualAppFilter.shared.selectRelevantApps(
                    from: manyApps,
                    for: "test context",
                    maxApps: 5
                )
            }
        }
    }
    
    // MARK: - Real-World Scenario Tests
    
    func testCodingScenario() {
        // Simulate the exact scenario from the user's feedback
        let realApps = ["Terminal", "Arc", "Xcode", "Finder", "BetterDisplay", "Cursor"]
        let context = "I want to code"
        
        let filteredApps = ContextualAppFilter.shared.selectRelevantApps(
            from: realApps,
            for: context,
            maxApps: 4
        )
        
        let layout = FlexibleLayoutEngine.generateCascadeLayout(
            for: filteredApps,
            screenSize: CGSize(width: 1440, height: 900),
            context: context
        )
        
        print("🧪 REAL CODING SCENARIO TEST:")
        print("  📝 Input: \(realApps.joined(separator: ", "))")
        print("  ✅ Filtered: \(filteredApps.joined(separator: ", "))")
        print("  📊 Layout:")
        
        for arrangement in layout {
            print("    📱 \(arrangement.window) → Layer \(arrangement.layer), \(arrangement.visibility)")
        }
        
        // Should match expected results from user's vision
        let expectedApps = ["Cursor", "Terminal", "Arc"]
        for app in expectedApps {
            XCTAssertTrue(filteredApps.contains(app), "Should include \(app)")
        }
        
        // Should filter out irrelevant apps
        XCTAssertFalse(filteredApps.contains("BetterDisplay"), "Should filter out BetterDisplay")
        XCTAssertFalse(filteredApps.contains("Finder"), "Should filter out Finder")
        
        // Cursor should be primary
        let cursorArrangement = layout.first { $0.window == "Cursor" }
        XCTAssertEqual(cursorArrangement?.layer, 3, "Cursor should be primary layer")
        
        // Terminal should be side column
        let terminalArrangement = layout.first { $0.window == "Terminal" }
        XCTAssertEqual(terminalArrangement?.layer, 1, "Terminal should be side column")
        
        // Arc should be peek
        let arcArrangement = layout.first { $0.window == "Arc" }
        XCTAssertEqual(arcArrangement?.layer, 2, "Arc should be peek layer")
    }
    
    func testResearchScenario() {
        let apps = ["Arc", "Safari", "Notes", "Preview", "Finder"]
        let context = "research mode"
        
        let layout = FlexibleLayoutEngine.generateCascadeLayout(
            for: apps,
            screenSize: CGSize(width: 1440, height: 900),
            context: context
        )
        
        print("🧪 RESEARCH SCENARIO TEST:")
        for arrangement in layout {
            print("  📱 \(arrangement.window) → Layer \(arrangement.layer)")
        }
        
        // Browser should be primary for research
        let browserArrangements = layout.filter { 
            $0.window.contains("Arc") || $0.window.contains("Safari") 
        }
        XCTAssertTrue(browserArrangements.contains { $0.layer == 3 }, "Browser should be primary for research")
    }
}

// MARK: - Test Utilities
extension CascadeSystemTests {
    
    private func printLayoutSummary(_ layout: [FlexibleWindowArrangement], screenSize: CGSize) {
        print("📊 LAYOUT SUMMARY:")
        for arrangement in layout.sorted(by: { $0.layer > $1.layer }) {
            let x = arrangement.position.x.toPixels(for: screenSize.width)
            let y = arrangement.position.y.toPixels(for: screenSize.height)
            let w = arrangement.size.width.toPixels(for: screenSize.width) ?? 0
            let h = arrangement.size.height.toPixels(for: screenSize.height) ?? 0
            
            let widthPct = Int((w / screenSize.width) * 100)
            let heightPct = Int((h / screenSize.height) * 100)
            
            print("  📱 \(arrangement.window): \(Int(x)),\(Int(y)) \(Int(w))x\(Int(h)) (\(widthPct)%w × \(heightPct)%h) Layer:\(arrangement.layer)")
        }
    }
}