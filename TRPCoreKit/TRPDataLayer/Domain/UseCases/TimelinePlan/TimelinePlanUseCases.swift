//
//  PlanUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchTimelinePlanUseCase {
    
    func executeFetchPlan(id: String, completion: ((Result<TRPTimelinePlan, Error>) -> Void)?)
}

public protocol ChangeDailyTimelinePlanUseCase {
    
    func executeChangeDailyPlan(id: String, completion: ((Result<TRPTimelinePlan, Error>) -> Void)?)
}

public protocol EditTimelinePlanUseCase {
    
    func executeEditPlanHours(startTime: String, endTime: String, completion: ((Result<TRPTimelinePlan, Error>) -> Void)?)
    func executeEditPlanStepOrder(stepOrders: [Int], completion: ((Result<TRPTimelinePlan, Error>) -> Void)?)
    
}
