import UIKit

/// Colours and fonts of the booking screens; the host passes its own to match the app.
public struct TRPBookingTheme {

    public var primary: UIColor
    public var onPrimary: UIColor
    public var background: UIColor
    public var surface: UIColor
    public var text: UIColor
    public var secondaryText: UIColor
    public var separator: UIColor
    public var success: UIColor
    public var warning: UIColor
    public var error: UIColor
    /// Returns the font for a weight and point size, e.g. the host's brand typeface.
    public var font: (UIFont.Weight, CGFloat) -> UIFont

    public init(primary: UIColor = .systemBlue,
                onPrimary: UIColor = .white,
                background: UIColor = .systemGroupedBackground,
                surface: UIColor = .secondarySystemGroupedBackground,
                text: UIColor = .label,
                secondaryText: UIColor = .secondaryLabel,
                separator: UIColor = .separator,
                success: UIColor = .systemGreen,
                warning: UIColor = .systemOrange,
                error: UIColor = .systemRed,
                font: @escaping (UIFont.Weight, CGFloat) -> UIFont = { UIFont.systemFont(ofSize: $1, weight: $0) }) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.background = background
        self.surface = surface
        self.text = text
        self.secondaryText = secondaryText
        self.separator = separator
        self.success = success
        self.warning = warning
        self.error = error
        self.font = font
    }

    var title: UIFont { font(.semibold, 20) }
    var headline: UIFont { font(.semibold, 16) }
    var body: UIFont { font(.regular, 16) }
    var caption: UIFont { font(.regular, 13) }
}
