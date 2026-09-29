import UIKit
import TRPBookingKit

/// Tells the host how a checkout ended.
@MainActor
public protocol TRPBookingCoordinatorDelegate: AnyObject {
    /// `record` is the stored booking, or nil when the customer left before anything was booked.
    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didFinishWith record: BookingRecord?)
}

/// Presents the native checkout for a tour-api activity and the list of the customer's bookings.
@MainActor
public final class TRPBookingCoordinator {

    public weak var delegate: TRPBookingCoordinatorDelegate?

    private let booking: TRPBooking
    private let victoryPayment: PaymentNonceProviding?
    private let theme: TRPBookingTheme
    private let text: TRPBookingText
    private var flow: BookingFlow?
    private weak var presented: UINavigationController?
    private let closeButtonKeeper = BookingCloseButtonKeeper()

    /// `victoryPayment` supplies the Braintree nonce Ticket Evolution charges; without it Victory events cannot be booked.
    public init(booking: TRPBooking, victoryPayment: PaymentNonceProviding? = nil,
                theme: TRPBookingTheme = TRPBookingTheme(), text: TRPBookingText = TRPBookingText()) {
        self.booking = booking
        self.victoryPayment = victoryPayment
        self.theme = theme
        self.text = text
    }

    /// Whether `start` can open a native checkout for the activity; otherwise the host should fall back to its web flow.
    public func canStart(activityId: String) -> Bool {
        guard booking.canBook(activityId: activityId), let activity = try? booking.activity(for: activityId) else { return false }
        switch activity {
        case .toristy: return booking.toristy != nil
        case .viator: return booking.viator != nil && booking.configuration.viator != nil
        case .victory: return booking.victory != nil && victoryPayment != nil
        }
    }

    /// Presents the checkout modally; `date` is the day the customer is planning, used as the first choice when bookable.
    @discardableResult
    public func start(activityId: String, title: String, date: Date, from presenter: UIViewController) -> Bool {
        guard canStart(activityId: activityId), let activity = try? booking.activity(for: activityId) else { return false }
        let root = BookingBaseViewController(theme: theme, text: text)
        root.title = title
        let navigationController = makeNavigationController(root: root)
        let context = BookingFlowContext(booking: booking, navigationController: navigationController, theme: theme, text: text,
                                         activityId: activityId, title: title, date: date) { [weak self] reference in
            self?.finish(with: reference)
        }
        guard let flow = makeFlow(for: activity, context: context) else { return false }
        self.flow = flow
        presenter.present(navigationController, animated: true)
        flow.start(on: root)
        return true
    }

    /// Presents the customer's bookings, where statuses can be refreshed and bookings cancelled.
    public func showBookings(from presenter: UIViewController) {
        let list = BookingListViewController(booking: booking, theme: theme, text: text)
        list.title = text(.myBookingsTitle)
        let navigationController = UINavigationController(rootViewController: list)
        list.navigationItem.leftBarButtonItem = UIBarButtonItem(title: text(.close), style: .plain, target: self,
                                                                action: #selector(closeBookings))
        presented = navigationController
        presenter.present(navigationController, animated: true)
    }

    private func makeFlow(for activity: BookableActivity, context: BookingFlowContext) -> BookingFlow? {
        switch activity {
        case .toristy(let serviceId):
            guard let checkout = booking.toristy else { return nil }
            return ToristyBookingFlow(context: context, checkout: checkout, serviceId: serviceId)
        case .viator(let productCode):
            guard let checkout = booking.viator, let credentials = booking.configuration.viator else { return nil }
            return ViatorBookingFlow(context: context, checkout: checkout, productCode: productCode, credentials: credentials)
        case .victory(let eventId):
            guard let checkout = booking.victory, let payment = victoryPayment else { return nil }
            return VictoryBookingFlow(context: context, checkout: checkout, eventId: eventId, payment: payment)
        }
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
            self?.finish(with: nil)
        })
        (presented.presentedViewController ?? presented).present(alert, animated: true)
    }

    @objc private func closeBookings() {
        presented?.dismiss(animated: true)
    }

    private func finish(with reference: BookingReference?) {
        let navigationController = presented
        flow = nil
        Task { @MainActor [weak self] in
            let records = await self?.booking.records() ?? []
            let record = reference.flatMap { reference in records.first { $0.reference == reference } }
            navigationController?.dismiss(animated: true) {
                guard let self else { return }
                self.delegate?.bookingCoordinator(self, didFinishWith: record)
            }
        }
    }
}

/// Keeps the close button on whichever screen a flow puts at the bottom of the stack, except the result screen.
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
