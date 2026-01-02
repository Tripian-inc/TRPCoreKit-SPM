//
//  TRPStepRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public class TRPTimelineStepRemoteApi: TimelineStepRemoteApi {
    
    public init() {}
    
    public func addStep(step: TRPTimelineStepCreate, completion: @escaping (TimelineStepResultValue) -> Void) {
                    
        let step = TimelineStepRequestMapper().makeCreateStep(step: step)
        
        TRPRestKit().addTimelineStep(step: step) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPTimelineStepInfoModel {
                if let converted = TimelineStepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func deleteStep(id: Int, completion: @escaping (TimelineStepStatusValue) -> Void) {
        TRPRestKit().deleteTimelineStep(stepId: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPParentJsonModel {
                completion(.success(result.success))
            }
        }
    }
    
    public func editStep(step: TRPTimelineStepEdit,  completion: @escaping (TimelineStepResultValue) -> Void) {
        
        let step = TimelineStepRequestMapper().makeEditStep(step: step)
        
        TRPRestKit().editTimelineStep(step: step) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPTimelineStepInfoModel {
                if let converted = TimelineStepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
}
