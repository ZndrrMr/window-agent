import Foundation
import CoreGraphics

// MARK: - Window Layout System
// Simplified layout system replacing complex flexible positioning

/// Pre-defined window layouts that work reliably with LLM selection
enum WindowLayout: String, CaseIterable {
    // Single window layouts
    case fullscreen = "fullscreen"
    case centered_large = "centered_large"
    case centered_medium = "centered_medium"
    
    // Two window layouts
    case left_right_split = "left_right_split"
    case top_bottom_split = "top_bottom_split"
    case main_sidebar = "main_sidebar"
    case sidebar_main = "sidebar_main"
    
    // Three window layouts
    case three_column = "three_column"
    case main_two_side = "main_two_side"
    case two_top_one_bottom = "two_top_one_bottom"
    
    // Four window layouts
    case four_quadrants = "four_quadrants"
    case main_three_side = "main_three_side"
    
    /// Human-readable description for LLM context
    var description: String {
        switch self {
        case .fullscreen:
            return "Single window takes full screen"
        case .centered_large:
            return "Single window centered, 80% of screen"
        case .centered_medium:
            return "Single window centered, 60% of screen"
        case .left_right_split:
            return "Two windows side by side, 50% each"
        case .top_bottom_split:
            return "Two windows stacked vertically, 50% each"
        case .main_sidebar:
            return "Main window 70% left, sidebar 30% right"
        case .sidebar_main:
            return "Sidebar 30% left, main window 70% right"
        case .three_column:
            return "Three windows in columns: 33%, 34%, 33%"
        case .main_two_side:
            return "Main window 50% left, two windows 25% each on right"
        case .two_top_one_bottom:
            return "Two windows on top 50% each, one window bottom 100%"
        case .four_quadrants:
            return "Four windows in 2x2 grid, 25% each"
        case .main_three_side:
            return "Main window 60% left, three windows stacked right 40%"
        }
    }
    
    /// Context categories this layout works well for
    var contextCategories: [String] {
        switch self {
        case .fullscreen, .centered_large:
            return ["focus", "presentation", "single_task"]
        case .main_sidebar, .sidebar_main:
            return ["coding", "research", "writing"]
        case .left_right_split:
            return ["comparison", "coding", "research"]
        case .three_column:
            return ["coding", "research", "design"]
        case .main_two_side:
            return ["coding", "development", "monitoring"]
        case .four_quadrants:
            return ["monitoring", "dashboard", "comparison"]
        default:
            return ["general"]
        }
    }
}

/// Window positioning data for a specific layout
struct LayoutPosition {
    let x: CGFloat      // X position as percentage (0.0-1.0)
    let y: CGFloat      // Y position as percentage (0.0-1.0)
    let width: CGFloat  // Width as percentage (0.0-1.0)
    let height: CGFloat // Height as percentage (0.0-1.0)
    
    /// Convert to actual CGRect for given screen size
    func toCGRect(screenSize: CGSize) -> CGRect {
        return CGRect(
            x: x * screenSize.width,
            y: y * screenSize.height,
            width: width * screenSize.width,
            height: height * screenSize.height
        )
    }
}

/// Window layout configuration for multiple windows
struct WindowLayoutConfiguration {
    let layout: WindowLayout
    let positions: [LayoutPosition]
    
    /// Get the position for window at specific index
    func position(for index: Int) -> LayoutPosition? {
        guard index < positions.count else { return nil }
        return positions[index]
    }
}

// MARK: - Layout Definitions
extension WindowLayout {
    
    /// Get the layout configuration for this layout type
    var configuration: WindowLayoutConfiguration {
        switch self {
        case .fullscreen:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
            ])
            
        case .centered_large:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            ])
            
        case .centered_medium:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
            ])
            
        case .left_right_split:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.5, height: 1.0),
                LayoutPosition(x: 0.5, y: 0.0, width: 0.5, height: 1.0)
            ])
            
        case .top_bottom_split:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 1.0, height: 0.5),
                LayoutPosition(x: 0.0, y: 0.5, width: 1.0, height: 0.5)
            ])
            
        case .main_sidebar:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.7, height: 1.0),
                LayoutPosition(x: 0.7, y: 0.0, width: 0.3, height: 1.0)
            ])
            
        case .sidebar_main:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.3, height: 1.0),
                LayoutPosition(x: 0.3, y: 0.0, width: 0.7, height: 1.0)
            ])
            
        case .three_column:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.33, height: 1.0),
                LayoutPosition(x: 0.33, y: 0.0, width: 0.34, height: 1.0),
                LayoutPosition(x: 0.67, y: 0.0, width: 0.33, height: 1.0)
            ])
            
        case .main_two_side:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.5, height: 1.0),
                LayoutPosition(x: 0.5, y: 0.0, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ])
            
        case .two_top_one_bottom:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.5, y: 0.0, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.0, y: 0.5, width: 1.0, height: 0.5)
            ])
            
        case .four_quadrants:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.5, y: 0.0, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.0, y: 0.5, width: 0.5, height: 0.5),
                LayoutPosition(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ])
            
        case .main_three_side:
            return WindowLayoutConfiguration(layout: self, positions: [
                LayoutPosition(x: 0.0, y: 0.0, width: 0.6, height: 1.0),
                LayoutPosition(x: 0.6, y: 0.0, width: 0.4, height: 0.33),
                LayoutPosition(x: 0.6, y: 0.33, width: 0.4, height: 0.34),
                LayoutPosition(x: 0.6, y: 0.67, width: 0.4, height: 0.33)
            ])
        }
    }
}

// MARK: - Layout Recommendation System
struct LayoutRecommender {
    
    /// Recommend layout based on number of apps and context
    static func recommendLayout(appCount: Int, context: String = "general") -> WindowLayout {
        let contextLower = context.lowercased()
        
        switch appCount {
        case 1:
            if contextLower.contains("focus") || contextLower.contains("present") {
                return .fullscreen
            } else {
                return .centered_large
            }
            
        case 2:
            if contextLower.contains("cod") || contextLower.contains("research") {
                return .main_sidebar
            } else {
                return .left_right_split
            }
            
        case 3:
            if contextLower.contains("cod") {
                return .main_two_side
            } else {
                return .three_column
            }
            
        case 4:
            return .four_quadrants
            
        default:
            if appCount >= 5 {
                return .main_three_side
            } else {
                return .centered_large
            }
        }
    }
    
    /// Get all layouts suitable for a given context
    static func layoutsForContext(_ context: String) -> [WindowLayout] {
        return WindowLayout.allCases.filter { layout in
            layout.contextCategories.contains { category in
                context.lowercased().contains(category.lowercased())
            }
        }
    }
}