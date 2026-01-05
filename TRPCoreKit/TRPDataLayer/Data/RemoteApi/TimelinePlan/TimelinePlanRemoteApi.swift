//
//  PlanRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol TimelinePlanRemoteApi {
    
    func fetchPlan(id: String,
                   completion: @escaping (TimelinePlanResultValue) -> Void)
    
    
    func updatePlanStepOrder(planId: Int,
                             stepOrders: [Int],
                             completion: @escaping (TimelinePlanResultValue) -> Void)
    
    func exportPlanMap(planId: Int,
                       tripHash: String,
                       completion: @escaping (TimelinePlanExportResultValue) -> Void)
    
}

