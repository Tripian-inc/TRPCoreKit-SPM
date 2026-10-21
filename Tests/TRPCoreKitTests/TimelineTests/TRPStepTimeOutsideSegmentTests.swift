import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// `updateStepTime` must widen the step's owning segment first when the new step times fall
/// outside it, and only report errors to the delegate once the bottom-sheet loader has hidden.
final class TRPStepTimeOutsideSegmentTests: XCTestCase {

    // MARK: - Fixtures

    private func makeViewModel() -> (TRPTimelineItineraryViewModel, RecordingTimelineRepository, RecordingStepRepository, StepTimeDelegateSpy) {
        let viewModel = TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline())
        let recorder = CallRecorder()
        let repository = RecordingTimelineRepository(recorder: recorder)
        repository.fetchTimelineResult = .success(viewModel.timeline!)
        let stepRepository = RecordingStepRepository(recorder: recorder)

        viewModel.timelineRepository = repository
        viewModel.timelineModeUseCases = TRPTimelineModeUseCases(
            timelineRepository: repository,
            planRepository: MockTimelinePlanRepository(),
            stepRepository: stepRepository,
            timelineModelRepository: MockTimelineModelRepository(),
            poiRepository: MockPoiRepository()
        )

        let spy = StepTimeDelegateSpy()
        viewModel.delegate = spy

        return (viewModel, repository, stepRepository, spy)
    }

    /// Step whose owning segment (`mondaySegment`, 2025-12-08 09:00-22:00) is narrow enough to be widened.
    private func narrowRangeStep(in viewModel: TRPTimelineItineraryViewModel) -> TRPTimelineStep {
        return viewModel.timeline!.plans!.first { $0.id == "25460" }!.steps.first { $0.id == 126405 }!
    }

    /// Step whose owning segment (`mainSegment`, 2025-12-07 09:00 to 2026-01-01 22:00) comfortably fits any same-day time.
    private func wideRangeStep(in viewModel: TRPTimelineItineraryViewModel) -> TRPTimelineStep {
        return viewModel.timeline!.plans!.first { $0.id == "25459" }!.steps.first { $0.id == 126396 }!
    }

    private func waitShort(for expectations: [XCTestExpectation]) {
        wait(for: expectations, timeout: 2)
    }

    // MARK: - Inside the segment range

    func testStepTimeInsideSegmentRangeEditsTheStepDirectlyWithoutWideningTheSegment() {
        let (viewModel, repository, stepRepository, _) = makeViewModel()
        let step = wideRangeStep(in: viewModel)
        stepRepository.editResult = .success(step)
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "16:00", endTime: "18:00") { result in
            guard case .success = result else { return XCTFail("expected success") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertTrue(repository.createEditCalls.isEmpty)
        XCTAssertEqual(stepRepository.editedSteps.map { $0.stepId }, [step.id])
        XCTAssertEqual(repository.fetchTimelineCallCount, 1)
    }

    func testStepTimeInsideSegmentEditFailureReportsTheErrorOnlyAfterTheLoaderHides() {
        let (viewModel, repository, stepRepository, spy) = makeViewModel()
        let step = wideRangeStep(in: viewModel)
        stepRepository.editResult = .failure(GeneralError.customMessage("edit failed"))
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "16:00", endTime: "18:00") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertTrue(spy.errors.isEmpty, "error must not be reported before the loader finishes hiding")
        XCTAssertEqual(repository.fetchTimelineCallCount, 0, "no widening happened, so no refresh is needed")

        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }

    // MARK: - Outside the segment range

    func testStepTimeOutsideSegmentRangeWidensTheSegmentBeforeEditingTheStep() {
        let (viewModel, repository, stepRepository, _) = makeViewModel()
        let step = narrowRangeStep(in: viewModel)
        let originalSegment = viewModel.mergedItem(containing: step)!.segment
        let originalSegmentType = originalSegment.segmentType
        let originalDoNotGenerate = originalSegment.doNotGenerate
        let originalSmartRecommendation = originalSegment.smartRecommendation
        stepRepository.editResult = .success(step)
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { result in
            guard case .success = result else { return XCTFail("expected success") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(repository.createEditCalls.first?.startDate, "2025-12-08 09:00")
        XCTAssertEqual(repository.createEditCalls.first?.endDate, "2025-12-08 23:00")
        XCTAssertEqual(repository.createEditCalls.first?.segmentType, originalSegmentType)
        XCTAssertEqual(repository.createEditCalls.first?.doNotGenerate, originalDoNotGenerate)
        XCTAssertEqual(repository.createEditCalls.first?.smartRecommendation, originalSmartRecommendation)
        XCTAssertEqual(stepRepository.editedSteps.map { $0.stepId }, [step.id])
        XCTAssertEqual(repository.callOrder, ["createEditTimelineSegment", "editStep", "fetchTimeline"])
    }

    func testSegmentWideningFailureSkipsTheStepEditAndReportsTheErrorAfterTheLoaderHides() {
        let (viewModel, repository, stepRepository, spy) = makeViewModel()
        let step = narrowRangeStep(in: viewModel)
        repository.createEditResult = .failure(GeneralError.customMessage("segment update failed"))
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertTrue(stepRepository.editedSteps.isEmpty, "the step must not be edited when widening fails")
        XCTAssertTrue(spy.errors.isEmpty, "error must not be reported before the loader finishes hiding")

        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }

    func testSegmentWideningReportingUpdatedFalseSkipsTheStepEditAndReportsAnError() {
        let (viewModel, repository, stepRepository, spy) = makeViewModel()
        let step = narrowRangeStep(in: viewModel)
        repository.createEditResult = .success(false)
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertTrue(stepRepository.editedSteps.isEmpty)
        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }

    func testStepEditFailureAfterWideningRefreshesTheTimelineAndReportsTheError() {
        let (viewModel, repository, stepRepository, spy) = makeViewModel()
        let step = narrowRangeStep(in: viewModel)
        stepRepository.editResult = .failure(GeneralError.customMessage("step edit failed"))
        let done = expectation(description: "updateStepTime")

        viewModel.updateStepTime(step: step, startTime: "20:00", endTime: "23:00") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertEqual(repository.createEditCalls.count, 1, "the segment should still have been widened")
        XCTAssertEqual(repository.fetchTimelineCallCount, 1, "a failed step edit after widening must still refresh the timeline")
        XCTAssertTrue(spy.errors.isEmpty, "error must not be reported before the loader finishes hiding")

        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }

    // MARK: - removeStep

    func testRemoveStepFailureReportsTheErrorOnlyAfterTheLoaderHides() {
        let (viewModel, _, stepRepository, spy) = makeViewModel()
        let step = wideRangeStep(in: viewModel)
        stepRepository.deleteResult = .failure(GeneralError.customMessage("delete failed"))
        let done = expectation(description: "removeStep")

        viewModel.removeStep(step) { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertEqual(stepRepository.deletedStepIds, [step.id])
        XCTAssertTrue(spy.errors.isEmpty, "error must not be reported before the loader finishes hiding")

        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }

    // MARK: - updateSegmentTime

    func testUpdateSegmentTimeFailureReportsTheErrorOnlyAfterTheLoaderHides() {
        let (viewModel, repository, _, spy) = makeViewModel()
        let segment = viewModel.timeline!.tripProfile!.segments.first { $0.title == "Gothic Quarter Deep Dive" }!
        repository.createEditResult = .failure(GeneralError.customMessage("segment update failed"))
        let done = expectation(description: "updateSegmentTime")

        viewModel.updateSegmentTime(segment: segment, startTime: "09:00", endTime: "22:00") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        waitShort(for: [done])
        XCTAssertTrue(spy.errors.isEmpty, "error must not be reported before the loader finishes hiding")

        spy.capturedHideLottieCompletion?()
        XCTAssertEqual(spy.errors.count, 1)
    }
}

// MARK: - Mocks

/// Records the sequence of timeline-repository calls so tests can assert ordering (e.g. segment edit before step edit).
final class CallRecorder {
    var order: [String] = []
}

final class RecordingTimelineRepository: TimelineRepository {
    private let recorder: CallRecorder

    var createEditResult: TimelineResultStatus = .success(true)
    var fetchTimelineResult: TimelineResultValue?
    var createEditCalls: [TRPCreateEditTimelineSegmentProfile] = []
    var fetchTimelineCallCount = 0
    var callOrder: [String] { recorder.order }

    init(recorder: CallRecorder) {
        self.recorder = recorder
    }

    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        fetchTimelineCallCount += 1
        recorder.order.append("fetchTimeline")
        completion(fetchTimelineResult ?? .failure(GeneralError.customMessage("no timeline")))
    }

    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("unsupported")))
    }

    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) {
        createEditCalls.append(profile)
        recorder.order.append("createEditTimelineSegment")
        completion(createEditResult)
    }

    func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) { completion(.success(true)) }
    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) { completion(.success(true)) }
    func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) { completion(.failure(GeneralError.customMessage("unsupported"))) }
    func saveTimeline(tripHash: String, data: TRPTimeline) {}
}

