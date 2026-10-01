import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Walks the Toristy and Ticket Evolution (Victory) fixtures, and the forward-compatibility and price-change
/// fixtures, through `CheckoutSession`, the way `CheckoutSessionTests` walks Viator.
@MainActor
final class CheckoutSessionProviderFlowTests: XCTestCase {

    private var sleeps: [TimeInterval] = []
    private var issues: [CheckoutSession.Issue] = []

    func testToristyFlowEndsConfirmed() async throws {
        let (session, script) = try await walk("toristy")
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .confirmed)
        try await assertSentWhatWasRecorded(script, "toristy")
    }

    /// Ticket Evolution confirms asynchronously, so the Victory fixture's flow is terminal at `pending`, not `confirmed`.
    func testVictoryFlowEndsPending() async throws {
        let (session, script) = try await walk("victory", currency: "USD")
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .pending)
        try await assertSentWhatWasRecorded(script, "victory")
    }

    func testForwardCompatStepFallsBack() async throws {
        let exchange = try ContractFixtures.exchange("_synthetic/g-forward-compat", "01-unknown-blocks")
        let script = BC.ReplayScript([exchange])
        let client = ResumeAsCreateClient(base: BC.ReplayCheckoutClient(script: script),
                                          checkoutId: "chk_01SYNG0001", lang: "en")
        let session = makeSession(client)
        await session.start(productId: "SYN-FUTURE-1")
        guard case .fallback(_, let reason) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertTrue(reason.contains("seat_map"), reason)
    }

    func testPriceChangedReplacesTheCheckoutAndReportsTheConflict() async throws {
        let main = try ContractFixtures.exchanges(in: "viator")
        let priceChanged = try ContractFixtures.exchange("viator/errors", "PRICE_CHANGED")
        let script = BC.ReplayScript(Array(main.prefix(while: { $0.name != "08-summary" })) + [priceChanged])
        let session = try await walk(script)
        XCTAssertEqual(issues, [.conflict(.priceChanged)])
        guard case .step(let step, let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(step.id, "summary")
        XCTAssertEqual(checkout.amount?.amount, "152.00")
    }

    private func makeSession(_ client: CheckoutClient, currency: String = "EUR") -> CheckoutSession {
        let clock = Date(timeIntervalSince1970: 1_790_000_000)
        let session = CheckoutSession(client: client, lang: "en", currency: currency, clock: { clock },
                                      sleep: { [weak self] interval in self?.sleeps.append(interval) })
        session.onIssue = { [weak self] issue in self?.issues.append(issue) }
        return session
    }

    private func walk(_ directory: String, currency: String = "EUR") async throws -> (CheckoutSession, BC.ReplayScript) {
        let script = BC.ReplayScript(try ContractFixtures.exchanges(in: directory))
        let session = try await walk(script, currency: currency)
        return (session, script)
    }

    /// Drives a session through every checkout request of `script`, answering steps with the recorded values.
    private func walk(_ script: BC.ReplayScript, currency: String = "EUR") async throws -> CheckoutSession {
        let session = makeSession(BC.ReplayCheckoutClient(script: script), currency: currency)
        while let next = await script.remaining.first, next.request.path.contains("/checkouts") {
            let path = next.request.path
            let body = next.request.body ?? .null
            let label = next.name
            if next.request.method == "POST", path.hasSuffix("/checkouts") {
                let create = try body.decode(as: BC.CreateCheckoutRequest.self)
                await session.start(productId: create.productId, optionId: create.optionId, date: create.date,
                                    bookingUuid: create.bookingUuid)
            } else if path.contains("/steps/") {
                guard case .step(let step, _) = session.state else { return failure(label, session) }
                XCTAssertTrue(path.hasSuffix("/steps/\(step.id)"), label)
                var form = FormState(layout: session.registry.layout(for: step))
                for (id, value) in try body.decode(as: BC.SubmitStepRequest.self).answers.values {
                    form.set(value, for: id)
                }
                await session.submit(answers: form.answers)
            } else if path.hasSuffix("/back") {
                XCTAssertTrue(session.canGoBack, label)
                await session.back()
            } else if path.hasSuffix("/extend") {
                XCTAssertTrue(session.canExtend, label)
                await session.extend()
            } else if path.contains("/actions/") {
                guard case .action(let action, _) = session.state else { return failure(label, session) }
                XCTAssertTrue(path.hasSuffix("/actions/\(action.id)"), label)
                await session.complete(action: action, result: try body.decode(as: BC.ActionResultRequest.self).result)
            } else if next.request.method == "GET" {
                await session.refresh()
            } else {
                XCTFail("unexpected request \(label)")
                break
            }
        }
        return session
    }

    private func failure(_ label: String, _ session: CheckoutSession) -> CheckoutSession {
        XCTFail("\(label) reached in state \(session.state)")
        return session
    }
}

/// Redirects `create` to `get`, for a fixture that starts the session by fetching an already-existing checkout.
private struct ResumeAsCreateClient: CheckoutClient {
    let base: CheckoutClient
    let checkoutId: String
    let lang: String

    func create(_ request: BC.CreateCheckoutRequest, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.get(id: checkoutId, lang: lang)
    }

    func get(id: String, lang: String) async throws -> BC.CheckoutResponse {
        try await base.get(id: id, lang: lang)
    }

    func submit(checkoutId: String, stepId: String, answers: BC.Answers, expectedAmount: BC.Money?, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.submit(checkoutId: checkoutId, stepId: stepId, answers: answers,
                              expectedAmount: expectedAmount, lang: lang, idempotencyKey: idempotencyKey)
    }

    func back(checkoutId: String, fromStepId: String, lang: String,
              idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.back(checkoutId: checkoutId, fromStepId: fromStepId, lang: lang, idempotencyKey: idempotencyKey)
    }

    func action(checkoutId: String, actionId: String, result: BC.ActionResult, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.action(checkoutId: checkoutId, actionId: actionId, result: result, lang: lang,
                              idempotencyKey: idempotencyKey)
    }

    func extend(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.extend(checkoutId: checkoutId, lang: lang, idempotencyKey: idempotencyKey)
    }

    func cancel(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.cancel(checkoutId: checkoutId, lang: lang, idempotencyKey: idempotencyKey)
    }
}
