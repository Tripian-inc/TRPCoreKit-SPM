import Foundation
import Testing
import TRPFoundationKit
@testable import TRPCoreKit

/// Test suite for NexusResumePolicy.decide (resume/recreate/create) and
/// NexusTripStore.clear persistence behaviour.
@Suite("Nexus Resume Policy Tests")
struct NexusResumePolicyTests {

    private let userDefaultsKey = "nexus_saved_trip_hash"

    private func city() -> TRPCity {
        TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))
    }

    private func sentinelSegment(start: String, end: String) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.title = "TimelineDate"
        segment.available = false
        segment.startDate = start
        segment.endDate = end
        return segment
    }

    private func plainSegment(start: String?, end: String?) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.startDate = start
        segment.endDate = end
        return segment
    }

    private func sentinelSegment(fromDay startDay: String, toDay endDay: String) -> TRPTimelineSegment {
        sentinelSegment(start: "\(startDay) 00:00", end: "\(endDay) 23:59")
    }

    private func timeline(profileSegments: [TRPTimelineSegment], segments: [TRPTimelineSegment]? = nil) -> TRPTimeline {
        let profile = TRPTimelineProfile()
        profile.segments = profileSegments
        return TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: city(), plans: [], segments: segments)
    }

    private func timeline(sentinelFromDay startDay: String, toDay endDay: String) -> TRPTimeline {
        timeline(profileSegments: [sentinelSegment(fromDay: startDay, toDay: endDay)])
    }

    private func itinerary(start: String, end: String, tripItems: [TRPSegmentActivityItem]? = nil) -> TRPItineraryWithActivities {
        TRPItineraryWithActivities(tripName: "Trip", startDatetime: start, endDatetime: end, uniqueId: "u1",
                                    tripianHash: "hash", destinationItems: [], favouriteItems: nil, tripItems: tripItems)
    }

    private func tripItem(activityId: String?, start: String) -> TRPSegmentActivityItem {
        TRPSegmentActivityItem(activityId: activityId, bookingId: nil, title: "Transfer", imageUrl: nil,
                               description: nil, startDatetime: start, endDatetime: nil,
                               coordinate: TRPLocation(lat: 28.1, lon: -16.6), cancellation: nil,
                               adultCount: 2, childCount: 0, cityId: 1, lineId: nil)
    }

    @Test("Overlapping ranges with no activity id on the reservation resume")
    func testOverlappingRangesWithNoActivityIdResume() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-28")
        let items = [tripItem(activityId: nil, start: "2026-10-22 09:00")]
        let itin = itinerary(start: "2026-10-20 00:00", end: "2026-10-25 00:00", tripItems: items)

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("Itinerary entirely after the stored timeline recreates")
    func testItineraryEntirelyAfterTimelineRecreates() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-23")
        let itin = itinerary(start: "2026-11-01 00:00", end: "2026-11-05 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .recreate)
    }

    @Test("Itinerary entirely before the stored timeline recreates")
    func testItineraryEntirelyBeforeTimelineRecreates() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-23")
        let itin = itinerary(start: "2026-09-01 00:00", end: "2026-09-05 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .recreate)
    }

    @Test("Same single day on both sides resumes")
    func testSameSingleDayBothSidesResumes() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-21")
        let itin = itinerary(start: "2026-10-21 00:00", end: "2026-10-21 23:59")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("Itinerary starting on the timeline's last day resumes")
    func testItineraryStartingOnTimelineLastDayResumes() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-28")
        let itin = itinerary(start: "2026-10-28 00:00", end: "2026-11-02 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("Itinerary starting the day after the timeline ends recreates")
    func testItineraryStartingDayAfterTimelineEndsRecreates() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-28")
        let itin = itinerary(start: "2026-10-29 00:00", end: "2026-11-02 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .recreate)
    }

    @Test("Fetch failure always creates")
    func testFetchFailureAlwaysCreates() {
        struct DummyError: Error {}
        let itin = itinerary(start: "2026-10-21 00:00", end: "2026-10-28 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .failure(DummyError()), itinerary: itin)

        #expect(decision == .create)
    }

    @Test("No TimelineDate sentinel falls back to min and max of segments and overlaps")
    func testNoSentinelFallsBackToMinMaxOfSegmentsAndOverlaps() {
        let tl = timeline(profileSegments: [plainSegment(start: "2026-10-21 09:00", end: "2026-10-22 18:00"),
                                            plainSegment(start: "2026-10-25 09:00", end: "2026-10-28 18:00")])
        let itin = itinerary(start: "2026-10-27 00:00", end: "2026-11-01 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("Timeline without any segments resumes")
    func testTimelineWithoutAnySegmentsResumes() {
        let tl = timeline(profileSegments: [])
        let itin = itinerary(start: "2026-10-27 00:00", end: "2026-11-01 00:00")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("Sentinel with unparseable dates falls back to segment min and max")
    func testSentinelWithUnparseableDatesFallsBackToSegmentMinMax() {
        let tl = timeline(profileSegments: [sentinelSegment(start: "not-a-date", end: "nope"),
                                            plainSegment(start: "2026-10-21 09:00", end: "2026-10-23 18:00")])
        let overlapping = itinerary(start: "2026-10-23 00:00", end: "2026-10-30 23:59")
        let disjoint = itinerary(start: "2026-10-24 00:00", end: "2026-10-30 23:59")

        #expect(NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: overlapping) == .resume)
        #expect(NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: disjoint) == .recreate)
    }

    @Test("Sentinel wins over conflicting segment dates")
    func testSentinelWinsOverConflictingSegmentDates() {
        let tl = timeline(profileSegments: [sentinelSegment(fromDay: "2026-10-21", toDay: "2026-10-23"),
                                            plainSegment(start: "2026-11-01 09:00", end: "2026-11-05 18:00")],
                          segments: [plainSegment(start: "2026-11-01 09:00", end: "2026-11-05 18:00")])
        let itin = itinerary(start: "2026-11-02 00:00", end: "2026-11-04 23:59")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .recreate)
        #expect(NexusResumePolicy.timelineDayRange(tl) == NexusResumePolicy.dayRange(start: "2026-10-21", end: "2026-10-23"))
    }

    @Test("Itinerary range that does not parse resumes")
    func testUnparseableItineraryRangeResumes() {
        let tl = timeline(sentinelFromDay: "2026-10-21", toDay: "2026-10-23")
        let itin = itinerary(start: "", end: "garbage")

        let decision = NexusResumePolicy.decide(fetchResult: .success(tl), itinerary: itin)

        #expect(decision == .resume)
    }

    @Test("NexusTripStore.clear removes the stored hash")
    func testNexusTripStoreClearRemovesStoredHash() {
        let previous = UserDefaults.standard.string(forKey: userDefaultsKey)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: userDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
        }

        NexusTripStore.tripHash = "abc123"
        #expect(UserDefaults.standard.string(forKey: userDefaultsKey) == "abc123")

        NexusTripStore.clear()

        #expect(UserDefaults.standard.string(forKey: userDefaultsKey) == nil)
        #expect(NexusTripStore.tripHash == nil)
    }
}
