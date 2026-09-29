import UIKit
import TRPBookingKit

/// A provider's checkout run inside the booking navigation controller.
@MainActor
protocol BookingFlow: AnyObject {
    func start(on root: BookingBaseViewController)
}

/// What every flow shares: the booking entry point, the navigation stack and a way to finish.
@MainActor
final class BookingFlowContext {

    let booking: TRPBooking
    let navigationController: UINavigationController
    let theme: TRPBookingTheme
    let text: TRPBookingText
    let activityId: String
    let title: String
    let date: Date
    let formatting = BookingFormatting()
    /// Called once the customer leaves the result screen, with the reference of what was booked.
    let finish: (BookingReference?) -> Void

    init(booking: TRPBooking, navigationController: UINavigationController, theme: TRPBookingTheme, text: TRPBookingText,
         activityId: String, title: String, date: Date, finish: @escaping (BookingReference?) -> Void) {
        self.booking = booking
        self.navigationController = navigationController
        self.theme = theme
        self.text = text
        self.activityId = activityId
        self.title = title
        self.date = date
        self.finish = finish
    }

    /// Runs `work` behind the screen's loading overlay; a failure is offered for retry unless `handle` takes it.
    func perform<Value>(on screen: BookingBaseViewController,
                        _ work: @escaping () async throws -> Value,
                        handle: ((Error) -> Bool)? = nil,
                        then: @escaping (Value) -> Void) {
        screen.setLoading(true)
        Task { @MainActor [weak self, weak screen] in
            do {
                let value = try await work()
                screen?.setLoading(false)
                then(value)
            } catch {
                guard let screen else { return }
                screen.setLoading(false)
                if handle?(error) == true { return }
                if case BookingError.paymentCancelled = error { return }
                screen.show(error) { [weak self, weak screen] in
                    guard let self, let screen else { return }
                    self.perform(on: screen, work, handle: handle, then: then)
                }
            }
        }
    }

    func push(_ screen: UIViewController) {
        navigationController.pushViewController(screen, animated: true)
    }

    func popTo(_ screen: UIViewController) {
        guard navigationController.viewControllers.contains(screen) else { return }
        navigationController.popToViewController(screen, animated: true)
    }

    /// Replaces the whole stack with the outcome so the customer cannot go back into a finished checkout.
    func showResult(_ kind: BookingOutcomeKind, message: String? = nil, rows: [BookingSummaryRow] = [],
                    voucherURL: URL? = nil, reference: BookingReference?) {
        let headline: String
        let body: String
        switch kind {
        case .success:
            headline = text(.successTitle)
            body = message ?? text(.successMessage)
        case .pending:
            headline = text(.pendingTitle)
            body = message ?? text(.pendingMessage)
        case .failure:
            headline = text(.failureTitle)
            body = message ?? text(.chargedNotConfirmed)
        }
        var allRows = rows
        if let reference {
            allRows.insert(BookingSummaryRow(title: text(.reference), value: reference.primary), at: 0)
        }
        let result = BookingResultViewController(kind: kind, title: headline, message: body, rows: allRows,
                                                 voucherURL: voucherURL, theme: theme, text: text)
        result.onDone = { [weak self] in self?.finish(reference) }
        result.navigationItem.hidesBackButton = true
        navigationController.setViewControllers([result], animated: true)
    }

    /// Handles the errors that end or rewind a checkout after the customer has committed to pay.
    func handleCheckoutError(_ error: Error, rewindTo screen: UIViewController, on current: BookingBaseViewController) -> Bool {
        switch error as? BookingError {
        case .holdExpired?:
            showAlert(on: current, message: text(.holdExpired)) { [weak self] in self?.popTo(screen) }
            return true
        case .confirmationFailedAfterCharge(_, let reference, _)?:
            showResult(.failure, message: text(.chargedNotConfirmed), reference: reference)
            return true
        case .outcomeUnknown(let reference)?:
            showResult(.pending, reference: reference)
            return true
        default:
            return false
        }
    }

    func showAlert(on screen: UIViewController, message: String, then: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: text(.close), style: .default) { _ in then?() })
        screen.present(alert, animated: true)
    }

    func price(_ amount: Decimal?, currency: String?) -> String {
        formatting.price(amount, currency: currency) ?? "–"
    }

    static func ageRange(minimum: Int?, maximum: Int?) -> String? {
        switch (minimum, maximum) {
        case let (minimum?, maximum?): return "\(minimum)–\(maximum)"
        case let (minimum?, nil): return "\(minimum)+"
        case let (nil, maximum?): return "0–\(maximum)"
        case (nil, nil): return nil
        }
    }
}
