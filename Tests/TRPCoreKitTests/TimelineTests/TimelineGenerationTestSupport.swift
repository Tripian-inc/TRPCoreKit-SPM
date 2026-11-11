import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Ordered log of repository calls and delegate callbacks shared by a test's fakes.
final class GenerationEventLog {
    var events: [String] = []
}

/// Timeline repository whose fetch results are scripted per call; records PUT and DELETE requests.
final class ScriptedTimelineRepository: TimelineRepository {
    private let log: GenerationEventLog

    var fetchResponder: (_ callIndex: Int) -> TimelineResultValue = { _ in
        .failure(GeneralError.customMessage("no timeline scripted"))
    }
    var defersFetchCompletions = false
    var createEditResult: TimelineResultStatus = .success(true)
    var deleteResult: TimelineResultStatus = .success(true)

    private(set) var fetchCallCount = 0
    private(set) var pendingFetchCompletions: [(TimelineResultValue) -> Void] = []
    private(set) var createEditCalls: [TRPCreateEditTimelineSegmentProfile] = []
    private(set) var deletedSegmentIndexes: [Int] = []

    init(log: GenerationEventLog = GenerationEventLog()) {
        self.log = log
    }

    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        let callIndex = fetchCallCount
        fetchCallCount += 1
        log.events.append("fetch")
        if defersFetchCompletions {
            pendingFetchCompletions.append(completion)
            return
        }
        completion(fetchResponder(callIndex))
    }

    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("unsupported")))
    }

    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) {
        createEditCalls.append(profile)
        log.events.append("put")
        completion(createEditResult)
    }

    func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) {
        completion(.success(true))
    }

    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) {
        deletedSegmentIndexes.append(segmentIndex)
        log.events.append("delete:\(segmentIndex)")
        completion(deleteResult)
    }

    func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("unsupported")))
    }

    func saveTimeline(tripHash: String, data: TRPTimeline) {}
}

/// Collects delayed work instead of running it, so polling advances only when a test asks.
final class ManualScheduler {
    private(set) var scheduledCount = 0
    private var pending: [() -> Void] = []

    var schedule: TimelineGenerateController.Scheduler {
        return { [unowned self] _, work in
            self.scheduledCount += 1
            self.pending.append(work)
        }
    }

    var hasPendingWork: Bool { !pending.isEmpty }

    func runNext() {
        guard !pending.isEmpty else { return }
        pending.removeFirst()()
    }

    func runUntilIdle(maxSteps: Int = 50) {
        var steps = 0
        while hasPendingWork && steps < maxSteps {
            runNext()
            steps += 1
        }
    }
}

enum GenerationFixtures {
    static let barcelona = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))

    static func steps(count: Int) -> [TRPTimelineStep] {
        let source = TRPTimelineMockData.getMockTimeline().plans?.flatMap { $0.steps } ?? []
        return Array(source.prefix(count))
    }

    static func plan(id: String, generatedStatus: Int, stepCount: Int = 0, day: String = "2025-12-09") -> TRPTimelinePlan {
        return TRPTimelinePlan(
            id: id,
            startDate: "\(day) 10:00",
            endDate: "\(day) 18:00",
            steps: steps(count: stepCount),
            available: true,
            tripType: 3,
            name: nil,
            description: nil,
            generatedStatus: generatedStatus,
            children: 0,
            pets: 0,
            adults: 1,
            city: barcelona,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }

    static func timeline(planStatuses: [Int]) -> TRPTimeline {
        let plans = planStatuses.enumerated().map { index, status in
            plan(id: "\(1000 + index)", generatedStatus: status, stepCount: status > 0 ? 1 : 0)
        }
        return TRPTimeline(id: 1, tripHash: "generation-hash", tripProfile: nil, city: barcelona, plans: plans)
    }

    static func itinerarySegment(title: String, startDate: String, endDate: String, planId: Int) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .itinerary
        segment.title = title
        segment.startDate = startDate
        segment.endDate = endDate
        segment.cityId = barcelona.id
        segment.city = barcelona
        segment.dayIds = [planId]
        return segment
    }

    /// The shared mock timeline with every plan marked as generated and no favourites.
    static func generatedMockTimeline() -> TRPTimeline {
        var timeline = TRPTimelineMockData.getMockTimeline()
        timeline.plans = timeline.plans?.map { plan in
            var generated = plan
            generated.generatedStatus = 1
            return generated
        }
        timeline.favouriteItems = nil
        return timeline
    }
}
