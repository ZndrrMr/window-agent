import Foundation
import CoreGraphics

// MARK: - Constraint Validation Test Suite
class ConstraintValidationTest {
    static let shared = ConstraintValidationTest()
    
    private init() {}
    
    // MARK: - Test Cases
    func runAllTests() {
        print("🧪 CONSTRAINT VALIDATION TEST SUITE")
        print("=" * 50)
        
        testBasicOverlapCalculation()
        testComplexOverlapScenario()
        testLayerAwareness()
        testConstraintViolationDetection()
        testSymbolicNotation()
        testWorkspaceAnalysis()
        
        print("\n✅ All constraint validation tests completed")
    }
    
    // Test 1: Basic overlap calculation
    private func testBasicOverlapCalculation() {
        print("\n🔍 Test 1: Basic Overlap Calculation")
        
        let window1 = WindowState(
            app: "Safari",
            id: "safari-1",
            frame: CGRect(x: 0, y: 0, width: 400, height: 300),
            layer: 1
        )
        
        let window2 = WindowState(
            app: "Terminal",
            id: "terminal-1",
            frame: CGRect(x: 350, y: 250, width: 300, height: 200),
            layer: 2
        )
        
        let windows = [window1, window2]
        let validator = ConstraintValidator.shared
        let overlaps = validator.calculateOverlaps(windows: windows)
        
        // Check Safari's overlaps
        let safariOverlaps = overlaps["Safari"] ?? []
        assert(safariOverlaps.count == 1, "Safari should have 1 overlap")
        
        let overlap = safariOverlaps[0]
        assert(overlap.intersectionRect == CGRect(x: 350, y: 250, width: 50, height: 50), "Overlap should be 50x50 at (350,250)")
        assert(overlap.area == 2500, "Overlap area should be 2500px²")
        
        print("   ✓ Basic overlap calculation works correctly")
        print("   ✓ Overlap area: \(Int(overlap.area))px²")
        print("   ✓ Symbolic notation: \(overlap.symbolicNotation)")
    }
    
    // Test 2: Complex overlap scenario with multiple windows
    private func testComplexOverlapScenario() {
        print("\n🔍 Test 2: Complex Overlap Scenario")
        
        let arc = WindowState(
            app: "Arc",
            id: "arc-1",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            layer: 1
        )
        
        let terminal = WindowState(
            app: "Terminal",
            id: "terminal-1",
            frame: CGRect(x: 400, y: 300, width: 400, height: 300),
            layer: 2
        )
        
        let cursor = WindowState(
            app: "Cursor",
            id: "cursor-1",
            frame: CGRect(x: 200, y: 150, width: 600, height: 450),
            layer: 3
        )
        
        let windows = [arc, terminal, cursor]
        let validator = ConstraintValidator.shared
        let validation = validator.validateConstraints(windows: windows)
        
        print("   ✓ Windows: \(windows.count)")
        print("   ✓ Overlaps calculated: \(validation.overlaps.values.flatMap { $0 }.count / 2) pairs")
        print("   ✓ Violations: \(validation.violations.count)")
        
        // Check that overlaps are properly calculated
        let arcOverlaps = validation.overlaps["Arc"] ?? []
        assert(arcOverlaps.count == 2, "Arc should overlap with 2 windows")
        
        print("   ✓ Complex overlap scenario handled correctly")
    }
    
    // Test 3: Layer awareness in occlusion calculations
    private func testLayerAwareness() {
        print("\n🔍 Test 3: Layer Awareness")
        
        // Bottom layer window
        let background = WindowState(
            app: "Background",
            id: "bg-1",
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            layer: 1
        )
        
        // Top layer window that completely covers background
        let foreground = WindowState(
            app: "Foreground",
            id: "fg-1",
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            layer: 2
        )
        
        let windows = [background, foreground]
        let validator = ConstraintValidator.shared
        let validation = validator.validateConstraints(windows: windows)
        
        // Background should have 0 visible area (completely occluded)
        let backgroundViolation = validation.violations.first { $0.window == "Background" }
        assert(backgroundViolation != nil, "Background window should violate constraint")
        assert(backgroundViolation!.actualArea == 0, "Background should have 0 visible area")
        
        print("   ✓ Layer-aware occlusion calculation works")
        print("   ✓ Background visible area: \(Int(backgroundViolation!.actualArea))px²")
        print("   ✓ Foreground visible area: \(40000)px² (not occluded)")
    }
    
