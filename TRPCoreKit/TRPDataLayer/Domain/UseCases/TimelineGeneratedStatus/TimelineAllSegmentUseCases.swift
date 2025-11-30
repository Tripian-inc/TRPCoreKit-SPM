//
//  TripAllDayUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchTimelineCheckAllPlanUseCase{
    
    func executeFetchTimelineCheckAllPlanGenerate(tripHash: String, completion: ((Result<TRPTimeline, Error>) -> Void)?)
}


public protocol ObserveTimelineCheckAllPlanUseCase {

    var timeline: ValueObserver<TRPTimeline> { get }
    
    var firstSegmentGenerated: ValueObserver<Bool> { get set}
    
    var allSegmentGenerated: ValueObserver<Bool> { get }
    
    var generationError: ValueObserver<Error?> { get }
}
