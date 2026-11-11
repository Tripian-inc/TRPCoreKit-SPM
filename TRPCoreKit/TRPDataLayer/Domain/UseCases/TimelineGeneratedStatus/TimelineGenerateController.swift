//
//  TripGenerateController.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

/// Reasons a timeline generation poll ends without a generated timeline.
enum TimelineGenerateError: Error {
    case timeout
}

extension TimelineGenerateError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout:
            return TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorTimeout)
        }
    }
}

/// Polls `GET /timeline/{hash}` until no plan has `generatedStatus == 0`, leaving out the plans `ignoredPlanIds` returns
/// for the fetched timeline (by default those of recommendations generating in the background, see `TRPBackgroundGenerationRegistry`).
///
/// Each fetch is one attempt; the next one is scheduled `pollInterval` after the previous response arrives.
/// A run ends with the last fetch error itself once `maxFailures` fetches have failed in total (checked first), or with
/// `.timeout` when attempt `maxAttempts` completes while a plan is still pending. Its completion fires exactly once;
/// starting a new run or calling `cancel()` silences the previous one. `onAttemptCompleted` receives the number of
/// every attempt that did not end the run, on the thread that delivered the response.
class TimelineGenerateController {

    typealias Scheduler = (_ delay: DispatchTimeInterval, _ work: @escaping () -> Void) -> Void
    /// Day ids of the plans in a fetched timeline that never count as pending.
    typealias IgnoredPlanIds = (_ timeline: TRPTimeline) -> Set<Int>

    static let ignoresBackgroundGeneration: IgnoredPlanIds = { timeline in
        TRPBackgroundGenerationRegistry.shared.ignoredPlanIds(in: timeline)
    }

    static let ignoresNoPlan: IgnoredPlanIds = { _ in [] }

    static let defaultMaxAttempts = 30

    static let globalQueueScheduler: Scheduler = { delay, work in
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }

    private enum NextStep {
        case pollAgain(attempt: Int)
        case finish(Result<TRPTimeline, Error>)
        case ignore
    }

    public var repository: TimelineRepository?

    private let pollInterval: DispatchTimeInterval
    private let maxAttempts: Int
    private let maxFailures: Int
    private let schedule: Scheduler
    private let ignoredPlanIds: IgnoredPlanIds

    private let stateLock = NSLock()
    private var activeRunToken = 0
    private var attemptCount = 0
    private var failureCount = 0

    init(pollInterval: DispatchTimeInterval = .seconds(2),
         maxAttempts: Int = TimelineGenerateController.defaultMaxAttempts,
         maxFailures: Int = 3,
         ignoredPlanIds: @escaping IgnoredPlanIds = TimelineGenerateController.ignoresBackgroundGeneration,
         schedule: @escaping Scheduler = TimelineGenerateController.globalQueueScheduler) {
        self.pollInterval = pollInterval
        self.maxAttempts = max(1, maxAttempts)
        self.maxFailures = max(1, maxFailures)
        self.ignoredPlanIds = ignoredPlanIds
        self.schedule = schedule
    }

    public func fetchTimeline(hash: String,
                              onAttemptCompleted: ((Int) -> Void)? = nil,
                              completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        let token = startRun()
        poll(hash: hash, token: token, onAttemptCompleted: onAttemptCompleted, completion: completion)
    }

    /// Stops the active run; its completion will not be called.
    func cancel() {
        stateLock.lock()
        activeRunToken += 1
        stateLock.unlock()
    }

    /// True when a plan still has `generatedStatus == 0` and not every day id it is made of is ignored.
    func isGenerationPending(_ timeline: TRPTimeline) -> Bool {
        let ignored = ignoredPlanIds(timeline)
        return timeline.plans?.contains(where: { plan in
            guard plan.generatedStatus == 0 else { return false }
            let dayIds = plan.dayIdComponents
            return dayIds.isEmpty || !dayIds.allSatisfy(ignored.contains)
        }) ?? false
    }

    private func startRun() -> Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        activeRunToken += 1
        attemptCount = 0
        failureCount = 0
        return activeRunToken
    }

    private func isActive(_ token: Int) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return token == activeRunToken
    }

    private func poll(hash: String,
                      token: Int,
                      onAttemptCompleted: ((Int) -> Void)?,
                      completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        guard isActive(token) else { return }
        guard let repository = repository else {
            let message = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong)
            finish(token: token, result: .failure(GeneralError.customMessage(message)), completion: completion)
            return
        }
        repository.fetchTimeline(tripHash: hash) { [weak self] result in
            self?.handle(result, hash: hash, token: token, onAttemptCompleted: onAttemptCompleted, completion: completion)
        }
    }

    private func handle(_ result: Result<TRPTimeline, Error>,
                        hash: String,
                        token: Int,
                        onAttemptCompleted: ((Int) -> Void)?,
                        completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        let isPending = (try? result.get()).map(isGenerationPending) ?? false
        switch nextStep(after: result, isPending: isPending, token: token) {
        case .ignore:
            return
        case .finish(let outcome):
            finish(token: token, result: outcome, completion: completion)
        case .pollAgain(let attempt):
            onAttemptCompleted?(attempt)
            schedule(pollInterval) { [weak self] in
                self?.poll(hash: hash, token: token, onAttemptCompleted: onAttemptCompleted, completion: completion)
            }
        }
    }

    private func nextStep(after result: Result<TRPTimeline, Error>, isPending: Bool, token: Int) -> NextStep {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard token == activeRunToken else { return .ignore }
        attemptCount += 1

        switch result {
        case .success(let timeline):
            guard isPending else { return .finish(.success(timeline)) }
        case .failure(let error):
            failureCount += 1
            if failureCount >= maxFailures {
                return .finish(.failure(error))
            }
        }
        return attemptCount >= maxAttempts ? .finish(.failure(TimelineGenerateError.timeout)) : .pollAgain(attempt: attemptCount)
    }

    private func finish(token: Int,
                        result: Result<TRPTimeline, Error>,
                        completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        stateLock.lock()
        let isCurrentRun = token == activeRunToken
        if isCurrentRun {
            activeRunToken += 1
        }
        stateLock.unlock()
        guard isCurrentRun else { return }
        completion?(result)
    }
}