    // Test 4: Constraint violation detection
    private func testConstraintViolationDetection() {
        print("\n🔍 Test 4: Constraint Violation Detection")
        
        // Create a window that's too small to satisfy 100x100 constraint
        let tinyWindow = WindowState(
            app: "TinyApp",
            id: "tiny-1",
            frame: CGRect(x: 0, y: 0, width: 80, height: 80),
            layer: 1
        )
        
        // Create a window that satisfies constraint
        let goodWindow = WindowState(
            app: "GoodApp",
            id: "good-1",
            frame: CGRect(x: 200, y: 200, width: 400, height: 300),
            layer: 2
        )
        
        let windows = [tinyWindow, goodWindow]
        let validator = ConstraintValidator.shared
        let validation = validator.validateConstraints(windows: windows)
        
        // Should find violation for tiny window
        assert(validation.violations.count == 1, "Should find 1 violation")
        
        let violation = validation.violations[0]
        assert(violation.window == "TinyApp", "Violation should be for TinyApp")
        assert(violation.actualArea == 6400, "TinyApp should have 6400px² total area")
        assert(violation.requiredArea == 10000, "Required area should be 10000px²")
        
        print("   ✓ Constraint violation detected correctly")
        print("   ✓ Violation: \(violation.window) has \(Int(violation.actualArea))px² (needs \(Int(violation.requiredArea))px²)")
    }
    
    // Test 5: Symbolic notation generation
    private func testSymbolicNotation() {
        print("\n🔍 Test 5: Symbolic Notation Generation")
        
        let window = WindowState(
            app: "TestApp",
            id: "test-1",
            frame: CGRect(x: 100, y: 200, width: 300, height: 400),
            layer: 2,
            displayIndex: 1,
            isMinimized: false
        )
        
        let expectedNotation = "TestApp[100,200,300,400,L2][D1]"
        assert(window.symbolicNotation == expectedNotation, "Symbolic notation should match expected format")
        
        print("   ✓ Symbolic notation: \(window.symbolicNotation)")
        
        // Test minimized window
        let minimizedWindow = WindowState(
            app: "MinimizedApp",
            id: "min-1",
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            layer: 1,
            isMinimized: true
        )
        
        let minimizedNotation = "MinimizedApp[0,0,200,200,L1][MINIMIZED]"
        assert(minimizedWindow.symbolicNotation == minimizedNotation, "Minimized window notation should include [MINIMIZED]")
        
        print("   ✓ Minimized notation: \(minimizedWindow.symbolicNotation)")
    }
    
    // Test 6: Workspace analysis
    private func testWorkspaceAnalysis() {
        print("\n🔍 Test 6: Workspace Analysis")
        
        // Create mock WindowInfo objects
        let windowInfo1 = WindowInfo(
            id: "1",
            appName: "Arc",
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            displayIndex: 0,
            isMinimized: false
        )
        
        let windowInfo2 = WindowInfo(
            id: "2",
            appName: "Terminal",
            bounds: CGRect(x: 600, y: 400, width: 400, height: 300),
            displayIndex: 0,
            isMinimized: false
        )
        
        let windowInfos = [windowInfo1, windowInfo2]
        let analyzer = WorkspaceAnalyzer.shared
        let analysis = analyzer.analyzeWorkspace(windowInfos)
        
        print("   ✓ Total windows: \(analysis.totalWindows)")
        print("   ✓ Constraint violations: \(analysis.constraintViolations)")
        print("   ✓ Suggestions:")
        for suggestion in analysis.suggestions {
            print("     - \(suggestion)")
        }
        
        // Test LLM context generation
        let llmContext = analyzer.generateLLMContext(from: windowInfos)
        assert(llmContext.contains("SYMBOLIC WINDOW ANALYSIS"), "LLM context should contain symbolic analysis")
        
        print("   ✓ LLM context generated successfully")
    }
    
    // Helper for validation results
    private func printValidationResults(_ validation: ConstraintValidationResult) {
        print("     Windows: \(validation.windows.count)")
        print("     Violations: \(validation.violations.count)")
        
        if !validation.violations.isEmpty {
            print("     Constraint violations:")
            for violation in validation.violations {
                print("       - \(violation.window): \(Int(violation.actualArea))px² visible (needs \(Int(violation.requiredArea))px²)")
            }
        }
    }
}

// MARK: - Test Runner
extension ConstraintValidationTest {
    static func runTests() {
        ConstraintValidationTest.shared.runAllTests()
    }
}

// MARK: - String Repetition Helper
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}