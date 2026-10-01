import UIKit
import SafariServices
import TRPBookingKit

/// Tells the host how a checkout ended.
@MainActor
public protocol TRPBookingCoordinatorDelegate: AnyObject {
    /// `checkout` is the last checkout the server returned, or nil when the customer left before one was created.
    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didFinishWith checkout: BookingContract.Checkout?)
}

/// Presents the server-driven checkout for any provider, and the customer's bookings.
///
/// Every screen is rendered from the steps and next actions the booking contract returns; nothing here knows a provider.
@MainActor
public final class TRPBookingCoordinator: NSObject {

    public weak var delegate: TRPBookingCoordinatorDelegate?
    /// Decides which blocks and fields render natively; anything else goes to the server's fallback.
    public var blocks: BlockRegistry
    /// Runs the checkout's next actions; an action without a presenter goes to the fallback.
    public var actions: NextActionRegistry

    private let checkoutClient: CheckoutClient
    private let bookingClient: BookingClient
    private let lang: String
    private let currency: String
    private let theme: TRPBookingTheme
    private let text: TRPBookingText
    private var session: CheckoutSession?
    private var runningActionId: String?
    private var openedWebURLs: Set<URL> = []
    private var refreshesOnSafariClose = false
    private weak var presented: UINavigationController?
    private weak var bookingsNavigation: UINavigationController?
    private let closeButtonKeeper = BookingCloseButtonKeeper()

    public init(checkout: CheckoutClient, bookings: BookingClient, payments: BookingPaymentPresenters = BookingPaymentPresenters(),
                lang: String, currency: String, theme: TRPBookingTheme = TRPBookingTheme(), text: TRPBookingText = TRPBookingText()) {
        checkoutClient = checkout
        bookingClient = bookings
        self.lang = lang
        self.currency = currency
        self.theme = theme
        self.text = text
        blocks = .standard
        actions = .standard(payments: payments, lang: lang, theme: theme, text: text)
        super.init()
    }

    /// What this client renders, in the form of the contract's capabilities header.
    public var capabilities: String {
        BookingCapabilities.header(blocks: blocks, actions: actions.supportedTypes)
    }

    /// Presents the checkout modally. `date` (`yyyy-MM-dd`) is the day the customer is planning, if any.
    /// Returns false when a checkout is already on screen.
    @discardableResult
    public func start(productId: String, optionId: String? = nil, date: String? = nil, title: String,
                      from presenter: UIViewController) -> Bool {
        guard session == nil else { return false }
        let session = CheckoutSession(client: checkoutClient, lang: lang, currency: currency, registry: blocks)
        session.onChange = { [weak self] state in self?.render(state) }
        session.onIssue = { [weak self] issue in self?.handle(issue) }
        self.session = session
        openedWebURLs = []
        let root = BookingBaseViewController(theme: theme, text: text)
        root.title = title
        let navigationController = makeNavigationController(root: root)
        presenter.present(navigationController, animated: true)
        let bookingUuid = UUID().uuidString.lowercased()
        Task { await session.start(productId: productId, optionId: optionId, date: date, bookingUuid: bookingUuid) }
        return true
    }

