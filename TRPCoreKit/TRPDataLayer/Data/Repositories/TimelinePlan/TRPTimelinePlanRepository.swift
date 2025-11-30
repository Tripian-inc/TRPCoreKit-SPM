//
//  TRPPlanRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTimelinePlanRepository: TimelinePlanRepository {
    
    private(set) var remoteApi: TimelinePlanRemoteApi
    
    public init(remoteApi: TimelinePlanRemoteApi = TRPTimelinePlanRemoteApi()) {
        self.remoteApi = remoteApi
    }
    
    public func fetchPlan(id: String, completion: @escaping (TimelinePlanResultValue) -> Void) {
        remoteApi.fetchPlan(id: id, completion: completion)
    }
    
    public func editPlanHours(planId: Int, start: String, end: String, completion: @escaping (TimelinePlanResultValue) -> Void) {
//        remoteApi.updatePlanHours(planId: planId, start: start, end: end, completion: completion)
    }
    
    public func editPlanStepOrder(planId: Int, stepOrders: [Int], completion: @escaping (TimelinePlanResultValue) -> Void) {
        remoteApi.updatePlanStepOrder(planId: planId, stepOrders: stepOrders, completion: completion)
    }
    
    
    public func exportItinerary(planId: Int, tripHash:String, completion: @escaping (TimelinePlanExportResultValue) -> Void) {
        remoteApi.exportPlanMap(planId: planId, tripHash: tripHash, completion: completion)
    }
}
