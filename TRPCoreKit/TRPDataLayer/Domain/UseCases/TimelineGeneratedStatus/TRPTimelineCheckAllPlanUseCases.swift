//
//  TRPTripCheckAllPlanUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public final class TRPTimelineCheckAllPlanUseCases {
    
    private(set) var timelineRepository: TimelineRepository
    private(set) var timelineModelRepository: TimelineModelRepository
    private(set) var generateController: TimelineGenerateController?
    
    //ObserveTripCheckAllPlanUseCase
    public var firstSegmentGenerated: ValueObserver<Bool> = .init(false)
    
    private var generatedStatus: Int = 0
    
    public convenience init(timelineRepository: TimelineRepository = TRPTimelineRepository(),
                            timelineModelRepository: TimelineModelRepository = TRPTimelineModelRepository()) {
        self.init(timelineRepository: timelineRepository,
                  timelineModelRepository: timelineModelRepository,
                  generateController: TimelineGenerateController())
    }

    init(timelineRepository: TimelineRepository,
         timelineModelRepository: TimelineModelRepository,
         generateController: TimelineGenerateController) {
        self.timelineRepository = timelineRepository
        self.timelineModelRepository = timelineModelRepository
        self.generateController = generateController
        generateController.repository = timelineRepository
    }

    /// Stops the running poll; its completion and observers are not notified afterwards.
    func cancelPolling() {
        generateController?.cancel()
    }
    
    private func checkFirstSegmentStatus(timeline: TRPTimeline) {

        if firstSegmentGenerated.value == true {return}

        // If there are no plans (only booked/reserved activities), consider it as generated
        guard let plans = timeline.plans, !plans.isEmpty else {
            firstSegmentGenerated.value = true
            return
        }

        for plan in plans {
            if plan.generatedStatus != 0 {
                self.generatedStatus = plan.generatedStatus
                firstSegmentGenerated.value = true
                break
            }
        }
    }
    
    private func checkAllSegmentStatus(timeline: TRPTimeline) {

        if allSegmentGenerated.value == true {return}

        let isPending = generateController?.isGenerationPending(timeline)
            ?? (timeline.plans?.contains(where: { $0.generatedStatus == 0 }) ?? false)
        if !isPending {
            allSegmentGenerated.value = true
        }
    }
    
}


extension TRPTimelineCheckAllPlanUseCases: ObserveTimelineCheckAllPlanUseCase{
    
    public var timeline: ValueObserver<TRPTimeline> {
        return timelineModelRepository.timeline
    }  
    
    public var allSegmentGenerated: ValueObserver<Bool> {
        return timelineModelRepository.allSegmentGenerated
    }
    
    public var generationError: ValueObserver<Error?> {
        return timelineModelRepository.generationError
    }
}


extension TRPTimelineCheckAllPlanUseCases: FetchTimelineCheckAllPlanUseCase {
    public func executeFetchTimelineCheckAllPlanGenerate(tripHash: String, completion: ((Result<TRPTimeline, any Error>) -> Void)?) {
        executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash, onAttemptCompleted: nil, completion: completion)
    }

    /// Same as `executeFetchTimelineCheckAllPlanGenerate(tripHash:completion:)`; `onAttemptCompleted` receives the number
    /// of every poll attempt that did not end the run, whether a plan was still pending or the fetch failed, on the polling thread.
    func executeFetchTimelineCheckAllPlanGenerate(tripHash: String,
                                                  onAttemptCompleted: ((Int) -> Void)?,
                                                  completion: ((Result<TRPTimeline, any Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        allSegmentGenerated.value = false
        generateController?.fetchTimeline(hash: tripHash, onAttemptCompleted: onAttemptCompleted, completion: { [weak self] result in
            switch result {
            case .success(let timeline):
                self?.timelineModelRepository.timeline.value = timeline
                self?.checkFirstSegmentStatus(timeline: timeline)
                self?.checkAllSegmentStatus(timeline: timeline)
                onComplete(.success(timeline))
            case .failure(let error):
                self?.generationError.value = error
                onComplete(.failure(error))
            }
        })
    }

}
