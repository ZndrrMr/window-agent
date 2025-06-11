import Cocoa

// MARK: - App Token View
class AppTokenView: NSView {
    private let appSuggestion: AppSuggestion
    private let iconImageView: NSImageView
    private let nameLabel: NSTextField
    
    private let cornerRadius: CGFloat = 8
    private let padding: CGFloat = 8
    private let iconSize: CGFloat = 20
    private let iconSpacing: CGFloat = 6
    
    init(appSuggestion: AppSuggestion) {
        self.appSuggestion = appSuggestion
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
        
        // Beautiful soft-edged box styling
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
        layer?.cornerRadius = cornerRadius
        layer?.cornerCurve = .continuous
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
        
        // Subtle shadow for depth
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.1
        layer?.shadowOffset = CGSize(width: 0, height: 1)
        layer?.shadowRadius = 2
        
        // Setup icon
        iconImageView.image = appSuggestion.icon
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        // Setup name label
        nameLabel.stringValue = appSuggestion.name
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = NSColor.controlAccentColor
        nameLabel.isBordered = false
        nameLabel.isEditable = false
        nameLabel.drawsBackground = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Icon positioning
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),
            
            // Name label positioning
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: iconSpacing),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            
            // Overall height
            heightAnchor.constraint(equalToConstant: iconSize + padding * 2)
        ])
    }
    
    // Calculate the intrinsic content size for proper layout
    override var intrinsicContentSize: NSSize {
        let nameSize = nameLabel.intrinsicContentSize
        let width = padding + iconSize + iconSpacing + nameSize.width + padding
        let height = iconSize + padding * 2
        return NSSize(width: width, height: height)
    }
}