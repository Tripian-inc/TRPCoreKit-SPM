import XCTest
import TRPFoundationKit
import TRPRestKit
@testable import TRPCoreKit

/// Smart-recommendation create flow: the loader stays up until the generated plan is evaluated, and an empty or
/// failed recommendation is deleted before the error is shown.
final class TRPRecommendationGenerationFlowTests: XCTestCase {

    private final class LoaderSpy: TRPTimelineItineraryViewModelDelegate {
        let log: GenerationEventLog
        var loaderHidden: XCTestExpectation?
        var bottomSheetHidden: XCTestExpectation?
        private(set) var errors: [Error] = []

        init(log: GenerationEventLog) {
            self.log = log
        }

        func timelineItineraryViewModel(didUpdateTimeline: Bool) {}
        func timelineItineraryViewModel(noCitiesAvailable: Bool) {}
        func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}

        func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
            log.events.append("loader:\(showLottieLoading)")
            if !showLottieLoading { loaderHidden?.fulfill() }
        }

        func viewModel(showPreloader: Bool) {
            log.events.append("preloader:\(showPreloader)")
        }

        func viewModel(error: Error) {
            errors.append(error)
            log.events.append("error")
        }

        func viewModel(showLottie presentation: LottieLoaderPresentation,
                       textMode: LottieLoadingTextMode,
                       completion: (() -> Void)?) {
            log.events.append("showLottie:\(presentation)")
            completion?()
        }

        func viewModel(hideLottie presentation: LottieLoaderPresentation,
                       completion: (() -> Void)?) {
            log.events.append("hideLottie:\(presentation)")
            completion?()
            if presentation == .bottomSheet { bottomSheetHidden?.fulfill() }
        }
    }

    private static let createdPlanId = 990001
    private static let segmentStart = "2025-12-09 10:00"
    private static let segmentEnd = "2025-12-09 18:00"

    private var log: GenerationEventLog!
    private var repository: ScriptedTimelineRepository!
    private var spy: LoaderSpy!
    private var viewModel: TRPTimelineItineraryViewModel!
    private var generationSchedule: TimelineGenerateController.Scheduler = { _, work in work() }

    override func setUp() {
        super.setUp()
        TRPTimelineRefreshState.shared.setIdle()
        log = GenerationEventLog()
        repository = ScriptedTimelineRepository(log: log)
        spy = LoaderSpy(log: log)
        generationSchedule = { _, work in work() }
        viewModel = TRPTimelineItineraryViewModel(timeline: GenerationFixtures.generatedMockTimeline())
        viewModel.timelineRepository = repository
        viewModel.makeGenerationCheckUseCase = { [unowned self] repository in
            TRPTimelineCheckAllPlanUseCases(
                timelineRepository: repository,
                timelineModelRepository: MockTimelineModelRepository(),
                generateController: TimelineGenerateController(schedule: self.generationSchedule)
            )
        }
        drainMainQueue()
        viewModel.delegate = spy
    }

    override func tearDown() {
        TRPTimelineRefreshState.shared.setIdle()
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)!
    }

    private func addPlanData() -> AddPlanData {
        var data = AddPlanData()
        data.selectedCity = GenerationFixtures.barcelona
        data.startTime = date(Self.segmentStart)
        data.endTime = date(Self.segmentEnd)
        data.startingPointLocation = GenerationFixtures.barcelona.coordinate
        data.travelers = 2
        data.availableDays = [date("2025-12-08 00:00"), date("2025-12-09 00:00")]
        data.selectedDay = date("2025-12-09 00:00")
        return data
    }

    /// Server timeline after the PUT: the existing mock plus the created segment, appended at the returned index.
    private func serverTimeline(title: String, generatedStatus: Int, stepCount: Int) -> (TRPTimeline, Int) {
        var timeline = GenerationFixtures.generatedMockTimeline()
        let segment = GenerationFixtures.itinerarySegment(title: title,
                                                          startDate: Self.segmentStart,
                                                          endDate: Self.segmentEnd,
                                                          planId: Self.createdPlanId)
        timeline.tripProfile?.segments.append(segment)
        timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "\(Self.createdPlanId)",
                                                                           generatedStatus: generatedStatus,
                                                                           stepCount: stepCount)]
        return (timeline, (timeline.tripProfile?.segments.count ?? 0) - 1)
    }

    private func expectedTitle() -> String {
        viewModel.generateSegmentTitle(for: GenerationFixtures.barcelona, on: Self.segmentStart)
    }

    private func runCreateFlow() {
        spy.loaderHidden = expectation(description: "loader hidden")
        viewModel.createSmartRecommendationSegment(from: addPlanData())
        wait(for: [spy.loaderHidden!], timeout: 2)
        drainMainQueue()
    }

    private var refreshFailed: Bool {
        guard case .failed = TRPTimelineRefreshState.shared.status.value else { return false }
        return true
    }

    private var genericFailureText: String {
        TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorGenerationFailed)
    }

    // MARK: - Tests

    func testGeneratedPlanWithStepsKeepsTheSegmentAndHidesTheLoaderOnceAtTheEnd() {
        let title = expectedTitle()
        let (server, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { _ in .success(server) }

        runCreateFlow()

        XCTAssertEqual(log.events, ["loader:true", "put", "fetch", "fetch", "loader:false"])
        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(viewModel.selectedDayIndex, 1)
        guard case .idle = TRPTimelineRefreshState.shared.status.value else { return XCTFail("refresh state should be idle") }
        XCTAssertEqual(repository.createEditCalls.first?.title, title)
    }

    func testFailedGenerationDeletesTheCreatedSegmentBeforeReportingTheError() {
        let title = expectedTitle()
        let (server, createdIndex) = serverTimeline(title: title, generatedStatus: -1, stepCount: 0)
        repository.fetchResponder = { _ in .success(server) }

        runCreateFlow()

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(log.events, ["loader:true", "put", "fetch", "fetch", "delete:\(createdIndex)", "fetch", "loader:false", "error"])
        XCTAssertEqual(spy.errors.map(\.localizedDescription), [genericFailureText])
        XCTAssertTrue(refreshFailed)
    }

    func testGeneratedPlanWithoutStepsIsDeletedAndReported() {
        let title = expectedTitle()
        let (server, createdIndex) = serverTimeline(title: title, generatedStatus: 1, stepCount: 0)
        repository.fetchResponder = { _ in .success(server) }

        runCreateFlow()

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(log.events.suffix(3), ["fetch", "loader:false", "error"])
        XCTAssertEqual(spy.errors.map(\.localizedDescription), [genericFailureText])
        XCTAssertEqual(log.events.filter { $0 == "loader:false" }.count, 1)
    }

    func testPollingFailureDeletesTheIdentifiableSegmentAndFailsTheRefreshState() {
        let (server, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        let pollFailures = 3
        repository.fetchResponder = { index in
            index < pollFailures ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(server)
        }

        runCreateFlow()

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(log.events.filter { $0 == "fetch" }.count, pollFailures + 2)
        XCTAssertEqual(log.events.suffix(4), ["delete:\(createdIndex)", "fetch", "loader:false", "error"])
        XCTAssertEqual(spy.errors.map(\.localizedDescription), [genericFailureText])
        XCTAssertTrue(refreshFailed)
    }

    func testPollingFailureWithoutTheCreatedSegmentDeletesNothing() {
        let unchanged = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { index in
            index < 3 ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(unchanged)
        }

        runCreateFlow()

        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertEqual(log.events.suffix(2), ["loader:false", "error"])
        XCTAssertEqual(spy.errors.count, 1)
        XCTAssertTrue(refreshFailed)
    }

    func testPollingTimeoutReportsTheTimeoutText() {
        let (pending, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        runCreateFlow()

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(spy.errors.map(\.localizedDescription),
                       [TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorTimeout)])
        XCTAssertTrue(refreshFailed)
    }

    func testRejectedCreateHidesTheLoaderWithoutPolling() {
        repository.createEditResult = .failure(TRPErrors.httpResult(code: 400, des: "", info: [:]))

        runCreateFlow()

        XCTAssertEqual(log.events, ["loader:true", "put", "loader:false", "error"])
        XCTAssertEqual(repository.fetchCallCount, 0)
    }

    func testPollingFailureThenRecoverySucceedsWithoutDeletingTheSegment() {
        let (server, _) = serverTimeline(title: expectedTitle(), generatedStatus: 1, stepCount: 3)
        let pollFailures = 2
        repository.fetchResponder = { index in
            index < pollFailures ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(server)
        }

        runCreateFlow()

        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(log.events.last, "loader:false")
        guard case .idle = TRPTimelineRefreshState.shared.status.value else { return XCTFail("refresh state should be idle") }
    }

    func testReleasingTheSharedCheckAllPlanUseCaseDoesNotStopTheRecommendationPoller() {
        let scheduler = ManualScheduler()
        generationSchedule = scheduler.schedule
        let title = expectedTitle()
        let (pending, _) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { index in index == 0 ? .success(pending) : .success(generated) }
        spy.loaderHidden = expectation(description: "loader hidden")

        viewModel.createSmartRecommendationSegment(from: addPlanData())
        drainMainQueue()
        XCTAssertTrue(scheduler.hasPendingWork)
        XCTAssertNotNil(viewModel.recommendationGenerationUseCase)
        viewModel.checkAllPlanUseCase?.cancelPolling()
        viewModel.checkAllPlanUseCase = nil
        scheduler.runUntilIdle()
        wait(for: [spy.loaderHidden!], timeout: 2)
        drainMainQueue()

        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(log.events.filter { $0 == "loader:false" }.count, 1)
        XCTAssertNil(viewModel.recommendationGenerationUseCase)
    }

    func testRefreshFailureAfterAFailedGenerationDeletesTheSegmentFoundInThePolledTimeline() {
        let (server, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: -1, stepCount: 0)
        let localSegmentCount = viewModel.timeline?.tripProfile?.segments.count ?? 0
        repository.fetchResponder = { index in
            index == 1 ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(server)
        }

        runCreateFlow()

        XCTAssertGreaterThanOrEqual(createdIndex, localSegmentCount)
        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(spy.errors.map(\.localizedDescription), [genericFailureText])
        XCTAssertTrue(refreshFailed)
    }

    func testRemoveSegmentDeletesAndHidesTheBottomSheetLoader() {
        guard let timeline = viewModel.timeline, let segments = timeline.tripProfile?.segments,
              let segmentToRemove = segments.first else {
            return XCTFail("expected a segment to remove")
        }
        repository.fetchResponder = { _ in .success(timeline) }

        spy.bottomSheetHidden = expectation(description: "bottom sheet hidden")
        viewModel.removeSegment(segmentToRemove)
        wait(for: [spy.bottomSheetHidden!], timeout: 2)
        drainMainQueue()

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(log.events, ["showLottie:bottomSheet", "delete:0", "fetch", "preloader:false", "loader:false", "hideLottie:bottomSheet"])
    }
}
