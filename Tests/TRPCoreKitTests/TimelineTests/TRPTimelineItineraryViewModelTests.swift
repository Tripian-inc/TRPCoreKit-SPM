import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

final class TRPTimelineItineraryViewModelTests: XCTestCase {

    private func makeViewModel() -> TRPTimelineItineraryViewModel {
        return TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline())
    }

    private func dayIndex(of ymd: String, in viewModel: TRPTimelineItineraryViewModel) -> Int? {
        return viewModel.getDayDates().firstIndex { TRPDateHelper.formatDateString($0) == ymd }
    }

    // MARK: - Loading

    func testNilTimelineProducesEmptyState() {
        let viewModel = TRPTimelineItineraryViewModel(timeline: nil)

        XCTAssertTrue(viewModel.getDayDates().isEmpty)
        XCTAssertEqual(viewModel.numberOfSections(), 0)
        XCTAssertNil(viewModel.getTripDateRange())
    }

    func testTripRangeFallsBackToSegmentBounds() {
        let viewModel = makeViewModel()
        let days = viewModel.getDayDates().map(TRPDateHelper.formatDateString)

        XCTAssertEqual(days.first, "2025-12-07")
        XCTAssertEqual(days.last, "2026-01-01")
        XCTAssertEqual(days.count, 26)
        XCTAssertEqual(viewModel.getDays().count, days.count)
    }

    func testPastTripOpensOnItsLastDay() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.selectedDayIndex, viewModel.getDayDates().count - 1)
        XCTAssertTrue(viewModel.isSelectedDayPast)
    }

    func testCitiesComeFromTimelinePlansAndSegments() {
        let names = makeViewModel().getCities().map { $0.name }

        XCTAssertTrue(names.contains("Barcelona"))
        XCTAssertTrue(names.contains("Madrid"))
        XCTAssertEqual(names.count, Set(names).count)
    }

    // MARK: - Day selection and table data

    func testSelectingADayWithBookingsGroupsItemsByCity() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-09", in: viewModel) else { return XCTFail("day missing") }

        viewModel.selectDay(at: index)

        XCTAssertEqual(viewModel.selectedDayIndex, index)
        XCTAssertEqual(viewModel.numberOfSections(), 2)
        XCTAssertEqual(viewModel.headerData(for: 0).cityName, "Barcelona")
        XCTAssertEqual(viewModel.headerData(for: 1).cityName, "Madrid")
        XCTAssertTrue(viewModel.headerData(for: 1).shouldShowHeader)
        XCTAssertTrue(viewModel.headerData(for: 0).hasMultipleDestinations)
    }

    func testBookedActivityIsListedFirstOnItsDay() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-09", in: viewModel) else { return XCTFail("day missing") }
        viewModel.selectDay(at: index)

        guard case .bookedActivity(let booked)? = viewModel.cellType(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("expected a booked activity first")
        }
        XCTAssertEqual(booked.title, "Authentic Paella Cooking Class")
        XCTAssertEqual(booked.order, 1)
    }

    func testItinerarySegmentRendersAsRecommendationsOnItsPlanDay() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-07", in: viewModel) else { return XCTFail("day missing") }
        viewModel.selectDay(at: index)

        XCTAssertEqual(viewModel.numberOfSections(), 1)
        guard case .recommendations(let data)? = viewModel.cellType(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("expected recommendations")
        }
        XCTAssertEqual(data.steps.count, viewModel.timeline!.plans!.first { $0.id == "25459" }!.steps.count)
    }

    func testDayWithoutItemsShowsEmptyState() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-25", in: viewModel) else { return XCTFail("day missing") }

        viewModel.selectDay(at: index)

        XCTAssertEqual(viewModel.numberOfSections(), 1)
        XCTAssertEqual(viewModel.numberOfRows(in: 0), 1)
        guard case .emptyState? = viewModel.cellType(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("expected the empty state")
        }
    }

    func testOutOfRangeIndexPathsAreRejected() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-09", in: viewModel) else { return XCTFail("day missing") }
        viewModel.selectDay(at: index)

        XCTAssertNil(viewModel.cellType(at: IndexPath(row: 0, section: 99)))
        XCTAssertNil(viewModel.cellType(at: IndexPath(row: 99, section: 0)))
        XCTAssertEqual(viewModel.numberOfRows(in: 99), 0)
        XCTAssertFalse(viewModel.headerData(for: 99).shouldShowHeader)

        viewModel.selectDay(at: 999)
        XCTAssertEqual(viewModel.selectedDayIndex, index)
    }

    func testPoisOfSelectedDayComeFromItsPlans() {
        let viewModel = makeViewModel()
        guard let index = dayIndex(of: "2025-12-07", in: viewModel) else { return XCTFail("day missing") }
        viewModel.selectDay(at: index)

        let day = viewModel.getDayDates()[index]
        let pois = viewModel.mergedTimeline?.allPois(for: day) ?? []
        let planPoiIds = Set(viewModel.timeline!.plans!.first { $0.id == "25459" }!.getPoi().map { $0.id })

        XCTAssertFalse(pois.isEmpty)
        XCTAssertTrue(pois.allSatisfy { planPoiIds.contains($0.id) })
    }

    // MARK: - Planned activities

    func testPlannedActivitiesIncludeBookingsAndActivitySteps() {
        let viewModel = makeViewModel()
        let planned = viewModel.plannedActivities()
        let stepsWithProduct = viewModel.timeline!.plans!.flatMap { $0.steps }
            .filter { $0.stepType == "activity" && !($0.poi?.additionalData?.productId ?? "").isEmpty }

        XCTAssertTrue(planned.contains { $0.source == .booking && $0.productId == "COOK-BCN-001" && $0.day == "2025-12-09" })
        XCTAssertEqual(planned.filter { $0.source == .recommendation }.count, stepsWithProduct.count)

        let idsByDay = viewModel.plannedActivityIdsByDay()
        XCTAssertTrue(idsByDay["2025-12-09"]?.contains { $0.hasPrefix("C_COOK-BCN-001_15") } ?? false)
    }

    func testSegmentIndexIsResolvedAgainstTripProfile() {
        let viewModel = makeViewModel()
        let profileSegment = viewModel.timeline!.tripProfile!.segments.first { $0.segmentType == .bookedActivity }!

        XCTAssertEqual(viewModel.getSegmentIndex(for: profileSegment), viewModel.timeline!.tripProfile!.segments.firstIndex { $0 === profileSegment })
        XCTAssertNil(viewModel.getSegmentIndex(for: TRPTimelineSegment()))
    }

    // MARK: - Updates

    func testUpdatingTimelineRebuildsDays() {
        let viewModel = makeViewModel()
        var updated = TRPTimelineMockData.getMockTimeline()
        let profile = TRPTimelineProfile()
        let segment = TRPTimelineSegment()
        segment.title = "TimelineDate"
        segment.available = false
        segment.startDate = "2026-03-01 00:00"
        segment.endDate = "2026-03-03 23:59"
        profile.segments = [segment]
        updated.tripProfile = profile
        updated.segments = []
        updated.plans = []

        viewModel.updateTimeline(updated)

        XCTAssertEqual(viewModel.getDayDates().map(TRPDateHelper.formatDateString), ["2026-03-01", "2026-03-02", "2026-03-03"])
        XCTAssertEqual(viewModel.getTripHash(), updated.tripHash)
    }
}
