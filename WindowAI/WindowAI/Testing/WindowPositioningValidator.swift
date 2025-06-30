import Foundation
import CoreGraphics
import AppKit

// MARK: - Window Positioning Validation System

/// Comprehensive validator for window positioning that tests:
/// 1. Desktop Coverage: Ensures 100% screen coverage with no exposed pixels
/// 2. Screen Bounds: Validates all windows stay within screen boundaries
class WindowPositioningValidator {
    
    // MARK: - Data Structures
    
    struct WindowCoordinates {
        let name: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        
        var rect: CGRect {
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        var area: Double {
            return width * height
        }
    }
    
    enum CoverageResult {
        case fullyCovered
        case hasGaps(exposedPixels: Int, gapAreas: [CGRect])
        
        var isPassed: Bool {
            switch self {
            case .fullyCovered: return true
            case .hasGaps: return false
            }
        }
    }
    
    enum BoundsResult {
        case allWithinBounds
        case hasOverflows(violations: [BoundsViolation])
        
        var isPassed: Bool {
            switch self {
            case .allWithinBounds: return true
            case .hasOverflows: return false
            }
        }
    }
    
    struct BoundsViolation {
        let windowName: String
        let violationType: ViolationType
        let actualValue: Double
        let allowedRange: ClosedRange<Double>
        
        var description: String {
            let rangeDesc = "\(allowedRange.lowerBound)...\(allowedRange.upperBound)"
            return "\(windowName): \(violationType.rawValue) = \(actualValue) (allowed: \(rangeDesc))"
        }
    }
    
    enum ViolationType: String, CaseIterable {
        case leftOverflow = "Left edge overflow"
        case rightOverflow = "Right edge overflow"  
        case topOverflow = "Top edge overflow"
        case bottomOverflow = "Bottom edge overflow"
    }
    
    struct ValidationReport {
        let screenBounds: CGRect
        let windows: [WindowCoordinates]
        let coverageResult: CoverageResult
        let boundsResult: BoundsResult
        let totalCoverage: Double
        let detailedReport: String
        
        var passedAllTests: Bool {
            return coverageResult.isPassed && boundsResult.isPassed
        }
    }
    
    // MARK: - Public API
    
    /// Main validation function that parses LLM output and runs all tests
    func validateLLMOutput(_ logOutput: String, screenBounds: CGRect? = nil) -> ValidationReport {
        let windows = parseCoordinates(logOutput)
        let actualScreenBounds = screenBounds ?? detectScreenBounds()
        
        let coverageResult = testDesktopCoverage(windows: windows, screenSize: actualScreenBounds.size)
        let boundsResult = testScreenBounds(windows: windows, screenBounds: actualScreenBounds)
        let totalCoverage = calculateTotalCoverage(windows: windows, screenSize: actualScreenBounds.size)
        let detailedReport = generateDetailedReport(
            windows: windows,
            screenBounds: actualScreenBounds,
            coverageResult: coverageResult,
            boundsResult: boundsResult,
            totalCoverage: totalCoverage
        )
        
        return ValidationReport(
            screenBounds: actualScreenBounds,
            windows: windows,
            coverageResult: coverageResult,
            boundsResult: boundsResult,
            totalCoverage: totalCoverage,
            detailedReport: detailedReport
        )
    }
    
    // MARK: - Test 1: Desktop Coverage Validation
    
    /// Tests if windows provide 100% screen coverage with no exposed desktop pixels
    func testDesktopCoverage(windows: [WindowCoordinates], screenSize: CGSize) -> CoverageResult {
        // Use a reasonable resolution for coverage analysis (avoid massive arrays)
        let gridWidth = Int(screenSize.width / 4)  // Every 4 pixels
        let gridHeight = Int(screenSize.height / 4)
        
        // Create coverage map - false = exposed desktop, true = covered
        var coverageMap = Array(repeating: Array(repeating: false, count: gridWidth), count: gridHeight)
        
        // Mark covered areas for each window
        for window in windows {
            let startX = max(0, Int(window.x / 4))
            let endX = min(gridWidth - 1, Int((window.x + window.width) / 4))
            let startY = max(0, Int(window.y / 4))
            let endY = min(gridHeight - 1, Int((window.y + window.height) / 4))
            
            for y in startY...endY {
                for x in startX...endX {
                    coverageMap[y][x] = true
                }
            }
        }
        
        // Count exposed pixels and find gap areas
        var exposedPixels = 0
        var gapAreas: [CGRect] = []
        var currentGap: CGRect?
        
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                if !coverageMap[y][x] {
                    exposedPixels += 1
                    
                    // Try to merge with current gap or start new one
                    let pixelRect = CGRect(x: x * 4, y: y * 4, width: 4, height: 4)
                    if let gap = currentGap, gap.maxX >= pixelRect.minX - 4 && gap.maxY >= pixelRect.minY - 4 {
                        currentGap = gap.union(pixelRect)
                    } else {
                        if let gap = currentGap {
                            gapAreas.append(gap)
                        }
                        currentGap = pixelRect
                    }
                }
            }
        }
        
