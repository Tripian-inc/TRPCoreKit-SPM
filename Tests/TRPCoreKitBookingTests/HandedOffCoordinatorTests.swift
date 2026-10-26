import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers how `TRPBookingCoordinator` ends a checkout the server answers `handed_off`: the checkout closes back to
/// the screen it was started from without a result screen, and the host learns of it once, with nothing recorded.
@MainActor
final class HandedOffCoordinatorTests: XCTestCase {

    func testAHandedOffCheckoutReturnsToTheAnchorWithoutAResultAndReportsItOnce() async throws {
        let client = try HandedOffCheckoutClient()
        let bookings = RecordingBookingClient()
        let presenter = HandingOffPresenter()
        let coordinator = TRPBookingCoordinator(checkout: client, bookings: bookings, lang: "en", currency: "USD")
        coordinator.actions.register(presenter)
        let delegate = FinishSpy()
        coordinator.delegate = delegate
        let anchor = AnchorViewController()

        XCTAssertTrue(coordinator.start(productId: "TEVO-2817364", title: "Hamilton", from: anchor))
        let checkoutNavigation = try XCTUnwrap(anchor.presentations.first as? UINavigationController)
        try await waitUntil { presenter.isWaiting }
        XCTAssertTrue(delegate.finished.isEmpty)

        presenter.leavePage()
        try await waitUntil { !delegate.finished.isEmpty }
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(anchor.presentations.count, 1)
        XCTAssertEqual(presenter.presentedActionIds, ["act_VHOST01"])
        XCTAssertEqual(client.actionResults, [.status(.handedOff)])
        XCTAssertEqual(delegate.finished.count, 1)
        XCTAssertEqual(delegate.finished.first??.status.value, .handedOff)
        XCTAssertEqual(checkoutNavigation.viewControllers.count, 1)
        XCTAssertFalse(checkoutNavigation.viewControllers.contains {
            $0 is BookingResultViewController || $0 is CheckoutFallbackViewController || $0 is CheckoutProcessingViewController
        })
        XCTAssertNil(checkoutNavigation.presentedViewController)
        XCTAssertTrue(delegate.confirmed.isEmpty)
        XCTAssertEqual(bookings.calls, 0)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(5)
        while !condition(), Date() < deadline { try await Task.sleep(nanoseconds: 10_000_000) }
    }
}

/// The screen a checkout starts from. The package's test runner has no window scene, so a real modal presentation
/// never completes there; this anchor keeps what it is asked to present instead, and the coordinator's dismissal of
/// that navigation completes at once, which is when the coordinator reports the finish to its delegate.
private final class AnchorViewController: UIViewController {
    private(set) var presentations: [UIViewController] = []

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentations.append(viewControllerToPresent)
        completion?()
    }
}

/// Answers `create` with the Victory checkout awaiting TE's hosted page and `action` with the handed-off checkout.
private final class HandedOffCheckoutClient: CheckoutClient, @unchecked Sendable {
    private let awaitingHandOff: BC.Checkout
    private let handedOff: BC.Checkout
    private let lock = NSLock()
    private var results: [BC.ActionResult] = []

    var actionResults: [BC.ActionResult] { lock.withLock { results } }

    init() throws {
        awaitingHandOff = try XCTUnwrap(ContractFixtures.checkout(
            of: ContractFixtures.exchange("_synthetic/victory-hosted", "03-quantity")))
        handedOff = try XCTUnwrap(ContractFixtures.checkout(
            of: ContractFixtures.exchange("_synthetic/victory-hosted", "04-handed-off")))
    }

    func create(_ request: BC.CreateCheckoutRequest, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 201)
    }

    func get(id: String, lang: String) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func submit(checkoutId: String, stepId: String, answers: BC.Answers, expectedAmount: BC.Money?, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func back(checkoutId: String, fromStepId: String, lang: String,
              idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func action(checkoutId: String, actionId: String, result: BC.ActionResult, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        lock.withLock { results.append(result) }
        return BC.CheckoutResponse(checkout: handedOff, httpStatus: 200)
    }

    func extend(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func cancel(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }
}

/// Stands in for TE's hosted page: answers `handed_off` once the test lets the customer leave the page.
private final class HandingOffPresenter: NextActionPresenter {
    let type = BC.NextActionType.providerHostedCart.rawValue
    private(set) var presentedActionIds: [String] = []
    private var leave: CheckedContinuation<Void, Never>?

    var isWaiting: Bool { leave != nil }

    func present(_ action: BC.NextAction, on navigationController: UINavigationController) async -> NextActionOutcome {
        presentedActionIds.append(action.id)
        await withCheckedContinuation { leave = $0 }
        return .result(.status(.handedOff))
    }

    func leavePage() {
        leave?.resume()
        leave = nil
    }
}

private final class FinishSpy: TRPBookingCoordinatorDelegate {
    private(set) var finished: [BC.Checkout?] = []
    private(set) var confirmed: [BC.Booking] = []

    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didFinishWith checkout: BC.Checkout?) {
        finished.append(checkout)
    }

    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didConfirm booking: BC.Booking) {
        confirmed.append(booking)
    }
}

/// Counts every call; a handed-off checkout has no booking to load.
private final class RecordingBookingClient: BookingClient, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var calls: Int { lock.withLock { count } }

    func list(status: [BC.BookingStatus], page: Int, limit: Int, lang: String) async throws -> BC.BookingPage {
        lock.withLock { count += 1 }
        throw URLError(.notConnectedToInternet)
    }

    func get(uuid: String, lang: String) async throws -> BC.Booking {
        lock.withLock { count += 1 }
        throw URLError(.notConnectedToInternet)
    }

    func cancel(uuid: String, reason: String?, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.Booking {
        lock.withLock { count += 1 }
        throw URLError(.notConnectedToInternet)
    }
}
