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

/// Polls `GET /timeline/{hash}` until no plan has `generatedStatus == 0`.
///
/// Each fetch is one attempt; the next one is scheduled `pollInterval` after the previous response arrives.
/// A run ends with the last fetch error itself once `maxFailures` fetches have failed in total (checked first), or with
/// `.timeout` when attempt `maxAttempts` completes while a plan is still pending. Its completion fires exactly once;
/// starting a new run or calling `cancel()` silences the previous one.
class TimelineGenerateController {

    typealias Scheduler = (_ delay: DispatchTimeInterval, _ work: @escaping () -> Void) -> Void

    static let globalQueueScheduler: Scheduler = { delay, work in
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }

    private enum NextStep {
        case pollAgain
        case finish(Result<TRPTimeline, Error>)
        case ignore
    }

    public var repository: TimelineRepository?

    private let pollInterval: DispatchTimeInterval
    private let maxAttempts: Int
    private let maxFailures: Int
    private let schedule: Scheduler

    private let stateLock = NSLock()
    private var activeRunToken = 0
    private var attemptCount = 0
    private var failureCount = 0

    init(pollInterval: DispatchTimeInterval = .seconds(2),
         maxAttempts: Int = 30,
         maxFailures: Int = 3,
         schedule: @escaping Scheduler = TimelineGenerateController.globalQueueScheduler) {
        self.pollInterval = pollInterval
        self.maxAttempts = max(1, maxAttempts)
        self.maxFailures = max(1, maxFailures)
        self.schedule = schedule
    }

    public func fetchTimeline(hash: String, completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        let token = startRun()
        poll(hash: hash, token: token, completion: completion)
    }

    /// Stops the active run; its completion will not be called.
    func cancel() {
        stateLock.lock()
        activeRunToken += 1
        stateLock.unlock()
    }

    static func isGenerationPending(_ timeline: TRPTimeline) -> Bool {
        return timeline.plans?.contains(where: { $0.generatedStatus == 0 }) ?? false
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

    private func poll(hash: String, token: Int, completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        guard isActive(token) else { return }
        guard let repository = repository else {
            let message = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong)
            finish(token: token, result: .failure(GeneralError.customMessage(message)), completion: completion)
            return
        }
        repository.fetchTimeline(tripHash: hash) { [weak self] result in
            self?.handle(result, hash: hash, token: token, completion: completion)
        }
    }

    private func handle(_ result: Result<TRPTimeline, Error>,
                        hash: String,
                        token: Int,
                        completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        switch nextStep(after: result, token: token) {
        case .ignore:
            return
        case .finish(let outcome):
            finish(token: token, result: outcome, completion: completion)
        case .pollAgain:
            schedule(pollInterval) { [weak self] in
                self?.poll(hash: hash, token: token, completion: completion)
            }
        }
    }

    private func nextStep(after result: Result<TRPTimeline, Error>, token: Int) -> NextStep {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard token == activeRunToken else { return .ignore }
        attemptCount += 1

        switch result {
        case .success(let timeline):
            guard Self.isGenerationPending(timeline) else { return .finish(.success(timeline)) }
        case .failure(let error):
            failureCount += 1
            if failureCount >= maxFailures {
                return .finish(.failure(error))
            }
        }
        return attemptCount >= maxAttempts ? .finish(.failure(TimelineGenerateError.timeout)) : .pollAgain
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
