import XCTest
@testable import TRPCoreKit

/// The Nexus flow must show and send the same calendar day wherever the traveller's device is,
/// so each check runs in zones on both sides of UTC.
final class NexusDayShiftTests: XCTestCase {

    private let zones = ["America/Mexico_City", "Pacific/Pago_Pago", "Europe/Istanbul", "Pacific/Kiritimati"]
    private var originalZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalZone = NSTimeZone.default
    }

    override func tearDown() {
        NSTimeZone.default = originalZone
        TripianNavigateBridge.shared.onNavigate = nil
        super.tearDown()
    }

    private func utc(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    private func local(_ text: String, in zone: TimeZone) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    func testReservationDaySentToTheHostDoesNotMove() {
        for id in zones {
            NSTimeZone.default = TimeZone(identifier: id)!
            var sent: [String?] = []
            TripianNavigateBridge.shared.onNavigate = { sent.append($0.date) }

            TripianNavigateBridge.shared.trpCoreKitDidRequestActivityReservation(activityId: "J_9148¬TKT_7", date: utc("2026-10-05 00:00"))
            TripianNavigateBridge.shared.trpCoreKitDidRequestActivityReservation(activityId: "J_9148¬TKT_7", date: utc("2026-10-05 23:30"))

            XCTAssertEqual(sent, ["2026-10-05", "2026-10-05"], id)
        }
    }

    func testTodayIsTheTravellersOwnDay() {
        for id in zones {
            let zone = TimeZone(identifier: id)!
            NSTimeZone.default = zone

            XCTAssertEqual(NexusItineraryBuilder.today(now: local("2026-10-05 00:10", in: zone)), "2026-10-05", id)
            XCTAssertEqual(NexusItineraryBuilder.today(now: local("2026-10-05 23:50", in: zone)), "2026-10-05", id)
        }
    }

    func testDaysUntilTheTripCountsCalendarDays() {
        var timeline = TRPTimelineMockData.getMockTimeline()
        guard var plan = timeline.plans?.first else { return XCTFail("mock timeline has no plan") }
        plan.startDate = "2026-10-08 00:00"
        plan.endDate = "2026-10-08 23:59"
        timeline.plans = [plan]

        for id in zones {
            let zone = TimeZone(identifier: id)!
            NSTimeZone.default = zone

            XCTAssertEqual(NexusTripDisplay.daysUntil(timeline, now: local("2026-10-05 00:10", in: zone)), 3, id)
            XCTAssertEqual(NexusTripDisplay.daysUntil(timeline, now: local("2026-10-05 23:50", in: zone)), 3, id)
            XCTAssertNil(NexusTripDisplay.daysUntil(timeline, now: local("2026-10-08 12:00", in: zone)), id)
        }
    }

    func testTripCardShowsThePlannedDays() {
        var timeline = TRPTimelineMockData.getMockTimeline()
        guard var plan = timeline.plans?.first else { return XCTFail("mock timeline has no plan") }
        plan.startDate = "2026-10-08 00:00"
        plan.endDate = "2026-10-10 23:59"
        timeline.plans = [plan]

        for id in zones {
            NSTimeZone.default = TimeZone(identifier: id)!
            XCTAssertEqual(NexusTripDisplay.dateRangeText(timeline), "10/08/2026 - 10/10/2026", id)
        }
    }
}
