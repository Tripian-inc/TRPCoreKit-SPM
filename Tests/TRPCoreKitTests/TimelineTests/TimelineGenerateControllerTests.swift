import XCTest
import TRPFoundationKit
import TRPRestKit
@testable import TRPCoreKit

/// Polling contract of `TimelineGenerateController`: one completion per run, strictly sequential fetches, an attempt
/// limit and a total failure budget per run that successful responses do not reset.
final class TimelineGenerateControllerTests: XCTestCase {

    private var repository: ScriptedTimelineRepository!
    private var scheduler: ManualScheduler!
    private var controller: TimelineGenerateController!
    private var results: [Result<TRPTimeline, Error>] = []

    override func setUp() {
        super.setUp()
        repository = ScriptedTimelineRepository()
        scheduler = ManualScheduler()
        controller = TimelineGenerateController(schedule: scheduler.schedule)
        controller.repository = repository
        results = []
    }

    private func script(_ responses: [TimelineResultValue]) {
        repository.fetchResponder = { index in responses[min(index, responses.count - 1)] }
    }

    private func start() {
        controller.fetchTimeline(hash: "generation-hash") { [unowned self] result in
            self.results.append(result)
        }
    }

    private var networkError: Error { TRPErrors.httpResult(code: 500, des: "", info: [:]) }

