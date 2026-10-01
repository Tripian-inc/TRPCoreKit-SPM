import UIKit
import TRPBookingKit

/// Confirms a card payment intent with the host's payment sheet.
@MainActor
public protocol StripePaymentIntentPresenting: AnyObject {
    /// True when the intent succeeded, false when the traveler closed the sheet.
    func confirmPaymentIntent(clientSecret: String, publishableKey: String, merchantName: String,
                              from viewController: UIViewController) async throws -> Bool
}

/// Collects a payment method nonce with the host's drop-in sheet.
@MainActor
public protocol BraintreeDropinPresenting: AnyObject {
    /// The nonce and device data, or nil when the traveler closed the sheet.
    func collectNonce(clientToken: String, amount: BookingContract.Money?,
                      from viewController: UIViewController) async throws -> (nonce: String, deviceData: String)?
}

/// Wraps the host's payment sheets as next action presenters.
@MainActor
enum HostPaymentPresenters {

    static func make(from payments: BookingPaymentPresenters) -> [NextActionPresenter] {
        var presenters: [NextActionPresenter] = []
        if let sheet = payments.paymentIntent {
            presenters.append(PaymentIntentActionPresenter(sheet: sheet))
        }
        if let sheet = payments.dropin {
            presenters.append(DropinActionPresenter(sheet: sheet))
        }
        return presenters
    }
}

@MainActor
final class PaymentIntentActionPresenter: NextActionPresenter {

    let type = BookingContract.NextActionType.stripePaymentIntent.rawValue
    private let sheet: StripePaymentIntentPresenting

    init(sheet: StripePaymentIntentPresenting) {
        self.sheet = sheet
    }

    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        guard case .stripePaymentIntent(let payload) = action else { return .unsupported(reason: action.typeRawValue) }
        let params = payload.params
        do {
            let succeeded = try await sheet.confirmPaymentIntent(
                clientSecret: params.clientSecret, publishableKey: params.publishableKey,
                merchantName: params.merchantName, from: navigationController)
            return .result(.status(succeeded ? .succeeded : .canceled))
        } catch {
            return .failed(error)
        }
    }
}

@MainActor
final class DropinActionPresenter: NextActionPresenter {

    let type = BookingContract.NextActionType.braintreeDropin.rawValue
    private let sheet: BraintreeDropinPresenting

    init(sheet: BraintreeDropinPresenting) {
        self.sheet = sheet
    }

    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        guard case .braintreeDropin(let payload) = action else { return .unsupported(reason: action.typeRawValue) }
        do {
            guard let collected = try await sheet.collectNonce(clientToken: payload.params.clientToken,
                                                               amount: payload.params.amount, from: navigationController) else {
                return .result(.status(.canceled))
            }
            return .result(.braintree(nonce: collected.nonce, deviceData: collected.deviceData))
        } catch {
            return .failed(error)
        }
    }
}
