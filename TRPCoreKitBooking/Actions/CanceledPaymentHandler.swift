import Foundation
import TRPBookingKit

/// Reports action results and keeps an action the customer closed without paying, or one already handed off to the
/// provider, from being shown again on its own.
///
/// After a canceled result the checkout goes back to its last step when it allows `back`; otherwise the caller
/// has to let the customer choose between trying again and leaving. A handed-off result that fails to reach the
/// server is sent again through the session's retry, never by showing the provider's page a second time.
@MainActor
final class CanceledPaymentHandler {

    /// What follows a reported action result.
    enum Outcome: Equatable {
        case completed
        case wentBack
        case needsChoice
    }

    private(set) var canceledActionId: String?
    private(set) var handedOffActionId: String?

    /// Whether `action` should be presented: false for the action the customer just canceled or handed off.
    func shouldPresent(_ action: BookingContract.NextAction) -> Bool {
        action.id != canceledActionId && action.id != handedOffActionId
    }

    /// Forgets the canceled action once the session has moved past it.
    func observe(_ state: CheckoutSession.State) {
        switch state {
        case .loading, .action: break
        default:
            canceledActionId = nil
            handedOffActionId = nil
        }
    }

    /// Lets the canceled action be presented again, for the customer's "try again".
    func allowAgain() {
        canceledActionId = nil
    }

    /// Reports `result` for `action` and, when it was canceled and the checkout still waits on that action,
    /// returns to the last step if the checkout allows it.
    func complete(_ action: BookingContract.NextAction, result: BookingContract.ActionResult,
                  session: CheckoutSession) async -> Outcome {
        guard result.status?.value == .canceled else {
            if result.status?.value == .handedOff { handedOffActionId = action.id }
            await session.complete(action: action, result: result)
            return .completed
        }
        canceledActionId = action.id
        await session.complete(action: action, result: result)
        guard case .action(let current, _) = session.state, current.id == action.id else { return .completed }
        guard session.canGoBack else { return .needsChoice }
        await session.back()
        return .wentBack
    }
}
