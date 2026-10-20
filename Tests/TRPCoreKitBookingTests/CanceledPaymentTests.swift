import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers a payment the customer closes, going back from an action, and the reference the result screen shows.
@MainActor
final class CanceledPaymentTests: XCTestCase {

    func testACanceledPaymentIsNotPresentedAgainAndGoesBackWhenAllowed() async throws {
        let client = try StubCheckoutClient(awaitingPaymentAllowsBack: true)
        let session = CheckoutSession(client: client, lang: "en", currency: "EUR")
        let handler = CanceledPaymentHandler()
        var presentable: [Bool] = []
        session.onChange = { state in
            handler.observe(state)
            if case .action(let action, _) = state { presentable.append(handler.shouldPresent(action)) }
        }
        await session.start(productId: "5010BCN_SAGRADA")
        await session.submit(answers: [:])
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }

        let outcome = await handler.complete(action, result: .status(.canceled), session: session)

        XCTAssertEqual(outcome, .wentBack)
        XCTAssertEqual(presentable, [true, false])
        XCTAssertEqual(client.backSteps, ["summary"])
        guard case .step(let step, _) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(step.id, "summary")
        XCTAssertNil(handler.canceledActionId)
    }

    func testADeclinedHostedCartGoesBackInsteadOfRunningTheActionAgain() async throws {
        let client = try StubCheckoutClient(awaitingPaymentAllowsBack: true)
        let session = CheckoutSession(client: client, lang: "en", currency: "EUR")
        let handler = CanceledPaymentHandler()
        let presenter = HostedCartActionPresenter(settlement: { _ in .pending }, theme: TRPBookingTheme(), text: TRPBookingText())
        await session.start(productId: "5010BCN_SAGRADA")
        await session.submit(answers: [:])
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }
        guard case .result(let result) = presenter.outcome(of: .declined(reason: "The reservation expired.")) else {
            return XCTFail("A declined cart must not fail the action, which the coordinator would retry")
        }

        let outcome = await handler.complete(action, result: result, session: session)

        XCTAssertEqual(outcome, .wentBack)
        XCTAssertFalse(handler.shouldPresent(action))
        XCTAssertEqual(client.backSteps, ["summary"])
    }

    func testACanceledPaymentAsksWhenTheCheckoutCannotGoBack() async throws {
        let client = try StubCheckoutClient(awaitingPaymentAllowsBack: false)
        let session = CheckoutSession(client: client, lang: "en", currency: "EUR")
        let handler = CanceledPaymentHandler()
        await session.start(productId: "5010BCN_SAGRADA")
        await session.submit(answers: [:])
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }

        let outcome = await handler.complete(action, result: .status(.canceled), session: session)

        XCTAssertEqual(outcome, .needsChoice)
        XCTAssertFalse(handler.shouldPresent(action))
        XCTAssertTrue(client.backSteps.isEmpty)
        handler.allowAgain()
        XCTAssertTrue(handler.shouldPresent(action))
    }

    func testBackFromTheActionStateSendsTheLastStepShown() async throws {
        let client = try StubCheckoutClient(awaitingPaymentAllowsBack: true)
        let session = CheckoutSession(client: client, lang: "en", currency: "EUR")
        await session.start(productId: "5010BCN_SAGRADA")
        await session.submit(answers: [:])
        guard case .action = session.state else { return XCTFail("\(session.state)") }
        XCTAssertTrue(session.canGoBack)

        await session.back()

        XCTAssertEqual(client.backSteps, ["summary"])
    }

    func testTheResultPrefersTheProviderReference() throws {
        let checkout = try XCTUnwrap(ContractFixtures.checkout(of: ContractFixtures.exchange("viator", "08-summary")))
        let booking = try ContractFixtures.exchange("viator", "12-booking").response.body
            .decode(as: BC.Envelope<BC.Booking>.self).data
        let text = TRPBookingText()

        let withBooking = BookingResultRows(checkout: checkout, booking: booking).rows(text: text)
        let withoutBooking = BookingResultRows(checkout: checkout, booking: nil).rows(text: text)

        XCTAssertEqual(withBooking.last?.value, "BR-1122334455")
        XCTAssertEqual(withoutBooking.last?.value, "3f6c1a9e-8d2b-4b7a-a1c4-5e9f0d2b7c11")
    }
}

/// Answers `create` and `back` with the Viator summary step, and `submit` and `action` with the checkout
/// awaiting payment; records the step every `back` is sent from.
private final class StubCheckoutClient: CheckoutClient, @unchecked Sendable {
    private let summary: BC.Checkout
    private let awaitingPayment: BC.Checkout
    private(set) var backSteps: [String] = []

    init(awaitingPaymentAllowsBack: Bool) throws {
        summary = try XCTUnwrap(ContractFixtures.checkout(of: ContractFixtures.exchange("viator", "07-details-again")))
        let recorded = try XCTUnwrap(ContractFixtures.checkout(of: ContractFixtures.exchange("viator", "08-summary")))
        let allowed: [BC.AllowedAction] = awaitingPaymentAllowsBack ? [.back, .cancel] : [.cancel]
        awaitingPayment = BC.Checkout(
            id: recorded.id, status: recorded.status, provider: recorded.provider, product: recorded.product,
            amount: recorded.amount, holdExpiresAt: recorded.holdExpiresAt, priceValidUntil: recorded.priceValidUntil,
            currentStep: recorded.currentStep, nextAction: recorded.nextAction,
            allowedActions: allowed.map { BC.OpenEnum($0) }, booking: recorded.booking, result: recorded.result,
            fallback: recorded.fallback)
    }

    func create(_ request: BC.CreateCheckoutRequest, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: summary, httpStatus: 201)
    }

    func get(id: String, lang: String) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingPayment, httpStatus: 200)
    }

    func submit(checkoutId: String, stepId: String, answers: BC.Answers, expectedAmount: BC.Money?, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingPayment, httpStatus: 200)
    }

    func back(checkoutId: String, fromStepId: String, lang: String,
              idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        backSteps.append(fromStepId)
        return BC.CheckoutResponse(checkout: summary, httpStatus: 200)
    }

    func action(checkoutId: String, actionId: String, result: BC.ActionResult, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingPayment, httpStatus: 200)
    }

    func extend(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingPayment, httpStatus: 200)
    }

    func cancel(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        BC.CheckoutResponse(checkout: awaitingPayment, httpStatus: 200)
    }
}
