import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

final class TRPTimelineModeUseCasesTests: XCTestCase {

    private var timelineRepository: MockTimelineRepository!
    private var planRepository: MockTimelinePlanRepository!
    private var stepRepository: MockTimelineStepRepository!
    private var modelRepository: MockTimelineModelRepository!
    private var poiRepository: MockPoiRepository!
    private var useCases: TRPTimelineModeUseCases!

    override func setUp() {
        super.setUp()
        timelineRepository = MockTimelineRepository()
        planRepository = MockTimelinePlanRepository()
        stepRepository = MockTimelineStepRepository()
        modelRepository = MockTimelineModelRepository()
        poiRepository = MockPoiRepository()
        useCases = TRPTimelineModeUseCases(
            timelineRepository: timelineRepository,
            planRepository: planRepository,
            stepRepository: stepRepository,
            timelineModelRepository: modelRepository,
            poiRepository: poiRepository
        )
    }

    private func generatedTimeline() -> TRPTimeline {
        var timeline = TRPTimelineMockData.getMockTimeline()
        timeline.plans = timeline.plans?.map { plan in
            var plan = plan
            plan.generatedStatus = 1
            return plan
        }
        return timeline
    }

    func testFetchTimelineStoresTripAndItsPois() {
        let expected = generatedTimeline()
        timelineRepository.timeline = expected
        let done = expectation(description: "fetch")

        useCases.executeFetchTimeline(tripHash: expected.tripHash) { result in
            guard case .success(let trip) = result else { return XCTFail("expected success") }
            XCTAssertEqual(trip.tripHash, expected.tripHash)
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(useCases.timeline.value?.tripHash, expected.tripHash)
        XCTAssertEqual(timelineRepository.savedTripHash, expected.tripHash)
        XCTAssertEqual(Set(poiRepository.pois.map { $0.id }), Set(expected.getPois().map { $0.id }))
    }

    func testFetchTimelineFailurePropagates() {
        timelineRepository.error = GeneralError.customMessage("boom")
        let done = expectation(description: "fetch")

        useCases.executeFetchTimeline(tripHash: "missing") { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertNil(useCases.timeline.value)
    }

    func testFetchPlanReplacesPlanInsideTrip() {
        let timeline = generatedTimeline()
        modelRepository.timeline.value = timeline
        var renamed = timeline.plans!.first!
        renamed.name = "Renamed"
        planRepository.plan = renamed
        let done = expectation(description: "plan")

        useCases.executeFetchPlan(id: renamed.id) { result in
            guard case .success(let plan) = result else { return XCTFail("expected success") }
            XCTAssertEqual(plan.name, "Renamed")
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(planRepository.fetchedPlanIds, [renamed.id])
        XCTAssertEqual(useCases.timeline.value?.plans?.first?.name, "Renamed")
    }

    func testChangeDailyPlanPublishesAnAlreadyGeneratedPlan() {
        let timeline = generatedTimeline()
        modelRepository.timeline.value = timeline
        let target = timeline.plans![1]
        let done = expectation(description: "change")

        useCases.executeChangeDailyPlan(id: target.id) { result in
            guard case .success(let plan) = result else { return XCTFail("expected success") }
            XCTAssertEqual(plan.id, target.id)
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(useCases.currentPlan.value?.id, target.id)
    }

    func testDeleteStepRemovesItFromCurrentPlanAndRefetches() {
        let timeline = generatedTimeline()
        modelRepository.timeline.value = timeline
        let plan = timeline.plans!.first!
        modelRepository.dailySegment.value = plan
        planRepository.plan = plan
        let removedStep = plan.steps.first!
        let done = expectation(description: "delete")

        useCases.executeDeleteStep(id: removedStep.id) { result in
            guard case .success(let ok) = result, ok else { return XCTFail("expected success") }
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(stepRepository.deletedStepIds, [removedStep.id])
        XCTAssertEqual(planRepository.fetchedPlanIds, [plan.id])
    }

    func testEditStepSendsThePoiAndRefetchesDailyPlan() {
        let timeline = generatedTimeline()
        modelRepository.timeline.value = timeline
        let plan = timeline.plans!.first!
        modelRepository.dailySegment.value = plan
        planRepository.plan = plan
        stepRepository.step = plan.steps.first!
        let done = expectation(description: "edit")

        useCases.executeEditStep(id: 42, poiId: "540484") { result in
            guard case .success = result else { return XCTFail("expected success") }
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(stepRepository.editedSteps.map { $0.stepId }, [42])
        XCTAssertEqual(stepRepository.editedSteps.first?.poiId, "540484")
        XCTAssertEqual(planRepository.fetchedPlanIds, [plan.id])
    }
}

// MARK: - Mocks

final class MockTimelineRepository: TimelineRepository {
    var timeline: TRPTimeline?
    var error: Error?
    var savedTripHash: String?

    private func respond(_ completion: (TimelineResultValue) -> Void) {
        if let error = error { return completion(.failure(error)) }
        guard let timeline = timeline else { return completion(.failure(GeneralError.customMessage("no timeline"))) }
        completion(.success(timeline))
    }

    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) { respond(completion) }
    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) { respond(completion) }
    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) { completion(.success(true)) }
    func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) { completion(.success(true)) }
    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) { completion(.success(true)) }
    func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) { respond(completion) }
    func saveTimeline(tripHash: String, data: TRPTimeline) { savedTripHash = tripHash }
}

