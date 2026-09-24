import XCTest
import MapboxDirections
import TRPFoundationKit
@testable import TRPCoreKit

/// Nexus lists a day as one flat, time-ordered run of rows with route legs between them. These build
/// the rows from the mock trip, with the plans marked generated because a plan still generating has none.
final class NexusFlatTimelineTests: XCTestCase {

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

    // MARK: - Helpers

    private let barcelona = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))

    private func makeViewModel(generatedPlanIds: Set<String>,
                               extraSegments: [TRPTimelineSegment] = [],
                               accommodation: TRPAccommodation? = nil) -> TRPTimelineItineraryViewModel {
        var timeline = TRPTimelineMockData.getMockTimeline()
        timeline.plans = timeline.plans?.map { plan in
            var plan = plan
            if generatedPlanIds.contains(plan.id) { plan.generatedStatus = 1 }
            return plan
        }
        if let accommodation = accommodation {
            timeline.tripProfile?.segments.first?.accommodation = accommodation
        }
        timeline.tripProfile?.segments.append(contentsOf: extraSegments)
        return TRPTimelineItineraryViewModel(timeline: timeline)
    }

    private func select(_ ymd: String, in viewModel: TRPTimelineItineraryViewModel) {
        guard let index = viewModel.getDayDates().firstIndex(where: { TRPDateHelper.formatDateString($0) == ymd }) else {
            return XCTFail("\(ymd) is not a day of the mock trip")
        }
        viewModel.selectDay(at: index)
    }

    /// The mock gives its Dec 9 plan no segment of its own, so the day only shows bookings without one.
    private func dayPlanSegment() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .itinerary
        segment.title = "Sagrada Familia & Markets"
        segment.startDate = "2025-12-09 09:00"
        segment.endDate = "2025-12-09 22:00"
        segment.city = barcelona
        segment.coordinate = barcelona.coordinate
        segment.dayIds = [25461]
        return segment
    }

    private func reservedSegment(title: String, start: String, end: String, flexible: Bool) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .reservedActivity
        segment.title = title
        segment.startDate = start
        segment.endDate = end
        segment.city = barcelona
        segment.coordinate = TRPLocation(lat: 41.40, lon: 2.17)
        var activity = TRPSegmentActivityItem(
            activityId: "J_555_7", bookingId: nil, title: title, imageUrl: nil, description: nil,
            startDatetime: start, endDatetime: end, coordinate: TRPLocation(lat: 41.40, lon: 2.17),
            cancellation: nil, adultCount: 2, childCount: 0, cityId: 109
        )
        if flexible { activity.duration = -1 }
        segment.additionalData = activity
        return segment
    }

    /// One short description per row, so a whole day can be compared at once.
    private func describe(_ rows: [TimelineFlatRow]) -> [String] {
        return rows.map { row in
            switch row {
            case .flexibleActivity(let item): return "flexible \(item.title ?? "")"
            case .startingPoint: return "start"
            case .routeSeparator: return "route"
            case .bookedActivity(let item, let order): return "\(order) \(item.isReservedActivity ? "reserved" : "booked") \(item.title ?? "")"
            case .manualPoi(let item, let order): return "\(order) poi \(item.title ?? "")"
            case .planStep(_, _, let order): return "\(order) step \(row.step?.id ?? 0)"
            }
        }
    }

    private func routeLeg(meters: Double, seconds: TimeInterval) -> TRPStepRouteInfo {
        let leg = RouteLeg(steps: [], name: "", distance: meters, expectedTravelTime: seconds, profileIdentifier: .walking)
        return TRPStepRouteInfo(leg: leg, isWalking: true)
    }

    private func cacheLegsForEveryChain(of viewModel: TRPTimelineItineraryViewModel) {
        for chain in viewModel.flatRouteChains() {
            viewModel.flatRouteCache[chain.key] = (1..<chain.locations.count).map { _ in routeLeg(meters: 1250, seconds: 900) }
        }
        viewModel.buildFlatSections()
    }

    // MARK: - Rows

    func testGeneratedDayStartsAtTheCityCentreThenListsStepsInTimeOrder() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)

        XCTAssertEqual(viewModel.flatSections.count, 1)
        XCTAssertEqual(describe(viewModel.flatSections[0].rows), [
            "start", "1 step 126392", "2 step 126393", "3 step 126394", "4 step 126395", "5 step 126396", "6 step 126397"
        ])
    }

    func testStartingPointFallsBackToTheCityCentre() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)

        guard case .startingPoint(let name, let coordinate, _)? = viewModel.flatSections.first?.rows.first else {
            return XCTFail("expected the starting point first")
        }
        let cityCenter = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter)
        XCTAssertEqual(name, "Barcelona | \(cityCenter)")
        XCTAssertNotNil(coordinate)
    }

    func testStartingPointIsTheAccommodationWhenItIsLocated() {
        let hotel = TRPAccommodation(name: "Hotel Arts", referanceId: nil, address: "Carrer de la Marina 19",
                                     coordinate: TRPLocation(lat: 41.386, lon: 2.196))
        let viewModel = makeViewModel(generatedPlanIds: ["25459"], accommodation: hotel)
        select("2025-12-07", in: viewModel)

        guard case .startingPoint(let name, let coordinate, _)? = viewModel.flatSections.first?.rows.first else {
            return XCTFail("expected the starting point first")
        }
        XCTAssertEqual(name, "Hotel Arts")
        XCTAssertEqual(coordinate?.lat, 41.386)
        XCTAssertEqual(coordinate?.lon, 2.196)
    }

    func testPlanStillGeneratingShowsTheEmptyState() {
        let viewModel = makeViewModel(generatedPlanIds: [])
        select("2025-12-07", in: viewModel)

        XCTAssertTrue(viewModel.flatSections.isEmpty)
        XCTAssertEqual(viewModel.numberOfSections(), 1)
        XCTAssertEqual(viewModel.numberOfRows(in: 0), 1)
        guard case .emptyState? = viewModel.cellType(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("expected the empty state")
        }
    }

    func testBookingsAndStepsShareOneNumberingAcrossCities() {
        let viewModel = makeViewModel(generatedPlanIds: ["25461"], extraSegments: [dayPlanSegment()])
        select("2025-12-09", in: viewModel)

        XCTAssertEqual(viewModel.flatSections.map { $0.city?.name }, ["Barcelona", "Madrid"])
        XCTAssertEqual(describe(viewModel.flatSections[0].rows), [
            "start",
            "1 booked Authentic Paella Cooking Class",
            "2 step 126406", "3 step 126421", "4 step 126408", "5 step 126409", "6 step 126422", "7 step 126410"
        ])
        XCTAssertEqual(describe(viewModel.flatSections[1].rows), [
            "8 booked Madrid Day Trip: Royal Palace & Prado Museum Tour"
        ])
    }

    func testFlexibleActivityIsPinnedFirstWithoutANumber() {
        let flexible = reservedSegment(title: "Any time tour", start: "2025-12-07 00:00", end: "2025-12-07 23:59", flexible: true)
        let viewModel = makeViewModel(generatedPlanIds: ["25459"], extraSegments: [flexible])
        select("2025-12-07", in: viewModel)

        XCTAssertEqual(describe(viewModel.flatSections[0].rows).prefix(3), ["flexible Any time tour", "start", "1 step 126392"])
    }

    func testReservedActivityAtTheSameTimeAsAPlaceIsListedBeforeIt() {
        let reserved = reservedSegment(title: "Tapas tour", start: "2025-12-07 10:30", end: "2025-12-07 12:00", flexible: false)
        let viewModel = makeViewModel(generatedPlanIds: ["25459"], extraSegments: [reserved])
        select("2025-12-07", in: viewModel)

        XCTAssertEqual(describe(viewModel.flatSections[0].rows), [
            "start", "1 step 126392", "2 reserved Tapas tour", "3 step 126393", "4 step 126394", "5 step 126395", "6 step 126396", "7 step 126397"
        ])
    }

    func testRowsMapToTheCellTypesTheListRenders() {
        let viewModel = makeViewModel(generatedPlanIds: ["25461"], extraSegments: [dayPlanSegment()])
        select("2025-12-09", in: viewModel)

        guard case .startingPoint? = viewModel.cellType(at: IndexPath(row: 0, section: 0)),
              case .bookedActivity(let booked)? = viewModel.cellType(at: IndexPath(row: 1, section: 0)),
              case .planStep(let step)? = viewModel.cellType(at: IndexPath(row: 2, section: 0)) else {
            return XCTFail("unexpected cell types for the first rows")
        }
        XCTAssertEqual(booked.order, 1)
        XCTAssertEqual(step.order, 2)
        XCTAssertEqual(step.step.id, 126406)
        XCTAssertEqual(viewModel.numberOfRows(in: 0), viewModel.flatSections[0].rows.count)
    }

    // MARK: - Route legs

    func testWithoutCachedLegsNoRouteRowsAreShown() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)

        XCTAssertFalse(describe(viewModel.flatSections[0].rows).contains("route"))
    }

    func testCachedLegsAreShownBeforeTheRowTheyArriveAt() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)

        cacheLegsForEveryChain(of: viewModel)

        XCTAssertEqual(describe(viewModel.flatSections[0].rows), [
            "start",
            "route", "1 step 126392", "route", "2 step 126393", "route", "3 step 126394",
            "route", "4 step 126395", "route", "5 step 126396", "route", "6 step 126397"
        ])
    }

    func testRouteRowShowsTheLegsDistanceAndMinutes() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)
        cacheLegsForEveryChain(of: viewModel)

        guard case .routeSeparator(let data)? = viewModel.cellType(at: IndexPath(row: 1, section: 0)) else {
            return XCTFail("expected a route row after the starting point")
        }
        XCTAssertEqual(data.distance, 1.3, accuracy: 0.001)
        XCTAssertEqual(data.minutes, 15)
        XCTAssertTrue(data.isWalking)
    }

    func testMapLegsLeaveOutTheLegFromTheStartingPoint() {
        let viewModel = makeViewModel(generatedPlanIds: ["25459"])
        select("2025-12-07", in: viewModel)
        cacheLegsForEveryChain(of: viewModel)

        let mapLegs = viewModel.flatMapRouteLegs()

        XCTAssertEqual(mapLegs.count, 1)
        XCTAssertEqual(mapLegs.first?.legs.count, 5)
    }

    func testMarkersFollowTheFlatListNumbering() {
        let viewModel = makeViewModel(generatedPlanIds: ["25461"], extraSegments: [dayPlanSegment()])
        select("2025-12-09", in: viewModel)

        let orders = viewModel.getOrderedItemsForMap().map { $0.order }

        XCTAssertEqual(orders, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    // MARK: - Route chains

    private func noLocationBookedItem() -> TRPMergedTimelineItem {
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.title = "Museum pass"
        segment.startDate = "2025-12-07 11:00"
        segment.endDate = "2025-12-07 12:00"
        var activity = TRPSegmentActivityItem(
            activityId: "J_1_7", bookingId: "B1", title: "Museum pass", imageUrl: nil, description: nil,
            startDatetime: "2025-12-07 11:00", endDatetime: "2025-12-07 12:00", coordinate: TRPLocation(lat: 0, lon: 0),
            cancellation: nil, adultCount: 1, childCount: 0, cityId: 109
        )
        activity.isNoLocation = true
        segment.additionalData = activity
        return TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 9)
    }

    private func planItem() -> TRPMergedTimelineItem {
        let timeline = TRPTimelineMockData.getMockTimeline()
        let plan = timeline.plans!.first { $0.id == "25459" }!
        let segment = timeline.tripProfile!.segments[0]
        return TRPMergedTimelineItem(segment: segment, plan: plan, originalSegmentIndex: 0)
    }

    func testATimedRowWithoutALocationSplitsTheRoute() {
        let plan = planItem()
        let rows: [TimelineFlatRow] = [
            .startingPoint(name: "start", coordinate: barcelona.coordinate, item: plan),
            .planStep(plan, stepIndex: 0, order: 1),
            .planStep(plan, stepIndex: 1, order: 2),
            .bookedActivity(noLocationBookedItem(), order: 3),
            .planStep(plan, stepIndex: 2, order: 4),
            .planStep(plan, stepIndex: 3, order: 5)
        ]

        let chains = TimelineFlatRouteChain.chains(cityId: 109, rows: rows)

        XCTAssertEqual(chains.map { $0.waypointKeys }, [["start", "s126392", "s126393"], ["s126394", "s126395"]])
        XCTAssertEqual(chains.map { $0.startsAtStartingPoint }, [true, false])
    }

    func testARunWithASinglePlaceIsNotRouted() {
        let plan = planItem()
        let rows: [TimelineFlatRow] = [
            .planStep(plan, stepIndex: 0, order: 1),
            .bookedActivity(noLocationBookedItem(), order: 2),
            .planStep(plan, stepIndex: 1, order: 3)
        ]

        XCTAssertTrue(TimelineFlatRouteChain.chains(cityId: 109, rows: rows).isEmpty)
    }

    func testChainKeyDoesNotChangeWhenOnlyTimesChange() {
        let original = planItem()
        let retimed = planItem()
        let retimedSteps = retimed.plan!.steps.map { step -> TRPTimelineStep in
            var step = step
            step.startDateTimes = "2025-12-07 18:00:00"
            return step
        }
        retimed.plan?.steps = retimedSteps
        let rows: (TRPMergedTimelineItem) -> [TimelineFlatRow] = { item in
            [.planStep(item, stepIndex: 0, order: 1), .planStep(item, stepIndex: 1, order: 2)]
        }

        XCTAssertEqual(TimelineFlatRouteChain.chains(cityId: 109, rows: rows(original)).first?.key,
                       TimelineFlatRouteChain.chains(cityId: 109, rows: rows(retimed)).first?.key)
    }

    func testChainKeyChangesWhenAPlaceMoves() {
        let plan = planItem()
        let first: [TimelineFlatRow] = [.planStep(plan, stepIndex: 0, order: 1), .planStep(plan, stepIndex: 1, order: 2)]
        let second: [TimelineFlatRow] = [.planStep(plan, stepIndex: 0, order: 1), .planStep(plan, stepIndex: 2, order: 2)]

        XCTAssertNotEqual(TimelineFlatRouteChain.chains(cityId: 109, rows: first).first?.key,
                          TimelineFlatRouteChain.chains(cityId: 109, rows: second).first?.key)
    }
}
