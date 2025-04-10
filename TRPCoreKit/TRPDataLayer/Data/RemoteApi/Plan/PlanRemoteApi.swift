//
//  PlanRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol PlanRemoteApi {
    
    func fetchPlan(id: Int,
                   completion: @escaping (PlanResultValue) -> Void)
    
    
    func updatePlanHours(planId: Int,
                       start: String,
                       end: String,
                       completion: @escaping (PlanResultValue) -> Void)
    
    
    func updatePlanStepOrder(planId: Int,
                             stepOrders: [Int],
                             completion: @escaping (PlanResultValue) -> Void)
    
    func exportPlanMap(planId: Int,
                       tripHash: String,
                       completion: @escaping (PlanExportResultValue) -> Void)
    
}

