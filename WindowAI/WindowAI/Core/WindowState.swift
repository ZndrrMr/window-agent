import Foundation
import CoreGraphics

// MARK: - Window State Representation
struct WindowState {
    let app: String
    let id: String
    let frame: CGRect
    let layer: Int
    let displayIndex: Int
    let isMinimized: Bool
    let visibleArea: CGFloat?
    let overlaps: [Overlap]
    
    init(app: String, id: String, frame: CGRect, layer: Int, displayIndex: Int = 0, isMinimized: Bool = false) {
        self.app = app
        self.id = id
        self.frame = frame
        self.layer = layer
        self.displayIndex = displayIndex
        self.isMinimized = isMinimized
        self.visibleArea = nil
        self.overlaps = []
    }
    
    // Symbolic notation representation
    var symbolicNotation: String {
        let x = Int(frame.origin.x)
        let y = Int(frame.origin.y)
        let w = Int(frame.width)
        let h = Int(frame.height)
        
        var notation = "\(app)[\(x),\(y),\(w),\(h),L\(layer)]"
        
        if isMinimized {
            notation += "[MINIMIZED]"
        }
        
        if displayIndex > 0 {
            notation += "[D\(displayIndex)]"
        }
        
        return notation
    }
    
    // Calculate area in pixels
    var totalArea: CGFloat {
        return frame.width * frame.height
    }
    
    // Check if this window satisfies the 100x100 visibility constraint
    var satisfiesVisibilityConstraint: Bool {
        guard let visible = visibleArea else { return false }
        return visible >= 10000 // 100x100 = 10,000 pixels
    }
}

// MARK: - Overlap Calculation
struct Overlap {
    let window1: String
    let window2: String
    let intersectionRect: CGRect
    let area: CGFloat
    
    init(window1: String, window2: String, intersectionRect: CGRect) {
        self.window1 = window1
        self.window2 = window2
        self.intersectionRect = intersectionRect
        self.area = intersectionRect.width * intersectionRect.height
    }
    
    // Symbolic notation for overlap
    var symbolicNotation: String {
        let x = Int(intersectionRect.origin.x)
        let y = Int(intersectionRect.origin.y)
        let w = Int(intersectionRect.width)
        let h = Int(intersectionRect.height)
        
        return "\(window1)∩\(window2) = [\(x),\(y),\(w),\(h)] = \(Int(area))px²"
    }
}

// MARK: - Constraint Validation System
class ConstraintValidator {
    static let shared = ConstraintValidator()
    
    private init() {}
    
    // Calculate overlaps between all windows considering layer hierarchy
    func calculateOverlaps(windows: [WindowState]) -> [String: [Overlap]] {
        var windowOverlaps: [String: [Overlap]] = [:]
        
        // Initialize empty overlap arrays for each window
        for window in windows {
            windowOverlaps[window.app] = []
        }
        
        // Calculate overlaps between all window pairs
        for i in 0..<windows.count {
            for j in (i+1)..<windows.count {
                let window1 = windows[i]
                let window2 = windows[j]
                
                // Skip if windows are on different displays
                if window1.displayIndex != window2.displayIndex {
                    continue
                }
                
                // Calculate intersection rectangle
                let intersection = window1.frame.intersection(window2.frame)
                
                // Only process if there's actual overlap
                if !intersection.isEmpty {
                    let overlap = Overlap(
                        window1: window1.app,
                        window2: window2.app,
                        intersectionRect: intersection
                    )
                    
                    // Add overlap to both windows
                    windowOverlaps[window1.app]?.append(overlap)
                    windowOverlaps[window2.app]?.append(overlap)
                }
            }
        }
        
        return windowOverlaps
    }
    
    // Calculate visible area for a window considering layer hierarchy
    func calculateVisibleArea(for window: WindowState, overlaps: [Overlap]) -> CGFloat {
        var visibleArea = window.totalArea
        
        // Subtract areas where this window is occluded by higher-layer windows
        for overlap in overlaps {
            // Find the other window in this overlap
            let otherWindowApp = overlap.window1 == window.app ? overlap.window2 : overlap.window1
            
            // We need to find the other window's layer to determine occlusion
            // This would require access to the full window list, so we'll implement this
            // in the workspace analyzer below
        }
        
        return max(visibleArea, 0)
    }
    
    // Validate that all windows satisfy the 100x100 constraint
    func validateConstraints(windows: [WindowState]) -> ConstraintValidationResult {
        var validatedWindows: [WindowState] = []
        var violations: [ConstraintViolation] = []
        
        // Calculate all overlaps
        let overlaps = calculateOverlaps(windows: windows)
        
        // Sort windows by layer (highest layer first for occlusion calculations)
        let sortedWindows = windows.sorted { $0.layer > $1.layer }
        
        // Calculate visible area for each window
        for window in sortedWindows {
            let windowOverlaps = overlaps[window.app] ?? []
            
            // Calculate visible area considering layer hierarchy
            var visibleArea = window.totalArea
            
            // Subtract areas where this window is occluded
            for overlap in windowOverlaps {
                let otherWindowApp = overlap.window1 == window.app ? overlap.window2 : overlap.window1
                
                // Find the other window's layer
                if let otherWindow = windows.first(where: { $0.app == otherWindowApp }) {
                    // If other window has higher layer, it occludes this window
                    if otherWindow.layer > window.layer {
                        visibleArea -= overlap.area
                    }
                }
            }
            
            // Ensure visible area doesn't go negative
            visibleArea = max(visibleArea, 0)
            
            // Create updated window state with visible area
            let updatedWindow = WindowState(
                app: window.app,
                id: window.id,
                frame: window.frame,
                layer: window.layer,
                displayIndex: window.displayIndex,
                isMinimized: window.isMinimized
            )
            
            // Update the visible area (would need to modify struct to be mutable)
            var mutableWindow = updatedWindow
            // Note: This would require making visibleArea mutable in the struct
            
            validatedWindows.append(updatedWindow)
            
            // Check constraint violation
            if visibleArea < 10000 {
                let violation = ConstraintViolation(
                    window: window.app,
                    requiredArea: 10000,
                    actualArea: visibleArea,
                    difference: 10000 - visibleArea
                )
                violations.append(violation)
            }
        }
        
        return ConstraintValidationResult(
            windows: validatedWindows,
            violations: violations,
            overlaps: overlaps
        )
    }
    
