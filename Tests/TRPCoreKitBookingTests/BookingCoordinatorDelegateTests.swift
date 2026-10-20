import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// Covers what `TRPBookingCoordinator` tells its delegate while a checkout runs.
@MainActor
final class BookingCoordinatorDelegateTests: XCTestCase {

    func testStartingACheckoutReportsItsBookingUuidOnceBeforeTheCheckoutIsCreated() async throws {
        let client = CreateRecordingClient()
        let coordinator = TRPBookingCoordinator(checkout: client, bookings: UnusedBookingClient(), lang: "en", currency: "EUR")
        let delegate = DelegateSpy(client: client)
        coordinator.delegate = delegate

        XCTAssertTrue(coordinator.start(productId: "C_48213_12", title: "Palma Cathedral", from: UIViewController()))
        XCTAssertEqual(delegate.startedUuids.count, 1)
        XCTAssertEqual(delegate.createdBeforeStart, [false])

        let deadline = Date().addingTimeInterval(5)
        while client.createdUuids.isEmpty, Date() < deadline { await Task.yield() }
        XCTAssertEqual(client.createdUuids, delegate.startedUuids)
    }
}

private final class DelegateSpy: TRPBookingCoordinatorDelegate {
    let client: CreateRecordingClient
    private(set) var startedUuids: [String] = []
    private(set) var createdBeforeStart: [Bool] = []

    init(client: CreateRecordingClient) {
        self.client = client
    }

    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didFinishWith checkout: BC.Checkout?) {}

    func bookingCoordinator(_ coordinator: TRPBookingCoordinator, didStartCheckout bookingUuid: String) {
        startedUuids.append(bookingUuid)
        createdBeforeStart.append(!client.createdUuids.isEmpty)
    }
}

/// Records the booking uuid of every checkout it is asked to create, then answers as an unreachable server.
private final class CreateRecordingClient: CheckoutClient, @unchecked Sendable {
    private let lock = NSLock()
    private var created: [String] = []

    var createdUuids: [String] { lock.withLock { created } }

    func create(_ request: BC.CreateCheckoutRequest, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        lock.withLock { created.append(request.bookingUuid) }
        throw URLError(.notConnectedToInternet)
    }

    func get(id: String, lang: String) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }

    func submit(checkoutId: String, stepId: String, answers: BC.Answers, expectedAmount: BC.Money?, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }

    func back(checkoutId: String, fromStepId: String, lang: String,
              idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }

    func action(checkoutId: String, actionId: String, result: BC.ActionResult, lang: String,
                idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }

    func extend(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }

    func cancel(checkoutId: String, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.CheckoutResponse {
        throw URLError(.notConnectedToInternet)
    }
}

private struct UnusedBookingClient: BookingClient {
    func list(status: [BC.BookingStatus], page: Int, limit: Int, lang: String) async throws -> BC.BookingPage {
        throw URLError(.notConnectedToInternet)
    }

    func get(uuid: String, lang: String) async throws -> BC.Booking {
        throw URLError(.notConnectedToInternet)
    }

    func cancel(uuid: String, reason: String?, lang: String, idempotencyKey: BC.IdempotencyKey) async throws -> BC.Booking {
        throw URLError(.notConnectedToInternet)
    }
}
