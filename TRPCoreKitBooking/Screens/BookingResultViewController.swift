import UIKit

/// How a booking attempt ended.
enum BookingOutcomeKind {
    case success
    case pending
    case failure
}

/// The closing screen of a booking: confirmed, waiting on the provider, or failed.
final class BookingResultViewController: BookingBaseViewController {

    var onDone: (() -> Void)?

    private let kind: BookingOutcomeKind
    private let headline: String
    private let message: String
    private let rows: [BookingSummaryRow]
    private let voucherURL: URL?
    private let layout = BookingScrollLayout()

    init(kind: BookingOutcomeKind, title: String, message: String, rows: [BookingSummaryRow] = [], voucherURL: URL? = nil,
         theme: TRPBookingTheme, text: TRPBookingText) {
        self.kind = kind
        self.headline = title
        self.message = message
        self.rows = rows
        self.voucherURL = voucherURL
        super.init(theme: theme, text: text)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        layout.install(in: view, theme: theme)

        let icon = UIImageView(image: UIImage(systemName: symbolName))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        icon.isAccessibilityElement = false
        let titleLabel = makeLabel(theme.title, color: theme.text)
        titleLabel.text = headline
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header
        let messageLabel = makeLabel(theme.body, color: theme.secondaryText)
        messageLabel.text = message
        messageLabel.textAlignment = .center
        let header = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel])
        header.axis = .vertical
        header.spacing = 12
        header.alignment = .fill
        layout.stack.addArrangedSubview(header)
        if !rows.isEmpty {
            layout.stack.addArrangedSubview(BookingScrollLayout.card([BookingKeyValueView(rows: rows, theme: theme)], theme: theme))
        }

        if voucherURL != nil {
            let voucher = UIButton(type: .system)
            voucher.setTitle(text(.voucher), for: .normal)
            voucher.titleLabel?.font = theme.headline
            voucher.tintColor = theme.primary
            voucher.addTarget(self, action: #selector(openVoucher), for: .touchUpInside)
            layout.footer.addArrangedSubview(voucher)
        }
        let done = BookingPrimaryButton(theme: theme, title: text(.done))
        done.addTarget(self, action: #selector(finish), for: .touchUpInside)
        layout.footer.addArrangedSubview(done)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: headline)
    }

    private var symbolName: String {
        switch kind {
        case .success: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    private var color: UIColor {
        switch kind {
        case .success: return theme.success
        case .pending: return theme.warning
        case .failure: return theme.error
        }
    }

    @objc private func openVoucher() {
        guard let voucherURL else { return }
        UIApplication.shared.open(voucherURL)
    }

    @objc private func finish() {
        onDone?()
    }
}
