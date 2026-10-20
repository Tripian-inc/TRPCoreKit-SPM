import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers `HostedCartSettlementPoller`'s outcomes and `NextActionRegistry.standard`'s conditional registration
/// of the hosted cart presenter.
@MainActor
final class HostedCartSettlementPollerTests: XCTestCase {
    private typealias BC = BookingContract

    private func makePoller(expiresAt: Date? = nil, now: @escaping () -> Date = { Date() },
                             sleep: @escaping (TimeInterval) async throws -> Void = { _ in },
                             settlement: @escaping () async throws -> BC.ActionSettlement) -> HostedCartSettlementPoller {
        var poller = HostedCartSettlementPoller(settlement: settlement, interval: 1, expiresAt: expiresAt)
        poller.now = now
        poller.sleep = sleep
        return poller
    }

    func testRunSucceedsWhenTheSettlementSucceeds() async {
        let poller = makePoller { .succeeded }
        let outcome = await poller.run()
        guard case .succeeded = outcome else { return XCTFail("\(outcome)") }
    }

    func testRunDeclinesWithTheReasonWhenTheSettlementFails() async {
        let poller = makePoller { .failed(reason: "The cart was cancelled.") }
        let outcome = await poller.run()
        guard case .declined(let reason) = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(reason, "The cart was cancelled.")
    }

    func testRunPollsAgainWhileTheSettlementIsPending() async {
        var callCount = 0
        let poller = makePoller {
            callCount += 1
            return callCount < 3 ? .pending : .succeeded
        }
        let outcome = await poller.run()
        guard case .succeeded = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(callCount, 3)
    }

    func testRunFailsOnANonRetryableClientError() async {
        let error = BC.ContractError(httpStatus: 422, data: BC.ErrorData(
            code: BC.OpenEnum(.validation), errors: [], retryable: false, checkout: nil))
        let poller = makePoller { throw error }
        let outcome = await poller.run()
        guard case .failed(let thrown as BC.ContractError) = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(thrown, error)
    }

    func testRunKeepsPollingOnARetryableServerError() async {
        var callCount = 0
        let retryableError = BC.ContractError(httpStatus: 503, data: BC.ErrorData(
            code: BC.OpenEnum(.supplierUnavailable), errors: [], retryable: true, checkout: nil))
        let poller = makePoller {
            callCount += 1
            if callCount == 1 { throw retryableError }
            return .succeeded
        }
        let outcome = await poller.run()
        guard case .succeeded = outcome else { return XCTFail("\(outcome)") }
        XCTAssertEqual(callCount, 2)
    }

    func testRunExpiresOnceNowReachesTheDeadline() async {
        let deadline = Date(timeIntervalSince1970: 1000)
        let poller = makePoller(expiresAt: deadline, now: { deadline }) { .pending }
        let outcome = await poller.run()
        guard case .expired = outcome else { return XCTFail("\(outcome)") }
    }

    func testRunCancelsWhenSleepThrows() async {
        struct SleepCancelled: Error {}
        let poller = makePoller(sleep: { _ in throw SleepCancelled() }) { .pending }
        let outcome = await poller.run()
        guard case .cancelled = outcome else { return XCTFail("\(outcome)") }
    }

    func testRunStopsAfterTheFirstFailedSettlement() async {
        var calls = 0
        let poller = makePoller {
            calls += 1
            return .failed(reason: "The reservation expired.")
        }
        _ = await poller.run()
        XCTAssertEqual(calls, 1)
    }

    func testAScreenThatDisappearedOutOfTheWindowCancelsItsPolling() async {
        let poller = makePoller(sleep: { try await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) }) { .pending }
        let screen = HostedCartPaymentViewController(pageURL: URL(string: "about:blank")!, theme: TRPBookingTheme(),
                                                     text: TRPBookingText())
        let polling = Task { await poller.run() }
        screen.polling = polling

        screen.viewDidDisappear(false)

        let outcome = await polling.value
        guard case .cancelled = outcome else { return XCTFail("\(outcome)") }
    }

    func testOutcomeIsCanceledForEverythingButAPaidCartSoTheActionIsNotRunAgain() {
        let presenter = HostedCartActionPresenter(settlement: { _ in .pending }, theme: TRPBookingTheme(), text: TRPBookingText())
        struct SomeError: Error {}
        let unpaid: [HostedCartSettlementPoller.Outcome] = [.declined(reason: "no funds"), .failed(SomeError()), .expired, .cancelled]

        guard case .result(let succeededResult) = presenter.outcome(of: .succeeded) else { return XCTFail() }
        XCTAssertEqual(succeededResult, .status(.succeeded))
        for polled in unpaid {
            guard case .result(let result) = presenter.outcome(of: polled) else { return XCTFail("\(polled)") }
            XCTAssertEqual(result, .status(.canceled), "\(polled)")
        }
    }

    func testNoticeExplainsOnlyAPageThatClosedOnItsOwn() {
        let text = TRPBookingText()
        let presenter = HostedCartActionPresenter(settlement: { _ in .pending }, theme: TRPBookingTheme(), text: text)
        let rejected = BC.ContractError(httpStatus: 409, data: BC.ErrorData(code: .init(.stepMismatch), errors: [],
                                                                             retryable: false, checkout: nil))

        XCTAssertEqual(presenter.notice(for: .declined(reason: "no funds")), text(.holdExpired))
        XCTAssertEqual(presenter.notice(for: .expired), text(.holdExpired))
        XCTAssertEqual(presenter.notice(for: .failed(rejected)), BookingErrorMessage(text: text).message(for: rejected))
        XCTAssertNil(presenter.notice(for: .succeeded))
        XCTAssertNil(presenter.notice(for: .cancelled))
    }

    func testStandardRegistersTheHostedCartPresenterOnlyWhenSettlementIsProvided() {
        let text = TRPBookingText()
        let theme = TRPBookingTheme()
        let payments = BookingPaymentPresenters()

        let withoutSettlement = NextActionRegistry.standard(payments: payments, lang: "en", theme: theme, text: text)
        XCTAssertFalse(withoutSettlement.supportedTypes.contains(BC.NextActionType.providerHostedCart.rawValue))

        let withSettlement = NextActionRegistry.standard(payments: payments, lang: "en", theme: theme, text: text,
                                                          settlement: { _ in .pending })
        XCTAssertTrue(withSettlement.supportedTypes.contains(BC.NextActionType.providerHostedCart.rawValue))
    }
}
