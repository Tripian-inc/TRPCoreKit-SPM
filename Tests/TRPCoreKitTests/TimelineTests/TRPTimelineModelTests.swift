import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

final class TRPTimelineModelTests: XCTestCase {

    private let timeline = TRPTimelineMockData.getMockTimeline()

    // MARK: - TRPTimeline

    func testPoisAreCollectedAcrossPlansWithoutDuplicates() {
        let pois = timeline.getPois()
        let ids = pois.map { $0.id }

        XCTAssertFalse(pois.isEmpty)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testPoisCanBeFilteredByCategory() {
        let restaurants = timeline.getPoisWith(types: [3])

        XCTAssertFalse(restaurants.isEmpty)
        XCTAssertTrue(restaurants.allSatisfy { poi in poi.categories.contains { $0.id == 3 } })
        XCTAssertTrue(timeline.getPoisWith(types: [999_999]).isEmpty)
    }

    // MARK: - TRPTimelinePlan / TRPTimelineStep

    /// Hosts compare these dates with their own UTC-parsed times, so the plan's wall clock is read as UTC.
    func testPlanDatesKeepTheirWallClockInUTC() {
        let plan = timeline.plans!.first { $0.id == "25459" }!

        XCTAssertEqual(plan.getStartDate()?.toString(format: "yyyy-MM-dd HH:mm", timeZone: "UTC"), "2025-12-07 09:00")
        XCTAssertEqual(plan.getEndDate()?.toString(format: "yyyy-MM-dd HH:mm", timeZone: "UTC"), "2025-12-07 21:00")
    }

    func testStepTimesAreExtractedAsHourMinute() {
        let step = timeline.plans!.first!.steps.first!

        XCTAssertEqual(step.getStartTime(), TRPDateHelper.extractHourMinute(from: step.startDateTimes))
        XCTAssertEqual(step.getStartTime()?.count, 5)
        XCTAssertNil(TRPTimelineStep(id: 1, poi: nil, alternatives: []).getStartTime())
    }

    func testProfileDateRangeSpansAllSegments() {
        let profile = timeline.tripProfile!

        XCTAssertEqual(TRPDateHelper.formatDateString(profile.getOldestStartDate()), "2025-12-07")
        XCTAssertEqual(TRPDateHelper.formatDateString(profile.getMaxEndDate()), "2026-01-01")
        XCTAssertFalse(profile.getDateRangeText()?.isEmpty ?? true)
    }

    // MARK: - Activity ids

    func testActivityIdFormatRoundTrips() {
        let id = TRPActivityIdFormat.make("12345", providerId: 15, cityId: 109)

        XCTAssertEqual(id, "C_12345_15_109")
        XCTAssertEqual(id.cleanedAsActivityId(), "12345")
        XCTAssertEqual(id.trp_parsedProviderId(), 15)
        XCTAssertEqual("12345".cleanedAsActivityId(), "12345")
        XCTAssertNil("12345".trp_parsedProviderId())
        XCTAssertEqual(TRPActivityIdFormat.make("C_777_15_3"), "C_777_15")
    }

    // MARK: - TRPDateHelper

    func testDateHelperExtractsPartsOfWallClockStrings() {
        XCTAssertEqual(TRPDateHelper.extractDateString("2026-09-14 13:05:00"), "2026-09-14")
        XCTAssertEqual(TRPDateHelper.extractTimeString("2026-09-14 13:05:00"), "13:05")
        XCTAssertEqual(TRPDateHelper.extractHourMinute(from: "13:05:00"), "13:05")
        XCTAssertEqual(TRPDateHelper.extractDateOnly(from: "2026-09-14 13:05"), "2026-09-14")
        XCTAssertNil(TRPDateHelper.extractDateOnly(from: "14/09/2026"))
        XCTAssertNil(TRPDateHelper.extractTimeString("2026-09-14"))
    }

    func testDateHelperParsesAndFormatsSymmetrically() {
        let parsed = TRPDateHelper.parseDateTime("2026-09-14 13:05")!

        XCTAssertEqual(TRPDateHelper.formatDateTime(parsed), "2026-09-14 13:05")
        XCTAssertEqual(TRPDateHelper.formatDateTimeWithSeconds(parsed), "2026-09-14 13:05:00")
        XCTAssertEqual(TRPDateHelper.formatTime(parsed), "13:05")
        XCTAssertEqual(TRPDateHelper.formatDisplayDate(parsed), "14/09/2026")
        XCTAssertTrue(TRPDateHelper.isOnDate("2026-09-14 23:59", targetDate: parsed))
        XCTAssertFalse(TRPDateHelper.isOnDate("2026-09-15 00:00", targetDate: parsed))
        XCTAssertEqual(TRPDateHelper.addMinutes(toTime: "23:30", minutes: 45), "00:15")
    }

    func testOpeningHoursDayKeyUsesGregorianWeekday() {
        let monday = TRPDateHelper.parseDate("2026-09-14")
        let sunday = TRPDateHelper.parseDate("2026-09-13")

        XCTAssertEqual(TRPOpeningHours.dayKey(of: monday), "Mon")
        XCTAssertEqual(TRPOpeningHours.dayKey(of: sunday), "Sun")
        XCTAssertNil(TRPOpeningHours.dayKey(of: nil))
    }
}
