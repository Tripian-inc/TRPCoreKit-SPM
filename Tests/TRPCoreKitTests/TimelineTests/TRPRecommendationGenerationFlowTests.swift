import XCTest
import TRPFoundationKit
import TRPRestKit
@testable import TRPCoreKit

/// Smart-recommendation create flow: the loader stays up for the foreground polls, generation then continues in the
/// background, and an empty or failed recommendation is deleted before the error is shown.
final class TRPRecommendationGenerationFlowTests: XCTestCase {

    private final class LoaderSpy: TRPTimelineItineraryViewModelDelegate {
        let log: GenerationEventLog
        var loaderHidden: XCTestExpectation?
        var bottomSheetHidden: XCTestExpectation?
        private(set) var errors: [Error] = []
        private(set) var messages: [(text: String, type: EvrAlertLevel)] = []

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

        func viewModel(showMessage: String, type: EvrAlertLevel) {
            messages.append((showMessage, type))
            log.events.append("message:\(type)")
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
    private static let titleToken = "created-token"

    private var log: GenerationEventLog!
    private var repository: ScriptedTimelineRepository!
    private var spy: LoaderSpy!
    private var viewModel: TRPTimelineItineraryViewModel!
    private var registry: TRPBackgroundGenerationRegistry!
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
        registry = TRPBackgroundGenerationRegistry()
        viewModel.backgroundGenerationRegistry = registry
        viewModel.makeRecommendationTitleToken = { Self.titleToken }
        viewModel.makeGenerationCheckUseCase = { [unowned self] repository, maxAttempts, ignoredPlanIds in
            TRPTimelineCheckAllPlanUseCases(
                timelineRepository: repository,
                timelineModelRepository: MockTimelineModelRepository(),
                generateController: TimelineGenerateController(maxAttempts: maxAttempts,
                                                               ignoredPlanIds: ignoredPlanIds,
                                                               schedule: self.generationSchedule)
            )
        }
        drainMainQueue()
        viewModel.delegate = spy
        viewModel.isViewVisible = true
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
        TRPTimelineItineraryViewModel.recommendationSegmentTitleBase + "-" + Self.titleToken
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

    private var continuesText: String {
        TimelineLocalizationKeys.localized(TimelineLocalizationKeys.infoRecommendationGenerationContinues)
    }

    private var readyText: String {
        TimelineLocalizationKeys.localized(TimelineLocalizationKeys.infoRecommendationGenerationReady)
    }

    private var refreshIdle: Bool {
        guard case .idle = TRPTimelineRefreshState.shared.status.value else { return false }
        return true
    }

    private func count(_ event: String) -> Int {
        log.events.filter { $0 == event }.count
    }

    /// Starts a create whose polls advance only through the returned scheduler; attempt 1 has already run.
    private func startCreateFlowWithManualPolling() -> ManualScheduler {
        let scheduler = ManualScheduler()
        generationSchedule = scheduler.schedule
        viewModel.createSmartRecommendationSegment(from: addPlanData())
        drainMainQueue()
        return scheduler
    }

    private func runPolls(_ scheduler: ManualScheduler, count: Int) {
        for _ in 0..<count { scheduler.runNext() }
        drainMainQueue()
    }

    /// Runs attempts 2...20, after which the screen is released.
    private func moveToBackgroundPhase(_ scheduler: ManualScheduler) {
        runPolls(scheduler, count: Self.foregroundAttempts - 1)
    }

    private func finishPolling(_ scheduler: ManualScheduler) {
        scheduler.runUntilIdle(maxSteps: 200)
        waitUntilGenerationEnds()
    }

    private func waitUntilGenerationEnds(file: StaticString = #filePath, line: UInt = #line) {
        waitUntil(file: file, line: line) { !self.viewModel.isRecommendationGenerationPending }
    }

    private func waitUntil(file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) {
        var rounds = 0
        while !condition() && rounds < 50 {
            drainMainQueue()
            rounds += 1
        }
        XCTAssertTrue(condition(), "condition not met", file: file, line: line)
    }

    private func refreshLocalTimeline() {
        let refreshed = expectation(description: "timeline refreshed")
        viewModel.fetchAndRefreshTimeline(hidesLoader: false) { _ in refreshed.fulfill() }
        wait(for: [refreshed], timeout: 2)
        drainMainQueue()
    }

    /// `timeline` with an unrelated itinerary segment inserted first, so the created segment moves one index up.
    private func insertingLeadingSegment(into timeline: TRPTimeline) -> TRPTimeline {
        let shifted = timeline
        let leading = GenerationFixtures.itinerarySegment(title: "Added elsewhere",
                                                          startDate: "2025-12-08 10:00",
                                                          endDate: "2025-12-08 12:00",
                                                          planId: Self.createdPlanId + 1)
        shifted.tripProfile?.segments.insert(leading, at: 0)
        return shifted
    }

    private static let foregroundAttempts = TRPTimelineItineraryViewModel.recommendationForegroundAttempts
    private static let maxAttempts = TRPTimelineItineraryViewModel.recommendationMaxAttempts

    /// A preexisting itinerary segment on the same day and city as the one about to be created, with a different unique title.
    private func preexistingSegment() -> TRPTimelineSegment {
        GenerationFixtures.itinerarySegment(title: "Recommendations-other",
                                            startDate: "2025-12-09 09:00",
                                            endDate: "2025-12-09 09:30",
                                            planId: 777)
    }

    /// Server timeline with `preexistingSegment()` plus the created segment appended, both for 2025-12-09 in Barcelona.
    private func serverTimelineWithPreexisting(title: String, generatedStatus: Int, stepCount: Int) -> (TRPTimeline, preexistingIndex: Int, createdIndex: Int) {
        var timeline = GenerationFixtures.generatedMockTimeline()
        timeline.tripProfile?.segments.append(preexistingSegment())
        let created = GenerationFixtures.itinerarySegment(title: title,
                                                          startDate: Self.segmentStart,
                                                          endDate: Self.segmentEnd,
                                                          planId: Self.createdPlanId)
        timeline.tripProfile?.segments.append(created)
        timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "\(Self.createdPlanId)",
                                                                           generatedStatus: generatedStatus,
                                                                           stepCount: stepCount)]
        let count = timeline.tripProfile?.segments.count ?? 0
        return (timeline, count - 2, count - 1)
    }

