import UIKit
import TRPBookingKit

/// What presenting a next action came to.
public enum NextActionOutcome {
    /// The result to send with `CheckoutSession.complete(action:result:)`.
    case result(BookingContract.ActionResult)
    /// The client cannot run this action; the checkout continues in the fallback.
    case unsupported(reason: String)
    /// The action failed before producing a result and may be presented again.
    case failed(Error)
}

/// Runs one `nextAction.type` on the booking navigation stack. A traveler who backs out answers `.status(.canceled)`.
@MainActor
public protocol NextActionPresenter: AnyObject {
    /// The `nextAction.type` this presenter handles.
    var type: String { get }
    func present(_ action: BookingContract.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome
}

/// The next action presenters the client supports, keyed by action type.
@MainActor
public struct NextActionRegistry {

    public private(set) var presenters: [String: NextActionPresenter]

    public init(presenters: [NextActionPresenter]) {
        self.presenters = Dictionary(presenters.map { ($0.type, $0) }, uniquingKeysWith: { _, last in last })
    }

    /// Redirect and 3-D Secure always; the hosted form and the host payment sheets when `payments` provides them;
    /// the provider's hosted cart when `settlement` can tell whether its payment settled.
    public static func standard(payments: BookingPaymentPresenters, lang: String,
                                theme: TRPBookingTheme, text: TRPBookingText,
                                settlement: HostedCartSettlement? = nil) -> NextActionRegistry {
        var presenters: [NextActionPresenter] = [
            RedirectActionPresenter(type: BookingContract.NextActionType.redirect.rawValue, theme: theme, text: text),
            RedirectActionPresenter(type: BookingContract.NextActionType.threeDS.rawValue, theme: theme, text: text)
        ]
        if let pageURL = payments.hostedFormPageURL {
            presenters.append(HostedFormActionPresenter(pageURL: pageURL, lang: lang, theme: theme, text: text))
        }
        if let settlement {
            presenters.append(HostedCartActionPresenter(settlement: settlement, theme: theme, text: text))
        }
        presenters += HostPaymentPresenters.make(from: payments)
        return NextActionRegistry(presenters: presenters)
    }

    public mutating func register(_ presenter: NextActionPresenter) {
        presenters[presenter.type] = presenter
    }

    public mutating func remove(_ type: String) {
        presenters[type] = nil
    }

    /// The action types the client can run, for the capabilities header.
    public var supportedTypes: [String] {
        presenters.keys.sorted()
    }

    public func presenter(for action: BookingContract.NextAction) -> NextActionPresenter? {
        presenters[action.typeRawValue]
    }
}

/// Payment sheets the host app links and the hosted-form page it is allowed to load.
///
/// The booking package links no payment SDK; an action whose presenter is missing goes to the fallback.
public struct BookingPaymentPresenters {
    public var paymentIntent: StripePaymentIntentPresenting?
    public var dropin: BraintreeDropinPresenting?
    /// The page that hosts a provider's card form for `provider_hosted_form` actions.
    public var hostedFormPageURL: URL?

    public init(paymentIntent: StripePaymentIntentPresenting? = nil, dropin: BraintreeDropinPresenting? = nil,
                hostedFormPageURL: URL? = nil) {
        self.paymentIntent = paymentIntent
        self.dropin = dropin
        self.hostedFormPageURL = hostedFormPageURL
    }
}
