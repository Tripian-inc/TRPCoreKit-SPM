//
//  TRPPlanRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPPlanRepository: PlanRepository {
    
    private(set) var remoteApi: PlanRemoteApi
    
    public init(remoteApi: PlanRemoteApi = TRPPlanRemoteApi()) {
        self.remoteApi = remoteApi
    }
    
    public func fetchPlan(id: Int, completion: @escaping (PlanResultValue) -> Void) {
        remoteApi.fetchPlan(id: id, completion: completion)
    }
    
    public func editPlanHours(planId: Int, start: String, end: String, completion: @escaping (PlanResultValue) -> Void) {
        remoteApi.updatePlanHours(planId: planId, start: start, end: end, completion: completion)
    }
    
    
    public func exportItinerary(planId: Int, tripHash:String, completion: @escaping (PlanExportResultValue) -> Void) {
        remoteApi.exportPlanMap(planId: planId, tripHash: tripHash, completion: completion)
    }
}
