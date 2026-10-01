import UIKit
import TRPBookingKit

/// Shared chrome of the booking screens: theme, text, a loading overlay and error alerts.
class BookingBaseViewController: UIViewController {

    let theme: TRPBookingTheme
    let text: TRPBookingText
    private var loadingView: UIView?

    init(theme: TRPBookingTheme, text: TRPBookingText) {
        self.theme = theme
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.background
        navigationItem.backButtonTitle = ""
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            guard loadingView == nil else { return }
            let overlay = UIView()
            overlay.backgroundColor = theme.background.withAlphaComponent(0.6)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = theme.primary
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            indicator.accessibilityLabel = text(.loading)
            overlay.addSubview(indicator)
            view.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])
            loadingView = overlay
            view.isUserInteractionEnabled = false
            navigationItem.hidesBackButton = true
        } else {
            loadingView?.removeFromSuperview()
            loadingView = nil
            view.isUserInteractionEnabled = true
            navigationItem.hidesBackButton = false
        }
    }

    /// Shows the error; `retry` adds a button that runs it.
    func show(_ error: Error, retry: (() -> Void)? = nil) {
        show(message: BookingErrorMessage(text: text).message(for: error), retry: retry)
    }

    func show(message: String, retry: (() -> Void)? = nil) {
        let alert = UIAlertController(title: text(.errorTitle), message: message, preferredStyle: .alert)
        if let retry {
            alert.addAction(UIAlertAction(title: text(.retry), style: .default) { _ in retry() })
            alert.addAction(UIAlertAction(title: text(.cancel), style: .cancel))
        } else {
            alert.addAction(UIAlertAction(title: text(.close), style: .cancel))
        }
        present(alert, animated: true)
    }

    func makeLabel(_ font: UIFont, color: UIColor, lines: Int = 0) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}

/// Turns a contract error, or a failure to reach the server, into text for the customer.
struct BookingErrorMessage {

    let text: TRPBookingText

    func message(for error: Error) -> String {
        guard let contractError = error as? BookingContract.ContractError else { return text(.unavailable) }
        switch contractError.code {
        case .priceChanged: return text(.priceChanged)
        case .holdExpired: return text(.holdExpired)
        case .soldOut: return text(.soldOutMessage)
        case .stepMismatch: return text(.stepChanged)
        case .paymentDeclined: return text(.paymentDeclined)
        case .notCancellable: return text(.notCancellable)
        case .inProgress: return text(.awaitingConfirmation)
        case .validation, .supplierUnavailable, .idempotencyMismatch, .versionUnsupported, .unknown: return text(.unavailable)
        }
    }
}
