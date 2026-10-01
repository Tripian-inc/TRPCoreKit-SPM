import UIKit
import TRPBookingKit

/// Hosts a provider's card form. Closing the screen cancels the payment.
final class HostedFormPaymentViewController: BookingBaseViewController {

    private let session: ViatorPaymentWebSession

    init(session: ViatorPaymentWebSession, theme: TRPBookingTheme, text: TRPBookingText) {
        self.session = session
        super.init(theme: theme, text: text)
        title = text(.paymentTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        BookingWebScreen.embed(session.webView, in: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            session.cancel()
        }
    }
}

/// Runs `provider_hosted_form`: shows the card form page and answers with the payment token it reports.
@MainActor
final class HostedFormActionPresenter: NextActionPresenter {

    let type = BookingContract.NextActionType.providerHostedForm.rawValue
    private let pageURL: URL
    private let lang: String
    private let theme: TRPBookingTheme
    private let text: TRPBookingText

    init(pageURL: URL, lang: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.pageURL = pageURL
        self.lang = lang
        self.theme = theme
        self.text = text
    }

    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        guard case .providerHostedForm(let payload) = action else { return .unsupported(reason: action.typeRawValue) }
        let session = ViatorPaymentWebSession(paymentPageURL: pageURL, languageCode: lang)
        let screen = HostedFormPaymentViewController(session: session, theme: theme, text: text)
        let anchor = navigationController.topViewController
        navigationController.pushViewController(screen, animated: true)
        defer {
            session.invalidate()
            if navigationController.topViewController === screen, let anchor {
                navigationController.popToViewController(anchor, animated: true)
            }
        }
        do {
            return .result(.paymentToken(try await session.paymentToken(sessionToken: payload.params.paymentSessionToken)))
        } catch BookingError.paymentCancelled {
            return .result(.status(.canceled))
        } catch {
            return .failed(error)
        }
    }
}

/// Lays a web view out under a screen's safe area.
enum BookingWebScreen {

    static func embed(_ webView: UIView, in viewController: UIViewController) {
        let view: UIView = viewController.view
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
