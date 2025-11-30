//
//  PlanRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias TimelinePlanResultValue = (Result<TRPTimelinePlan, Error>)

public typealias TimelinePlanExportResultValue = (Result<TRPExportItinerary, Error>)

public protocol TimelinePlanRepository {
    
    func fetchPlan(id: String,
                   completion: @escaping (TimelinePlanResultValue) -> Void)
    
    
    func editPlanHours(planId: Int,
                       start: String,
                       end: String,
                       completion: @escaping (TimelinePlanResultValue) -> Void)
    
    
    func editPlanStepOrder(planId: Int,
                           stepOrders: [Int],
                           completion: @escaping (TimelinePlanResultValue) -> Void)
    
    
    func exportItinerary(planId: Int,
                         tripHash:String,
                         completion: @escaping (TimelinePlanExportResultValue) -> Void)
    
}