    // MARK: - Tests

    func testMakeRecommendationSegmentTitleProducesUniquePrefixedTitles() {
        let freshViewModel = TRPTimelineItineraryViewModel(timeline: GenerationFixtures.generatedMockTimeline())

        let first = freshViewModel.makeRecommendationSegmentTitle()
        let second = freshViewModel.makeRecommendationSegmentTitle()

        XCTAssertNotEqual(first, second)
        XCTAssertTrue(first.hasPrefix(TRPTimelineItineraryViewModel.recommendationSegmentTitleBase + "-"))
        XCTAssertTrue(second.hasPrefix(TRPTimelineItineraryViewModel.recommendationSegmentTitleBase + "-"))
    }

    func testCreateSmartRecommendationSegmentPutsTheInjectedTokenTitle() {
        let title = expectedTitle()
        let (server, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { _ in .success(server) }

        runCreateFlow()

        XCTAssertEqual(repository.createEditCalls.first?.title, TRPTimelineItineraryViewModel.recommendationSegmentTitleBase + "-" + Self.titleToken)
    }

    func testLocateCreatedRecommendationReturnsTheSegmentMatchingTheRequestKeyEvenWhenItIsSecond() {
        let title = expectedTitle()
        let timeline = GenerationFixtures.generatedMockTimeline()
        let other = GenerationFixtures.itinerarySegment(title: "Recommendations-other",
                                                        startDate: Self.segmentStart,
                                                        endDate: Self.segmentEnd,
                                                        planId: 555)
        let created = GenerationFixtures.itinerarySegment(title: title,
                                                          startDate: Self.segmentStart,
                                                          endDate: Self.segmentEnd,
                                                          planId: Self.createdPlanId)
        timeline.tripProfile?.segments.append(contentsOf: [other, created])
        let secondIndex = (timeline.tripProfile?.segments.count ?? 0) - 1

        let request = TRPRecommendationGenerationRequest(
            tripHash: timeline.tripHash,
            key: TRPRecommendationSegmentKey(title: title, startDate: Self.segmentStart, cityId: GenerationFixtures.barcelona.id),
            preexistingKeys: [],
            targetDayIndex: nil
        )

        let located = viewModel.locateCreatedRecommendation(request, in: timeline)

        XCTAssertEqual(located?.segmentIndex, secondIndex)
    }

    func testForegroundFailureDeletesTheCreatedSegmentNotThePreexistingOne() {
        viewModel.timeline?.tripProfile?.segments.append(preexistingSegment())
        let title = expectedTitle()
        let (server, preexistingIndex, createdIndex) = serverTimelineWithPreexisting(title: title, generatedStatus: -1, stepCount: 0)
        repository.fetchResponder = { _ in .success(server) }

        runCreateFlow()

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertFalse(repository.deletedSegmentIndexes.contains(preexistingIndex))
    }

    func testBackgroundFailureDeletesTheCreatedSegmentNotThePreexistingOne() {
        viewModel.timeline?.tripProfile?.segments.append(preexistingSegment())
        let title = expectedTitle()
        let (pending, preexistingIndex, createdIndex) = serverTimelineWithPreexisting(title: title, generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertFalse(repository.deletedSegmentIndexes.contains(preexistingIndex))
    }

    func testBackgroundSuccessDoesNotTouchThePreexistingSegment() {
        viewModel.timeline?.tripProfile?.segments.append(preexistingSegment())
        let title = expectedTitle()
        let (pending, _, _) = serverTimelineWithPreexisting(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, preexistingIndex, createdIndex) = serverTimelineWithPreexisting(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { index in index < Self.foregroundAttempts + 4 ? .success(pending) : .success(generated) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText, readyText])
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count == createdIndex + 1 else {
            return XCTFail("expected the preexisting and the created segment in the refreshed timeline")
        }
        XCTAssertEqual(segments[createdIndex].title, title)
        XCTAssertEqual(segments[createdIndex].dayIds, [Self.createdPlanId])
        XCTAssertEqual(segments[preexistingIndex].title, preexistingSegment().title)
        XCTAssertTrue(registry.isEmpty)
    }

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

    // MARK: - Background generation

    func testGenerationFinishingAtAttemptFiveKeepsTheForegroundSequence() {
        let title = expectedTitle()
        let (pending, _) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { index in index < 4 ? .success(pending) : .success(generated) }
        XCTAssertNotEqual(viewModel.selectedDayIndex, 1)

        runCreateFlow()

        XCTAssertEqual(log.events, ["loader:true", "put"] + Array(repeating: "fetch", count: 6) + ["loader:false"])
        XCTAssertTrue(spy.messages.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(viewModel.selectedDayIndex, 1)
        XCTAssertFalse(viewModel.isRecommendationGenerationPending)
        XCTAssertTrue(refreshIdle)
    }

    func testGenerationStillPendingAfterAttemptTwentyReleasesTheScreenAndKeepsPolling() {
        let (pending, _) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }
        let initialDay = viewModel.selectedDayIndex

        let scheduler = startCreateFlowWithManualPolling()
        runPolls(scheduler, count: Self.foregroundAttempts - 2)

        XCTAssertEqual(repository.fetchCallCount, Self.foregroundAttempts - 1)
        XCTAssertEqual(count("loader:false"), 0)
        guard case .refreshing = TRPTimelineRefreshState.shared.status.value else { return XCTFail("refresh state should be refreshing") }

        runPolls(scheduler, count: 1)

        XCTAssertEqual(log.events,
                       ["loader:true", "put"] + Array(repeating: "fetch", count: Self.foregroundAttempts) + ["loader:false", "message:info"])
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText])
        XCTAssertEqual(spy.messages.map { $0.type }, [.info])
        XCTAssertTrue(scheduler.hasPendingWork)
        XCTAssertTrue(viewModel.isRecommendationGenerationPending)
        XCTAssertEqual(viewModel.selectedDayIndex, initialDay)
        XCTAssertTrue(refreshIdle)

        runPolls(scheduler, count: 5)

        XCTAssertEqual(repository.fetchCallCount, Self.foregroundAttempts + 5)
        XCTAssertEqual(count("loader:false"), 1)
        XCTAssertEqual(spy.messages.count, 1)
        XCTAssertTrue(spy.errors.isEmpty)
    }

