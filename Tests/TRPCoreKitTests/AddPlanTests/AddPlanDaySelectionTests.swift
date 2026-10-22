import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Pins `AddPlanDaySelection`, the shared initial-day rule used by every Add Plan entry point.
final class AddPlanDaySelectionTests: XCTestCase {

    private func day(_ offset: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: offset, to: today)!.addingTimeInterval(12 * 3600)
    }

    private func assertSameDay(_ lhs: Date?, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs = lhs else {
            return XCTFail("Expected a day", file: file, line: line)
        }
        XCTAssertTrue(Calendar.current.isDate(lhs, inSameDayAs: rhs), file: file, line: line)
    }

    // MARK: - firstSelectableDay(in:)

    func testFirstSelectableDayPicksEarliestNonPastAmongUnsortedDays() {
        let days = [day(2), day(-1), day(0), day(3)]

        assertSameDay(AddPlanDaySelection.firstSelectableDay(in: days), day(0))
    }

    func testFirstSelectableDayIsNilWhenEveryDayIsPast() {
        let days = [day(-3), day(-1), day(-2)]

        XCTAssertNil(AddPlanDaySelection.firstSelectableDay(in: days))
    }

    func testFirstSelectableDayIsNilForEmptyDays() {
        XCTAssertNil(AddPlanDaySelection.firstSelectableDay(in: []))
    }

    // MARK: - initialDay(in:preferredIndex:)

    func testInitialDayKeepsPreferredIndexWhenNotPast() {
        let days = [day(-1), day(0), day(1), day(2)]

        assertSameDay(AddPlanDaySelection.initialDay(in: days, preferredIndex: 3), day(2))
    }

    func testInitialDayFallsBackWhenPreferredIndexIsPast() {
        let days = [day(-2), day(-1), day(1), day(2)]

        assertSameDay(AddPlanDaySelection.initialDay(in: days, preferredIndex: 0), day(1))
    }

    func testInitialDayFallsBackWhenPreferredIndexOutOfRange() {
        let days = [day(-1), day(0), day(1)]

        assertSameDay(AddPlanDaySelection.initialDay(in: days, preferredIndex: 99), day(0))
    }

    func testInitialDayFallsBackWhenPreferredIndexIsNil() {
        let days = [day(-1), day(1), day(2)]

        assertSameDay(AddPlanDaySelection.initialDay(in: days, preferredIndex: nil), day(1))
    }

    func testInitialDayIsNilWhenEveryDayIsPastRegardlessOfPreferredIndex() {
        let days = [day(-3), day(-2), day(-1)]

        XCTAssertNil(AddPlanDaySelection.initialDay(in: days, preferredIndex: 1))
    }

    func testInitialDayHandlesUnsortedDays() {
        let days = [day(2), day(-1), day(0)]

        assertSameDay(AddPlanDaySelection.initialDay(in: days, preferredIndex: nil), day(0))
    }
}