    func testPendingPlansKeepPollingAndCompleteOnceWhenGenerated() {
        script([
            .success(GenerationFixtures.timeline(planStatuses: [1, 0])),
            .success(GenerationFixtures.timeline(planStatuses: [1, 0])),
            .success(GenerationFixtures.timeline(planStatuses: [1, 1]))
        ])

        start()
        XCTAssertTrue(results.isEmpty, "no completion while a plan is still pending")
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 3)
        XCTAssertEqual(results.count, 1)
        guard case .success(let timeline)? = results.first else { return XCTFail("expected success") }
        XCTAssertEqual(timeline.plans?.map(\.generatedStatus), [1, 1])
    }

    func testThreeFailuresAbortWithASingleFailure() {
        script([.failure(networkError)])

        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 3)
        XCTAssertEqual(results.count, 1)
        guard case .failure(let error)? = results.first else { return XCTFail("expected failure") }
        guard case TRPErrors.httpResult(let code, _, _)? = error as? TRPErrors else { return XCTFail("expected the original TRPErrors, got \(error)") }
        XCTAssertEqual(code, 500)
        XCTAssertFalse(scheduler.hasPendingWork)
    }

    func testSuccessfulResponseDoesNotResetTheFailureCount() {
        script([
            .failure(networkError),
            .success(GenerationFixtures.timeline(planStatuses: [0])),
            .failure(networkError),
            .failure(networkError),
            .success(GenerationFixtures.timeline(planStatuses: [1]))
        ])

        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 4)
        XCTAssertEqual(scheduler.scheduledCount, 3, "nothing may be scheduled after the third failure")
        XCTAssertFalse(scheduler.hasPendingWork)
        XCTAssertEqual(results.count, 1)
        guard case .failure(let error)? = results.first else { return XCTFail("expected failure, got \(String(describing: results.first))") }
        XCTAssertNotNil(error as? TRPErrors)
    }

    func testThirtyPendingAttemptsTimeOutWithoutSchedulingAgain() {
        script([.success(GenerationFixtures.timeline(planStatuses: [0]))])

        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 30)
        XCTAssertEqual(scheduler.scheduledCount, 29, "nothing may be scheduled after the last attempt")
        XCTAssertFalse(scheduler.hasPendingWork)
        XCTAssertEqual(results.count, 1)
        guard case .failure(let error)? = results.first else { return XCTFail("expected failure") }
        guard case TimelineGenerateError.timeout = error else { return XCTFail("expected timeout, got \(error)") }
        XCTAssertEqual(error.localizedDescription, TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorTimeout))
    }

    func testFailureWithinTheBudgetOnTheLastAttemptTimesOut() {
        let pending = GenerationFixtures.timeline(planStatuses: [0])
        let failure = networkError
        repository.fetchResponder = { index in index == 29 ? .failure(failure) : .success(pending) }

        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 30)
        XCTAssertEqual(scheduler.scheduledCount, 29, "nothing may be scheduled after the last attempt")
        XCTAssertFalse(scheduler.hasPendingWork)
        XCTAssertEqual(results.count, 1)
        guard case .failure(let error)? = results.first else { return XCTFail("expected failure") }
        guard case TimelineGenerateError.timeout = error else { return XCTFail("expected timeout, got \(error)") }
    }

    func testExhaustedFailureBudgetPassesTheRefreshTokenErrorThrough() {
        script([.failure(TRPErrors.refreshTokenError)])

        start()
        scheduler.runUntilIdle()

        guard case .failure(let error)? = results.first else { return XCTFail("expected failure") }
        guard let trpError = error as? TRPErrors, case .refreshTokenError = trpError else {
            return XCTFail("expected refreshTokenError, got \(error)")
        }
    }

    func testNextFetchStartsOnlyAfterThePreviousResponseArrives() {
        repository.defersFetchCompletions = true

        start()
        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertEqual(scheduler.scheduledCount, 0, "no wait may be scheduled before the response arrives")
        XCTAssertFalse(scheduler.hasPendingWork)

        repository.pendingFetchCompletions[0](.success(GenerationFixtures.timeline(planStatuses: [0])))
        XCTAssertEqual(scheduler.scheduledCount, 1)
        XCTAssertEqual(repository.fetchCallCount, 1)

        scheduler.runNext()
        XCTAssertEqual(repository.fetchCallCount, 2)
        XCTAssertEqual(scheduler.scheduledCount, 1, "no wait may be scheduled before the second response arrives")
        XCTAssertFalse(scheduler.hasPendingWork)

        repository.pendingFetchCompletions[1](.success(GenerationFixtures.timeline(planStatuses: [1])))
        XCTAssertEqual(results.count, 1)
        guard case .success? = results.first else { return XCTFail("expected success") }
    }

    func testNegativeGeneratedStatusEndsPollingWithSuccess() {
        script([.success(GenerationFixtures.timeline(planStatuses: [-1]))])

        start()

        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertEqual(scheduler.scheduledCount, 0)
        XCTAssertEqual(results.count, 1)
        guard case .success? = results.first else { return XCTFail("expected success") }
    }

    func testCancelSuppressesALateCompletionAndFurtherPolling() {
        script([.success(GenerationFixtures.timeline(planStatuses: [0]))])
        start()
        XCTAssertEqual(scheduler.scheduledCount, 1)

        controller.cancel()
        scheduler.runUntilIdle()
        XCTAssertEqual(repository.fetchCallCount, 1, "a cancelled run must not fetch again")

        repository.defersFetchCompletions = true
        start()
        controller.cancel()
        repository.pendingFetchCompletions.forEach { $0(.success(GenerationFixtures.timeline(planStatuses: [1]))) }

        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(scheduler.hasPendingWork)
    }

    func testStartingANewRunSilencesThePreviousRunsCompletion() {
        repository.defersFetchCompletions = true
        start()
        XCTAssertEqual(repository.fetchCallCount, 1)
        let firstPendingCompletions = repository.pendingFetchCompletions

        repository.defersFetchCompletions = false
        script([.success(GenerationFixtures.timeline(planStatuses: [1]))])
        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(results.count, 1, "only the newest run's completion should fire")
        firstPendingCompletions.forEach { $0(.success(GenerationFixtures.timeline(planStatuses: [1]))) }
        XCTAssertEqual(results.count, 1, "a late completion from the superseded run must stay silent")
    }

    func testUseCasePublishesGeneratedTimelineAndPropagatesFailures() {
        let modelRepository = MockTimelineModelRepository()
        let useCase = TRPTimelineCheckAllPlanUseCases(timelineRepository: repository,
                                                      timelineModelRepository: modelRepository,
                                                      generateController: controller)
        script([
            .success(GenerationFixtures.timeline(planStatuses: [0])),
            .success(GenerationFixtures.timeline(planStatuses: [1]))
        ])
        var completions: [Result<TRPTimeline, Error>] = []

        useCase.executeFetchTimelineCheckAllPlanGenerate(tripHash: "generation-hash") { completions.append($0) }
        XCTAssertEqual(useCase.allSegmentGenerated.value, false)
        scheduler.runUntilIdle()

        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(useCase.allSegmentGenerated.value, true)
        XCTAssertEqual(modelRepository.timeline.value?.plans?.first?.generatedStatus, 1)

        script([.failure(networkError)])
        completions = []
        useCase.executeFetchTimelineCheckAllPlanGenerate(tripHash: "generation-hash") { completions.append($0) }
        scheduler.runUntilIdle()

        XCTAssertEqual(completions.count, 1)
        guard case .failure? = completions.first else { return XCTFail("expected failure") }
        XCTAssertEqual(useCase.allSegmentGenerated.value, false)
        XCTAssertNotNil(useCase.generationError.value ?? nil)
    }

    func testAttemptCallbackReportsEveryNonTerminalAttemptButNotTheTerminalOne() {
        script([
            .success(GenerationFixtures.timeline(planStatuses: [0])),
            .success(GenerationFixtures.timeline(planStatuses: [0])),
            .success(GenerationFixtures.timeline(planStatuses: [0])),
            .success(GenerationFixtures.timeline(planStatuses: [1]))
        ])
        var attempts: [Int] = []

        controller.fetchTimeline(hash: "generation-hash", onAttemptCompleted: { attempts.append($0) }) { [unowned self] result in
            self.results.append(result)
        }
        scheduler.runUntilIdle()

        XCTAssertEqual(attempts, [1, 2, 3])
        XCTAssertEqual(repository.fetchCallCount, 4)
        XCTAssertEqual(results.count, 1)
        guard case .success? = results.first else { return XCTFail("expected success") }
    }

    func testAttemptCallbackIsNotCalledForTheFailureThatExhaustsTheBudget() {
        script([.failure(networkError)])
        var attempts: [Int] = []

        controller.fetchTimeline(hash: "generation-hash", onAttemptCompleted: { attempts.append($0) }) { [unowned self] result in
            self.results.append(result)
        }
        scheduler.runUntilIdle()

        XCTAssertEqual(attempts, [1, 2])
        XCTAssertEqual(results.count, 1)
        guard case .failure? = results.first else { return XCTFail("expected failure") }
    }

    func testSixtyAttemptLimitIsHonouredAndReportsFiftyNineProgressCallbacks() {
        controller = TimelineGenerateController(maxAttempts: 60, schedule: scheduler.schedule)
        controller.repository = repository
        script([.success(GenerationFixtures.timeline(planStatuses: [0]))])
        var attempts: [Int] = []

        controller.fetchTimeline(hash: "generation-hash", onAttemptCompleted: { attempts.append($0) }) { [unowned self] result in
            self.results.append(result)
        }
        scheduler.runUntilIdle(maxSteps: 200)

        XCTAssertEqual(repository.fetchCallCount, 60)
        XCTAssertEqual(scheduler.scheduledCount, 59)
        XCTAssertFalse(scheduler.hasPendingWork)
        XCTAssertEqual(attempts, Array(1...59))
        XCTAssertEqual(results.count, 1)
        guard case .failure(let error)? = results.first else { return XCTFail("expected failure") }
        guard case TimelineGenerateError.timeout = error else { return XCTFail("expected timeout, got \(error)") }
    }

    func testDefaultAttemptLimitStaysThirty() {
        script([.success(GenerationFixtures.timeline(planStatuses: [0]))])

        start()
        scheduler.runUntilIdle(maxSteps: 200)

        XCTAssertEqual(repository.fetchCallCount, 30)
    }

    /// Mock timeline plus one pending itinerary plan per title, each linked to its segment through `dayIds`.
    private func timelineWithPendingSegments(_ titles: [String]) -> (TRPTimeline, [TRPTimelineSegment]) {
        var timeline = GenerationFixtures.generatedMockTimeline()
        var segments: [TRPTimelineSegment] = []
        for (offset, title) in titles.enumerated() {
            let planId = 9001 + offset
            let segment = GenerationFixtures.itinerarySegment(title: title,
                                                              startDate: "2025-12-09 10:00",
                                                              endDate: "2025-12-09 18:00",
                                                              planId: planId)
            timeline.tripProfile?.segments.append(segment)
            timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "\(planId)", generatedStatus: 0)]
            segments.append(segment)
        }
        return (timeline, segments)
    }

    func testTrackedSegmentsPendingPlanDoesNotKeepTheRunPendingWhileAnUntrackedOneDoes() {
        let registry = TRPBackgroundGenerationRegistry()
        let ignoring = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) }, schedule: scheduler.schedule)
        let (trackedOnly, trackedSegments) = timelineWithPendingSegments(["Tracked"])
        let (mixed, mixedSegments) = timelineWithPendingSegments(["Tracked", "Untracked"])

        XCTAssertTrue(ignoring.isGenerationPending(trackedOnly), "nothing is tracked yet")

        registry.register(TRPRecommendationSegmentKey(segment: trackedSegments[0]), tripHash: trackedOnly.tripHash)

        XCTAssertFalse(ignoring.isGenerationPending(trackedOnly))
        XCTAssertTrue(registry.isTracked(mixedSegments[0], tripHash: mixed.tripHash))
        XCTAssertFalse(registry.isTracked(mixedSegments[1], tripHash: mixed.tripHash))
        XCTAssertTrue(ignoring.isGenerationPending(mixed), "the untracked pending plan keeps the run pending")

        let ignoringNothing = TimelineGenerateController(ignoredPlanIds: TimelineGenerateController.ignoresNoPlan,
                                                         schedule: scheduler.schedule)
        XCTAssertTrue(ignoringNothing.isGenerationPending(trackedOnly))
    }

    func testRunCompletesOnTheFirstFetchWhenOnlyATrackedSegmentIsPending() {
        let registry = TRPBackgroundGenerationRegistry()
        let (trackedOnly, segments) = timelineWithPendingSegments(["Tracked"])
        registry.register(TRPRecommendationSegmentKey(segment: segments[0]), tripHash: trackedOnly.tripHash)
        controller = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) }, schedule: scheduler.schedule)
        controller.repository = repository
        script([.success(trackedOnly)])

        start()
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertEqual(results.count, 1)
        guard case .success? = results.first else { return XCTFail("expected success") }
        XCTAssertFalse(scheduler.hasPendingWork)
    }

    func testCheckAllPlanUseCaseReportsGeneratedWhenOnlyATrackedSegmentIsPending() {
        let registry = TRPBackgroundGenerationRegistry()
        let (trackedOnly, segments) = timelineWithPendingSegments(["Tracked"])
        registry.register(TRPRecommendationSegmentKey(segment: segments[0]), tripHash: trackedOnly.tripHash)
        controller = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) }, schedule: scheduler.schedule)
        let useCase = TRPTimelineCheckAllPlanUseCases(timelineRepository: repository,
                                                      timelineModelRepository: MockTimelineModelRepository(),
                                                      generateController: controller)
        script([.success(trackedOnly)])
        var generatedValues: [Bool] = []
        useCase.allSegmentGenerated.addObserver(self) { generatedValues.append($0) }

        useCase.executeFetchTimelineCheckAllPlanGenerate(tripHash: "generation-hash", completion: nil)
        scheduler.runUntilIdle()

        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertEqual(generatedValues.last, true)
    }

    func testMergedPlanOfATrackedSegmentIsIgnoredOnlyWhenAllOfItsDayIdsAreTracked() {
        let registry = TRPBackgroundGenerationRegistry()
        let ignoring = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) }, schedule: scheduler.schedule)
        var timeline = GenerationFixtures.generatedMockTimeline()
        let segment = GenerationFixtures.itinerarySegment(title: "Merged", startDate: "2025-12-09 10:00", endDate: "2025-12-09 18:00", planId: 2188)
        segment.dayIds = [2188, 2189]
        timeline.tripProfile?.segments.append(segment)
        timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "2188-2189", generatedStatus: 0)]

        XCTAssertTrue(ignoring.isGenerationPending(timeline), "nothing is tracked yet")

        registry.register(TRPRecommendationSegmentKey(segment: segment), tripHash: timeline.tripHash)
        XCTAssertFalse(ignoring.isGenerationPending(timeline))

        segment.dayIds = [2188]
        XCTAssertTrue(ignoring.isGenerationPending(timeline), "day 2189 of the merged plan is not tracked")
    }

    func testPlanWithoutNumericDayIdsAlwaysCountsAsPending() {
        let registry = TRPBackgroundGenerationRegistry()
        let ignoring = TimelineGenerateController(ignoredPlanIds: { registry.ignoredPlanIds(in: $0) }, schedule: scheduler.schedule)
        var timeline = GenerationFixtures.generatedMockTimeline()
        timeline.plans = (timeline.plans ?? []) + [GenerationFixtures.plan(id: "unparsable", generatedStatus: 0)]

        XCTAssertTrue(ignoring.isGenerationPending(timeline))
    }
}