final class MockTimelinePlanRepository: TimelinePlanRepository {
    var plan: TRPTimelinePlan?
    var fetchedPlanIds: [String] = []

    private func respond(_ completion: (TimelinePlanResultValue) -> Void) {
        guard let plan = plan else { return completion(.failure(GeneralError.customMessage("no plan"))) }
        completion(.success(plan))
    }

    func fetchPlan(id: String, completion: @escaping (TimelinePlanResultValue) -> Void) {
        fetchedPlanIds.append(id)
        respond(completion)
    }
    func editPlanHours(planId: Int, start: String, end: String, completion: @escaping (TimelinePlanResultValue) -> Void) { respond(completion) }
    func editPlanStepOrder(planId: Int, stepOrders: [Int], completion: @escaping (TimelinePlanResultValue) -> Void) { respond(completion) }
    func exportItinerary(planId: Int, tripHash: String, completion: @escaping (TimelinePlanExportResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("not supported")))
    }
}

final class MockTimelineStepRepository: TimelineStepRepository {
    var step: TRPTimelineStep?
    var deletedStepIds: [Int] = []
    var editedSteps: [TRPTimelineStepEdit] = []

    func addStep(step: TRPTimelineStepCreate, completion: @escaping (TimelineStepResultValue) -> Void) {
        guard let step = self.step else { return completion(.failure(GeneralError.customMessage("no step"))) }
        completion(.success(step))
    }
    func deleteStep(id: Int, completion: @escaping (TimelineStepStatusValue) -> Void) {
        deletedStepIds.append(id)
        completion(.success(true))
    }
    func editStep(step: TRPTimelineStepEdit, completion: @escaping (TimelineStepResultValue) -> Void) {
        editedSteps.append(step)
        guard let stored = self.step else { return completion(.failure(GeneralError.customMessage("no step"))) }
        completion(.success(stored))
    }
}

final class MockTimelineModelRepository: TimelineModelRepository {
    var timeline: ValueObserver<TRPTimeline> = .init(nil)
    var dailySegment: ValueObserver<TRPTimelinePlan> = .init(nil)
    var allSegmentGenerated: ValueObserver<Bool> = .init(nil)
    var generationError: ValueObserver<Error?> = .init(nil)
}

final class MockPoiRepository: PoiRepository {
    var pois: [TRPPoi] = []
    var poisWithParameters: [PoiParameters: [TRPPoi]] = [:]
    var poiCategories: [TRPPoiCategoyGroup] = []

    func fetchPoi(poiId: String, completion: @escaping (PoiResultValue) -> Void) {
        guard let poi = pois.first(where: { $0.id == poiId }) else { return completion(.failure(GeneralError.customMessage("no poi"))) }
        completion(.success(poi))
    }
    func fetchPoi(cityId: Int, parameters: PoiParameters, completion: @escaping (PoiResultsValue) -> Void) { completion((.success(pois), nil)) }
    func fetchPoi(coordinate: TRPLocation, parameters: PoiParameters, completion: @escaping (PoiResultsValue) -> Void) { completion((.success(pois), nil)) }
    func fetchPoi(url: String, completion: @escaping (PoiResultsValue) -> Void) { completion((.success(pois), nil)) }
    func addPois(contentsOf newPois: [TRPPoi]) {
        for poi in newPois where !pois.contains(where: { $0.id == poi.id }) { pois.append(poi) }
    }
    func fetchLocalPoi(completion: @escaping (PoiResultsValue) -> Void) { completion((.success(pois), nil)) }
    func fetchPoiCategories(completion: @escaping (PoiCategoriesResultValue) -> Void) { completion(.success(poiCategories)) }
}