final class RecordingStepRepository: TimelineStepRepository {
    private let recorder: CallRecorder

    var editResult: TimelineStepResultValue = .failure(GeneralError.customMessage("no step"))
    var editedSteps: [TRPTimelineStepEdit] = []
    var deleteResult: TimelineStepStatusValue = .success(true)
    var deletedStepIds: [Int] = []

    init(recorder: CallRecorder) {
        self.recorder = recorder
    }

    func addStep(step: TRPTimelineStepCreate, completion: @escaping (TimelineStepResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("unsupported")))
    }

    func deleteStep(id: Int, completion: @escaping (TimelineStepStatusValue) -> Void) {
        deletedStepIds.append(id)
        completion(deleteResult)
    }

    func editStep(step: TRPTimelineStepEdit, completion: @escaping (TimelineStepResultValue) -> Void) {
        editedSteps.append(step)
        recorder.order.append("editStep")
        completion(editResult)
    }
}

/// Captures the `hideLottie` completion instead of invoking it, so tests can assert that
/// `viewModel(error:)` is not reported until the caller invokes it.
final class StepTimeDelegateSpy: TRPTimelineItineraryViewModelDelegate {
    var errors: [Error] = []
    var capturedHideLottieCompletion: (() -> Void)?

    func timelineItineraryViewModel(didUpdateTimeline: Bool) {}
    func timelineItineraryViewModel(noCitiesAvailable: Bool) {}
    func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}

    func viewModel(error: Error) { errors.append(error) }

    func viewModel(showLottie presentation: LottieLoaderPresentation, textMode: LottieLoadingTextMode, completion: (() -> Void)?) {
        completion?()
    }

    func viewModel(hideLottie presentation: LottieLoaderPresentation, completion: (() -> Void)?) {
        capturedHideLottieCompletion = completion
    }
}
