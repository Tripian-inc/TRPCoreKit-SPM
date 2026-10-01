import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Walks recorded flows through `CheckoutSession` over a replay client, sending what the fixtures recorded.
@MainActor
final class CheckoutSessionTests: XCTestCase {

    private var sleeps: [TimeInterval] = []
    private var issues: [CheckoutSession.Issue] = []

    func testFullFlowEndsConfirmedAfterPolling() async throws {
        let (session, script) = try await walk("_synthetic/a-full-flow")
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .confirmed)
        XCTAssertEqual(sleeps, [2, 2])
        XCTAssertTrue(issues.isEmpty, "\(issues)")
        try await assertSentWhatWasRecorded(script, "_synthetic/a-full-flow")
    }

    func testViatorFlowEndsConfirmed() async throws {
        let (session, script) = try await walk("viator")
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .confirmed)
        try await assertSentWhatWasRecorded(script, "viator")
    }

    func testExpiredHoldIsReportedAndEndsTheCheckout() async throws {
        let (session, script) = try await walk("_synthetic/f-hold-expired")
        XCTAssertEqual(issues, [.conflict(.holdExpired)])
        guard case .finished(let checkout) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(checkout.status.value, .expired)
        XCTAssertNotNil(checkout.fallback?.webUrl)
        try await assertSentWhatWasRecorded(script, "_synthetic/f-hold-expired")
    }

    func testAnUnreachableServerKeepsTheStepAndRetriesWithTheSameKey() async throws {
        let failing = FailingOnceClient(base: BC.ReplayCheckoutClient(script: BC.ReplayScript(
            try ContractFixtures.exchanges(in: "viator"))))
        let session = makeSession(failing)
        await session.start(productId: "5010BCN_SAGRADA", bookingUuid: "3f6c1a9e-8d2b-4b7a-a1c4-5e9f0d2b7c11")
        guard case .step(let step, _) = session.state else { return XCTFail("\(session.state)") }
        failing.failNext = true
        await session.submit(answers: ["date": .string("2026-10-15")])
        guard case .step(let same, _) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(same, step)
        XCTAssertEqual(issues, [.unavailable])
        XCTAssertTrue(session.canRetry)
        await session.retry()
        guard case .step(let next, _) = session.state else { return XCTFail("\(session.state)") }
        XCTAssertEqual(next.id, "travelers")
        XCTAssertEqual(failing.keys.count, 2)
        XCTAssertEqual(Set(failing.keys).count, 1)
    }

    private func makeSession(_ client: CheckoutClient) -> CheckoutSession {
        let clock = Date(timeIntervalSince1970: 1_790_000_000)
        let session = CheckoutSession(client: client, lang: "en", currency: "EUR", clock: { clock },
                                      sleep: { [weak self] interval in self?.sleeps.append(interval) })
        session.onIssue = { [weak self] issue in self?.issues.append(issue) }
        return session
    }

    /// Drives a session through every checkout request of `directory`, answering steps with the recorded values.
    private func walk(_ directory: String) async throws -> (CheckoutSession, BC.ReplayScript) {
        let script = BC.ReplayScript(try ContractFixtures.exchanges(in: directory))
        let session = makeSession(BC.ReplayCheckoutClient(script: script))
        while let next = await script.remaining.first, next.request.path.contains("/checkouts") {
            let path = next.request.path
            let body = next.request.body ?? .null
            let label = "\(directory)/\(next.name)"
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
        return (session, script)
    }

    private func failure(_ label: String, _ session: CheckoutSession) -> (CheckoutSession, BC.ReplayScript) {
        XCTFail("\(label) reached in state \(session.state)")
        return (session, BC.ReplayScript([]))
    }

    private func assertSentWhatWasRecorded(_ script: BC.ReplayScript, _ directory: String) async throws {
        let recorded = try ContractFixtures.exchanges(in: directory).filter { $0.request.path.contains("/checkouts") }
        let sent = await script.sent
        XCTAssertEqual(sent.map(\.signature), recorded.map(\.request.signature))
        for (request, exchange) in zip(sent, recorded) {
            XCTAssertEqual(request.body?.withoutNullMembers, exchange.request.body?.withoutNullMembers, exchange.name)
        }
        XCTAssertTrue(sent.filter { $0.method == "POST" }.allSatisfy { $0.idempotencyKey != nil })
    }
}

/// Throws a transport error on the call after `failNext` is set, then forwards to `base`; records submit keys.
private final class FailingOnceClient: CheckoutClient, @unchecked Sendable {
    let base: CheckoutClient
    var failNext = false
    var keys: [String] = []

    init(base: CheckoutClient) {
        self.base = base
    }

    func create(_ request: BC.CreateCheckoutRequest, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        try await base.create(request, idempotencyKey: idempotencyKey)
    }

    func get(id: String, lang: String) async throws -> BC.CheckoutResponse {
        try await base.get(id: id, lang: lang)
    }

    func submit(checkoutId: String, stepId: String, answers: BC.Answers, expectedAmount: BC.Money?, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        keys.append(idempotencyKey.rawValue)
        if failNext {
            failNext = false
            throw URLError(.notConnectedToInternet)
        }
        return try await base.submit(checkoutId: checkoutId, stepId: stepId, answers: answers,
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
