import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// A flexible activity arrives as a reserved activity with -1 as its duration and a 00:00–23:59 window.
final class TRPMergedTimelineItemDurationTests: XCTestCase {

    private func activityItem(type: TRPTimelineSegmentType = .reservedActivity,
                              start: String,
                              end: String,
                              duration: Double?) -> TRPMergedTimelineItem {
        let segment = TRPTimelineSegment()
        segment.segmentType = type
        segment.title = "Old town walk"
        segment.startDate = start
        segment.endDate = end
        var activity = TRPSegmentActivityItem(
            activityId: "G_555_7", bookingId: nil, title: "Old town walk", imageUrl: nil, description: nil,
            startDatetime: start, endDatetime: end, coordinate: TRPLocation(lat: 41.40, lon: 2.17),
            cancellation: nil, adultCount: 2, childCount: 0, cityId: 109
        )
        activity.duration = duration
        segment.additionalData = activity
        return TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)
    }

    private func flexibleItem() -> TRPMergedTimelineItem {
        return activityItem(start: "2025-12-09 00:00", end: "2025-12-09 23:59", duration: -1)
    }

    func testFlexibleActivityHasNoDuration() {
        let item = flexibleItem()

        XCTAssertTrue(item.isFlexibleActivity)
        XCTAssertNil(item.duration)
    }

    func testFlexibleActivityCellShowsNoDuration() {
        XCTAssertNil(FlexibleActivityCellData(from: flexibleItem()).duration)
    }

    func testTimedActivityKeepsItsOwnDuration() {
        let item = activityItem(start: "2025-12-09 10:30", end: "2025-12-09 12:00", duration: 150)

        XCTAssertFalse(item.isFlexibleActivity)
        XCTAssertEqual(item.duration, 150)
    }

    func testTimedActivityWithoutADurationTakesItsWindow() {
        let item = activityItem(start: "2025-12-09 10:30", end: "2025-12-09 12:00", duration: nil)

        XCTAssertEqual(item.duration, 90)
    }

    func testAllDayWindowWithARealDurationIsNotFlexible() {
        let item = activityItem(start: "2025-12-09 00:00", end: "2025-12-09 23:59", duration: 120)

        XCTAssertFalse(item.isFlexibleActivity)
        XCTAssertEqual(item.duration, 120)
    }

    func testBookedActivityCellKeepsATimedDuration() {
        let item = activityItem(type: .bookedActivity, start: "2025-12-09 10:30", end: "2025-12-09 12:00", duration: 150)

        XCTAssertEqual(BookedActivityCellData(from: item, order: 1).duration, 150)
    }
}