    // Generate symbolic reasoning output for debugging
    func generateSymbolicAnalysis(windows: [WindowState]) -> String {
        var analysis = "SYMBOLIC WINDOW ANALYSIS:\n\n"
        
        // List all windows with symbolic notation
        analysis += "WINDOW LAYOUT:\n"
        for window in windows.sorted(by: { $0.layer > $1.layer }) {
            analysis += "- \(window.symbolicNotation)\n"
        }
        
        // Calculate and show overlaps
        let overlaps = calculateOverlaps(windows: windows)
        analysis += "\nOVERLAP ANALYSIS:\n"
        
        var processedPairs: Set<String> = []
        
        for (windowApp, windowOverlaps) in overlaps {
            for overlap in windowOverlaps {
                let pairKey = [overlap.window1, overlap.window2].sorted().joined(separator: "-")
                
                if !processedPairs.contains(pairKey) {
                    analysis += "- \(overlap.symbolicNotation)\n"
                    processedPairs.insert(pairKey)
                }
            }
        }
        
        // Validate constraints
        let validation = validateConstraints(windows: windows)
        analysis += "\nCONSTRAINT VALIDATION:\n"
        
        if validation.violations.isEmpty {
            analysis += "✓ All windows satisfy 100x100px visibility constraint\n"
        } else {
            analysis += "✗ \(validation.violations.count) constraint violations found:\n"
            for violation in validation.violations {
                analysis += "  - \(violation.window): \(Int(violation.actualArea))px² visible (need \(Int(violation.requiredArea))px²)\n"
            }
        }
        
        return analysis
    }
}

// MARK: - Validation Result Types
struct ConstraintValidationResult {
    let windows: [WindowState]
    let violations: [ConstraintViolation]
    let overlaps: [String: [Overlap]]
}

struct ConstraintViolation {
    let window: String
    let requiredArea: CGFloat
    let actualArea: CGFloat
    let difference: CGFloat
}

// MARK: - Workspace Analyzer
class WorkspaceAnalyzer {
    static let shared = WorkspaceAnalyzer()
    
    private init() {}
    
    // Convert WindowSummary to WindowState with layer assignment
    func convertToWindowStates(_ windowSummaries: [LLMContext.WindowSummary]) -> [WindowState] {
        var windowStates: [WindowState] = []
        
        for (index, windowSummary) in windowSummaries.enumerated() {
            // Assign layers based on z-order (front to back)
            let layer = windowSummaries.count - index
            
            let windowState = WindowState(
                app: windowSummary.appName,
                id: UUID().uuidString, // Generate ID since WindowSummary doesn't have it
                frame: windowSummary.bounds,
                layer: layer,
                displayIndex: windowSummary.displayIndex,
                isMinimized: windowSummary.isMinimized
            )
            
            windowStates.append(windowState)
        }
        
        return windowStates
    }
    
    // Generate LLM context with symbolic analysis
    func generateLLMContext(from windowSummaries: [LLMContext.WindowSummary]) -> String {
        let windowStates = convertToWindowStates(windowSummaries)
        let validator = ConstraintValidator.shared
        
        return validator.generateSymbolicAnalysis(windows: windowStates)
    }
    
    // Analyze workspace and suggest improvements
    func analyzeWorkspace(_ windowSummaries: [LLMContext.WindowSummary]) -> WorkspaceAnalysis {
        let windowStates = convertToWindowStates(windowSummaries)
        let validator = ConstraintValidator.shared
        let validation = validator.validateConstraints(windows: windowStates)
        
        let analysis = WorkspaceAnalysis(
            totalWindows: windowStates.count,
            constraintViolations: validation.violations.count,
            suggestions: generateSuggestions(from: validation)
        )
        
        return analysis
    }
    
    private func generateSuggestions(from validation: ConstraintValidationResult) -> [String] {
        var suggestions: [String] = []
        
        if validation.violations.isEmpty {
            suggestions.append("✓ All windows satisfy visibility constraints")
        } else {
            suggestions.append("⚠️ \(validation.violations.count) windows need repositioning")
            
            for violation in validation.violations {
                suggestions.append("→ \(violation.window) needs \(Int(violation.difference))px² more visible area")
            }
        }
        
        return suggestions
    }
}

// MARK: - Analysis Result Types
struct WorkspaceAnalysis {
    let totalWindows: Int
    let constraintViolations: Int
    let suggestions: [String]
}