    /// Presents the customer's bookings, where a booking's details, vouchers and cancellation live.
    public func showBookings(from presenter: UIViewController) {
        let list = BookingListViewController(client: bookingClient, lang: lang, theme: theme, text: text)
        list.title = text(.myBookingsTitle)
        let navigationController = UINavigationController(rootViewController: list)
        list.navigationItem.leftBarButtonItem = UIBarButtonItem(title: text(.close), style: .plain, target: self,
                                                                action: #selector(closeBookings))
        bookingsNavigation = navigationController
        presenter.present(navigationController, animated: true)
    }

    private var top: BookingBaseViewController? {
        presented?.topViewController as? BookingBaseViewController
    }

    private func render(_ state: CheckoutSession.State) {
        guard let session, let navigationController = presented else { return }
        if case .loading = state {
            top?.setLoading(true)
            return
        }
        navigationController.viewControllers.compactMap { $0 as? BookingBaseViewController }.forEach { $0.setLoading(false) }
        switch state {
        case .idle, .loading:
            break
        case .step(let step, let checkout):
            if let current = navigationController.topViewController as? CheckoutStepViewController, current.step == step { return }
            show(makeStepScreen(step: step, checkout: checkout, session: session))
        case .action(let action, _):
            run(action, session: session)
        case .processing:
            guard !(navigationController.topViewController is CheckoutProcessingViewController) else { return }
            let screen = CheckoutProcessingViewController(theme: theme, text: text)
            screen.title = navigationController.viewControllers.first?.title
            screen.onRefresh = { Task { await session.refresh() } }
            show(screen)
        case .finished(let checkout):
            show(makeResultScreen(for: checkout))
        case .fallback(let fallback, _):
            show(makeFallbackScreen(fallback, session: session))
        }
    }

    private func show(_ screen: UIViewController) {
        guard let navigationController = presented else { return }
        if screen.title == nil { screen.title = navigationController.viewControllers.first?.title }
        navigationController.setViewControllers([screen], animated: true)
        closeButtonKeeper.attach(to: screen)
    }

    private func makeStepScreen(step: BookingContract.Step, checkout: BookingContract.Checkout,
                                session: CheckoutSession) -> CheckoutStepViewController {
        let screen = CheckoutStepViewController(step: step, layout: blocks.layout(for: step), checkout: checkout,
                                                canGoBack: session.canGoBack, canExtend: session.canExtend,
                                                now: { [weak session] in session?.now ?? Date() }, theme: theme, text: text)
        screen.onSubmit = { answers in Task { await session.submit(answers: answers) } }
        screen.onBack = { Task { await session.back() } }
        screen.onExtend = { Task { await session.extend() } }
        screen.onDeadline = { Task { await session.refresh() } }
        screen.onOpenURL = { [weak self] url in self?.openInSafari(url, refreshOnClose: false) }
        return screen
    }

    private func makeResultScreen(for checkout: BookingContract.Checkout) -> BookingResultViewController {
        let kind: BookingOutcomeKind
        switch checkout.status.value {
        case .confirmed: kind = .success
        case .pending: kind = .pending
        default: kind = .failure
        }
        var rows: [BookingSummaryRow] = []
        rows.append(BookingSummaryRow(title: checkout.product.title, value: ""))
        if let amount = BookingFormatting().price(checkout.amount) { rows.append(BookingSummaryRow(title: text(.total), value: amount)) }
        if let uuid = checkout.booking?.uuid ?? checkout.result?.bookingUuid {
            rows.append(BookingSummaryRow(title: text(.reference), value: uuid))
        }
        let screen = BookingResultViewController(kind: kind, title: checkout.result?.title ?? defaultTitle(for: kind),
                                                 message: checkout.result?.message ?? defaultMessage(for: kind),
                                                 rows: rows, theme: theme, text: text)
        screen.onDone = { [weak self] in self?.finish(with: checkout) }
        return screen
    }

    private func defaultTitle(for kind: BookingOutcomeKind) -> String {
        switch kind {
        case .success: return text(.successTitle)
        case .pending: return text(.pendingTitle)
        case .failure: return text(.failureTitle)
        }
    }

    private func defaultMessage(for kind: BookingOutcomeKind) -> String {
        switch kind {
        case .success: return text(.successMessage)
        case .pending: return text(.pendingMessage)
        case .failure: return text(.unavailable)
        }
    }

    private func makeFallbackScreen(_ fallback: BookingContract.Fallback?, session: CheckoutSession) -> CheckoutFallbackViewController {
        let webURL = fallback?.webUrl.flatMap(URL.init(string:))
        let screen = CheckoutFallbackViewController(message: fallback?.text ?? text(.unavailable), webURL: webURL,
                                                    canCancel: session.canCancel, theme: theme, text: text)
        screen.onOpenWeb = { [weak self] url in self?.openInSafari(url, refreshOnClose: session.checkout != nil) }
        screen.onCancel = { Task { await session.cancel() } }
        screen.onDone = { [weak self] in self?.finish(with: session.checkout) }
        if let webURL, !openedWebURLs.contains(webURL) {
            openedWebURLs.insert(webURL)
            DispatchQueue.main.async { [weak self] in self?.openInSafari(webURL, refreshOnClose: session.checkout != nil) }
        }
        return screen
    }

    private func run(_ action: BookingContract.NextAction, session: CheckoutSession) {
        guard let navigationController = presented, runningActionId != action.id else { return }
        guard let presenter = actions.presenter(for: action) else {
            session.fallBack(reason: "action:\(action.typeRawValue)")
            return
        }
        runningActionId = action.id
        top?.setLoading(true)
        Task { [weak self] in
            let outcome = await presenter.present(action, on: navigationController)
            guard let self else { return }
            self.runningActionId = nil
            self.top?.setLoading(false)
            switch outcome {
            case .result(let result):
                await session.complete(action: action, result: result)
            case .unsupported(let reason):
                session.fallBack(reason: reason)
            case .failed(let error):
                self.top?.show(error) { [weak self] in self?.run(action, session: session) }
            }
        }
    }

    private func handle(_ issue: CheckoutSession.Issue) {
        guard let session else { return }
        switch issue {
        case .fieldIssues(let errors):
            (top as? CheckoutStepViewController)?.show(fieldErrors: errors)
        case .conflict(let code):
            top?.show(message: message(for: code))
        case .paymentDeclined:
            top?.show(message: text(.paymentDeclined))
        case .unavailable:
            top?.show(message: text(.unavailable), retry: session.canRetry ? { Task { await session.retry() } } : nil)
        case .awaitingConfirmation:
            (top as? CheckoutProcessingViewController)?.showAwaitingConfirmation()
        }
    }

    private func message(for code: BookingContract.ErrorCode) -> String {
        switch code {
        case .priceChanged: return text(.priceChanged)
        case .holdExpired: return text(.holdExpired)
        case .soldOut: return text(.soldOutMessage)
        case .notCancellable: return text(.notCancellable)
        case .stepMismatch: return text(.stepChanged)
        default: return text(.unavailable)
        }
    }

    private func openInSafari(_ url: URL, refreshOnClose: Bool) {
        guard let navigationController = presented, ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return }
        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        safari.preferredControlTintColor = theme.primary
        refreshesOnSafariClose = refreshOnClose
        (navigationController.presentedViewController ?? navigationController).present(safari, animated: true)
    }

