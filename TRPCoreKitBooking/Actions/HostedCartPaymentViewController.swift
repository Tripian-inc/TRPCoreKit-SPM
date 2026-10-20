import UIKit
import WebKit
import TRPBookingKit

/// Shows a provider's hosted cart page and owns the polling behind it, which stops when the screen closes or goes away.
///
/// A page whose outcome is not polled shows a Done button and calls `onLeave` once when the customer leaves it.
final class HostedCartPaymentViewController: BookingBaseViewController, WKUIDelegate {

    var polling: Task<HostedCartSettlementPoller.Outcome, Never>?
    /// Called once, when the screen is popped, dismissed or otherwise taken out of the window.
    var onLeave: (() -> Void)?
    private let pageURL: URL
    private let webView: WKWebView
    private let showsDoneButton: Bool

    init(pageURL: URL, showsDoneButton: Bool = false, theme: TRPBookingTheme, text: TRPBookingText) {
        self.pageURL = pageURL
        self.showsDoneButton = showsDoneButton
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(theme: theme, text: text)
        title = text(.paymentTitle)
    }

    deinit {
        polling?.cancel()
        onLeave?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        BookingWebScreen.embed(webView, in: self)
        if showsDoneButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: text(.hostedCheckoutDone), style: .done,
                                                                target: self, action: #selector(done))
        }
        webView.load(URLRequest(url: pageURL))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if hasLeftTheScreen {
            webView.stopLoading()
            polling?.cancel()
            reportLeaving()
        }
    }

    private func reportLeaving() {
        let onLeave = onLeave
        self.onLeave = nil
        onLeave?()
    }

    @objc private func done() {
        navigationController?.popViewController(animated: true)
    }

    /// Whether the screen was popped, dismissed or otherwise taken out of the window, so its cart can no longer be paid.
    private var hasLeftTheScreen: Bool {
        isMovingFromParent || isBeingDismissed || navigationController == nil
            || navigationController?.isBeingDismissed == true || viewIfLoaded?.window == nil
    }

    /// Opens a page the cart wants in a new window in the same web view, so a payment step stays on screen.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }
}

/// Asks the checkout whether the payment behind a hosted cart action has settled.
public typealias HostedCartSettlement = @MainActor (_ actionId: String) async throws -> BookingContract.ActionSettlement

/// Polls a hosted cart action's settlement until the provider settles it, the action expires or the task is cancelled.
///
/// A thrown error is retried on the next poll unless it is a contract error the server marked not retryable.
@MainActor
struct HostedCartSettlementPoller {

    /// How the polling ended.
    enum Outcome {
        case succeeded
        case declined(reason: String?)
        case failed(Error)
        case expired
        case cancelled
    }

    let settlement: () async throws -> BookingContract.ActionSettlement
    let interval: TimeInterval
    let expiresAt: Date?
    var now: () -> Date = { Date() }
    var sleep: (TimeInterval) async throws -> Void = { try await Task.sleep(nanoseconds: UInt64(max($0, 0) * 1_000_000_000)) }

    func run() async -> Outcome {
        while !Task.isCancelled {
            if let expiresAt, now() >= expiresAt { return .expired }
            do {
                switch try await settlement() {
                case .succeeded: return .succeeded
                case .failed(let reason): return .declined(reason: reason)
                case .pending: break
                }
            } catch let error as BookingContract.ContractError where !error.data.retryable && error.httpStatus < 500 {
                return .failed(error)
            } catch {
                guard !Task.isCancelled else { return .cancelled }
            }
            do {
                try await sleep(interval)
            } catch {
                return .cancelled
            }
        }
        return .cancelled
    }
}

/// Runs `provider_hosted_cart`: shows the provider's cart page and polls the checkout until the cart is paid.
///
/// The page reports nothing back, so a paid cart answers `.status(.succeeded)`. Anything else answers
/// `.status(.canceled)`, so the checkout releases the cart instead of the action being run again; when the page
/// closed on its own the customer is told why.
///
/// A cart whose settlement is `handOff` is not polled: leaving its page answers `.status(.handedOff)` without a notice.
@MainActor
final class HostedCartActionPresenter: NextActionPresenter {

    let type = BookingContract.NextActionType.providerHostedCart.rawValue
    private let settlement: HostedCartSettlement
    private let theme: TRPBookingTheme
    private let text: TRPBookingText

    init(settlement: @escaping HostedCartSettlement, theme: TRPBookingTheme, text: TRPBookingText) {
        self.settlement = settlement
        self.theme = theme
        self.text = text
    }

    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        guard case .providerHostedCart(let payload) = action, let pageURL = URL(string: payload.params.url) else {
            return .unsupported(reason: action.typeRawValue)
        }
        if payload.params.settlement == .handOff {
            return await handOff(to: pageURL, on: navigationController)
        }
        let settlement = settlement
        let poller = HostedCartSettlementPoller(settlement: { try await settlement(payload.id) },
                                                interval: TimeInterval(max(payload.params.pollIntervalSeconds, 1)),
                                                expiresAt: CheckoutDeadline.date(from: payload.expiresAt))
        let polling = Task { await poller.run() }
        weak var anchor = navigationController.topViewController
        weak var navigation = navigationController
        weak var screen = pushScreen(pageURL: pageURL, polling: polling, on: navigationController)
        let outcome = await polling.value
        if let navigation, let screen, navigation.topViewController === screen, let anchor {
            navigation.popToViewController(anchor, animated: true)
        }
        if let navigation, let notice = notice(for: outcome) {
            showNotice(notice, on: navigation)
        }
        return self.outcome(of: outcome)
    }

    /// Shows a page the checkout does not poll and answers `.status(.handedOff)` once the customer leaves it.
    func handOff(to pageURL: URL, on navigationController: UINavigationController) async -> NextActionOutcome {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let screen = HostedCartPaymentViewController(pageURL: pageURL, showsDoneButton: true, theme: theme, text: text)
            screen.onLeave = { continuation.resume() }
            navigationController.pushViewController(screen, animated: true)
        }
        return .result(.status(.handedOff))
    }

    /// Pushes the cart page that owns `polling`; the caller keeps no strong reference, so a closed page is released.
    private func pushScreen(pageURL: URL, polling: Task<HostedCartSettlementPoller.Outcome, Never>,
                            on navigationController: UINavigationController) -> HostedCartPaymentViewController {
        let screen = HostedCartPaymentViewController(pageURL: pageURL, theme: theme, text: text)
        screen.polling = polling
        navigationController.pushViewController(screen, animated: true)
        return screen
    }

    /// The presenter's answer for how the polling ended: `succeeded` for a paid cart, `canceled` for anything else.
    func outcome(of polled: HostedCartSettlementPoller.Outcome) -> NextActionOutcome {
        switch polled {
        case .succeeded: return .result(.status(.succeeded))
        case .declined, .failed, .expired, .cancelled: return .result(.status(.canceled))
        }
    }

    /// Why the cart page closed on its own, or nil when it was paid or the customer closed it.
    func notice(for polled: HostedCartSettlementPoller.Outcome) -> String? {
        switch polled {
        case .declined, .expired: return text(.holdExpired)
        case .failed(let error): return BookingErrorMessage(text: text).message(for: error)
        case .succeeded, .cancelled: return nil
        }
    }

    private func showNotice(_ message: String, on navigationController: UINavigationController) {
        let alert = UIAlertController(title: text(.errorTitle), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: text(.close), style: .cancel))
        (navigationController.presentedViewController ?? navigationController).present(alert, animated: true)
    }
}
