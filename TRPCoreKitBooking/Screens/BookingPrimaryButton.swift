import UIKit

/// The full-width call to action at the bottom of a booking screen.
final class BookingPrimaryButton: UIButton {

    private let theme: TRPBookingTheme

    init(theme: TRPBookingTheme, title: String) {
        self.theme = theme
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(theme.onPrimary, for: .normal)
        setTitleColor(theme.onPrimary.withAlphaComponent(0.6), for: .disabled)
        titleLabel?.font = theme.headline
        titleLabel?.adjustsFontForContentSizeCategory = true
        backgroundColor = theme.primary
        layer.cornerRadius = 12
        contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isEnabled: Bool {
        didSet { backgroundColor = isEnabled ? theme.primary : theme.secondaryText }
    }
}

/// A scrolling column with a pinned button bar, the layout every booking form and summary uses.
final class BookingScrollLayout {

    let scrollView = UIScrollView()
    let stack = UIStackView()
    let footer = UIStackView()

    func install(in view: UIView, theme: TRPBookingTheme) {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        footer.axis = .vertical
        footer.spacing = 8
        footer.translatesAutoresizingMaskIntoConstraints = false

        let bar = UIView()
        bar.backgroundColor = theme.background
        bar.translatesAutoresizingMaskIntoConstraints = false
        let hairline = UIView()
        hairline.backgroundColor = theme.separator
        hairline.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        view.addSubview(bar)
        bar.addSubview(hairline)
        bar.addSubview(footer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bar.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),

            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hairline.topAnchor.constraint(equalTo: bar.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            footer.topAnchor.constraint(equalTo: bar.topAnchor, constant: 12),
            footer.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            footer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuideCompat.topAnchor, constant: -12)
        ])
    }

    /// A rounded card holding `views`, one under the other.
    static func card(_ views: [UIView], theme: TRPBookingTheme) -> UIView {
        let card = UIView()
        card.backgroundColor = theme.surface
        card.layer.cornerRadius = 12
        let column = UIStackView(arrangedSubviews: views)
        column.axis = .vertical
        column.spacing = 12
        column.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(column)
        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            column.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            column.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            column.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])
        return card
    }
}

extension UIView {

    /// The keyboard layout guide on iOS 15 and later, the safe area before it.
    var keyboardLayoutGuideCompat: UILayoutGuide {
        if #available(iOS 15.0, *) {
            return keyboardLayoutGuide
        }
        return safeAreaLayoutGuide
    }
}
