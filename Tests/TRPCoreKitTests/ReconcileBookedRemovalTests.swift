import Testing
import TRPFoundationKit
@testable import TRPCoreKit

/// Test suite for `BookedActivityPairing.bookedSegmentsMissingFromHost`, the reconcile step that
/// removes booked-activity segments the host no longer reports.
@Suite("Reconcile Booked Removal Tests")
struct ReconcileBookedRemovalTests {

    @Test("Booked segment the host no longer reports is removed")
    func testStaleBookedSegmentIsRemoved() {
        let host = tripItem(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let stale = bookedSegment(activityId: "200", lineId: "L2", cityId: 2, start: "2026-10-22 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [host], segments: [stale])

        #expect(result == [0])
    }

    @Test("Booked segment still reported by the host is kept")
    func testBookedSegmentStillPresentIsKept() {
        let host = tripItem(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let segment = bookedSegment(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [host], segments: [segment])

        #expect(result == [])
    }

    @Test("Booked segment without an activity id is never a removal candidate")
    func testBookedSegmentWithoutActivityIdIsKept() {
        let host = tripItem(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let segment = bookedSegment(activityId: nil, lineId: nil, cityId: 2, start: "2026-10-22 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [host], segments: [segment])

        #expect(result == [])
    }

    @Test("Host trip items with no activity id trip the guard and keep everything")
    func testIdLessHostTripItemsTripTheGuard() {
        let idLessHost = tripItem(activityId: nil, lineId: nil, cityId: 1, start: "2026-10-21 09:00")
        let segment = bookedSegment(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [idLessHost], segments: [segment])

        #expect(result == nil)
    }

    @Test("Empty host trip item list trips the guard and keeps everything")
    func testEmptyHostTripItemListTripsTheGuard() {
        let segment = bookedSegment(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [], segments: [segment])

        #expect(result == nil)
    }

    @Test("Partial host payload with one id-less trip item trips the guard and keeps all booked segments")
    func testPartialHostPayloadKeepsAllBookedSegments() {
        let keyedHost = tripItem(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let idLessHost = tripItem(activityId: nil, lineId: "L2", cityId: 2, start: "2026-10-22 09:00")
        let stillBooked = bookedSegment(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let unmatched = bookedSegment(activityId: "200", lineId: "L2", cityId: 2, start: "2026-10-22 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(
            tripItems: [keyedHost, idLessHost],
            segments: [stillBooked, unmatched]
        )

        #expect(result == nil)
    }

    @Test("Two legs sharing a product id by line id: only the cancelled leg is removed")
    func testTwoLegsSameProductIdDifferentLineIdOnlyCancelledLegRemoved() {
        let inbound = tripItem(activityId: "100", lineId: "L-IN", cityId: 1, start: "2026-10-21 09:00")
        let storedInbound = bookedSegment(activityId: "100", lineId: "L-IN", cityId: 1, start: "2026-10-21 09:00")
        let storedOutbound = bookedSegment(activityId: "100", lineId: "L-OUT", cityId: 2, start: "2026-10-28 10:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(
            tripItems: [inbound],
            segments: [storedInbound, storedOutbound]
        )

        #expect(result == [1])
    }

    @Test("Two legacy legs without line id distinguished by city and day: only the cancelled leg is removed")
    func testTwoLegacyLegsDistinguishedByCityAndDayOnlyCancelledLegRemoved() {
        let inbound = tripItem(activityId: "100", lineId: nil, cityId: 1, start: "2026-10-21 09:00")
        let storedInbound = bookedSegment(activityId: "100", lineId: nil, cityId: 1, start: "2026-10-21 09:00")
        let storedOutbound = bookedSegment(activityId: "100", lineId: nil, cityId: 2, start: "2026-10-28 10:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(
            tripItems: [inbound],
            segments: [storedInbound, storedOutbound]
        )

        #expect(result == [1])
    }

    @Test("Reserved segments are never returned regardless of host state")
    func testReservedSegmentsNeverReturned() {
        let host = tripItem(activityId: "100", lineId: "L1", cityId: 1, start: "2026-10-21 09:00")
        let reserved = reservedSegment(activityId: "999", lineId: nil, cityId: 2, start: "2026-10-22 09:00")

        let result = BookedActivityPairing.bookedSegmentsMissingFromHost(tripItems: [host], segments: [reserved])

        #expect(result == [])
    }

    private func tripItem(activityId: String?, lineId: String?, cityId: Int, start: String) -> TRPSegmentActivityItem {
        TRPSegmentActivityItem(activityId: activityId, bookingId: nil, title: "Transfer", imageUrl: nil,
                               description: nil, startDatetime: start, endDatetime: nil,
                               coordinate: TRPLocation(lat: 28.1, lon: -16.6), cancellation: nil,
                               adultCount: 2, childCount: 0, cityId: cityId, lineId: lineId)
    }

    private func bookedSegment(activityId: String?, lineId: String?, cityId: Int, start: String) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.cityId = cityId
        segment.startDate = start
        segment.additionalData = TRPSegmentActivityItem(activityId: activityId, bookingId: nil, title: "Transfer",
                                                        imageUrl: nil, description: nil, startDatetime: start,
                                                        endDatetime: nil, coordinate: TRPLocation(lat: 28.1, lon: -16.6),
                                                        cancellation: nil, adultCount: 2, childCount: 0,
                                                        cityId: cityId, lineId: lineId)
        return segment
    }

    private func reservedSegment(activityId: String?, lineId: String?, cityId: Int, start: String) -> TRPTimelineSegment {
        let segment = bookedSegment(activityId: activityId, lineId: lineId, cityId: cityId, start: start)
        segment.segmentType = .reservedActivity
        return segment
    }
}
