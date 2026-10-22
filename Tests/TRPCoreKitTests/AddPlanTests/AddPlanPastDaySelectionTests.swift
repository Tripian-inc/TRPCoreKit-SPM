import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins the AddPlan select-day rule: a past day is never the selected day and Continue
/// follows `AddPlanContainerViewModel.canContinueFromSelectDay`.
final class AddPlanPastDaySelectionTests: XCTestCase {

    private let city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))

    private func day(_ offset: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: offset, to: today)!.addingTimeInterval(12 * 3600)
    }

    private func makeContainer(days: [Date], selectedDayIndex: Int) -> AddPlanContainerViewModel {
        return AddPlanContainerViewModel(days: days, cities: [city], selectedDayIndex: selectedDayIndex)
    }

    private func assertSameDay(_ lhs: Date?, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs = lhs else {
            return XCTFail("Expected a selected day", file: file, line: line)
        }
        XCTAssertTrue(Calendar.current.isDate(lhs, inSameDayAs: rhs), file: file, line: line)
    }

    func testAllDaysPastLeavesNoSelectionAndBlocksContinue() {
        let container = makeContainer(days: [day(-3), day(-2), day(-1)], selectedDayIndex: 2)
        container.planData.selectedMode = .smartRecommendations

        XCTAssertNil(container.planData.selectedDay)
        XCTAssertNil(container.getSelectedAvailableDayIndex())
        XCTAssertNotNil(container.planData.selectedCity)
        XCTAssertFalse(container.canContinueFromSelectDay)
    }

    func testPastArgumentIndexIsRemappedToToday() {
        let container = makeContainer(days: [day(-2), day(-1), day(0), day(1)], selectedDayIndex: 0)

        assertSameDay(container.planData.selectedDay, day(0))
        XCTAssertEqual(container.getSelectedAvailableDayIndex(), 2)
    }

    func testPastArgumentIndexIsRemappedToFirstFutureDayWithoutToday() {
        let container = makeContainer(days: [day(-2), day(-1), day(2), day(3)], selectedDayIndex: 1)

        assertSameDay(container.planData.selectedDay, day(2))
        XCTAssertEqual(container.getSelectedAvailableDayIndex(), 2)
    }

    func testFutureArgumentIndexIsKept() {
        let container = makeContainer(days: [day(-1), day(0), day(1)], selectedDayIndex: 2)

        assertSameDay(container.planData.selectedDay, day(1))
    }

    func testSelectingPastDayIsIgnored() {
        let days = [day(-1), day(0), day(1)]
        let container = makeContainer(days: days, selectedDayIndex: 2)
        let selectDayViewModel = AddPlanSelectDayViewModel(containerViewModel: container)

        selectDayViewModel.selectDay(days[0])
        assertSameDay(selectDayViewModel.getSelectedDay(), day(1))
        XCTAssertEqual(selectDayViewModel.getSelectedDayIndex(), 2)

        container.selectDay(days[0])
        assertSameDay(container.planData.selectedDay, day(1))

        selectDayViewModel.selectDay(days[1])
        assertSameDay(selectDayViewModel.getSelectedDay(), day(0))
    }

    func testTimeAndTravelersSelectingPastDayIsIgnored() {
        let days = [day(-1), day(0)]
        let container = makeContainer(days: days, selectedDayIndex: 1)
        let viewModel = AddPlanTimeAndTravelersViewModel(containerViewModel: container)

        viewModel.selectDay(days[0])

        assertSameDay(container.planData.selectedDay, day(0))
        XCTAssertEqual(viewModel.getSelectedAvailableDayIndex(), 1)
    }

    func testClearSelectionWithAllDaysPastLeavesNoSelection() {
        let container = makeContainer(days: [day(-2), day(-1)], selectedDayIndex: 0)
        let selectDayViewModel = AddPlanSelectDayViewModel(containerViewModel: container)
        container.planData.selectedMode = .smartRecommendations

        selectDayViewModel.clearSelection()

        XCTAssertNil(selectDayViewModel.getSelectedDay())
        XCTAssertNil(selectDayViewModel.getSelectedDayIndex())
        XCTAssertFalse(selectDayViewModel.canContinue())
    }

    func testClearSelectionResetsToToday() {
        let days = [day(-1), day(0), day(1)]
        let container = makeContainer(days: days, selectedDayIndex: 2)
        let selectDayViewModel = AddPlanSelectDayViewModel(containerViewModel: container)

        selectDayViewModel.clearSelection()

        assertSameDay(selectDayViewModel.getSelectedDay(), day(0))
    }

    func testTodayWithCityAndSmartModeCanContinue() {
        let container = makeContainer(days: [day(-1), day(0), day(1)], selectedDayIndex: 1)
        container.planData.selectedMode = .smartRecommendations

        XCTAssertTrue(container.canContinueFromSelectDay)
        XCTAssertTrue(AddPlanSelectDayViewModel(containerViewModel: container).canContinue())
    }

    func testFutureDayWithCityAndSmartModeCanContinue() {
        let container = makeContainer(days: [day(1), day(2)], selectedDayIndex: 0)
        container.planData.selectedMode = .smartRecommendations

        XCTAssertTrue(container.canContinueFromSelectDay)
    }

    func testManualModeRequiresCategory() {
        let container = makeContainer(days: [day(0), day(1)], selectedDayIndex: 0)
        let selectDayViewModel = AddPlanSelectDayViewModel(containerViewModel: container)
        container.planData.selectedMode = .manual

        XCTAssertFalse(container.canContinueFromSelectDay)

        selectDayViewModel.setSelectedManualCategory("activities")
        XCTAssertTrue(container.canContinueFromSelectDay)
    }

    func testNoModeBlocksContinue() {
        let container = makeContainer(days: [day(0)], selectedDayIndex: 0)

        XCTAssertFalse(container.canContinueFromSelectDay)
    }

    func testMissingCityBlocksContinue() {
        let container = AddPlanContainerViewModel(days: [day(0)], cities: [], selectedDayIndex: 0)
        container.planData.selectedMode = .smartRecommendations

        XCTAssertFalse(container.canContinueFromSelectDay)
    }

    func testPastDayWrittenDirectlyBlocksContinue() {
        let container = makeContainer(days: [day(-1), day(0)], selectedDayIndex: 1)
        container.planData.selectedMode = .smartRecommendations
        container.planData.selectedDay = day(-1)

        XCTAssertFalse(container.canContinueFromSelectDay)
        XCTAssertNil(container.getSelectedAvailableDayIndex())
    }
}
