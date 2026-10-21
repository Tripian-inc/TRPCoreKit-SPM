import XCTest
@testable import TRPCoreKit

final class TRPSegmentTimeRangeAdjustmentTests: XCTestCase {

    private func date(_ string: String) -> Date {
        guard let date = TRPDateHelper.parseDateTime(string) else {
            XCTFail("Could not parse \(string)")
            return Date()
        }
        return date
    }

    // MARK: - widenedRange

    func testStepFittingInsideSegmentNeedsNoWidening() {
        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: date("2025-12-07 21:00"),
            stepStart: date("2025-12-07 10:00"),
            stepEnd: date("2025-12-07 11:00")
        )

        XCTAssertNil(result)
    }

    func testStepStartingBeforeSegmentOnlyWidensTheStart() {
        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: date("2025-12-07 21:00"),
            stepStart: date("2025-12-07 07:00"),
            stepEnd: date("2025-12-07 10:00")
        )

        XCTAssertEqual(result?.start, date("2025-12-07 07:00"))
        XCTAssertEqual(result?.end, date("2025-12-07 21:00"))
    }

    func testStepEndingAfterSegmentOnlyWidensTheEnd() {
        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: date("2025-12-07 21:00"),
            stepStart: date("2025-12-07 20:00"),
            stepEnd: date("2025-12-07 23:00")
        )

        XCTAssertEqual(result?.start, date("2025-12-07 09:00"))
        XCTAssertEqual(result?.end, date("2025-12-07 23:00"))
    }

    func testStepOutsideOnBothSidesWidensBoth() {
        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: date("2025-12-07 21:00"),
            stepStart: date("2025-12-07 06:00"),
            stepEnd: date("2025-12-07 23:00")
        )

        XCTAssertEqual(result?.start, date("2025-12-07 06:00"))
        XCTAssertEqual(result?.end, date("2025-12-07 23:00"))
    }

    func testStepOnALaterDayOfAMultiDaySegmentThatStillFitsNeedsNoWidening() {
        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: date("2026-01-01 22:00"),
            stepStart: date("2025-12-20 10:00"),
            stepEnd: date("2025-12-20 11:00")
        )

        XCTAssertNil(result)
    }

    func testStepOnTheSegmentsLastDayPastItsEndWidensTheEnd() {
        let segmentEnd = date("2026-01-01 22:00")
        let stepEnd = date("2026-01-01 23:00")

        let result = TRPSegmentTimeRangeAdjustment.widenedRange(
            segmentStart: date("2025-12-07 09:00"),
            segmentEnd: segmentEnd,
            stepStart: date("2026-01-01 21:00"),
            stepEnd: stepEnd
        )

        XCTAssertEqual(result?.start, date("2025-12-07 09:00"))
        XCTAssertEqual(result?.end, stepEnd)
    }

    // MARK: - stepRange

    func testStepRangePlacesPickerTimesOnTheStepsCalendarDay() {
        let range = TRPSegmentTimeRangeAdjustment.stepRange(onDayOf: "2025-12-09 16:00:00", startTime: "10:00", endTime: "11:30")

        XCTAssertEqual(range?.start, date("2025-12-09 10:00"))
        XCTAssertEqual(range?.end, date("2025-12-09 11:30"))
    }

    func testStepRangeWithEndBeforeStartStaysOnTheSameDay() {
        let range = TRPSegmentTimeRangeAdjustment.stepRange(onDayOf: "2025-12-09 16:00:00", startTime: "23:00", endTime: "01:00")

        XCTAssertEqual(range?.start, date("2025-12-09 23:00"))
        XCTAssertEqual(range?.end, date("2025-12-09 01:00"))
        XCTAssertTrue(range!.end < range!.start)
    }

    func testStepRangeReturnsNilWithoutAStepDateTime() {
        XCTAssertNil(TRPSegmentTimeRangeAdjustment.stepRange(onDayOf: nil, startTime: "10:00", endTime: "11:00"))
    }
}
