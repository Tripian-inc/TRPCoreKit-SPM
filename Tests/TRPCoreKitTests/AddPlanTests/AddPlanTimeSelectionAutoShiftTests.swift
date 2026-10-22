import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins the add-flow auto-shift in `AddPlanTimeSelectionViewModel`: when the initially selected
/// day has no availability, the first available day is picked, but a past day is never a candidate.
final class AddPlanTimeSelectionAutoShiftTests: XCTestCase {

    private let city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))

    private func day(_ offset: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: offset, to: today)!.addingTimeInterval(12 * 3600)
    }

    private func dateString(_ offset: Int) -> String {
        return TRPDateHelper.formatDateString(day(offset))
    }

    private func makeTour(slots: [TRPTourSlot]) -> TRPTourProduct {
        var tour = TRPTourProduct(
            id: "C_1_15_1", productId: "C_1_15_1", cityId: 1, name: "City Tour",
            image: nil, gallery: nil, duration: nil, price: nil, rating: nil,
            ratingCount: nil, description: nil, webUrl: nil, phone: nil, hours: nil,
            address: nil, icon: "", coordinate: nil, categories: [], tags: [],
            distance: nil, status: true, offers: [], additionalData: nil
        )
        tour.slots = slots
        return tour
    }

    private func assertSameDay(_ lhs: Date?, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs = lhs else {
            return XCTFail("Expected a selected day", file: file, line: line)
        }
        XCTAssertTrue(Calendar.current.isDate(lhs, inSameDayAs: rhs), file: file, line: line)
    }

    func testAutoShiftSkipsPastDayAndLandsOnFirstFutureDayWithSlots() {
        let days = [day(-1), day(0), day(1)]
        var planData = AddPlanData()
        planData.availableDays = days
        planData.selectedDay = day(0)
        planData.selectedCity = city

        let slots = [
            TRPTourSlot(date: dateString(-1), time: "10:00", price: nil),
            TRPTourSlot(date: dateString(1), time: "11:00", price: nil)
        ]

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(slots: slots), planData: planData)

        assertSameDay(viewModel.getSelectedDate(), day(1))
        XCTAssertEqual(viewModel.getSelectedAvailableDayIndex(), 2)
    }

    func testAutoShiftNeverMovesToAPastDayWhenAllOtherDaysAreUnavailable() {
        let days = [day(-1), day(0), day(1)]
        var planData = AddPlanData()
        planData.availableDays = days
        planData.selectedDay = day(0)
        planData.selectedCity = city

        let slots = [
            TRPTourSlot(date: dateString(-1), time: "10:00", price: nil)
        ]

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(slots: slots), planData: planData)

        assertSameDay(viewModel.getSelectedDate(), day(0))
        XCTAssertFalse(Calendar.current.isDate(viewModel.getSelectedDate() ?? day(0), inSameDayAs: day(-1)))
        XCTAssertFalse(viewModel.canContinue())
    }

    func testAutoShiftKeepsSelectedDayWhenItAlreadyHasSlots() {
        let days = [day(-1), day(0), day(1)]
        var planData = AddPlanData()
        planData.availableDays = days
        planData.selectedDay = day(0)
        planData.selectedCity = city

        let slots = [
            TRPTourSlot(date: dateString(0), time: "09:00", price: nil),
            TRPTourSlot(date: dateString(1), time: "11:00", price: nil)
        ]

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(slots: slots), planData: planData)

        assertSameDay(viewModel.getSelectedDate(), day(0))
    }
}
