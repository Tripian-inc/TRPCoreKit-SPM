import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins the Saved Plans "Add to Plan" day rule: the time-selection sheet starts on the timeline's
/// selected day when plannable, else the earliest non-past day, else no day.
final class SavedPlansSelectedDayTests: XCTestCase {

    private let city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))

    private func day(_ offset: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: offset, to: today)!.addingTimeInterval(12 * 3600)
    }

    private func makeViewModel(days: [Date], selectedDayIndex: Int?) -> SavedPlansViewModel {
        return SavedPlansViewModel(favouriteItems: [],
                                   tripHash: "hash",
                                   availableDays: days,
                                   availableCities: [city],
                                   selectedDayIndex: selectedDayIndex)
    }

    private func makeTour() -> TRPTourProduct {
        return TRPTourProduct(id: "C_1_15_1", productId: "C_1_15_1", cityId: 1, name: "City Tour",
                              image: nil, gallery: nil, duration: nil, price: nil, rating: nil,
                              ratingCount: nil, description: nil, webUrl: nil, phone: nil, hours: nil,
                              address: nil, icon: "", coordinate: nil, categories: [], tags: [],
                              distance: nil, status: true, offers: [], additionalData: nil)
    }

    private func assertSameDay(_ lhs: Date?, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs = lhs else {
            return XCTFail("Expected a selected day", file: file, line: line)
        }
        XCTAssertTrue(Calendar.current.isDate(lhs, inSameDayAs: rhs), file: file, line: line)
    }

    // MARK: - SavedPlansViewModel.createAddPlanData(cityId:)

    func testSelectedFutureDayIsKept() {
        let viewModel = makeViewModel(days: [day(-1), day(0), day(1), day(2)], selectedDayIndex: 2)

        let planData = viewModel.createAddPlanData(cityId: city.id)

        assertSameDay(planData.selectedDay, day(1))
    }

    func testSelectedTodayIsKept() {
        let viewModel = makeViewModel(days: [day(-1), day(0), day(1)], selectedDayIndex: 1)

        assertSameDay(viewModel.createAddPlanData(cityId: city.id).selectedDay, day(0))
    }

    func testSelectedPastDayFallsBackToEarliestNonPastDay() {
        let viewModel = makeViewModel(days: [day(-2), day(-1), day(2), day(3)], selectedDayIndex: 0)

        assertSameDay(viewModel.createAddPlanData(cityId: city.id).selectedDay, day(2))
    }

    func testAllDaysPastLeavesNoSelectedDay() {
        let viewModel = makeViewModel(days: [day(-3), day(-2), day(-1)], selectedDayIndex: 2)

        XCTAssertNil(viewModel.createAddPlanData(cityId: city.id).selectedDay)
    }

    func testOutOfRangeIndexFallsBackToEarliestNonPastDay() {
        let viewModel = makeViewModel(days: [day(-1), day(0), day(1)], selectedDayIndex: 7)

        assertSameDay(viewModel.createAddPlanData(cityId: city.id).selectedDay, day(0))
    }

    func testMissingIndexFallsBackToEarliestNonPastDay() {
        let viewModel = makeViewModel(days: [day(-1), day(1), day(2)], selectedDayIndex: nil)

        assertSameDay(viewModel.createAddPlanData(cityId: city.id).selectedDay, day(1))
    }

    func testCreateAddPlanDataKeepsTripContext() {
        let days = [day(0), day(1)]
        let viewModel = makeViewModel(days: days, selectedDayIndex: 1)

        let planData = viewModel.createAddPlanData(cityId: city.id)

        XCTAssertEqual(planData.tripHash, "hash")
        XCTAssertEqual(planData.availableDays, days)
        XCTAssertEqual(planData.selectedCity?.id, city.id)
        XCTAssertEqual(planData.travelers, 1)
    }

    // MARK: - AddPlanTimeSelectionViewModel seeded from Saved Plans

    func testTimeSelectionStartsOnTimelineSelectedDay() {
        let days = [day(-1), day(0), day(1), day(2)]
        let planData = makeViewModel(days: days, selectedDayIndex: 3).createAddPlanData(cityId: city.id)

        let timeSelection = AddPlanTimeSelectionViewModel(tour: makeTour(), planData: planData)

        XCTAssertEqual(timeSelection.getSelectedAvailableDayIndex(), 3)
        assertSameDay(timeSelection.getSelectedDate(), day(2))
    }

    func testTimeSelectionWithAllDaysPastHasNoDayAndCannotContinue() {
        let planData = makeViewModel(days: [day(-2), day(-1)], selectedDayIndex: 1).createAddPlanData(cityId: city.id)

        let timeSelection = AddPlanTimeSelectionViewModel(tour: makeTour(), planData: planData)

        XCTAssertNil(timeSelection.getSelectedDate())
        XCTAssertNil(timeSelection.getSelectedAvailableDayIndex())
        XCTAssertTrue(timeSelection.getTimeSlots().isEmpty)
        XCTAssertFalse(timeSelection.isSelectedDayFlexible())
        XCTAssertFalse(timeSelection.canContinue())
    }
}
