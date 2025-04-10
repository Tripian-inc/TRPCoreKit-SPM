//
//  PlanRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias PlanResultValue = (Result<TRPPlan, Error>)

public typealias PlanExportResultValue = (Result<TRPExportItinerary, Error>)

public protocol PlanRepository {
    
    func fetchPlan(id: Int,
                   completion: @escaping (PlanResultValue) -> Void)
    
    
    func editPlanHours(planId: Int,
                       start: String,
                       end: String,
                       completion: @escaping (PlanResultValue) -> Void)
    
    
    func editPlanStepOrder(planId: Int,
                           stepOrders: [Int],
                           completion: @escaping (PlanResultValue) -> Void)
    
    
    func exportItinerary(planId: Int,
                         tripHash:String,
                         completion: @escaping (PlanExportResultValue) -> Void)
    
}

