import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins the key identity, the trip scope, the itinerary-only gate and the self-cleanup of `TRPBackgroundGenerationRegistry`,
/// independent of the shared singleton instance used elsewhere.
final class TRPBackgroundGenerationRegistryTests: XCTestCase {

    private var registry: TRPBackgroundGenerationRegistry!
    private let tripHash = "registry-trip"

    override func setUp() {
        super.setUp()
        registry = TRPBackgroundGenerationRegistry()
    }

    private func itinerarySegment(title: String = "Trip", startDate: String = "2025-12-09 10:00", cityId: Int = 109) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .itinerary
        segment.title = title
        segment.startDate = startDate
        segment.cityId = cityId
        return segment
    }

    func testRegisteringASegmentsKeyMakesItTracked() {
        let segment = itinerarySegment()
        XCTAssertFalse(registry.isTracked(segment, tripHash: tripHash))

        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: tripHash)

        XCTAssertTrue(registry.isTracked(segment, tripHash: tripHash))
        XCTAssertFalse(registry.isEmpty)
    }

    func testUnregisteringRemovesTheKey() {
        let segment = itinerarySegment()
        let key = TRPRecommendationSegmentKey(segment: segment)
        registry.register(key, tripHash: tripHash)
        XCTAssertTrue(registry.isTracked(segment, tripHash: tripHash))

        registry.unregister(key, tripHash: tripHash)

        XCTAssertFalse(registry.isTracked(segment, tripHash: tripHash))
        XCTAssertTrue(registry.isEmpty)
    }

    func testNonItinerarySegmentIsNeverTrackedEvenWithAMatchingKey() {
        let segment = itinerarySegment()
        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: tripHash)
        segment.segmentType = .reservedActivity

        XCTAssertFalse(registry.isTracked(segment, tripHash: tripHash), "only itinerary segments are subject to background-generation tracking")
    }

    func testKeyIgnoresTheTimeOfDayAndKeepsOnlyTheDayPrefix() {
        let morning = itinerarySegment(startDate: "2025-12-09 10:00")
        let evening = itinerarySegment(startDate: "2025-12-09 22:30")

        registry.register(TRPRecommendationSegmentKey(segment: morning), tripHash: tripHash)

        XCTAssertTrue(registry.isTracked(evening, tripHash: tripHash), "same title/day/city, different time of day, must match")
    }

    func testKeyDistinguishesSegmentsByTitleDayOrCity() {
        let base = itinerarySegment(title: "Trip", startDate: "2025-12-09 10:00", cityId: 109)
        registry.register(TRPRecommendationSegmentKey(segment: base), tripHash: tripHash)

        XCTAssertFalse(registry.isTracked(itinerarySegment(title: "Other", startDate: "2025-12-09 10:00", cityId: 109), tripHash: tripHash))
        XCTAssertFalse(registry.isTracked(itinerarySegment(title: "Trip", startDate: "2025-12-10 10:00", cityId: 109), tripHash: tripHash))
        XCTAssertFalse(registry.isTracked(itinerarySegment(title: "Trip", startDate: "2025-12-09 10:00", cityId: 45), tripHash: tripHash))
    }

    func testRemoveAllClearsEveryRegisteredKey() {
        let first = itinerarySegment(title: "First")
        let second = itinerarySegment(title: "Second")
        registry.register(TRPRecommendationSegmentKey(segment: first), tripHash: tripHash)
        registry.register(TRPRecommendationSegmentKey(segment: second), tripHash: tripHash)

        registry.removeAll()

        XCTAssertTrue(registry.isEmpty)
        XCTAssertFalse(registry.isTracked(first, tripHash: tripHash))
        XCTAssertFalse(registry.isTracked(second, tripHash: tripHash))
    }

    func testUnregisteringAnUnknownKeyIsANoOp() {
        let segment = itinerarySegment()
        registry.unregister(TRPRecommendationSegmentKey(segment: segment), tripHash: tripHash)

        XCTAssertTrue(registry.isEmpty)
        XCTAssertFalse(registry.isTracked(segment, tripHash: tripHash))
    }

    func testKeyRegisteredForAnotherTripIsNotTracked() {
        let segment = itinerarySegment()
        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: "other-trip")

        XCTAssertFalse(registry.isTracked(segment, tripHash: tripHash))
        XCTAssertTrue(registry.isTracked(segment, tripHash: "other-trip"))
    }

    func testKeyOfAnotherTripIsNotIgnoredAndSurvivesThePoll() {
        let (timeline, segment) = timelineWithPendingPlan(of: itinerarySegment(), planId: 7001)
        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: "other-trip")

        XCTAssertTrue(registry.ignoredPlanIds(in: timeline).isEmpty)
        XCTAssertTrue(registry.isTracked(segment, tripHash: "other-trip"))
    }

    func testPollWithTheTrackedPlanStillPendingIgnoresItsDayIdsAndKeepsTheKey() {
        let (timeline, segment) = timelineWithPendingPlan(of: itinerarySegment(), planId: 7001)
        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: timeline.tripHash)

        XCTAssertEqual(registry.ignoredPlanIds(in: timeline), [7001])
        XCTAssertTrue(registry.isTracked(segment, tripHash: timeline.tripHash))
    }

    func testPollThatSeesTheTrackedPlanGeneratedRemovesTheKey() {
        let (timeline, segment) = timelineWithPendingPlan(of: itinerarySegment(), planId: 7001, generatedStatus: 1)
        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: timeline.tripHash)

        XCTAssertTrue(registry.ignoredPlanIds(in: timeline).isEmpty)
        XCTAssertTrue(registry.isEmpty)
    }

    func testPollThatNoLongerFindsTheTrackedSegmentRemovesTheKey() {
        let (timeline, _) = timelineWithPendingPlan(of: itinerarySegment(), planId: 7001)
        registry.register(TRPRecommendationSegmentKey(segment: itinerarySegment(title: "Deleted")), tripHash: timeline.tripHash)

        XCTAssertTrue(registry.ignoredPlanIds(in: timeline).isEmpty)
        XCTAssertTrue(registry.isEmpty)
    }

    /// Mock timeline holding `segment`, linked through `dayIds` to one plan with `generatedStatus`.
    private func timelineWithPendingPlan(of segment: TRPTimelineSegment, planId: Int, generatedStatus: Int = 0) -> (TRPTimeline, TRPTimelineSegment) {
        var timeline = GenerationFixtures.generatedMockTimeline()
        segment.dayIds = [planId]
        timeline.tripProfile?.segments.append(segment)
        timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "\(planId)", generatedStatus: generatedStatus)]
        return (timeline, segment)
    }
}