    private func runBackgroundSuccessAtAttemptTwentyFive() {
        let title = expectedTitle()
        let (pending, createdIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { index in index < 24 ? .success(pending) : .success(generated) }
        let initialDay = viewModel.selectedDayIndex

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertEqual(repository.fetchCallCount, 26)
        XCTAssertEqual(count("loader:true"), 1)
        XCTAssertEqual(count("loader:false"), 1)
        XCTAssertEqual(count("preloader:false"), 0)
        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(viewModel.selectedDayIndex, initialDay)
        XCTAssertEqual(viewModel.timeline?.tripProfile?.segments.count, createdIndex + 1)
        XCTAssertTrue(refreshIdle)
        XCTAssertTrue(registry.isEmpty)
    }

    func testBackgroundSuccessRefreshesSilentlyAndShowsTheReadyNoticeWhenVisible() {
        runBackgroundSuccessAtAttemptTwentyFive()

        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText, readyText])
        XCTAssertEqual(spy.messages.map { $0.type }, [.info, .info])
        XCTAssertEqual(Array(log.events.suffix(2)), ["fetch", "message:info"])
    }

    func testBackgroundSuccessShowsNoNoticeWhenTheScreenIsNotVisible() {
        viewModel.isViewVisible = false

        runBackgroundSuccessAtAttemptTwentyFive()

        XCTAssertTrue(spy.messages.isEmpty)
        XCTAssertEqual(log.events.last, "fetch")
    }

    func testBackgroundEmptyResultDeletesTheRelocatedSegmentAndShowsANonBlockingError() {
        let title = expectedTitle()
        let (pending, polledIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (empty, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 0)
        let shifted = insertingLeadingSegment(into: serverTimeline(title: title, generatedStatus: 1, stepCount: 0).0)
        repository.fetchResponder = { index in
            switch index {
            case ..<24: return .success(pending)
            case 24: return .success(empty)
            default: return .success(shifted)
            }
        }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        let relocatedIndex = polledIndex + 1
        XCTAssertEqual(repository.deletedSegmentIndexes, [relocatedIndex])
        XCTAssertEqual(Array(log.events.suffix(4)), ["fetch", "delete:\(relocatedIndex)", "fetch", "message:error"])
        XCTAssertEqual(spy.messages.last?.text, genericFailureText)
        XCTAssertEqual(spy.messages.last?.type, .error)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(count("loader:false"), 1)
        XCTAssertFalse(refreshFailed)
    }

    func testBackgroundTimeoutAtAttemptSixtyDeletesTheSegmentAndShowsANonBlockingError() {
        let (pending, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertEqual(repository.fetchCallCount, Self.maxAttempts + 2)
        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(Array(log.events.suffix(4)), ["fetch", "delete:\(createdIndex)", "fetch", "message:error"])
        XCTAssertEqual(spy.messages.map { $0.type }, [.info, .error])
        XCTAssertEqual(spy.messages.last?.text, genericFailureText)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertFalse(refreshFailed)
        XCTAssertTrue(registry.isEmpty)
    }

    func testBackgroundPollingFailuresDeleteTheSegmentWithoutAnAlert() {
        let (pending, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        var pollsFail = false
        repository.fetchResponder = { _ in
            pollsFail ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(pending)
        }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        pollsFail = true
        scheduler.runUntilIdle(maxSteps: 200)
        pollsFail = false
        waitUntilGenerationEnds()

        XCTAssertEqual(repository.fetchCallCount, Self.foregroundAttempts + 3 + 2)
        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertEqual(spy.messages.map { $0.type }, [.info, .error])
        XCTAssertTrue(spy.errors.isEmpty)
    }

    func testSegmentRemovedByTheUserDuringTheBackgroundPhaseIsNotDeletedAgain() {
        let (pending, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        var server = pending
        repository.fetchResponder = { _ in .success(server) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        refreshLocalTimeline()
        guard let created = viewModel.timeline?.tripProfile?.segments[createdIndex] else {
            return XCTFail("expected the created segment in the local timeline")
        }

        server = GenerationFixtures.generatedMockTimeline()
        spy.bottomSheetHidden = expectation(description: "bottom sheet hidden")
        viewModel.removeSegment(created)
        wait(for: [spy.bottomSheetHidden!], timeout: 2)
        finishPolling(scheduler)

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText])
        XCTAssertEqual(log.events.last, "fetch")
    }

    func testSecondCreateDuringTheBackgroundPhaseIsRefusedWithTheInfoNotice() {
        let (pending, _) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        let eventCount = log.events.count

        viewModel.createSmartRecommendationSegment(from: addPlanData())
        drainMainQueue()

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(Array(log.events.dropFirst(eventCount)), ["message:info"])
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText, continuesText])
        XCTAssertTrue(viewModel.isRecommendationGenerationPending)
        XCTAssertTrue(scheduler.hasPendingWork)
    }

    func testAddPlanCompletionDuringTheBackgroundPhaseKeepsTheRecommendationTargetDay() {
        let title = expectedTitle()
        let (pending, _) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        var server = pending
        repository.fetchResponder = { _ in .success(server) }
        let addPlanDayIndex = 0
        viewModel.selectDay(at: 1)

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        XCTAssertNil(viewModel.pendingNavigationDayIndex)
        XCTAssertEqual(viewModel.activeRecommendationGeneration?.targetDayIndex, 1)

        viewModel.pendingNavigationDayIndex = addPlanDayIndex
        TRPTimelineRefreshState.shared.setRefreshing()
        TRPTimelineRefreshState.shared.setCompleted()
        waitUntil { self.viewModel.pendingNavigationDayIndex == nil }
        drainMainQueue()

        XCTAssertEqual(viewModel.selectedDayIndex, addPlanDayIndex)
        XCTAssertEqual(viewModel.activeRecommendationGeneration?.targetDayIndex, 1)

        server = generated
        finishPolling(scheduler)

        XCTAssertEqual(viewModel.selectedDayIndex, addPlanDayIndex)
        XCTAssertNil(viewModel.pendingNavigationDayIndex)
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText, readyText])
    }

    func testSecondCreateDuringTheForegroundPhaseIsRefusedWithoutASecondPutOrLoaderToggle() {
        let (pending, _) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        runPolls(scheduler, count: 2)

        XCTAssertTrue(viewModel.isRecommendationGenerationPending)
        let loaderTrueCountBefore = count("loader:true")
        let fetchCountBefore = repository.fetchCallCount

        viewModel.createSmartRecommendationSegment(from: addPlanData())
        drainMainQueue()

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(count("loader:true"), loaderTrueCountBefore)
        XCTAssertEqual(repository.fetchCallCount, fetchCountBefore)
        XCTAssertEqual(spy.messages.map { $0.text }, [continuesText])
        XCTAssertTrue(viewModel.isRecommendationGenerationPending)
        XCTAssertTrue(scheduler.hasPendingWork)
    }

    func testBackgroundEmptyResultShowsNoNoticeWhenTheScreenIsNotVisible() {
        viewModel.isViewVisible = false
        let title = expectedTitle()
        let (pending, polledIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (empty, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 0)
        repository.fetchResponder = { index in index < 24 ? .success(pending) : .success(empty) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertEqual(repository.deletedSegmentIndexes, [polledIndex])
        XCTAssertTrue(spy.messages.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertEqual(log.events.last, "fetch")
    }

    func testBackgroundTimeoutShowsNoNoticeWhenTheScreenIsNotVisible() {
        viewModel.isViewVisible = false
        let (pending, createdIndex) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        finishPolling(scheduler)

        XCTAssertEqual(repository.deletedSegmentIndexes, [createdIndex])
        XCTAssertTrue(spy.messages.isEmpty)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertFalse(refreshFailed)
        XCTAssertTrue(registry.isEmpty)
    }

    func testLateCompletionAfterTheViewModelIsDeallocatedDoesNothing() {
        let title = expectedTitle()
        let (pending, _) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { _ in .success(pending) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)

        let isViewModelReleased: () -> Bool = { [weak releasedViewModel = viewModel] in releasedViewModel == nil }
        viewModel = nil
        XCTAssertTrue(isViewModelReleased())

        let eventsBeforeRelease = log.events.count
        let messagesBeforeRelease = spy.messages.map { $0.text }
        XCTAssertEqual(messagesBeforeRelease, [continuesText])

        scheduler.runUntilIdle(maxSteps: 200)
        drainMainQueue()

        XCTAssertFalse(scheduler.hasPendingWork)
        XCTAssertTrue(log.events.dropFirst(eventsBeforeRelease).allSatisfy { $0 == "fetch" },
                      "no loader, message or delete after release: \(log.events.dropFirst(eventsBeforeRelease))")
        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertEqual(spy.messages.map { $0.text }, messagesBeforeRelease)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertTrue(refreshIdle)
        XCTAssertFalse(registry.isEmpty, "an abandoned background recommendation stays excluded until a poll of its trip clears it")

        let registry = self.registry!
        let genericPoller = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) })
        XCTAssertFalse(genericPoller.isGenerationPending(pending))
        XCTAssertFalse(registry.isEmpty, "a poll that still sees the plan pending keeps the key")

        XCTAssertFalse(genericPoller.isGenerationPending(generated))
        XCTAssertTrue(registry.isEmpty, "a poll that sees the plan generated removes the abandoned key")
    }

    func testFailedUserDeleteStillReleasesTheGateForTheQueuedCleanupDelete() {
        let title = expectedTitle()
        let (pending, createdIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let empty = serverTimeline(title: title, generatedStatus: 1, stepCount: 0).0
        var server = pending
        repository.fetchResponder = { _ in .success(server) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        refreshLocalTimeline()
        guard let userSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment for the user to remove")
        }

        repository.defersDeleteCompletions = true
        repository.deleteResult = .failure(TRPErrors.httpResult(code: 500, des: "", info: [:]))
        spy.bottomSheetHidden = expectation(description: "bottom sheet hidden")
        viewModel.removeSegment(userSegment)

        server = empty
        scheduler.runUntilIdle(maxSteps: 200)
        drainMainQueue()

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(viewModel.queuedSegmentMutations.count, 1)
        XCTAssertTrue(viewModel.isSegmentMutationInFlight)

        repository.completeNextDelete()
        wait(for: [spy.bottomSheetHidden!], timeout: 2)
        drainMainQueue()

        XCTAssertEqual(spy.errors.count, 1)
        XCTAssertEqual(repository.deletedSegmentIndexes, [0, createdIndex])
        XCTAssertTrue(viewModel.isSegmentMutationInFlight, "the queued cleanup delete should now be running")

        repository.deleteResult = .success(true)
        waitUntil { self.repository.pendingDeleteCompletions.count == 1 }
        repository.completeNextDelete()
        waitUntilGenerationEnds()

        XCTAssertEqual(repository.deletedSegmentIndexes, [0, createdIndex])
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertEqual(spy.messages.map { $0.type }, [.info, .error])
    }

    func testSecondQueuedRemoveSegmentReResolvesItsIndexAfterTheFirstDeleteCompletes() {
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count >= 2 else {
            return XCTFail("expected at least two segments in the mock timeline")
        }
        let firstSegment = segments[0]
        let secondSegment = segments[1]
        let serverAfterFirstDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterFirstDelete.tripProfile?.segments.removeAll { $0.title != secondSegment.title }
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(firstSegment)
        viewModel.removeSegment(secondSegment)

        XCTAssertEqual(viewModel.queuedSegmentMutations.count, 1)
        XCTAssertEqual(repository.deletedSegmentIndexes, [0])

        server = serverAfterFirstDelete
        repository.completeNextDelete()
        waitUntil { self.repository.pendingDeleteCompletions.count == 1 }
        repository.completeNextDelete()
        waitUntil { !self.viewModel.isSegmentMutationInFlight }

        XCTAssertEqual(repository.deletedSegmentIndexes, [0, 0])
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
    }

    func testUserDeleteAndBackgroundCleanupRunSeriallyAndTheCleanupRelocates() {
        let title = expectedTitle()
        let (pending, createdIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let empty = serverTimeline(title: title, generatedStatus: 1, stepCount: 0).0
        let emptyAfterUserDelete = serverTimeline(title: title, generatedStatus: 1, stepCount: 0).0
        emptyAfterUserDelete.tripProfile?.segments.removeFirst()
        var server = pending
        repository.fetchResponder = { _ in .success(server) }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        refreshLocalTimeline()
        guard let userSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment for the user to remove")
        }

        repository.defersDeleteCompletions = true
        spy.bottomSheetHidden = expectation(description: "bottom sheet hidden")
        viewModel.removeSegment(userSegment)
        server = empty
        scheduler.runUntilIdle(maxSteps: 200)
        drainMainQueue()

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(viewModel.queuedSegmentMutations.count, 1)
        XCTAssertTrue(viewModel.isRecommendationGenerationPending)

        server = emptyAfterUserDelete
        let fetchesBeforeUserDeleteCompletes = repository.fetchCallCount
        repository.completeNextDelete()
        wait(for: [spy.bottomSheetHidden!], timeout: 2)
        waitUntil { self.repository.pendingDeleteCompletions.count == 1 }

        let relocatedIndex = createdIndex - 1
        XCTAssertEqual(repository.deletedSegmentIndexes, [0, relocatedIndex])
        XCTAssertEqual(repository.fetchCallCount, fetchesBeforeUserDeleteCompletes + 2)

        repository.completeNextDelete()
        waitUntilGenerationEnds()

        XCTAssertEqual(Array(log.events.suffix(3)), ["delete:\(relocatedIndex)", "fetch", "message:error"])
        XCTAssertEqual(spy.messages.last?.text, genericFailureText)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
    }

    func testRecommendationIsTrackedFromAttemptTwentyUntilTheBackgroundFlowConcludes() {
        let title = expectedTitle()
        let (pending, createdIndex) = serverTimeline(title: title, generatedStatus: 0, stepCount: 0)
        let (generated, _) = serverTimeline(title: title, generatedStatus: 1, stepCount: 3)
        repository.fetchResponder = { index in index < 24 ? .success(pending) : .success(generated) }
        guard let createdSegment = pending.tripProfile?.segments[createdIndex] else {
            return XCTFail("expected the created segment in the server timeline")
        }

        let scheduler = startCreateFlowWithManualPolling()
        runPolls(scheduler, count: Self.foregroundAttempts - 2)

        XCTAssertTrue(registry.isEmpty, "the foreground phase is not tracked")

        runPolls(scheduler, count: 1)

        XCTAssertTrue(registry.isTracked(createdSegment, tripHash: pending.tripHash))

        finishPolling(scheduler)

        XCTAssertTrue(registry.isEmpty)
    }

    func testGenericSegmentGenerationPollDuringTheBackgroundPhaseDoesNotWaitForTheRecommendation() {
        let (pending, _) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        repository.fetchResponder = { _ in .success(pending) }
        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)

        var fetchesAtCompletion: Int?
        TRPTimelineRefreshState.shared.status.addObserver(self, getDefaultValues: false) { [unowned self] status in
            guard case .completed = status, fetchesAtCompletion == nil else { return }
            fetchesAtCompletion = self.repository.fetchCallCount
        }
        defer { TRPTimelineRefreshState.shared.status.removeObserver(self) }
        let fetchesBefore = repository.fetchCallCount

        viewModel.waitForSegmentGeneration(tripHash: "generation-hash")
        waitUntil { fetchesAtCompletion != nil }

        XCTAssertEqual(fetchesAtCompletion, fetchesBefore + 1, "one generic poll, no waiting for the recommendation")
        XCTAssertNil(viewModel.checkAllPlanUseCase)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertFalse(refreshFailed)
        XCTAssertTrue(viewModel.isRecommendationGenerationPending)
        XCTAssertTrue(scheduler.hasPendingWork, "the recommendation keeps polling on its own")
    }

    func testBackgroundPollingFailuresWithAFailedRefreshShowTheErrorWithoutDeleting() {
        let (pending, _) = serverTimeline(title: expectedTitle(), generatedStatus: 0, stepCount: 0)
        var isOffline = false
        repository.fetchResponder = { _ in
            isOffline ? .failure(TRPErrors.httpResult(code: 500, des: "", info: [:])) : .success(pending)
        }

        let scheduler = startCreateFlowWithManualPolling()
        moveToBackgroundPhase(scheduler)
        isOffline = true
        scheduler.runUntilIdle(maxSteps: 200)
        waitUntilGenerationEnds()

        XCTAssertEqual(repository.fetchCallCount, Self.foregroundAttempts + 3 + 1)
        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)
        XCTAssertEqual(spy.messages.map { $0.type }, [.info, .error])
        XCTAssertEqual(spy.messages.last?.text, genericFailureText)
        XCTAssertTrue(spy.errors.isEmpty)
        XCTAssertFalse(viewModel.isRecommendationGenerationPending)
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertTrue(registry.isEmpty)
    }

    func testIndexBasedEditQueuedBehindADeleteTargetsTheSegmentAtItsNewIndex() {
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count >= 2 else {
            return XCTFail("expected at least two segments in the mock timeline")
        }
        let deletedSegment = segments[0]
        let editedSegment = segments[1]
        let capturedIndex = 1
        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeFirst()
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var editedIndexes: [Int] = []
        var segmentGoneCalls = 0
        viewModel.performSegmentEdit(of: editedSegment, onSegmentGone: { segmentGoneCalls += 1 }) { [unowned self] segmentIndex, done in
            editedIndexes.append(segmentIndex)
            let profile = TRPCreateEditTimelineSegmentProfile(from: editedSegment, tripHash: "generation-hash", segmentIndex: segmentIndex)
            self.repository.createEditTimelineSegment(profile: profile) { _ in done() }
        }

        XCTAssertTrue(editedIndexes.isEmpty, "the edit waits for the running delete")
        XCTAssertEqual(viewModel.queuedSegmentMutations.count, 1)

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { !self.viewModel.isSegmentMutationInFlight }

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(editedIndexes, [capturedIndex - 1])
        XCTAssertEqual(repository.createEditCalls.map { $0.segmentIndex }, [capturedIndex - 1])
        XCTAssertEqual(segmentGoneCalls, 0)
        XCTAssertTrue(spy.messages.isEmpty)
    }

    func testIndexBasedEditOfASegmentDeletedMeanwhileSendsNothingAndShowsAnError() {
        guard let deletedSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment in the mock timeline")
        }
        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeFirst()
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var editedIndexes: [Int] = []
        var segmentGoneCalls = 0
        viewModel.performSegmentEdit(of: deletedSegment, onSegmentGone: { segmentGoneCalls += 1 }) { segmentIndex, done in
            editedIndexes.append(segmentIndex)
            done()
        }

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { segmentGoneCalls == 1 }
        drainMainQueue()

        XCTAssertTrue(editedIndexes.isEmpty)
        XCTAssertTrue(repository.createEditCalls.isEmpty)
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertEqual(spy.messages.map { $0.text },
                       [TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong)])
        XCTAssertEqual(spy.messages.map { $0.type }, [.error])
    }

    func testSegmentTimeEditQueuedBehindADeleteTargetsTheSegmentAtItsNewIndex() {
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count >= 2 else {
            return XCTFail("expected at least two segments in the mock timeline")
        }
        let deletedSegment = segments[0]
        let editedSegment = segments[1]
        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeFirst()
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var results: [Result<Bool, Error>] = []
        viewModel.updateSegmentTime(segment: editedSegment, startTime: "11:00", endTime: "17:00") { results.append($0) }

        XCTAssertTrue(repository.createEditCalls.isEmpty, "the time edit waits for the running delete")

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { !results.isEmpty }

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(repository.createEditCalls.map { $0.segmentIndex }, [0])
        XCTAssertEqual(repository.createEditCalls.first?.startDate?.hasSuffix(" 11:00"), true)
        guard case .success(true)? = results.first else { return XCTFail("expected success, got \(results)") }
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertTrue(spy.messages.isEmpty)
    }

    func testSegmentTimeEditOfASegmentDeletedMeanwhileSendsNoPutAndShowsAnError() {
        guard let deletedSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment in the mock timeline")
        }
        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeFirst()
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var results: [Result<Bool, Error>] = []
        viewModel.updateSegmentTime(segment: deletedSegment, startTime: "11:00", endTime: "17:00") { results.append($0) }

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { !results.isEmpty }
        drainMainQueue()

        XCTAssertTrue(repository.createEditCalls.isEmpty)
        guard case .failure? = results.first else { return XCTFail("expected failure, got \(results)") }
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertEqual(spy.messages.map { $0.text },
                       [TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong)])
        XCTAssertEqual(spy.messages.map { $0.type }, [.error])
    }

    func testSegmentTimeEditHoldsTheGateUntilItsRefreshHasLanded() {
        guard let editedSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment in the mock timeline")
        }
        let server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersFetchCompletions = true

        var results: [Result<Bool, Error>] = []
        viewModel.updateSegmentTime(segment: editedSegment, startTime: "11:00", endTime: "17:00") { results.append($0) }
        waitUntil { self.repository.fetchCallCount == 1 }

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertTrue(viewModel.isSegmentMutationInFlight, "the PUT returned but its refresh has not landed yet")
        XCTAssertTrue(results.isEmpty)

        repository.pendingFetchCompletions[0](.success(server))
        waitUntil { !results.isEmpty }

        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        guard case .success(true)? = results.first else { return XCTFail("expected success, got \(results)") }
    }

    func testFailedSegmentTimeEditReleasesTheGateWithoutARefresh() {
        guard let editedSegment = viewModel.timeline?.tripProfile?.segments.first else {
            return XCTFail("expected a segment in the mock timeline")
        }
        repository.createEditResult = .success(false)

        var results: [Result<Bool, Error>] = []
        viewModel.updateSegmentTime(segment: editedSegment, startTime: "11:00", endTime: "17:00") { results.append($0) }
        waitUntil { !results.isEmpty }

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        guard case .failure? = results.first else { return XCTFail("expected failure, got \(results)") }
    }

    // MARK: - updateStepTime widening behind the segment mutation gate

    /// Step owned by `mondaySegment` (index 1, 2025-12-08 09:00-22:00), narrow enough that "20:00"-"23:00" widens it.
    private func narrowRangeStep() -> TRPTimelineStep {
        return viewModel.timeline!.plans!.first { $0.id == "25460" }!.steps.first { $0.id == 126405 }!
    }

    private func installStepRepository() -> RecordingStepRepository {
        let stepRepository = RecordingStepRepository(recorder: CallRecorder())
        viewModel.timelineModeUseCases = TRPTimelineModeUseCases(
            timelineRepository: repository,
            planRepository: MockTimelinePlanRepository(),
            stepRepository: stepRepository,
            timelineModelRepository: MockTimelineModelRepository(),
            poiRepository: MockPoiRepository()
        )
        return stepRepository
    }

    func testStepTimeWideningQueuedBehindADeleteTargetsTheSegmentAtItsNewIndex() {
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count >= 2 else {
            return XCTFail("expected at least two segments in the mock timeline")
        }
        let deletedSegment = segments[0]
        let step = narrowRangeStep()
        let stepRepository = installStepRepository()
        stepRepository.editResult = .success(step)

        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeFirst()
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var results: [Result<TRPTimelineStep, Error>] = []
        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { results.append($0) }

        XCTAssertTrue(repository.createEditCalls.isEmpty, "the widen PUT waits for the running delete")

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { !results.isEmpty }

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
        XCTAssertEqual(repository.createEditCalls.map { $0.segmentIndex }, [0], "mondaySegment moved to index 0 once mainSegment was deleted")
        XCTAssertEqual(repository.createEditCalls.first?.startDate, "2025-12-08 09:00")
        XCTAssertEqual(repository.createEditCalls.first?.endDate, "2025-12-08 23:00")
        XCTAssertEqual(stepRepository.editedSteps.map { $0.stepId }, [step.id])
        guard case .success? = results.first else { return XCTFail("expected success, got \(results)") }
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
    }

    func testStepTimeWideningForASegmentDeletedMeanwhileSendsNoPutAndShowsAnError() {
        let step = narrowRangeStep()
        guard let deletedSegment = viewModel.mergedItem(containing: step)?.segment else {
            return XCTFail("expected the step's owning segment")
        }
        let stepRepository = installStepRepository()

        let serverAfterDelete = GenerationFixtures.generatedMockTimeline()
        serverAfterDelete.tripProfile?.segments.removeAll { $0.title == deletedSegment.title }
        var server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersDeleteCompletions = true

        viewModel.removeSegment(deletedSegment)
        var results: [Result<TRPTimelineStep, Error>] = []
        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { results.append($0) }

        server = serverAfterDelete
        repository.completeNextDelete()
        waitUntil { !results.isEmpty }
        drainMainQueue()

        XCTAssertTrue(repository.createEditCalls.isEmpty)
        XCTAssertTrue(stepRepository.editedSteps.isEmpty)
        guard case .failure? = results.first else { return XCTFail("expected failure, got \(results)") }
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        XCTAssertEqual(spy.messages.map { $0.text },
                       [TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong)])
        XCTAssertEqual(spy.messages.map { $0.type }, [.error])
    }

    func testStepTimeWideningSuccessHoldsTheGateUntilTheStepEditRefreshLands() {
        let step = narrowRangeStep()
        let stepRepository = installStepRepository()
        stepRepository.editResult = .success(step)
        let server = GenerationFixtures.generatedMockTimeline()
        repository.fetchResponder = { _ in .success(server) }
        repository.defersFetchCompletions = true

        var results: [Result<TRPTimelineStep, Error>] = []
        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { results.append($0) }
        waitUntil { self.repository.fetchCallCount == 1 }

        XCTAssertEqual(repository.createEditCalls.count, 1, "the widening PUT must have gone out before the step edit")
        XCTAssertEqual(stepRepository.editedSteps.map { $0.stepId }, [step.id])
        XCTAssertTrue(viewModel.isSegmentMutationInFlight, "the step edit returned but its refresh has not landed yet")
        XCTAssertTrue(results.isEmpty)

        repository.pendingFetchCompletions[0](.success(server))
        waitUntil { !results.isEmpty }

        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        guard case .success? = results.first else { return XCTFail("expected success, got \(results)") }
    }

    func testFailedStepTimeWideningReleasesTheGateWithoutARefresh() {
        let step = narrowRangeStep()
        let stepRepository = installStepRepository()
        repository.createEditResult = .success(false)

        var results: [Result<TRPTimelineStep, Error>] = []
        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { results.append($0) }
        waitUntil { !results.isEmpty }

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0, "a failed widen must not reach the step edit or trigger a refresh")
        XCTAssertTrue(stepRepository.editedSteps.isEmpty)
        XCTAssertFalse(viewModel.isSegmentMutationInFlight)
        guard case .failure? = results.first else { return XCTFail("expected failure, got \(results)") }
    }

    // MARK: - performRefreshingSegmentEdit queues a delete behind its own refresh

    func testDeleteQueuedBehindARefreshingSegmentEditRunsOnlyAfterTheRefreshAndUsesTheRefreshedIndex() {
        guard let segments = viewModel.timeline?.tripProfile?.segments, segments.count >= 2 else {
            return XCTFail("expected at least two segments in the mock timeline")
        }
        let editedSegment = segments[0]
        let deletedSegment = segments[1]

        let serverAfterRefresh = GenerationFixtures.generatedMockTimeline()
        serverAfterRefresh.tripProfile?.segments.removeFirst()
        repository.fetchResponder = { _ in .success(serverAfterRefresh) }
        repository.defersFetchCompletions = true

        var onRefreshedCalls = 0
        viewModel.performRefreshingSegmentEdit(of: editedSegment, onSegmentGone: {
            XCTFail("editedSegment is present")
        }, send: { [unowned self] segmentIndex, finished in
            let profile = TRPCreateEditTimelineSegmentProfile(from: editedSegment, tripHash: "generation-hash", segmentIndex: segmentIndex)
            self.repository.createEditTimelineSegment(profile: profile) { result in
                switch result {
                case .success(true): finished(true)
                default: finished(false)
                }
            }
        }, onRefreshed: { onRefreshedCalls += 1 })

        XCTAssertEqual(repository.createEditCalls.count, 1)
        waitUntil { self.repository.fetchCallCount == 1 }
        XCTAssertTrue(viewModel.isSegmentMutationInFlight, "the edit's refresh has not landed yet")

        viewModel.removeSegment(deletedSegment)
        XCTAssertEqual(viewModel.queuedSegmentMutations.count, 1, "the delete must wait for the edit's refresh")
        XCTAssertTrue(repository.deletedSegmentIndexes.isEmpty)

        repository.pendingFetchCompletions[0](.success(serverAfterRefresh))
        waitUntil { self.repository.fetchCallCount == 2 }

        XCTAssertEqual(onRefreshedCalls, 1)
        XCTAssertEqual(repository.deletedSegmentIndexes, [0], "deletedSegment moved to index 0 once the refresh landed")

        repository.pendingFetchCompletions[1](.success(serverAfterRefresh))
        waitUntil { !self.viewModel.isSegmentMutationInFlight }

        XCTAssertEqual(repository.deletedSegmentIndexes, [0])
    }
}
