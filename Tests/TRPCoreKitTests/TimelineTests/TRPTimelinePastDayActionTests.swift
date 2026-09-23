import XCTest
import UIKit
import TRPFoundationKit
@testable import TRPCoreKit

/// Drives the real cells the timeline renders and taps whatever the user could tap, so the
/// past-day rules (removal stays, change-time and reservation go) are checked through behaviour.
final class TRPTimelinePastDayActionTests: XCTestCase {

    // MARK: - Spies

    private final class ActivityCellSpy: TRPTimelineActivityCellDelegate {
        var removed = false
        var changedTime = false
        var reserved = false
        func activityCellDidTapCell(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) {}
        func activityCellDidTapReservation(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) { reserved = true }
        func activityCellDidTapChangeTime(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) { changedTime = true }
        func activityCellDidTapRemove(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) { removed = true }
    }

    private final class ManualPoiCellSpy: TRPTimelineManualPoiCellDelegate {
        var removed = false
        var changedTime = false
        func manualPoiCellDidTapChangeTime(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) { changedTime = true }
        func manualPoiCellDidTapRemove(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment) { removed = true }
        func manualPoiCellDidTapCell(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) {}
    }

    private final class RecommendationsCellSpy: TRPTimelineRecommendationsCellDelegate {
        var removedStep = false
        var changedTime = false
        var reserved = false
        func recommendationsCellDidTapClose(_ cell: TRPTimelineRecommendationsCell, segment: TRPTimelineSegment?) {}
        func recommendationsCellDidTapToggle(_ cell: TRPTimelineRecommendationsCell, isExpanded: Bool) {}
        func recommendationsCellDidSelectStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {}
        func recommendationsCellDidTapChangeTime(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) { changedTime = true }
        func recommendationsCellDidTapRemoveStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) { removedStep = true }
        func recommendationsCellDidTapReservation(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) { reserved = true }
        func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, locations: [TRPLocation], cellIndexPath: IndexPath) {}
    }

    // MARK: - Helpers

    /// Buttons a user could actually hit: visible themselves and inside no hidden ancestor.
    private func tappableButtons(in root: UIView) -> [UIButton] {
        var found: [UIButton] = []
        func walk(_ view: UIView) {
            guard !view.isHidden, view.alpha > 0.01 else { return }
            if let button = view as? UIButton { found.append(button) }
            view.subviews.forEach(walk)
        }
        walk(root)
        return found
    }

    /// Invokes each button's registered target/action directly: without an app host
    /// `sendActions(for:)` has no `UIApplication` to route through and does nothing.
    private func tapEverything(in cell: UITableViewCell) {
        cell.layoutIfNeeded()
        for button in tappableButtons(in: cell.contentView) {
            for target in button.allTargets {
                for action in button.actions(forTarget: target, forControlEvent: .touchUpInside) ?? [] {
                    _ = (target as AnyObject).perform(Selector(action), with: button)
                }
            }
        }
    }

    private let city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))

    private func reservedSegment() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .reservedActivity
        segment.title = "Reserved activity"
        segment.startDate = "2026-09-20 10:00"
        segment.endDate = "2026-09-20 12:00"
        segment.city = city
        return segment
    }

    private func reservedCellData() -> BookedActivityCellData {
        return BookedActivityCellData(
            segmentIndex: 0, order: 1, title: "Reserved activity", imageUrl: nil,
            timeRange: "10:00 - 12:00", isReserved: true, adultCount: 2, childCount: 0,
            duration: 120, price: nil, cancellation: nil, segment: reservedSegment()
        )
    }

    // MARK: - Reserved activity cell

    func testPastDayReservedActivityKeepsRemovalAndDropsTheOtherActions() {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let spy = ActivityCellSpy()
        cell.delegate = spy
        cell.configure(with: reservedCellData())
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertTrue(spy.removed, "removal must stay available on a past day")
        XCTAssertFalse(spy.changedTime, "change time must be gone on a past day")
        XCTAssertFalse(spy.reserved, "reservation must be gone on a past day")
    }

    func testActiveDayReservedActivityKeepsEveryAction() {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let spy = ActivityCellSpy()
        cell.delegate = spy
        cell.configure(with: reservedCellData())

        tapEverything(in: cell)

        XCTAssertTrue(spy.removed)
        XCTAssertTrue(spy.changedTime)
        XCTAssertTrue(spy.reserved)
    }

    func testReusedCellDropsThePastDayStyle() {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let spy = ActivityCellSpy()
        cell.delegate = spy
        cell.configure(with: reservedCellData())
        cell.applyPastDayStyle()
        cell.prepareForReuse()
        cell.configure(with: reservedCellData())

        tapEverything(in: cell)

        XCTAssertTrue(spy.changedTime, "a recycled cell on a future day must offer change time again")
    }

    // MARK: - Manual POI cell

    func testPastDayManualPoiKeepsRemovalAndDropsChangeTime() {
        let cell = TRPTimelineManualPoiCell(style: .default, reuseIdentifier: nil)
        let spy = ManualPoiCellSpy()
        cell.delegate = spy
        let segment = reservedSegment()
        segment.segmentType = .manualPoi
        cell.configure(with: segment, poi: nil, order: 1)
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertTrue(spy.removed)
        XCTAssertFalse(spy.changedTime)
    }

    // MARK: - Recommendation steps

    func testPastDayRecommendationStepKeepsRemovalAndDropsChangeTime() {
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first(where: { !$0.steps.isEmpty }),
              let segment = timeline.tripProfile?.segments.first(where: { $0.segmentType == .itinerary }) else {
            return XCTFail("mock timeline is missing an itinerary segment")
        }

        let cell = TRPTimelineRecommendationsCell(style: .default, reuseIdentifier: nil)
        let spy = RecommendationsCellSpy()
        cell.delegate = spy
        cell.configure(
            with: RecommendationsCellData(segmentIndex: 0, startingOrder: 1, title: "Recommendations",
                                          steps: plan.steps, isExpanded: true, segment: segment, city: city),
            indexPath: IndexPath(row: 0, section: 0)
        )
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertTrue(spy.removedStep)
        XCTAssertFalse(spy.changedTime)
        XCTAssertFalse(spy.reserved)
    }

    // MARK: - Screen smoke test

    func testTimelineScreenRendersTheMockTripWithoutNetwork() {
        let viewModel = TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline())
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)

        viewController.loadViewIfNeeded()
        viewController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        viewController.view.layoutIfNeeded()
        viewController.reload()

        let sections = viewController.tableView.numberOfSections
        XCTAssertGreaterThan(sections, 0)
        XCTAssertGreaterThan((0..<sections).reduce(0) { $0 + viewController.tableView.numberOfRows(inSection: $1) }, 0)

        let indexPath = IndexPath(row: 0, section: 0)
        XCTAssertNotNil(viewController.tableView.dataSource?.tableView(viewController.tableView, cellForRowAt: indexPath))
    }
}

