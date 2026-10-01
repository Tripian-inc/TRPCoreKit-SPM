import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// A host booking without an end time must still reach the API with a usable `endDate`, otherwise the segment is rejected with a 400.
final class TRPBookedActivityMissingEndTests: XCTestCase {

    private let start = "2026-10-09 10:30"

    private func booking(end: String?, duration: Double?) -> TRPSegmentActivityItem {
        TRPSegmentActivityItem(activityId: "111", bookingId: "B-111", title: "Tour", imageUrl: nil, description: nil,
                               startDatetime: start, endDatetime: end,
                               coordinate: TRPLocation(lat: 41.38, lon: 2.17), cancellation: nil, adultCount: 2, childCount: 0,
                               duration: duration, cityId: 1)
    }

    private let cases: [(end: String?, duration: Double?, expectedEnd: String)] = [
        (nil, 90, "2026-10-09 12:00"),
        ("", 90, "2026-10-09 12:00"),
        (nil, nil, "2026-10-09 10:30"),
        ("", nil, "2026-10-09 10:30"),
        ("2026-10-09 13:00", 90, "2026-10-09 13:00")
    ]

    func testSyncedBookingSendsAnEndDate() {
        let viewModel = TRPTimelineItineraryViewModel(timeline: nil)
        for testCase in cases {
            let profile = viewModel.createSegmentProfileFromTripItem(booking(end: testCase.end, duration: testCase.duration), tripHash: "hash")
            let parameters = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "hash")?.getParameters()

            XCTAssertEqual(parameters?["endDate"] as? String, testCase.expectedEnd, "end: \(testCase.end ?? "nil"), duration: \(String(describing: testCase.duration))")
        }
    }

    func testBookingInTheCreatedTimelineHasAnEndDate() {
        for testCase in cases {
            let itinerary = TRPItineraryWithActivities(tripName: nil, startDatetime: "2026-10-08 00:00", endDatetime: "2026-10-12 23:59",
                                                       uniqueId: "u", tripianHash: nil, destinationItems: [], favouriteItems: nil,
                                                       tripItems: [booking(end: testCase.end, duration: testCase.duration)])

            let booked = itinerary.createTimelineProfileFromBookings().segments.first { $0.segmentType == .bookedActivity }

            XCTAssertEqual(booked?.endDate, testCase.expectedEnd, "end: \(testCase.end ?? "nil"), duration: \(String(describing: testCase.duration))")
        }
    }
}
