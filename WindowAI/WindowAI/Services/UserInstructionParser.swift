import Foundation
import CoreGraphics

// MARK: - User Instruction Parser
/// Parses natural language user instructions and stores them as persistent preferences
class UserInstructionParser {
    static let shared = UserInstructionParser()
    
    private let learningService = LearningService.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Instruction Patterns
    
    /// Parse user instruction and extract persistent preferences
    func parseInstruction(_ instruction: String) -> ParsedInstruction? {
        let normalized = instruction.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Pattern 1: "Always put/place [app] [position]"
        if let alwaysRule = parseAlwaysRule(normalized) {
            return alwaysRule
        }
        
        // Pattern 2: "Never open [app]" or "Don't use [app]"
        if let neverRule = parseNeverRule(normalized) {
            return neverRule
        }
        
        // Pattern 3: "[App] should always be [size/position]"
        if let shouldRule = parseShouldRule(normalized) {
            return shouldRule
        }
        
        // Pattern 4: "I prefer [app] on the [position]"
        if let preferRule = parsePreferRule(normalized) {
            return preferRule
        }
        
        // Pattern 5: "When coding, [instruction]"
        if let contextRule = parseContextRule(normalized) {
            return contextRule
        }
        
        return nil
    }
    
    private func parseAlwaysRule(_ instruction: String) -> ParsedInstruction? {
        // Patterns: "always put terminal on the right", "always place xcode on left half"
        let alwaysPatterns = [
            #"always (?:put|place|open) (\w+) (?:on the |in the )?(\w+(?:\s\w+)*)"#,
            #"always have (\w+) (?:on the |in the )?(\w+(?:\s\w+)*)"#
        ]
        
        for pattern in alwaysPatterns {
            if let (_, captures) = instruction.firstMatch(of: try! NSRegularExpression(pattern: pattern)) {
                let appName = captures.count > 0 ? captures[0] : ""
                let position = captures.count > 1 ? captures[1] : ""
                
                return ParsedInstruction(
                    type: .alwaysPosition,
                    appName: appName.capitalized,
                    position: normalizePosition(position),
                    context: "general",
                    originalText: instruction
                )
            }
        }
        
        return nil
    }
    
    private func parseNeverRule(_ instruction: String) -> ParsedInstruction? {
        // Patterns: "never open xcode", "don't use safari", "never suggest finder"
        let neverPatterns = [
            #"never (?:open|use|suggest) (\w+)"#,
            #"don't (?:open|use) (\w+)"#,
            #"do not (?:open|use) (\w+)"#
        ]
        
        for pattern in neverPatterns {
            if let (_, captures) = instruction.firstMatch(of: try! NSRegularExpression(pattern: pattern)) {
                let appName = captures.count > 0 ? captures[0] : ""
                
                return ParsedInstruction(
                    type: .neverUse,
                    appName: appName.capitalized,
                    context: "general",
                    originalText: instruction
                )
            }
        }
        
        return nil
    }
    
    private func parseShouldRule(_ instruction: String) -> ParsedInstruction? {
        // Patterns: "terminal should always be narrow", "cursor should be primary"
        let shouldPatterns = [
            #"(\w+) should (?:always )?be (\w+(?:\s\w+)*)"#,
            #"(\w+) should (?:always )?go (?:on the |in the )?(\w+(?:\s\w+)*)"#
        ]
        
        for pattern in shouldPatterns {
            if let (_, captures) = instruction.firstMatch(of: try! NSRegularExpression(pattern: pattern)) {
                let appName = captures.count > 0 ? captures[0] : ""
                let preference = captures.count > 1 ? captures[1] : ""
                
                let instructionType: InstructionType
                if preference.contains("narrow") || preference.contains("wide") || preference.contains("small") || preference.contains("large") {
                    instructionType = .alwaysSize
                } else {
                    instructionType = .alwaysPosition
                }
                
                return ParsedInstruction(
                    type: instructionType,
                    appName: appName.capitalized,
                    position: instructionType == .alwaysPosition ? normalizePosition(preference) : nil,
                    size: instructionType == .alwaysSize ? normalizeSize(preference) : nil,
                    context: "general",
                    originalText: instruction
                )
            }
        }
        
        return nil
    }
    
