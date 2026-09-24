import XCTest
@testable import TRPCoreKit

/// Reservations the builder can reject before looking anything up. Anything that decodes to at least
/// one reservation resolves its city over the network, so the trip range is not covered here.
final class NexusItineraryBuilderTests: XCTestCase {

    private func build(_ json: String?) -> (itinerary: TRPItineraryWithActivities?, onMainThread: Bool) {
        let done = expectation(description: "builder completes")
        var result: (TRPItineraryWithActivities?, Bool) = (nil, false)
        NexusItineraryBuilder.build(reservationsJson: json) { itinerary in
            result = (itinerary, Thread.isMainThread)
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        return result
    }

    func testMissingReservationsBuildNothing() {
        let result = build(nil)

        XCTAssertNil(result.itinerary)
        XCTAssertTrue(result.onMainThread)
    }

    func testMalformedReservationsBuildNothing() {
        let result = build("{\"Date\": \"2026-07-02\"}")

        XCTAssertNil(result.itinerary)
        XCTAssertTrue(result.onMainThread)
    }

    func testEmptyReservationListBuildsNothing() {
        let result = build("[]")

        XCTAssertNil(result.itinerary)
        XCTAssertTrue(result.onMainThread)
    }
}
