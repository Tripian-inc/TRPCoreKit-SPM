import XCTest
import UIKit
import TRPFoundationKit
@testable import TRPCoreKit

/// Past-day actions follow `TripianProvider.pastDayActionStyle`: Civitatis keeps removal
/// (covered by `TRPTimelinePastDayActionTests`), while Nexus and GetYourGuide keep every
/// action greyed out and inert. These drive the same cells with the provider switched.
final class TRPTimelinePastDayProviderTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
        TRPCoreKit.shared.provider = .nexus
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        super.tearDown()
    }

    // MARK: - Spies

    private final class ActivityCellSpy: TRPTimelineActivityCellDelegate {
        var taps = 0
        func activityCellDidTapCell(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) {}
        func activityCellDidTapReservation(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) { taps += 1 }
        func activityCellDidTapChangeTime(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) { taps += 1 }
        func activityCellDidTapRemove(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) { taps += 1 }
    }

    private final class ManualPoiCellSpy: TRPTimelineManualPoiCellDelegate {
        var taps = 0
        func manualPoiCellDidTapChangeTime(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) { taps += 1 }
        func manualPoiCellDidTapRemove(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment) { taps += 1 }
        func manualPoiCellDidTapCell(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) {}
    }

    private final class PlanStepCellSpy: TRPTimelinePlanStepCellDelegate {
        var taps = 0
        func planStepCellDidSelect(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) {}
        func planStepCellDidTapChangeTime(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) { taps += 1 }
        func planStepCellDidTapRemove(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) { taps += 1 }
        func planStepCellDidTapReservation(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) { taps += 1 }
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

    /// Invokes each visible button's target/action directly, since there is no app host to route taps.
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

    // MARK: - Tests

    func testProvidersKeepTheirPastDayStyles() {
        XCTAssertEqual(TripianProvider.civitatis.pastDayActionStyle, .removalOnly)
        XCTAssertEqual(TripianProvider.nexus.pastDayActionStyle, .readOnly)
        XCTAssertEqual(TripianProvider.getYourGuide.pastDayActionStyle, .readOnly)
    }

    func testNexusPastDayReservedActivityIgnoresEveryAction() {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let spy = ActivityCellSpy()
        cell.delegate = spy
        cell.configure(with: reservedCellData())
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertEqual(spy.taps, 0)
    }

    func testNexusReusedActivityCellOffersEveryActionAgain() {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let spy = ActivityCellSpy()
        cell.delegate = spy
        cell.configure(with: reservedCellData())
        cell.applyPastDayStyle()
        cell.prepareForReuse()
        cell.configure(with: reservedCellData())

        tapEverything(in: cell)

        XCTAssertEqual(spy.taps, 3, "remove, change time and reservation must all work again on a future day")
    }

    func testNexusPastDayManualPoiIgnoresEveryAction() {
        let cell = TRPTimelineManualPoiCell(style: .default, reuseIdentifier: nil)
        let spy = ManualPoiCellSpy()
        cell.delegate = spy
        let segment = reservedSegment()
        segment.segmentType = .manualPoi
        cell.configure(with: segment, poi: nil, order: 1)
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertEqual(spy.taps, 0)
    }

    func testNexusPastDayPlanStepIgnoresEveryAction() {
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let step = timeline.plans?.first(where: { !$0.steps.isEmpty })?.steps.first,
              let segment = timeline.tripProfile?.segments.first(where: { $0.segmentType == .itinerary }) else {
            return XCTFail("mock timeline is missing an itinerary step")
        }
        let cell = TRPTimelinePlanStepCell(style: .default, reuseIdentifier: nil)
        let spy = PlanStepCellSpy()
        cell.delegate = spy
        cell.configure(with: PlanStepCellData(segmentIndex: 0, order: 1, step: step, segment: segment))
        cell.applyPastDayStyle()

        tapEverything(in: cell)

        XCTAssertEqual(spy.taps, 0)
    }
}
