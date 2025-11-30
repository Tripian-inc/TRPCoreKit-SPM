//
//  TRPPlanRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public class TRPTimelinePlanRemoteApi: TimelinePlanRemoteApi {
    
  
    public init() {}
    
    
    public func fetchPlan(id: String, completion: @escaping (TimelinePlanResultValue) -> Void) {
        TRPRestKit().getTimelinePlan(id: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? [TRPTimelinePlansInfoModel] {
                guard let converted = TimelinePlanMapper().map(result).first else {
                    completion(.failure(GeneralError.customMessage("Not Implemented")))
                    return
                }
                completion(.success(converted))
            }
        }
    }
    
    public func updatePlanStepOrder(planId: Int, stepOrders: [Int], completion: @escaping (TimelinePlanResultValue) -> Void) {
        
        completion(.failure(GeneralError.customMessage("Not Implemented")))
//        TRPRestKit().updateDailyPlanStepOrders(dailyPlanId: planId, stepOrders: stepOrders) { result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            if let result = result as? TRPTimelinePlansInfoModel {
//                let converted = TimelinePlanMapper().map(result)
//                completion(.success(converted))
//            }
//        }
    }
    
    public func exportPlanMap(planId: Int, tripHash: String, completion: @escaping (PlanExportResultValue) -> Void) {
        
        completion(.failure(GeneralError.customMessage("Not Implemented")))
//        TRPRestKit().exportPlanMap(planId: planId, tripHash: tripHash) { result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            if let result = result as? TRPExportPlanJsonModel {
//                completion(.success(TRPExportItinerary(url: result.url)))
//            }
//        }
    }
    
}
