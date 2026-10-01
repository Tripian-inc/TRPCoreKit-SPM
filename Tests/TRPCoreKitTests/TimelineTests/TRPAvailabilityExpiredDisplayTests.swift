import XCTest
import UIKit
import TRPFoundationKit
@testable import TRPCoreKit

/// An activity whose availability has expired asks the user to re-check it, timed or flexible.
final class TRPAvailabilityExpiredDisplayTests: XCTestCase {

    private func flexibleReservedItem(isAvailabilityExpired: Bool) -> TRPMergedTimelineItem {
        let segment = TRPTimelineSegment()
        segment.segmentType = .reservedActivity
        segment.startDate = "2026-10-24 00:00"
        segment.endDate = "2026-10-24 23:59"
        segment.additionalData = TRPSegmentActivityItem(activityId: "1505", bookingId: nil, title: "Tour", imageUrl: nil, description: nil,
                                                        startDatetime: "2026-10-24 00:00", endDatetime: "2026-10-24 23:59",
                                                        coordinate: TRPLocation(lat: 0, lon: 0), cancellation: nil, adultCount: 1, childCount: 0)
        segment.additionalData?.duration = -1
        segment.additionalData?.isAvailabilityExpired = isAvailabilityExpired
        return TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)
    }

    private func visibleTexts(in view: UIView) -> [String] {
        let own = (view as? UILabel).flatMap { label in label.isHidden ? nil : label.text }.map { [$0] } ?? []
        return own + view.subviews.filter { !$0.isHidden }.flatMap(visibleTexts)
    }

    private var notAvailableText: String { TimelineLocalizationKeys.localized(TimelineLocalizationKeys.notAvailable) }
    private var subtitleText: String { TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntrySubtitle) }

    func testReservationButtonAsksToCheckAvailabilityOnlyWhenExpired() {
        XCTAssertEqual(TimelineLocalizationKeys.reservationButtonTitle(isAvailabilityExpired: true),
                       TimelineLocalizationKeys.localized(TimelineLocalizationKeys.checkAvailability))
        XCTAssertEqual(TimelineLocalizationKeys.reservationButtonTitle(isAvailabilityExpired: false),
                       TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation))
    }

    func testFlexibleActivityCarriesTheExpiredAvailability() {
        for expired in [true, false] {
            guard case .flexibleActivity(let data) = TimelineCellType.from(flexibleReservedItem(isAvailabilityExpired: expired), order: 1) else {
                return XCTFail("A flexible reserved activity uses the flexible cell")
            }
            XCTAssertEqual(data.isAvailabilityExpired, expired)
        }
    }

    func testExpiredFlexibleBadgeShowsNotAvailableInsteadOfTheSubtitle() {
        let badge = TRPTimelineFlexibleTimeBadgeView()

        badge.configure(title: "Flexible entry", subtitle: subtitleText, isAvailabilityExpired: true)

        XCTAssertTrue(visibleTexts(in: badge).contains(notAvailableText))
        XCTAssertFalse(visibleTexts(in: badge).contains(subtitleText))
    }

    func testResetFlexibleBadgeDropsTheExpiredState() {
        let badge = TRPTimelineFlexibleTimeBadgeView()
        badge.configure(title: "Flexible entry", subtitle: subtitleText, isAvailabilityExpired: true)

        badge.resetStyle()

        XCTAssertFalse(visibleTexts(in: badge).contains(notAvailableText))
        XCTAssertTrue(visibleTexts(in: badge).contains(subtitleText))
    }
}
