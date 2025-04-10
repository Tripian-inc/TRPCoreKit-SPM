//
//  TRPPlanRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public class TRPPlanRemoteApi: PlanRemoteApi {
    
  
    public init() {}
    
    
    public func fetchPlan(id: Int, completion: @escaping (PlanResultValue) -> Void) {
        TRPRestKit().dailyPlan(id: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPPlansInfoModel {
                let converted = PlanMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func updatePlanHours(planId: Int, start: String, end: String, completion: @escaping (PlanResultValue) -> Void) {
        
        TRPRestKit().updateDailyPlanHour(dailyPlanId: planId, start: start, end: end) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPPlansInfoModel {
                let converted = PlanMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func updatePlanStepOrder(planId: Int, stepOrders: [Int], completion: @escaping (PlanResultValue) -> Void) {
        
        TRPRestKit().updateDailyPlanStepOrders(dailyPlanId: planId, stepOrders: stepOrders) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPPlansInfoModel {
                let converted = PlanMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func exportPlanMap(planId: Int, tripHash: String, completion: @escaping (PlanExportResultValue) -> Void) {
        
        TRPRestKit().exportPlanMap(planId: planId, tripHash: tripHash) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPExportPlanJsonModel {
                completion(.success(TRPExportItinerary(url: result.url)))
            }
        }
    }
    
}
