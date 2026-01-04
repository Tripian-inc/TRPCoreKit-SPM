//
//  StepRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias TimelineStepResultValue = (Result<TRPTimelineStep, Error>)

public typealias TimelineStepStatusValue = (Result<Bool, Error>)

public protocol TimelineStepRepository {
    
    func addStep(step: TRPTimelineStepCreate,
                 completion: @escaping (TimelineStepResultValue) -> Void)
    
    func deleteStep(id: Int,
                    completion: @escaping (TimelineStepStatusValue) -> Void)
 
    func editStep(step: TRPTimelineStepEdit,
                  completion: @escaping (TimelineStepResultValue) -> Void)
}

