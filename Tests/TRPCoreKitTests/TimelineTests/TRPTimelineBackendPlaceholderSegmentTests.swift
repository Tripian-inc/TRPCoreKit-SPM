import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// The backend pre-allocates an "empty" segment (REST `segmentType == "empty"`) that the mapper
/// maps as `.itinerary` but flags with `isBackendPlaceholder`. It never gets generated, so without
/// the flag its plan (no steps, `generatedStatus == -1`) looked exactly like a real plan that failed
/// to generate and triggered the "No recommendations found for this area" message on every day.
final class TRPTimelineBackendPlaceholderSegmentTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis
    private var originalZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
        originalZone = NSTimeZone.default
        TRPCoreKit.shared.provider = .nexus
        NSTimeZone.default = TimeZone(identifier: "Europe/Madrid")!
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        NSTimeZone.default = originalZone
        super.tearDown()
    }

    private final class SpyTimelineDelegate: TRPTimelineItineraryViewModelDelegate {
        private(set) var shownMessages: [(message: String, type: EvrAlertLevel)] = []
        var messageExpectation: XCTestExpectation?

        func timelineItineraryViewModel(didUpdateTimeline: Bool) {}
        func timelineItineraryViewModel(noCitiesAvailable: Bool) {}
        func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}

        func viewModel(showMessage: String, type: EvrAlertLevel) {
            shownMessages.append((showMessage, type))
            messageExpectation?.fulfill()
        }
    }

    private let barcelona = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))
    private let targetDay = "2025-12-10"

    private func emptyPlan(id: String) -> TRPTimelinePlan {
        return TRPTimelinePlan(
            id: id,
            startDate: "2025-12-10 09:00",
            endDate: "2025-12-10 10:00",
            steps: [],
            available: true,
            tripType: 3,
            name: nil,
            description: nil,
            generatedStatus: -1,
            children: 0,
            pets: 0,
            adults: 1,
            city: barcelona,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }

    private func itinerarySegment(dayId: Int, isBackendPlaceholder: Bool?) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .itinerary
        segment.startDate = "2025-12-10 09:00"
        segment.endDate = "2025-12-10 10:00"
        segment.city = barcelona
        segment.coordinate = barcelona.coordinate
        segment.dayIds = [dayId]
        segment.isBackendPlaceholder = isBackendPlaceholder
        return segment
    }

    private func makeViewModel(extraSegments: [TRPTimelineSegment], extraPlans: [TRPTimelinePlan]) -> TRPTimelineItineraryViewModel {
        var timeline = TRPTimelineMockData.getMockTimeline()
        timeline.tripProfile?.segments.append(contentsOf: extraSegments)
        timeline.plans = (timeline.plans ?? []) + extraPlans
        return TRPTimelineItineraryViewModel(timeline: timeline)
    }

    private func select(_ viewModel: TRPTimelineItineraryViewModel) {
        guard let index = viewModel.getDayDates().firstIndex(where: { TRPDateHelper.formatDateString($0) == targetDay }) else {
            return XCTFail("\(targetDay) is not a day of the mock trip")
        }
        viewModel.selectDay(at: index)
    }

    private func flushMainQueue() {
        let expectation = expectation(description: "main queue flushed")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }

    func testBackendPlaceholderSegmentAloneIsNotReported() {
        let segment = itinerarySegment(dayId: 90001, isBackendPlaceholder: true)
        let viewModel = makeViewModel(extraSegments: [segment], extraPlans: [emptyPlan(id: "90001")])
        let spy = SpyTimelineDelegate()
        viewModel.delegate = spy

        select(viewModel)
        flushMainQueue()

        XCTAssertTrue(viewModel.reportedEmptyPlanIds.isEmpty)
        XCTAssertTrue(spy.shownMessages.isEmpty)
    }

    func testRealEmptySegmentIsStillReported() {
        let segment = itinerarySegment(dayId: 90002, isBackendPlaceholder: nil)
        let viewModel = makeViewModel(extraSegments: [segment], extraPlans: [emptyPlan(id: "90002")])
        let spy = SpyTimelineDelegate()
        spy.messageExpectation = expectation(description: "no recommendations message shown")
        viewModel.delegate = spy

        select(viewModel)
        wait(for: [spy.messageExpectation!], timeout: 1.0)

        XCTAssertEqual(viewModel.reportedEmptyPlanIds, ["90002"])
        XCTAssertEqual(spy.shownMessages.count, 1)
        XCTAssertEqual(spy.shownMessages.first?.message, AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.noRecommendations))
        XCTAssertEqual(spy.shownMessages.first?.type, .error)
    }

    func testPlaceholderMixedWithRealSegmentOnlyReportsTheRealOne() {
        let placeholder = itinerarySegment(dayId: 90001, isBackendPlaceholder: true)
        let real = itinerarySegment(dayId: 90002, isBackendPlaceholder: nil)
        let viewModel = makeViewModel(extraSegments: [placeholder, real],
                                      extraPlans: [emptyPlan(id: "90001"), emptyPlan(id: "90002")])
        let spy = SpyTimelineDelegate()
        spy.messageExpectation = expectation(description: "no recommendations message shown")
        viewModel.delegate = spy

        select(viewModel)
        wait(for: [spy.messageExpectation!], timeout: 1.0)

        XCTAssertEqual(viewModel.reportedEmptyPlanIds, ["90002"])
        XCTAssertEqual(spy.shownMessages.count, 1)
    }

    func testDayWithNoItinerarySegmentsReportsNothing() {
        let viewModel = makeViewModel(extraSegments: [], extraPlans: [])
        let spy = SpyTimelineDelegate()
        viewModel.delegate = spy

        select(viewModel)
        flushMainQueue()

        XCTAssertTrue(viewModel.reportedEmptyPlanIds.isEmpty)
        XCTAssertTrue(spy.shownMessages.isEmpty)
    }
}