        if let gap = currentGap {
            gapAreas.append(gap)
        }
        
        if exposedPixels == 0 {
            return .fullyCovered
        } else {
            return .hasGaps(exposedPixels: exposedPixels * 16, gapAreas: gapAreas) // Scale back to actual pixels
        }
    }
    
    // MARK: - Test 2: Screen Bounds Validation
    
    /// Tests if all windows stay within screen boundaries
    func testScreenBounds(windows: [WindowCoordinates], screenBounds: CGRect) -> BoundsResult {
        var violations: [BoundsViolation] = []
        
        for window in windows {
            // Check left edge
            if window.x < screenBounds.minX {
                violations.append(BoundsViolation(
                    windowName: window.name,
                    violationType: .leftOverflow,
                    actualValue: window.x,
                    allowedRange: screenBounds.minX...screenBounds.maxX
                ))
            }
            
            // Check right edge
            if window.x + window.width > screenBounds.maxX {
                violations.append(BoundsViolation(
                    windowName: window.name,
                    violationType: .rightOverflow,
                    actualValue: window.x + window.width,
                    allowedRange: screenBounds.minX...screenBounds.maxX
                ))
            }
            
            // Check top edge
            if window.y < screenBounds.minY {
                violations.append(BoundsViolation(
                    windowName: window.name,
                    violationType: .topOverflow,
                    actualValue: window.y,
                    allowedRange: screenBounds.minY...screenBounds.maxY
                ))
            }
            
            // Check bottom edge
            if window.y + window.height > screenBounds.maxY {
                violations.append(BoundsViolation(
                    windowName: window.name,
                    violationType: .bottomOverflow,
                    actualValue: window.y + window.height,
                    allowedRange: screenBounds.minY...screenBounds.maxY
                ))
            }
        }
        
        if violations.isEmpty {
            return .allWithinBounds
        } else {
            return .hasOverflows(violations: violations)
        }
    }
    
    // MARK: - Coordinate Parsing
    
    /// Parses window coordinates from LLM positioning log output
    func parseCoordinates(_ logText: String) -> [WindowCoordinates] {
        var windows: [WindowCoordinates] = []
        
        // Regex pattern to match: "📍 Positioning AppName to (x, y, width, height)"
        let pattern = #"📍 Positioning (\w+) to \(([0-9.]+), ([0-9.]+), ([0-9.]+), ([0-9.]+)\)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(logText.startIndex..<logText.endIndex, in: logText)
            
            regex.enumerateMatches(in: logText, options: [], range: range) { match, _, _ in
                guard let match = match, match.numberOfRanges == 6 else { return }
                
                let nameRange = Range(match.range(at: 1), in: logText)!
                let xRange = Range(match.range(at: 2), in: logText)!
                let yRange = Range(match.range(at: 3), in: logText)!
                let widthRange = Range(match.range(at: 4), in: logText)!
                let heightRange = Range(match.range(at: 5), in: logText)!
                
                let name = String(logText[nameRange])
                if let x = Double(logText[xRange]),
                   let y = Double(logText[yRange]),
                   let width = Double(logText[widthRange]),
                   let height = Double(logText[heightRange]) {
                    
                    windows.append(WindowCoordinates(
                        name: name,
                        x: x,
                        y: y,
                        width: width,
                        height: height
                    ))
                }
            }
        } catch {
            print("⚠️ Regex parsing error: \(error)")
        }
        
        return windows
    }
    
    // MARK: - Utility Functions
    
    /// Auto-detect current screen bounds
    func detectScreenBounds() -> CGRect {
        return NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }
    
    /// Calculate total screen coverage percentage
    func calculateTotalCoverage(windows: [WindowCoordinates], screenSize: CGSize) -> Double {
        let totalWindowArea = windows.reduce(0) { $0 + $1.area }
        let screenArea = Double(screenSize.width * screenSize.height)
        return min(100.0, (totalWindowArea / screenArea) * 100.0)
    }
    
    /// Generate detailed validation report
    func generateDetailedReport(
        windows: [WindowCoordinates],
        screenBounds: CGRect,
        coverageResult: CoverageResult,
        boundsResult: BoundsResult,
        totalCoverage: Double
    ) -> String {
        var report = """
        🧪 WINDOW POSITIONING VALIDATION REPORT
        =====================================
        
        📐 Screen: \(Int(screenBounds.width))x\(Int(screenBounds.height)) pixels
        📱 Windows: \(windows.count) detected
        
        """
        
        // Coverage test results
        report += "🔍 DESKTOP COVERAGE TEST:\n"
        switch coverageResult {
        case .fullyCovered:
            report += "✅ PASSED - 100% screen coverage (0 exposed pixels)\n"
        case .hasGaps(let exposedPixels, let gapAreas):
            report += "❌ FAILED - \(exposedPixels) exposed pixels in \(gapAreas.count) gap(s)\n"
            for (index, gap) in gapAreas.enumerated() {
                report += "   Gap \(index + 1): (\(Int(gap.minX)),\(Int(gap.minY))) \(Int(gap.width))×\(Int(gap.height))\n"
            }
        }
        
        report += "\n"
        
        // Bounds test results
        report += "🔍 BOUNDS VALIDATION TEST:\n"
        switch boundsResult {
        case .allWithinBounds:
            report += "✅ PASSED - All windows within screen boundaries\n"
        case .hasOverflows(let violations):
            report += "❌ FAILED - \(violations.count) boundary violation(s):\n"
            for violation in violations {
                report += "   • \(violation.description)\n"
            }
        }
        
        report += "\n"
        
        // Window analysis
        report += "📊 WINDOW ANALYSIS:\n"
        let screenArea = screenBounds.width * screenBounds.height
        for window in windows {
            let coverage = (window.area / Double(screenArea)) * 100.0
            let status = (window.x >= 0 && window.y >= 0 && 
                         window.x + window.width <= screenBounds.width && 
                         window.y + window.height <= screenBounds.height) ? "✅" : "❌"
            report += "• \(window.name): (\(Int(window.x)),\(Int(window.y))) \(Int(window.width))×\(Int(window.height)) = \(String(format: "%.1f", coverage))% coverage \(status)\n"
        }
        
        report += "\n"
        
        // Overall result
        let overallStatus = (coverageResult.isPassed && boundsResult.isPassed) ? "✅ ALL TESTS PASSED" : "❌ TESTS FAILED"
        report += "🎯 OVERALL RESULT: \(overallStatus)\n"
        report += "📈 Total Coverage: \(String(format: "%.1f", totalCoverage))%"
        
        return report
    }
}

