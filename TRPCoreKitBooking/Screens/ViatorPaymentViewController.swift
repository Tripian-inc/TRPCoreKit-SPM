import UIKit
import TRPBookingKit

/// Hosts Viator's card form. Closing the screen cancels the payment.
final class ViatorPaymentViewController: BookingBaseViewController {

    private let session: ViatorPaymentWebSession

    init(session: ViatorPaymentWebSession, theme: TRPBookingTheme, text: TRPBookingText) {
        self.session = session
        super.init(theme: theme, text: text)
        title = text(.paymentTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = session.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            session.cancel()
        }
    }
}

/// Shows Viator's card form on the booking navigation stack and hands the payment token back.
final class ViatorPaymentPresenter: ViatorPaymentTokenProviding, @unchecked Sendable {

    private weak var navigationController: UINavigationController?
    private let credentials: ViatorCredentials
    private let languageCode: String
    private let theme: TRPBookingTheme
    private let text: TRPBookingText

    init(navigationController: UINavigationController, credentials: ViatorCredentials, languageCode: String,
         theme: TRPBookingTheme, text: TRPBookingText) {
        self.navigationController = navigationController
        self.credentials = credentials
        self.languageCode = languageCode
        self.theme = theme
        self.text = text
    }

    func paymentToken(for hold: ViatorCheckoutHold) async throws -> String {
        try await present(sessionToken: hold.paymentSessionToken)
    }

    @MainActor
    private func present(sessionToken: String) async throws -> String {
        guard let navigationController else { throw BookingError.paymentCancelled }
        let session = ViatorPaymentWebSession(credentials: credentials, languageCode: languageCode)
        let screen = ViatorPaymentViewController(session: session, theme: theme, text: text)
        let anchor = navigationController.topViewController
        navigationController.pushViewController(screen, animated: true)
        defer {
            session.invalidate()
            if navigationController.topViewController === screen, let anchor {
                navigationController.popToViewController(anchor, animated: true)
            }
        }
        return try await session.paymentToken(sessionToken: sessionToken)
    }
}
