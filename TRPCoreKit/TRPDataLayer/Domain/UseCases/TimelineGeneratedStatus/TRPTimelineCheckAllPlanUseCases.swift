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
    
    public init(timelineRepository: TimelineRepository = TRPTimelineRepository(),
                timelineModelRepository: TimelineModelRepository = TRPTimelineModelRepository()) {
        self.timelineRepository = timelineRepository
        self.timelineModelRepository = timelineModelRepository
        
        generateController = TimelineGenerateController()
        generateController?.repository = self.timelineRepository
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

        // If there are no plans (only booked/reserved activities), consider it as generated
        guard let plans = timeline.plans, !plans.isEmpty else {
            allSegmentGenerated.value = true
            return
        }

        var notGenerated = false
        for plan in plans {
            if plan.generatedStatus == 0 {
                notGenerated = true
                break
            }
        }
        if !notGenerated {
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
        let onComplete = completion ?? { result in }
        allSegmentGenerated.value = false
        generateController?.fetchTimeline(hash: tripHash, completion: { [weak self] result in
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