/// Covers the inline warnings the POI time-range sheet shows instead of locking the pickers.
final class TRPTimeRangeWarningTests: XCTestCase {

    private var startPassedText: String {
        AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTimePassedWarning)
    }
    private var endBeforeStartText: String {
        AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTimeBeforeStartWarning)
    }

    private func isShowing(_ text: String, in root: UIView) -> Bool {
        var visible = false
        func walk(_ view: UIView) {
            guard !view.isHidden, view.alpha > 0.01 else { return }
            if let label = view as? UILabel, label.text == text { visible = true }
            view.subviews.forEach(walk)
        }
        walk(root)
        return visible
    }

    private func settle() {
        let pumped = expectation(description: "main queue")
        DispatchQueue.main.async { pumped.fulfill() }
        wait(for: [pumped], timeout: 2)
    }

    private func makeSheet(on day: Date) -> TRPTimeRangeSelectionViewController {
        let sheet = TRPTimeRangeSelectionViewController()
        sheet.setSelectedDate(day)
        sheet.loadViewIfNeeded()
        sheet.view.frame = CGRect(x: 0, y: 0, width: 390, height: 500)
        return sheet
    }

    func testStartTimeAlreadyPassedTodayRaisesTheInlineWarning() throws {
        let calendar = Calendar.current
        let now = Date()
        try XCTSkipUnless(calendar.component(.hour, from: now) >= 2, "needs an earlier hour to exist today")

        let sheet = makeSheet(on: calendar.startOfDay(for: now))
        sheet.setInitialTimes(from: calendar.date(byAdding: .hour, value: -1, to: now)!,
                              to: calendar.date(byAdding: .hour, value: 1, to: now)!)
        settle()
        sheet.view.layoutIfNeeded()

        XCTAssertTrue(isShowing(startPassedText, in: sheet.view))
        XCTAssertFalse(isShowing(endBeforeStartText, in: sheet.view))
    }

    func testSameTimesOnAFutureDayRaiseOnlyTheEndTimeWarning() {
        let calendar = Calendar.current
        let futureDay = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureDay)!

        let sheet = makeSheet(on: futureDay)
        sheet.setInitialTimes(from: start, to: start)
        settle()
        sheet.view.layoutIfNeeded()

        XCTAssertTrue(isShowing(endBeforeStartText, in: sheet.view))
        XCTAssertFalse(isShowing(startPassedText, in: sheet.view))
    }

    func testAValidFutureRangeShowsNoWarningAndKeepsTheSheetShort() {
        let calendar = Calendar.current
        let futureDay = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureDay)!
        let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: futureDay)!

        let sheet = makeSheet(on: futureDay)
        let baseHeight = sheet.preferredContentHeight
        sheet.setInitialTimes(from: start, to: end)
        settle()
        sheet.view.layoutIfNeeded()

        XCTAssertFalse(isShowing(startPassedText, in: sheet.view))
        XCTAssertFalse(isShowing(endBeforeStartText, in: sheet.view))
        XCTAssertEqual(sheet.preferredContentHeight, baseHeight, accuracy: 0.5)
    }

    func testAWarningGrowsTheSheet() throws {
        let calendar = Calendar.current
        let futureDay = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureDay)!

        let sheet = makeSheet(on: futureDay)
        let baseHeight = sheet.preferredContentHeight
        sheet.setInitialTimes(from: start, to: start)
        settle()
        sheet.view.layoutIfNeeded()

        XCTAssertGreaterThan(sheet.preferredContentHeight, baseHeight)
    }
}
