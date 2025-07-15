import Foundation
import Cocoa

// MARK: - ASCII Grid System for Window Management
// Transforms window positioning from percentage-based to visual grid representation
// for better LLM spatial reasoning and constraint satisfaction

struct ASCIIGridSystem {
    
    // MARK: - Grid Configuration Constants
    static let GRID_CELL_SIZE: CGFloat = 50.0  // Each ASCII cell = 50x50 pixels
    static let MIN_VISIBLE_CELLS: Int = 4      // 2x2 cells = 100x100 pixels minimum
    static let MAX_APPS_SUPPORTED: Int = 35    // 0-9, A-Z
    
    // MARK: - App-to-Character Mapping
    static let APP_MAPPING: [String: String] = [
        // Numbers for most common apps
        "Arc": "1",
        "Safari": "2", 
        "Terminal": "3",
        "Finder": "4",
        "Messages": "5",
        "Cursor": "6",
        "Xcode": "7",
        "Chrome": "8",
        "Slack": "9",
        "Claude": "0",
        
        // Letters for additional apps
        "Mail": "A",
        "Calendar": "B",
        "Notes": "C",
        "Notion": "D",
        "Spotify": "E",
        "Discord": "F",
        "Telegram": "G",
        "WhatsApp": "H",
        "Figma": "I",
        "Photoshop": "J",
        "Illustrator": "K",
        "VS Code": "L",
        "IntelliJ": "M",
        "PyCharm": "N",
        "Atom": "O",
        "Sublime": "P",
        "TextEdit": "Q",
        "Preview": "R",
        "System Preferences": "S",
        "Activity Monitor": "T",
        "Console": "U",
        "Disk Utility": "V",
        "Keychain Access": "W",
        "Font Book": "X",
        "Migration Assistant": "Y",
        "Boot Camp": "Z"
    ]
    
    // MARK: - Grid Calculation
    static func calculateGridDimensions(for screenSize: CGSize) -> (width: Int, height: Int) {
        let width = Int(screenSize.width / GRID_CELL_SIZE)
        let height = Int(screenSize.height / GRID_CELL_SIZE)
        return (width, height)
    }
    
    // MARK: - Window to Grid Conversion
    static func windowToGridCoordinates(_ window: WindowInfo, screenSize: CGSize) -> (startX: Int, startY: Int, endX: Int, endY: Int) {
        let gridDimensions = calculateGridDimensions(for: screenSize)
        
        let startX = max(0, Int(window.bounds.minX / GRID_CELL_SIZE))
        let startY = max(0, Int(window.bounds.minY / GRID_CELL_SIZE))
        let endX = min(gridDimensions.width, Int(window.bounds.maxX / GRID_CELL_SIZE))
        let endY = min(gridDimensions.height, Int(window.bounds.maxY / GRID_CELL_SIZE))
        
        return (startX, startY, endX, endY)
    }
    
    // MARK: - Get App Character
    static func getAppCharacter(for appName: String) -> String {
        return APP_MAPPING[appName] ?? "?"
    }
    
    // MARK: - Create App Legend
    static func createAppLegend(for windows: [WindowInfo]) -> String {
        var legend = "LEGEND:\n"
        
        for window in windows {
            let char = getAppCharacter(for: window.appName)
            legend += "\(char) = \(window.appName)\n"
        }
        
        return legend
    }
}

// MARK: - Grid Generation Result
struct GridGenerationResult {
    let asciiGrid: String
    let legend: String
    let validations: [String: WindowValidation]
    let gridDimensions: (width: Int, height: Int)
}

// MARK: - Window Validation
struct WindowValidation {
    let appName: String
    let visibleCells: Int
    let meetsMinimum: Bool
    let visiblePixels: Int
    let hasOverlap: Bool
}

// MARK: - ASCII Grid Generator
class ASCIIGridGenerator {
    
    // MARK: - Main Grid Generation
    static func generateGrid(for windows: [WindowInfo], screenSize: CGSize) -> GridGenerationResult {
        let gridDimensions = ASCIIGridSystem.calculateGridDimensions(for: screenSize)
        
        // Initialize empty grid
        var grid = Array(repeating: Array(repeating: ".", count: gridDimensions.width), count: gridDimensions.height)
        
        // Process windows in z-order (back to front)
        for window in windows {
            let appChar = ASCIIGridSystem.getAppCharacter(for: window.appName)
            let coords = ASCIIGridSystem.windowToGridCoordinates(window, screenSize: screenSize)
            
            // Mark window on grid
            for y in coords.startY..<coords.endY {
                for x in coords.startX..<coords.endX {
                    if y < gridDimensions.height && x < gridDimensions.width {
                        if grid[y][x] == "." {
                            grid[y][x] = appChar
                        } else {
                            // Mark overlap with 'X'
                            grid[y][x] = "X"
                        }
                    }
                }
            }
        }
        
        // Validate minimum visibility for each window
        let validations = validateMinimumVisibility(grid: grid, windows: windows, screenSize: screenSize)
        
        // Format grid output
        let asciiGrid = formatGridOutput(grid: grid)
        let legend = ASCIIGridSystem.createAppLegend(for: windows)
        
        return GridGenerationResult(
            asciiGrid: asciiGrid,
            legend: legend,
            validations: validations,
            gridDimensions: gridDimensions
        )
    }
    
