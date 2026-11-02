import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// `BookingCancelPrompt.cancellation` and `outcome`: a quoting client's live terms replace the booking's stored
/// snapshot, and the snapshot is kept whenever quoting is unavailable or fails.
final class BookingCancelPromptTests: XCTestCase {

    private func text() -> TRPBookingText {
        TRPBookingText(localize: { _, fallback in fallback })
    }

    private func prompt() -> BookingCancelPrompt {
        var prompt = BookingCancelPrompt(text: text())
        prompt.formatting.locale = Locale(identifier: "en_US")
        return prompt
    }

    private func booking(cancellation: BookingContract.Booking.Cancellation) -> BookingContract.Booking {
        BookingContract.Booking(
            uuid: "3f6c1a9e-8d2b-4b7a-a1c4-5e9f0d2b7c11", status: .init(.confirmed), provider: "viator",
            providerReference: "BR-1122334455",
            product: BookingContract.Product(id: "5010BCN_SAGRADA", optionId: "TG1",
                                             title: "Sagrada Família guided tour", imageUrl: nil),
            units: ["ADULT": 2], start: BookingContract.Booking.Start(date: "2026-10-15", time: "10:30", timezone: "Europe/Madrid"),
            durationMinutes: 90, meetingPoint: nil, amount: BookingContract.Money(amount: "145.00", currency: "EUR"),
            utcExpiresAt: nil, vouchers: [], cancellation: cancellation, refund: nil,
            contact: BookingContract.Booking.Contact(name: "Cem Yilmaz", email: "cem@example.com"))
    }

    private static let snapshot = BookingContract.Booking.Cancellation(
        allowed: true, deadline: "2026-10-14T08:30:00Z", refund: .init(.full), refundAmount: nil)

    func testQuotingClientWithADifferingPartialRefundOverridesTheSnapshot() async throws {
        let quoted = BookingContract.Booking.Cancellation(
            allowed: true, deadline: "2026-10-14T08:30:00Z", refund: .init(.partial),
            refundAmount: BookingContract.Money(amount: "31.25", currency: "EUR"))
        let client = StubQuotingClient(result: .success(quoted))
        let booking = booking(cancellation: Self.snapshot)
        let prompt = prompt()

        let cancellation = await BookingCancelPrompt.cancellation(for: booking, client: client)

        XCTAssertNotEqual(cancellation, Self.snapshot)
        let outcome = prompt.outcome(for: booking, cancellation: cancellation)
        guard case .confirm(let message) = outcome else { return XCTFail("expected a confirm outcome") }
        XCTAssertTrue(message.contains("31.25"), message)
    }

    func testQuotingClientThatThrowsFallsBackToTheSnapshot() async throws {
        let client = StubQuotingClient(result: .failure(URLError(.notConnectedToInternet)))
        let booking = booking(cancellation: Self.snapshot)
        let prompt = prompt()

        let cancellation = await BookingCancelPrompt.cancellation(for: booking, client: client)

        XCTAssertEqual(cancellation, Self.snapshot)
        let outcome = prompt.outcome(for: booking, cancellation: cancellation)
        guard case .confirm(let message) = outcome else { return XCTFail("expected a confirm outcome") }
        XCTAssertTrue(message.contains("145.00"), message)
    }

    func testNonConformingClientReturnsTheSnapshotWithoutQuoting() async throws {
        let booking = booking(cancellation: Self.snapshot)

        let cancellation = await BookingCancelPrompt.cancellation(for: booking, client: NonQuotingBookingClient())

        XCTAssertEqual(cancellation, Self.snapshot)
    }

    func testDisallowedQuoteIsReportedAsNotCancellable() async throws {
        let quoted = BookingContract.Booking.Cancellation(allowed: false, deadline: nil, refund: .init(.none), refundAmount: nil)
        let client = StubQuotingClient(result: .success(quoted))
        let booking = booking(cancellation: Self.snapshot)
        let prompt = prompt()

        let cancellation = await BookingCancelPrompt.cancellation(for: booking, client: client)
        let outcome = prompt.outcome(for: booking, cancellation: cancellation)

        guard case .notCancellable = outcome else { return XCTFail("expected a notCancellable outcome") }
    }

    func testBookingWithAnotherCancellationOnlyReplacesTheCancellation() throws {
        let original = booking(cancellation: Self.snapshot)
        let quoted = BookingContract.Booking.Cancellation(
            allowed: false, deadline: nil, refund: .init(.none), refundAmount: nil)

        let replaced = BookingCancelPrompt.booking(original, with: quoted)

        XCTAssertEqual(replaced.cancellation, quoted)
        XCTAssertEqual(replaced.uuid, original.uuid)
        XCTAssertEqual(replaced.status, original.status)
        XCTAssertEqual(replaced.amount, original.amount)
    }

}

private struct NonQuotingBookingClient: BookingClient {
    func list(status: [BookingContract.BookingStatus], page: Int, limit: Int,
             lang: String) async throws -> BookingContract.BookingPage {
        throw URLError(.notConnectedToInternet)
    }

    func get(uuid: String, lang: String) async throws -> BookingContract.Booking {
        throw URLError(.notConnectedToInternet)
    }

    func cancel(uuid: String, reason: String?, lang: String,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.Booking {
        throw URLError(.notConnectedToInternet)
    }
}

private struct StubQuotingClient: BookingClient, BookingCancellationQuoting {
    let result: Result<BookingContract.Booking.Cancellation, Error>

    func list(status: [BookingContract.BookingStatus], page: Int, limit: Int,
             lang: String) async throws -> BookingContract.BookingPage {
        throw URLError(.notConnectedToInternet)
    }

    func get(uuid: String, lang: String) async throws -> BookingContract.Booking {
        throw URLError(.notConnectedToInternet)
    }

    func cancel(uuid: String, reason: String?, lang: String,
               idempotencyKey: BookingContract.IdempotencyKey) async throws -> BookingContract.Booking {
        throw URLError(.notConnectedToInternet)
    }

    func cancellationQuote(uuid: String) async throws -> BookingContract.Booking.Cancellation {
        try result.get()
    }
}