    private func parsePreferRule(_ instruction: String) -> ParsedInstruction? {
        // Patterns: "I prefer terminal on the right", "I like arc in the center"
        let preferPatterns = [
            #"i (?:prefer|like) (\w+) (?:on the |in the )?(\w+(?:\s\w+)*)"#
        ]
        
        for pattern in preferPatterns {
            if let (_, captures) = instruction.firstMatch(of: try! NSRegularExpression(pattern: pattern)) {
                let appName = captures.count > 0 ? captures[0] : ""
                let position = captures.count > 1 ? captures[1] : ""
                
                return ParsedInstruction(
                    type: .preferPosition,
                    appName: appName.capitalized,
                    position: normalizePosition(position),
                    context: "general",
                    originalText: instruction
                )
            }
        }
        
        return nil
    }
    
    private func parseContextRule(_ instruction: String) -> ParsedInstruction? {
        // Patterns: "when coding, always put terminal on right", "for design work, use figma"
        let contextPatterns = [
            #"when (\w+(?:\s\w+)*), (.+)"#,
            #"for (\w+(?:\s\w+)*), (.+)"#,
            #"during (\w+(?:\s\w+)*), (.+)"#
        ]
        
        for pattern in contextPatterns {
            if let (_, captures) = instruction.firstMatch(of: try! NSRegularExpression(pattern: pattern)) {
                let context = captures.count > 0 ? captures[0] : ""
                let subInstruction = captures.count > 1 ? captures[1] : ""
                
                // Parse the sub-instruction recursively
                if var parsed = parseInstruction(subInstruction) {
                    parsed.context = normalizeContext(context)
                    return parsed
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Normalization Helpers
    
    private func normalizePosition(_ position: String) -> String {
        let pos = position.lowercased()
        
        // Map natural language to standard positions
        if pos.contains("right") && pos.contains("side") || pos == "right" {
            return "right"
        } else if pos.contains("left") && pos.contains("side") || pos == "left" {
            return "left"
        } else if pos.contains("center") || pos.contains("middle") {
            return "center"
        } else if pos.contains("top") && pos.contains("right") {
            return "topRight"
        } else if pos.contains("top") && pos.contains("left") {
            return "topLeft"
        } else if pos.contains("bottom") && pos.contains("right") {
            return "bottomRight"
        } else if pos.contains("bottom") && pos.contains("left") {
            return "bottomLeft"
        } else if pos.contains("top") {
            return "top"
        } else if pos.contains("bottom") {
            return "bottom"
        } else if pos.contains("right") && pos.contains("half") {
            return "rightHalf"
        } else if pos.contains("left") && pos.contains("half") {
            return "leftHalf"
        }
        
        return position // Return as-is if no match
    }
    
    private func normalizeSize(_ size: String) -> String {
        let sz = size.lowercased()
        
        if sz.contains("narrow") || sz.contains("thin") {
            return "narrow"
        } else if sz.contains("wide") || sz.contains("broad") {
            return "wide"
        } else if sz.contains("small") || sz.contains("tiny") {
            return "small"
        } else if sz.contains("large") || sz.contains("big") {
            return "large"
        } else if sz.contains("primary") || sz.contains("main") {
            return "primary"
        }
        
        return size
    }
    
    private func normalizeContext(_ context: String) -> String {
        let ctx = context.lowercased()
        
        if ctx.contains("cod") || ctx.contains("develop") || ctx.contains("program") {
            return "coding"
        } else if ctx.contains("design") || ctx.contains("creat") {
            return "design"
        } else if ctx.contains("research") || ctx.contains("read") || ctx.contains("study") {
            return "research"
        } else if ctx.contains("meet") || ctx.contains("call") || ctx.contains("video") {
            return "meeting"
        }
        
        return "general"
    }
    
    // MARK: - Storage and Retrieval
    
    /// Store a parsed instruction as a persistent preference
    func storeInstruction(_ instruction: ParsedInstruction) {
        var storedInstructions = getStoredInstructions()
        
        // Remove any existing instruction for the same app/context combo
        storedInstructions.removeAll { existing in
            existing.appName == instruction.appName && 
            existing.context == instruction.context &&
            existing.type == instruction.type
        }
        
        storedInstructions.append(instruction)
        
        // Store to UserDefaults
        if let data = try? JSONEncoder().encode(storedInstructions) {
            userDefaults.set(data, forKey: "userInstructions")
        }
        
        print("📝 STORED USER INSTRUCTION:")
        print("   App: \(instruction.appName)")
        print("   Type: \(instruction.type.rawValue)")
        print("   Context: \(instruction.context)")
        if let position = instruction.position {
            print("   Position: \(position)")
        }
        if let size = instruction.size {
            print("   Size: \(size)")
        }
        print("   Original: \"\(instruction.originalText)\"")
    }
    
    /// Get stored instructions for a specific app and context
    func getInstructionsForApp(_ appName: String, context: String = "general") -> [ParsedInstruction] {
        let storedInstructions = getStoredInstructions()
        
        return storedInstructions.filter { instruction in
            instruction.appName.lowercased() == appName.lowercased() &&
            (instruction.context == context || instruction.context == "general")
        }
    }
    
    /// Get all stored instructions
    func getStoredInstructions() -> [ParsedInstruction] {
        guard let data = userDefaults.data(forKey: "userInstructions"),
              let instructions = try? JSONDecoder().decode([ParsedInstruction].self, from: data) else {
            return []
        }
        return instructions
    }
    
    /// Check if an app should never be used
    func shouldNeverUse(_ appName: String, context: String = "general") -> Bool {
        let instructions = getInstructionsForApp(appName, context: context)
        return instructions.contains { $0.type == .neverUse }
    }
    
    /// Get preferred position for an app
    func getPreferredPosition(for appName: String, context: String = "general") -> String? {
        let instructions = getInstructionsForApp(appName, context: context)
        
        // Prioritize "always" rules over "prefer" rules
        if let alwaysRule = instructions.first(where: { $0.type == .alwaysPosition }) {
            return alwaysRule.position
        }
        
        if let preferRule = instructions.first(where: { $0.type == .preferPosition }) {
            return preferRule.position
        }
        
        return nil
    }
    
    /// Get preferred size for an app
    func getPreferredSize(for appName: String, context: String = "general") -> String? {
        let instructions = getInstructionsForApp(appName, context: context)
        return instructions.first(where: { $0.type == .alwaysSize })?.size
    }
    
    /// Clear all stored instructions (for testing/reset)
    func clearAllInstructions() {
        userDefaults.removeObject(forKey: "userInstructions")
    }
    
    /// Generate instruction string for LLM prompt
    func generateInstructionString() -> String {
        let instructions = getStoredInstructions()
        
        if instructions.isEmpty {
            return ""
        }
        
        var instructionText = "\n\nUSER PREFERENCES (ALWAYS FOLLOW THESE):\n"
        
        // Group by context
        let groupedInstructions = Dictionary(grouping: instructions) { $0.context }
        
        for (context, contextInstructions) in groupedInstructions {
            if context != "general" {
                instructionText += "For \(context) tasks:\n"
            }
            
            for instruction in contextInstructions {
                switch instruction.type {
                case .alwaysPosition:
                    instructionText += "- ALWAYS place \(instruction.appName) at \(instruction.position ?? "specified position")\n"
                case .alwaysSize:
                    instructionText += "- ALWAYS make \(instruction.appName) \(instruction.size ?? "specified size")\n"
                case .preferPosition:
                    instructionText += "- User prefers \(instruction.appName) at \(instruction.position ?? "specified position")\n"
                case .neverUse:
                    instructionText += "- NEVER suggest or use \(instruction.appName)\n"
                }
            }
        }
        
        return instructionText
    }
}

// MARK: - Data Structures

struct ParsedInstruction: Codable {
    let type: InstructionType
    let appName: String
    var position: String?
    var size: String?
    var context: String
    let originalText: String
    let timestamp: Date
    
    init(type: InstructionType, appName: String, position: String? = nil, size: String? = nil, context: String, originalText: String) {
        self.type = type
        self.appName = appName
        self.position = position
        self.size = size
        self.context = context
        self.originalText = originalText
        self.timestamp = Date()
    }
}

enum InstructionType: String, Codable {
    case alwaysPosition = "always_position"
    case alwaysSize = "always_size"
    case preferPosition = "prefer_position"
    case neverUse = "never_use"
}

// MARK: - String Extension for Regex
extension String {
    func firstMatch(of regex: NSRegularExpression) -> (String, [String])? {
        let range = NSRange(location: 0, length: self.utf16.count)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        
        let fullMatch = String(self[Range(match.range, in: self)!])
        var captures: [String] = []
        
        for i in 1..<match.numberOfRanges {
            let captureRange = match.range(at: i)
            if captureRange.location != NSNotFound,
               let range = Range(captureRange, in: self) {
                captures.append(String(self[range]))
            } else {
                captures.append("")
            }
        }
        
        return (fullMatch, captures)
    }
}