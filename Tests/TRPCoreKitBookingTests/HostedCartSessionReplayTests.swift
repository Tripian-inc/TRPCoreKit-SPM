import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Walks the synthetic `victory-hosted` fixtures through `CheckoutSession` to the `provider_hosted_cart` action
/// whose settlement is `.handOff`, then reports it handed off the way `HostedCartActionPresenter` does.
@MainActor
final class HostedCartSessionReplayTests: XCTestCase {
    private typealias BC = BookingContract

    func testHandOffActionCarriesHandOffSettlementAndZeroPollInterval() async throws {
        let (session, _) = try await walkToAction()
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }
        guard case .providerHostedCart(let payload) = action else { return XCTFail("\(action)") }

        XCTAssertEqual(payload.params.settlement, .handOff)
        XCTAssertEqual(payload.params.pollIntervalSeconds, 0)
    }

    func testCompletingTheHandOffActionSendsAHandedOffResultAndFinishesTheSession() async throws {
        let (session, script) = try await walkToAction()
        guard case .action(let action, _) = session.state else { return XCTFail("\(session.state)") }

        await session.complete(action: action, result: .status(.handedOff))

        try await assertSentWhatWasRecorded(script, "_synthetic/victory-hosted")
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .handedOff)
    }

    /// Creates the checkout and answers its tickets and quantity steps, leaving the session at the hand-off action.
    private func walkToAction() async throws -> (CheckoutSession, BC.ReplayScript) {
        let exchanges = try ContractFixtures.exchanges(in: "_synthetic/victory-hosted")
        let script = BC.ReplayScript(exchanges)
        let session = CheckoutSession(client: BC.ReplayCheckoutClient(script: script), lang: "en", currency: "USD")

        await session.start(productId: "TEVO-2817364", bookingUuid: "3f6c1a9e-8d2b-4b7a-a1c4-5e9f0d2b7c11")
        guard case .step(let ticketsStep, let ticketsCheckout) = session.state else {
            XCTFail("\(session.state)")
            return (session, script)
        }
        var ticketsForm = FormState(layout: session.registry.layout(for: ticketsStep))
        ticketsForm.set(.string("TG_9004"), for: "tickets")
        await session.submit(answers: ticketsForm.answers)
        _ = ticketsCheckout

        guard case .step(let quantityStep, _) = session.state else {
            XCTFail("\(session.state)")
            return (session, script)
        }
        var quantityForm = FormState(layout: session.registry.layout(for: quantityStep))
        quantityForm.set(.object(["TICKET": .number(2)]), for: "units")
        await session.submit(answers: quantityForm.answers)

        return (session, script)
    }
}
