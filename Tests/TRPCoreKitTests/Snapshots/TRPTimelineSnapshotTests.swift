import XCTest
import UIKit
import SnapshotTesting
import TRPRestKit
import TRPFoundationKit
@testable import TRPCoreKit

/// Timeline rows and the add-plan choice screen, drawn once per provider at a fixed 390 pt width from
/// `TRPTimelineMockData` with every image removed. Record by deleting a reference and running again.
final class TRPTimelineSnapshotTests: XCTestCase {

    private struct EnvironmentError: Error, CustomStringConvertible {
        let description: String
    }

    private let providers: [(provider: TripianProvider, name: String)] = [
        (.civitatis, "civitatis"),
        (.nexus, "nexus"),
        (.getYourGuide, "getYourGuide")
    ]
    private let width: CGFloat = 390
    private let traits = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(layoutDirection: .leftToRight),
        UITraitCollection(preferredContentSizeCategory: .large),
        UITraitCollection(displayScale: 2)
    ])

    private var originalProvider: TripianProvider = .civitatis
    private var originalZone: TimeZone!
    private var originalSystemZoneVariable: String?
    private var originalLanguage: String = "en"

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalProvider = TRPCoreKit.shared.provider
        originalZone = NSTimeZone.default
        originalLanguage = TRPClient.getLanguage()
        originalSystemZoneVariable = ProcessInfo.processInfo.environment["TZ"]
        setSystemZone("Europe/Madrid")
        NSTimeZone.default = TimeZone(identifier: "Europe/Madrid")!
        TRPClient.changeLanguage("en")
        TRPFonts.registerAll()
        guard Locale.current.identifier == "en_US" else {
            throw EnvironmentError(description: "snapshots are recorded with the en_US locale (xcodebuild -testLanguage en -testRegion US), found \(Locale.current.identifier)")
        }
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        NSTimeZone.default = originalZone
        setSystemZone(originalSystemZoneVariable)
        TRPClient.changeLanguage(originalLanguage)
        super.tearDown()
    }

    /// Points the process's system time zone at `identifier`, or back at the machine's when nil, so code that
    /// reads the system zone rather than `NSTimeZone.default` draws the same days on every machine.
    private func setSystemZone(_ identifier: String?) {
        if let identifier {
            setenv("TZ", identifier, 1)
        } else {
            unsetenv("TZ")
        }
        tzset()
        NSTimeZone.resetSystemTimeZone()
    }

    // MARK: - Mock data without images

    private func withoutImages(_ poi: TRPPoi) -> TRPPoi {
        guard let data = try? JSONEncoder().encode(poi),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return poi }
        json["image"] = nil
        json["gallery"] = []
        guard let stripped = try? JSONSerialization.data(withJSONObject: json),
              let decoded = try? JSONDecoder().decode(TRPPoi.self, from: stripped) else { return poi }
        return decoded
    }

    private func withoutImages(_ steps: [TRPTimelineStep]) -> [TRPTimelineStep] {
        return steps.map { step in
            var step = step
            step.poi = step.poi.map(withoutImages)
            return step
        }
    }

    private func mockPlan(_ id: String) -> TRPTimelinePlan {
        var plan = TRPTimelineMockData.getMockTimeline().plans!.first { $0.id == id }!
        plan.steps = withoutImages(plan.steps)
        return plan
    }

    /// The mock's booked cooking class, turned into the requested kind of activity.
    private func activityItem(_ kind: TRPTimelineActivityCellKind) -> TRPMergedTimelineItem {
        let segment = TRPTimelineMockData.getMockTimeline().tripProfile!.segments[2]
        segment.additionalData?.imageUrl = nil
        switch kind {
        case .booked:
            break
        case .reserved:
            segment.segmentType = .reservedActivity
            segment.additionalData?.price = TRPSegmentActivityPrice(currency: "EUR", value: 65)
        case .flexible:
            segment.segmentType = .reservedActivity
            segment.startDate = "2025-12-09 00:00"
            segment.endDate = "2025-12-09 23:59"
            segment.additionalData?.startDatetime = "2025-12-09 00:00"
            segment.additionalData?.endDatetime = "2025-12-09 23:59"
            segment.additionalData?.duration = -1
            segment.additionalData?.price = TRPSegmentActivityPrice(currency: "EUR", value: 65)
        }
        return TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 2)
    }

    private func manualPoiItem() -> TRPMergedTimelineItem {
        let timeline = TRPTimelineMockData.getMockTimeline()
        var plan = mockPlan("25459")
        plan.steps = [plan.steps[1]]
        let segment = TRPTimelineSegment()
        segment.segmentType = .manualPoi
        segment.title = plan.steps[0].poi?.name
        segment.startDate = "2025-12-07 10:30"
        segment.endDate = "2025-12-07 12:00"
        segment.city = timeline.city
        return TRPMergedTimelineItem(segment: segment, plan: plan, originalSegmentIndex: 4)
    }

    private func itinerarySegment() -> TRPTimelineSegment {
        return TRPTimelineMockData.getMockTimeline().tripProfile!.segments[0]
    }

    // MARK: - Rendering

    /// The cell at the fixed width and the height its constraints ask for, on the list's white background.
    private func sized(_ cell: UITableViewCell) -> UIView {
        cell.frame = CGRect(x: 0, y: 0, width: width, height: 1000)
        cell.layoutIfNeeded()
        let fitting = cell.contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let frame = CGRect(x: 0, y: 0, width: width, height: ceil(fitting.height))
        let container = UIView(frame: frame)
        container.backgroundColor = .white
        cell.frame = frame
        container.addSubview(cell)
        container.layoutIfNeeded()
        return container
    }

    private func assertCellSnapshot(_ makeCell: () -> UITableViewCell,
                                    file: StaticString = #filePath,
                                    testName: String = #function,
                                    line: UInt = #line) {
        for entry in providers {
            TRPCoreKit.shared.provider = entry.provider
            let view = sized(makeCell())
            assertSnapshot(of: view,
                           as: .image(precision: 1, perceptualPrecision: 0.98, traits: traits),
                           named: entry.name,
                           file: file, testName: testName, line: line)
        }
    }

    private func activityCell(_ kind: TRPTimelineActivityCellKind, pastDay: Bool) -> UITableViewCell {
        let cell = TRPTimelineActivityCell(style: .default, reuseIdentifier: nil)
        let item = activityItem(kind)
        if kind == .flexible {
            cell.configure(with: FlexibleActivityCellData(from: item))
        } else {
            cell.configure(with: BookedActivityCellData(from: item, order: 1))
        }
        if pastDay { cell.applyPastDayStyle() }
        return cell
    }

    // MARK: - Activity cell

    func testReservedActivityCell() {
        assertCellSnapshot { activityCell(.reserved, pastDay: false) }
    }

    func testReservedActivityCellOnAPastDay() {
        assertCellSnapshot { activityCell(.reserved, pastDay: true) }
    }

    func testBookedActivityCell() {
        assertCellSnapshot { activityCell(.booked, pastDay: false) }
    }

    func testBookedActivityCellOnAPastDay() {
        assertCellSnapshot { activityCell(.booked, pastDay: true) }
    }

    func testFlexibleActivityCell() {
        assertCellSnapshot { activityCell(.flexible, pastDay: false) }
    }

    func testFlexibleActivityCellOnAPastDay() {
        assertCellSnapshot { activityCell(.flexible, pastDay: true) }
    }

    // MARK: - Manual POI cell

    private func manualPoiCell(pastDay: Bool) -> UITableViewCell {
        let cell = TRPTimelineManualPoiCell(style: .default, reuseIdentifier: nil)
        cell.configure(with: ManualPoiCellData(from: manualPoiItem(), order: 2))
        if pastDay { cell.applyPastDayStyle() }
        return cell
    }

    func testManualPoiCell() {
        assertCellSnapshot { manualPoiCell(pastDay: false) }
    }

    func testManualPoiCellOnAPastDay() {
        assertCellSnapshot { manualPoiCell(pastDay: true) }
    }

    // MARK: - Recommendations cell

    private func recommendationsCell(pastDay: Bool) -> UITableViewCell {
        let cell = TRPTimelineRecommendationsCell(style: .default, reuseIdentifier: nil)
        let segment = itinerarySegment()
        cell.configure(
            with: RecommendationsCellData(segmentIndex: 0, startingOrder: 1,
                                          title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.recommendations),
                                          steps: mockPlan("25461").steps, isExpanded: true,
                                          segment: segment, city: segment.city),
            indexPath: IndexPath(row: 0, section: 0)
        )
        if pastDay { cell.applyPastDayStyle() }
        return cell
    }

    func testExpandedRecommendationsCell() {
        assertCellSnapshot { recommendationsCell(pastDay: false) }
    }

    func testExpandedRecommendationsCellOnAPastDay() {
        assertCellSnapshot { recommendationsCell(pastDay: true) }
    }

    // MARK: - Plan step cell

    private func planStepCell(stepIndex: Int, pastDay: Bool) -> UITableViewCell {
        let cell = TRPTimelinePlanStepCell(style: .default, reuseIdentifier: nil)
        let step = mockPlan("25461").steps[stepIndex]
        cell.configure(with: PlanStepCellData(segmentIndex: 0, order: stepIndex + 2, step: step, segment: itinerarySegment()))
        if pastDay { cell.applyPastDayStyle() }
        return cell
    }

    func testPlanStepCellForAPlace() {
        assertCellSnapshot { planStepCell(stepIndex: 0, pastDay: false) }
    }

    func testPlanStepCellForAPlaceOnAPastDay() {
        assertCellSnapshot { planStepCell(stepIndex: 0, pastDay: true) }
    }

    func testPlanStepCellForAnActivity() {
        assertCellSnapshot { planStepCell(stepIndex: 1, pastDay: false) }
    }

    func testPlanStepCellForAnActivityOnAPastDay() {
        assertCellSnapshot { planStepCell(stepIndex: 1, pastDay: true) }
    }

    // MARK: - Add plan choice screen

    /// The screen and the container view model it only holds weakly, which the add-plan container owns in the app.
    private func addPlanSelectDayScreen() -> (screen: AddPlanSelectDayVC, container: AddPlanContainerViewModel) {
        let timelineViewModel = TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline())
        let containerViewModel = AddPlanContainerViewModel(days: timelineViewModel.getDayDates(),
                                                           cities: timelineViewModel.getCities(),
                                                           selectedDayIndex: 0,
                                                           bookedActivities: timelineViewModel.getAllBookedActivities())
        let screen = AddPlanSelectDayVC()
        screen.viewModel = AddPlanSelectDayViewModel(containerViewModel: containerViewModel)
        return (screen, containerViewModel)
    }

    /// Puts the screen on screen so its day strip lays out its days, then waits for the strip's deferred scroll to settle.
    private func onScreen(_ screen: UIViewController, size: CGSize) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = screen
        window.isHidden = false
        screen.view.layoutIfNeeded()
        waitForScrollToSettle(in: screen.view)
        screen.view.layoutIfNeeded()
        return window
    }

    /// Spins the run loop until no scroll view under `view` has moved for a while, so a slow machine snapshots the same offset as a fast one.
    private func waitForScrollToSettle(in view: UIView, quietPeriod: TimeInterval = 0.5, timeout: TimeInterval = 5) {
        func offsets(in view: UIView) -> [CGPoint] {
            let own = (view as? UIScrollView).map { [$0.contentOffset] } ?? []
            return own + view.subviews.flatMap { offsets(in: $0) }
        }
        let deadline = Date().addingTimeInterval(timeout)
        var lastOffsets = offsets(in: view)
        var lastChange = Date()
        while Date() < deadline, Date().timeIntervalSince(lastChange) < quietPeriod {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            view.layoutIfNeeded()
            let current = offsets(in: view)
            if current != lastOffsets {
                lastOffsets = current
                lastChange = Date()
            }
        }
    }

    func testAddPlanSelectDayScreen() {
        for entry in providers {
            TRPCoreKit.shared.provider = entry.provider
            let (screen, container) = addPlanSelectDayScreen()
            screen.loadViewIfNeeded()
            let size = CGSize(width: width, height: screen.preferredContentHeight)
            let window = onScreen(screen, size: size)

            assertSnapshot(of: screen.view,
                           as: .image(precision: 1, perceptualPrecision: 0.98, size: size, traits: traits),
                           named: entry.name)
            window.isHidden = true
            withExtendedLifetime(container) {}
        }
    }
}
