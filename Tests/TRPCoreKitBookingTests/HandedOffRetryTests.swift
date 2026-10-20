import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers a hand-off result the server fails to record on the first try: the session stays on the same action so
/// the coordinator retries reporting it instead of showing the provider's page again.
@MainActor
final class HandedOffRetryTests: XCTestCase {

    func testAHandedOffResultThatFailsToReportKeepsTheSameActionUntilRetried() async throws {
        let client = try StubHandOffClient()
        let session = CheckoutSession(client: client, lang: "en", currency: "USD")
        let handler = CanceledPaymentHandler()
        var presentable: [Bool] = []
        session.onChange = { state in
            handler.observe(state)
            if case .action(let action, _) = state { presentable.append(handler.shouldPresent(action)) }
        }
        await session.start(productId: "TEVO-2817364")
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }

        let outcome = await handler.complete(action, result: .status(.handedOff), session: session)

        XCTAssertEqual(outcome, .completed)
        guard case .action(let current, _) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(current.id, action.id)
        XCTAssertEqual(handler.handedOffActionId, action.id)
        XCTAssertFalse(handler.shouldPresent(action))
        XCTAssertTrue(session.canRetry)

        await session.retry()

        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .handedOff)
        XCTAssertNil(handler.handedOffActionId)
        XCTAssertEqual(presentable, [true, false])
    }
}

/// Answers `create` with an action awaiting a hand-off result; `action` throws a network error the first time and
/// answers with the handed-off checkout from then on.
private final class StubHandOffClient: CheckoutClient, @unchecked Sendable {
    private let awaitingHandOff: BookingContract.Checkout
    private let handedOff: BookingContract.Checkout
    private var actionCalls = 0

    init() throws {
        awaitingHandOff = try XCTUnwrap(ContractFixtures.checkout(
            of: ContractFixtures.exchange("_synthetic/victory-hosted", "03-quantity")))
        handedOff = try XCTUnwrap(ContractFixtures.checkout(
            of: ContractFixtures.exchange("_synthetic/victory-hosted", "04-handed-off")))
    }

    func create(_ request: BookingContract.CreateCheckoutRequest,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 201)
    }

    func get(id: String, lang: String) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func submit(checkoutId: String, stepId: String, answers: BookingContract.Answers, expectedAmount: BookingContract.Money?,
               lang: String, idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func back(checkoutId: String, fromStepId: String, lang: String,
              idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func action(checkoutId: String, actionId: String, result: BookingContract.ActionResult, lang: String,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        actionCalls += 1
        if actionCalls == 1 { throw URLError(.networkConnectionLost) }
        return BookingContract.CheckoutResponse(checkout: handedOff, httpStatus: 200)
    }

    func extend(checkoutId: String, lang: String,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }

    func cancel(checkoutId: String, lang: String,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.CheckoutResponse {
        BookingContract.CheckoutResponse(checkout: awaitingHandOff, httpStatus: 200)
    }
}
