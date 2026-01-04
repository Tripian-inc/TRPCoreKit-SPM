//
//  StepUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol AddTimelineStepUseCase {
        
    
    /// CurrentDay e yeni bir step(poi) ekler.
    /// - Parameters:
    ///   - poiId: Place Id
    ///   - completion:
    func executeAddStep(poiId: String, stepDate: String?, startTime: String?, endTime: String?, completion: ((Result<TRPTimelineStep, Error>) -> Void)?)
    
    func executeAddCustomStep(planId: String,
                             stepDate: String?,
                             startTime: String?,
                             endTime: String?,
                             customStep: TRPTimelineStepCustomPoi?,
                             completion: ((Result<TRPTimelineStep, any Error>) -> Void)?)
}

public protocol DeleteTimelineStepUseCase {
        
    func executeDeleteStep(id: Int, completion: ((Result<Bool, Error>) -> Void)?)
    
    func executeDeletePoi(id: String, completion: ((Result<Bool, Error>) -> Void)?)
}

public protocol EditTimelineStepUseCase {
    
    func executeEditStep(id: Int, poiId: String, completion: ((Result<TRPTimelineStep, Error>) -> Void)?)
    
    func executeEditStepHour(id: Int, startTime: String, endTime: String, completion: ((Result<TRPTimelineStep, Error>) -> Void)?)
}

public protocol ReOrderTimelineStepUseCase {
    
    func executeReOrderStep(id: Int, order: Int, completion: ((Result<TRPTimelineStep, Error>) -> Void)?)
    
}