// MARK: - Quick Test Functions

extension WindowPositioningValidator {
    
    /// Quick test for common LLM output patterns
    static func quickTest(logOutput: String) {
        let validator = WindowPositioningValidator()
        let report = validator.validateLLMOutput(logOutput)
        print(report.detailedReport)
    }
    
    /// Test with known coordinates
    static func testKnownCoordinates(_ coordinates: [(String, Double, Double, Double, Double)], screenSize: CGSize = CGSize(width: 1440, height: 900)) {
        let validator = WindowPositioningValidator()
        let windows = coordinates.map { 
            WindowPositioningValidator.WindowCoordinates(name: $0.0, x: $0.1, y: $0.2, width: $0.3, height: $0.4)
        }
        
        let screenBounds = CGRect(origin: .zero, size: screenSize)
        let coverageResult = validator.testDesktopCoverage(windows: windows, screenSize: screenSize)
        let boundsResult = validator.testScreenBounds(windows: windows, screenBounds: screenBounds)
        let totalCoverage = validator.calculateTotalCoverage(windows: windows, screenSize: screenSize)
        
        let report = validator.generateDetailedReport(
            windows: windows,
            screenBounds: screenBounds,
            coverageResult: coverageResult,
            boundsResult: boundsResult,
            totalCoverage: totalCoverage
        )
        
        print(report)
    }
}