    private func makeNavigationController(root: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.isModalInPresentation = true
        closeButtonKeeper.makeItem = { [weak self] in
            guard let self else { return nil }
            return UIBarButtonItem(title: self.text(.close), style: .plain, target: self, action: #selector(self.confirmLeaving))
        }
        navigationController.delegate = closeButtonKeeper
        closeButtonKeeper.attach(to: root)
        presented = navigationController
        return navigationController
    }

    @objc private func confirmLeaving() {
        guard let presented else { return }
        let alert = UIAlertController(title: text(.leaveTitle), message: text(.leaveMessage), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: text(.stay), style: .cancel))
        alert.addAction(UIAlertAction(title: text(.leaveConfirm), style: .destructive) { [weak self] _ in
            self?.leave()
        })
        (presented.presentedViewController ?? presented).present(alert, animated: true)
    }

    private func leave() {
        guard let session else { return finish(with: nil) }
        let checkout = session.checkout
        session.onChange = nil
        session.onIssue = nil
        if session.canCancel { Task { await session.cancel() } }
        finish(with: checkout)
    }

    @objc private func closeBookings() {
        bookingsNavigation?.dismiss(animated: true)
    }

    private func finish(with checkout: BookingContract.Checkout?) {
        let navigationController = presented
        session?.onChange = nil
        session?.onIssue = nil
        session = nil
        runningActionId = nil
        navigationController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.bookingCoordinator(self, didFinishWith: checkout)
        }
    }
}

extension TRPBookingCoordinator: SFSafariViewControllerDelegate {

    nonisolated public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        Task { @MainActor [weak self] in
            guard let self, self.refreshesOnSafariClose, let session = self.session else { return }
            self.refreshesOnSafariClose = false
            await session.refresh()
        }
    }
}

/// Keeps the close button on whichever screen is at the bottom of the stack, except the result screen.
@MainActor
private final class BookingCloseButtonKeeper: NSObject, UINavigationControllerDelegate {

    var makeItem: (() -> UIBarButtonItem?)?

    func attach(to screen: UIViewController) {
        guard !(screen is BookingResultViewController), screen.navigationItem.leftBarButtonItem == nil else { return }
        screen.navigationItem.leftBarButtonItem = makeItem?()
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard viewController === navigationController.viewControllers.first else { return }
        attach(to: viewController)
    }
}