    // MARK: - Constraint Validation
    static func validateMinimumVisibility(grid: [[String]], windows: [WindowInfo], screenSize: CGSize) -> [String: WindowValidation] {
        var validations: [String: WindowValidation] = [:]
        
        for window in windows {
            let appChar = ASCIIGridSystem.getAppCharacter(for: window.appName)
            var visibleCells = 0
            var hasOverlap = false
            
            // Count non-overlapped cells for this window
            for row in grid {
                for cell in row {
                    if cell == appChar {
                        visibleCells += 1
                    }
                }
            }
            
            // Check for overlaps
            for row in grid {
                for cell in row {
                    if cell == "X" {
                        hasOverlap = true
                        break
                    }
                }
                if hasOverlap { break }
            }
            
            let visiblePixels = visibleCells * Int(ASCIIGridSystem.GRID_CELL_SIZE * ASCIIGridSystem.GRID_CELL_SIZE)
            
            validations[window.appName] = WindowValidation(
                appName: window.appName,
                visibleCells: visibleCells,
                meetsMinimum: visibleCells >= ASCIIGridSystem.MIN_VISIBLE_CELLS,
                visiblePixels: visiblePixels,
                hasOverlap: hasOverlap
            )
        }
        
        return validations
    }
    
    // MARK: - Grid Formatting
    static func formatGridOutput(grid: [[String]]) -> String {
        var output = ""
        
        // Add top border
        output += "+" + String(repeating: "-", count: grid[0].count) + "+\n"
        
        // Add grid rows
        for row in grid {
            output += "|" + row.joined() + "|\n"
        }
        
        // Add bottom border
        output += "+" + String(repeating: "-", count: grid[0].count) + "+\n"
        
        return output
    }
}

// MARK: - ASCII Response Parser
struct ASCIIResponseParser {
    
    // MARK: - Parse LLM Response
    static func parseASCIIResponse(_ response: String, screenSize: CGSize) -> [WindowCommand]? {
        // Extract ASCII grid from response
        guard let gridText = extractGridFromResponse(response) else {
            print("❌ Failed to extract ASCII grid from response")
            return nil
        }
        
        // Convert ASCII back to window positions
        return asciiToWindowPositions(gridText: gridText, screenSize: screenSize)
    }
    
    // MARK: - Extract Grid from Response
    static func extractGridFromResponse(_ response: String) -> String? {
        // Look for grid pattern: +---+ with |...| rows
        let pattern = #"\+[-]+\+\n((?:\|.*\|\n)+)\+[-]+\+"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.count)) else {
            return nil
        }
        
        let gridRange = Range(match.range(at: 1), in: response)!
        return String(response[gridRange])
    }
    
    // MARK: - Convert ASCII to Window Positions
    static func asciiToWindowPositions(gridText: String, screenSize: CGSize) -> [WindowCommand] {
        var commands: [WindowCommand] = []
        let lines = gridText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Parse each line of the grid
        var appPositions: [String: [(x: Int, y: Int)]] = [:]
        
        for (y, line) in lines.enumerated() {
            let chars = line.replacingOccurrences(of: "|", with: "")
            for (x, char) in chars.enumerated() {
                let charStr = String(char)
                if charStr != "." && charStr != "X" {
                    if appPositions[charStr] == nil {
                        appPositions[charStr] = []
                    }
                    appPositions[charStr]?.append((x: x, y: y))
                }
            }
        }
        
        // Convert positions to window commands
        for (appChar, positions) in appPositions {
            if let appName = getAppNameFromCharacter(appChar) {
                if let bounds = calculateBoundsFromPositions(positions, screenSize: screenSize) {
                    let command = WindowCommand(
                        action: .move,
                        target: appName,
                        position: .precise,
                        size: .precise,
                        customSize: bounds.size,
                        customPosition: bounds.origin
                    )
                    commands.append(command)
                }
            }
        }
        
        return commands
    }
    
    // MARK: - Get App Name from Character
    static func getAppNameFromCharacter(_ char: String) -> String? {
        return ASCIIGridSystem.APP_MAPPING.first { $0.value == char }?.key
    }
    
    // MARK: - Calculate Bounds from Positions
    static func calculateBoundsFromPositions(_ positions: [(x: Int, y: Int)], screenSize: CGSize) -> CGRect? {
        guard !positions.isEmpty else { return nil }
        
        let minX = positions.map { $0.x }.min()!
        let maxX = positions.map { $0.x }.max()!
        let minY = positions.map { $0.y }.min()!
        let maxY = positions.map { $0.y }.max()!
        
        let x = CGFloat(minX) * ASCIIGridSystem.GRID_CELL_SIZE
        let y = CGFloat(minY) * ASCIIGridSystem.GRID_CELL_SIZE
        let width = CGFloat(maxX - minX + 1) * ASCIIGridSystem.GRID_CELL_SIZE
        let height = CGFloat(maxY - minY + 1) * ASCIIGridSystem.GRID_CELL_SIZE
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}