import Cocoa
import Foundation

// MARK: - Smart Command Text Field
class SmartCommandTextField: NSTextField {
    private var isProcessingText = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextField()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        // Allow rich text for attributed strings
        self.allowsEditingTextAttributes = true
        
        // Disable automatic text features that might interfere
        if let textView = self.currentEditor() as? NSTextView {
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
        }
    }
    
    func updateTextWithAppStyling() {
        guard !isProcessingText else { return }
        isProcessingText = true
        
        let text = self.stringValue
        
        // Don't apply styling if text is empty or too short
        if text.isEmpty || text.count < 2 {
            // Just clear any existing styling
            self.attributedStringValue = NSAttributedString(string: text, attributes: [
                .font: self.font ?? NSFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ])
            isProcessingText = false
            return
        }
        
        // Store current cursor position before any changes
        let currentRange = self.currentEditor()?.selectedRange ?? NSRange(location: text.count, length: 0)
        let wasAtEnd = (currentRange.location == text.count)
        
        // If we're already displaying attributed text that matches the plain text, don't reprocess
        if self.attributedStringValue.string == text {
            isProcessingText = false
            return
        }
        
        // Don't apply styling if the text field is currently being edited
        if let editor = self.currentEditor(), editor.selectedRange.length > 0 {
            isProcessingText = false
            return
        }
        
        let words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let attributedString = NSMutableAttributedString()
        let normalFont = self.font ?? NSFont.systemFont(ofSize: 22, weight: .medium)
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: normalFont,
            .foregroundColor: NSColor.labelColor
        ]
        
        // No complex cursor tracking needed without icons
        var styledTextLength = 0
        
        for (index, word) in words.enumerated() {
            let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedWord.isEmpty, let appSuggestion = findAppMatch(for: trimmedWord) {
                // Only highlight if the word exactly matches the app name (no partial matches)
                if trimmedWord.lowercased() == appSuggestion.name.lowercased() {
                    // Create app name with special styling - NO ICON
                    let appAttributes: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
                        .foregroundColor: NSColor.controlAccentColor,
                        .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(0.12),
                        .strokeWidth: 0,
                        .strokeColor: NSColor.clear
                    ]
                    
                    let appString = NSAttributedString(string: word, attributes: appAttributes)
                    attributedString.append(appString)
                    styledTextLength += word.count
                } else {
                    // Word doesn't exactly match, use normal styling
                    let normalString = NSAttributedString(string: word, attributes: normalAttributes)
                    attributedString.append(normalString)
                    styledTextLength += word.count
                }
            } else {
                // Regular word - no special formatting
                let normalString = NSAttributedString(string: word, attributes: normalAttributes)
                attributedString.append(normalString)
                styledTextLength += word.count
            }
            
            // Add space between words
            if index < words.count - 1 {
                if index + 1 < words.count && !words[index + 1].isEmpty {
                    attributedString.append(NSAttributedString(string: " ", attributes: normalAttributes))
                    styledTextLength += 1
                }
            }
        }
        
        // Apply the attributed string
        self.attributedStringValue = attributedString
        
        // Restore cursor position - much simpler without icons
        DispatchQueue.main.async {
            if let editor = self.currentEditor() as? NSTextView {
                let newLocation: Int
                if wasAtEnd {
                    // If cursor was at the end, keep it at the end
                    newLocation = attributedString.length
                } else {
                    // Try to preserve relative position
                    newLocation = min(currentRange.location, attributedString.length)
                }
                // Ensure no text is selected, only position cursor
                editor.setSelectedRange(NSRange(location: newLocation, length: 0))
                
                // Extra safety: explicitly prevent any selection
                if editor.selectedRange.length > 0 {
                    editor.setSelectedRange(NSRange(location: newLocation, length: 0))
                }
            }
            self.isProcessingText = false
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle space key specifically to ensure it's processed correctly
        if event.charactersIgnoringModifiers == " " {
            // Insert space directly into the string value
            let currentText = self.stringValue
            let range = self.currentEditor()?.selectedRange ?? NSRange(location: currentText.count, length: 0)
            
            let newText = (currentText as NSString).replacingCharacters(in: range, with: " ")
            self.stringValue = newText
            
            // Position cursor after the space
            DispatchQueue.main.async {
                if let editor = self.currentEditor() as? NSTextView {
                    let newPosition = range.location + 1
                    editor.setSelectedRange(NSRange(location: newPosition, length: 0))
                }
            }
            
            // Trigger change notification manually
            NotificationCenter.default.post(
                name: NSControl.textDidChangeNotification,
                object: self
            )
            
            return
        }
        
        // Let normal key processing handle other keys
        super.keyDown(with: event)
    }
    
    private func findAppMatch(for word: String) -> AppSuggestion? {
        // Case-insensitive exact match with installed apps
        let wordLower = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get suggestions and find exact match
        let suggestions = AppAutocomplete.shared.getSuggestions(for: word, maxResults: 100)
        
        // Look for exact match (case-insensitive)
        for suggestion in suggestions {
            if suggestion.name.lowercased() == wordLower {
                return suggestion
            }
        }
        
        return nil
    }
}