import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// What the timeline map is asked to route for the selected day: one walking route per itinerary
/// segment for Civitatis, and the day's located items per city for the day-legs style.
final class TRPMapRouteInputTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis
    private var originalZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
        originalZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "Europe/Madrid")!
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        NSTimeZone.default = originalZone
        super.tearDown()
    }

    /// The mock trip with a segment for its Dec 9 plan, which the mock itself leaves without one.
    private func makeTimeline(generatedPlanIds: Set<String>) -> TRPTimeline {
        var timeline = TRPTimelineMockData.getMockTimeline()
        timeline.plans = timeline.plans?.map { plan in
            var plan = plan
            if generatedPlanIds.contains(plan.id) { plan.generatedStatus = 1 }
            return plan
        }
        let dayPlan = TRPTimelineSegment()
        dayPlan.segmentType = .itinerary
        dayPlan.startDate = "2025-12-09 09:00"
        dayPlan.endDate = "2025-12-09 22:00"
        dayPlan.city = timeline.city
        dayPlan.coordinate = timeline.city.coordinate
        dayPlan.dayIds = [25461]
        timeline.tripProfile?.segments.append(dayPlan)
        return timeline
    }

    private func makeViewModel(provider: TripianProvider, generatedPlanIds: Set<String> = []) -> TRPTimelineItineraryViewModel {
        TRPCoreKit.shared.provider = provider
        return TRPTimelineItineraryViewModel(timeline: makeTimeline(generatedPlanIds: generatedPlanIds))
    }

    private func select(_ ymd: String, in viewModel: TRPTimelineItineraryViewModel) {
        guard let index = viewModel.getDayDates().firstIndex(where: { TRPDateHelper.formatDateString($0) == ymd }) else {
            return XCTFail("\(ymd) is not a day of the mock trip")
        }
        viewModel.selectDay(at: index)
    }

    private func planPoiIds(_ planId: String) -> [String] {
        return TRPTimelineMockData.getMockTimeline().plans!.first { $0.id == planId }!.steps.compactMap { $0.poi?.id }
    }

    // MARK: - Walking route per segment (Civitatis)

    func testEachItinerarySegmentIsRoutedThroughItsPlacesInOrder() {
        let viewModel = makeViewModel(provider: .civitatis)
        select("2025-12-07", in: viewModel)

        XCTAssertEqual(viewModel.getSegmentsWithPoisForSelectedDay().map { $0.map { $0.id } }, [planPoiIds("25459")])
    }

    func testBookedActivitiesAddNoPlacesToTheWalkingRoutes() {
        let viewModel = makeViewModel(provider: .civitatis)
        select("2025-12-09", in: viewModel)

        XCTAssertEqual(viewModel.getSegmentsWithPoisForSelectedDay().map { $0.map { $0.id } }, [planPoiIds("25461")])
    }

    func testADayWithoutPlacesHasNoWalkingRoutes() {
        let viewModel = makeViewModel(provider: .civitatis)
        select("2025-12-25", in: viewModel)

        XCTAssertTrue(viewModel.getSegmentsWithPoisForSelectedDay().isEmpty)
    }

    // MARK: - Day legs

    func testDayLegsRouteEveryLocatedItemOfACityInListOrder() {
        let viewModel = makeViewModel(provider: .nexus, generatedPlanIds: ["25461"])
        select("2025-12-09", in: viewModel)

        let groups = viewModel.getRouteGroupsForMap()

        XCTAssertEqual(groups.count, 1, "Madrid holds a single located item, so it gets no route")
        XCTAssertEqual(groups.first?.cityIndex, 0)
        XCTAssertEqual(groups.first?.locations.count, 7)
        XCTAssertEqual(groups.first?.locations.first?.lat, 41.3850639)
    }

    func testDayLegsSkipItemsWithoutALocation() {
        TRPCoreKit.shared.provider = .nexus
        let timeline = makeTimeline(generatedPlanIds: ["25461"])
        timeline.tripProfile?.segments[2].additionalData?.isNoLocation = true
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        select("2025-12-09", in: viewModel)

        XCTAssertEqual(viewModel.getRouteGroupsForMap().first?.locations.count, 6)
    }

    func testDayLegsNeedTwoLocatedItems() {
        let viewModel = makeViewModel(provider: .nexus)
        select("2025-12-09", in: viewModel)

        XCTAssertTrue(viewModel.getRouteGroupsForMap().isEmpty)
    }
}
