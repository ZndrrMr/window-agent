import Cocoa

protocol AutocompleteDropdownDelegate: AnyObject {
    func autocompleteDropdown(_ dropdown: AutocompleteDropdown, didSelect suggestion: AppSuggestion)
}

class AutocompleteDropdown: NSView {
    weak var delegate: AutocompleteDropdownDelegate?
    
    private var suggestions: [AppSuggestion] = []
    private var selectedIndex = 0
    private var suggestionViews: [AutocompleteSuggestionView] = []
    
    private let maxVisibleItems = 5
    private let itemHeight: CGFloat = 44
    private let borderRadius: CGFloat = 12
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        
        // Beautiful dropdown styling
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = borderRadius
        layer?.cornerCurve = .continuous
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        
        // Shadow for depth
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.2
        layer?.shadowOffset = CGSize(width: 0, height: -4)
        layer?.shadowRadius = 8
        
        isHidden = true
    }
    
    func updateSuggestions(_ newSuggestions: [AppSuggestion]) {
        print("🎯 AutocompleteDropdown.updateSuggestions called with \(newSuggestions.count) suggestions")
        suggestions = newSuggestions
        selectedIndex = 0
        
        // Remove old views
        suggestionViews.forEach { $0.removeFromSuperview() }
        suggestionViews.removeAll()
        
        if suggestions.isEmpty {
            print("❌ No suggestions, hiding dropdown")
            isHidden = true
            return
        }
        
        print("✅ Creating \(suggestions.count) suggestion views")
        
        // Create new suggestion views
        for (index, suggestion) in suggestions.enumerated() {
            let suggestionView = AutocompleteSuggestionView(suggestion: suggestion)
            suggestionView.isSelected = (index == selectedIndex)
            suggestionView.onClicked = { [weak self] in
                print("🖱️ Suggestion clicked: \(suggestion.name)")
                self?.delegate?.autocompleteDropdown(self!, didSelect: suggestion)
            }
            
            addSubview(suggestionView)
            suggestionViews.append(suggestionView)
            print("  📱 Created view for: \(suggestion.name)")
        }
        
        // Update layout
        layoutSuggestions()
        isHidden = false
        print("📐 Dropdown frame after layout: \(frame), hidden: \(isHidden)")
    }
    
    private func layoutSuggestions() {
        let itemCount = min(suggestions.count, maxVisibleItems)
        let totalHeight = CGFloat(itemCount) * itemHeight
        
        print("📏 Layout: itemCount=\(itemCount), totalHeight=\(totalHeight), frameWidth=\(frame.width)")
        
        // Update dropdown size
        frame.size.height = totalHeight
        
        // Layout suggestion views from top to bottom
        for (index, view) in suggestionViews.enumerated() {
            // Position items from top: first item at top, subsequent items below
            let y = totalHeight - CGFloat(index + 1) * itemHeight
            let viewFrame = NSRect(x: 0, y: y, width: frame.width, height: itemHeight)
            view.frame = viewFrame
            print("  📱 View \(index) (\(suggestions[index].name)): frame=\(viewFrame)")
        }
        
        print("📐 Final dropdown frame: \(frame)")
    }
    
    func selectNext() {
        guard !suggestions.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % suggestions.count
        updateSelection()
    }
    
    func selectPrevious() {
        guard !suggestions.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + suggestions.count) % suggestions.count
        updateSelection()
    }
    
    func selectFirst() {
        guard !suggestions.isEmpty else { return }
        selectedIndex = 0
        updateSelection()
    }
    
    private func updateSelection() {
        for (index, view) in suggestionViews.enumerated() {
            view.isSelected = (index == selectedIndex)
        }
    }
    
    func getSelectedSuggestion() -> AppSuggestion? {
        guard selectedIndex < suggestions.count else { return nil }
        return suggestions[selectedIndex]
    }
    
    func hide() {
        isHidden = true
        suggestions.removeAll()
        suggestionViews.forEach { $0.removeFromSuperview() }
        suggestionViews.removeAll()
    }
}

// MARK: - Individual Suggestion View
class AutocompleteSuggestionView: NSView {
    private let suggestion: AppSuggestion
    private let iconImageView: NSImageView
    private let nameLabel: NSTextField
    var onClicked: (() -> Void)?
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    init(suggestion: AppSuggestion) {
        self.suggestion = suggestion
        self.iconImageView = NSImageView()
        self.nameLabel = NSTextField()
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        
        // Icon
        iconImageView.image = suggestion.icon
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        // Name label
        nameLabel.stringValue = suggestion.name
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.isBordered = false
        nameLabel.isEditable = false
        nameLabel.drawsBackground = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
        
        // Click handling
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(viewClicked))
        addGestureRecognizer(clickGesture)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.8).cgColor
            nameLabel.textColor = NSColor.selectedMenuItemTextColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            nameLabel.textColor = NSColor.labelColor
        }
    }
    
    @objc private func viewClicked() {
        print("🎯 View clicked via gesture recognizer")
        onClicked?()
    }
    
    override func mouseDown(with event: NSEvent) {
        print("🖱️ Mouse down in suggestion view")
        onClicked?()
        super.mouseDown(with: event)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        updateAppearance()
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
}