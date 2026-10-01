import UIKit

/// Shown while the server confirms a payment or a booking; offers a status refresh once polling gives up.
final class CheckoutProcessingViewController: BookingBaseViewController {

    var onRefresh: (() -> Void)?

    private let spinner = UIActivityIndicatorView(style: .large)
    private lazy var messageLabel = makeLabel(theme.body, color: theme.text)
    private lazy var refreshButton = BookingPrimaryButton(theme: theme, title: text(.refreshStatus))

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        spinner.color = theme.primary
        spinner.startAnimating()
        messageLabel.textAlignment = .center
        messageLabel.text = text(.processing)
        refreshButton.isHidden = true
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        let column = UIStackView(arrangedSubviews: [spinner, messageLabel, refreshButton])
        column.axis = .vertical
        column.spacing = 20
        column.alignment = .fill
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)
        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    /// Stops the spinner and offers a refresh, used when the server is still confirming after polling stopped.
    func showAwaitingConfirmation() {
        loadViewIfNeeded()
        spinner.stopAnimating()
        messageLabel.text = text(.awaitingConfirmation)
        refreshButton.isHidden = false
    }

    @objc private func refreshTapped() {
        spinner.startAnimating()
        messageLabel.text = text(.processing)
        refreshButton.isHidden = true
        onRefresh?()
    }
}

/// Shown when the client cannot render the checkout: the server's text and, when given, a way to finish on the web.
final class CheckoutFallbackViewController: BookingBaseViewController {

    var onOpenWeb: ((URL) -> Void)?
    var onCancel: (() -> Void)?
    var onDone: (() -> Void)?

    private let message: String
    private let webURL: URL?
    private let canCancel: Bool

    init(message: String, webURL: URL?, canCancel: Bool, theme: TRPBookingTheme, text: TRPBookingText) {
        self.message = message
        self.webURL = webURL
        self.canCancel = canCancel
        super.init(theme: theme, text: text)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        let layout = BookingScrollLayout()
        layout.install(in: view, theme: theme)
        let label = makeLabel(theme.body, color: theme.text)
        label.text = message
        layout.stack.addArrangedSubview(BookingScrollLayout.card([label], theme: theme))
        if webURL != nil {
            let web = BookingPrimaryButton(theme: theme, title: text(.continueOnWeb))
            web.addTarget(self, action: #selector(openWeb), for: .touchUpInside)
            layout.footer.addArrangedSubview(web)
        }
        if canCancel {
            layout.footer.addArrangedSubview(secondary(text(.cancelBooking), action: #selector(cancelTapped)))
        }
        layout.footer.addArrangedSubview(secondary(text(.done), action: #selector(doneTapped)))
    }

    private func secondary(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = theme.body
        button.tintColor = theme.primary
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func openWeb() {
        if let webURL { onOpenWeb?(webURL) }
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func doneTapped() {
        onDone?()
    }
}
