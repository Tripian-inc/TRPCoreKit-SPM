//
//  TRPStepRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit


public class TRPStepRemoteApi: StepRemoteApi {
    
    
    public init() {}
    
    public func addStep(planId: Int, poiId: String, completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().addStep(planId: planId, poiId: poiId) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result, planId: planId) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func addCustomStep(planId: Int, name: String, address: String, description: String, photoUrl: String?, web: String?, latitude: Double?, longitude: Double?, completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().addCustomStep(planId: planId, name: name, address: address, description: description, photoUrl: photoUrl, web: web, latitude: latitude, longitude: longitude) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result, planId: planId) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func deleteStep(id: Int, completion: @escaping (StepStatusValue) -> Void) {
        TRPRestKit().deleteStep(stepId: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPParentJsonModel {
                
                completion(.success(result.success))
            }
        }
    }
    
    public func editStep(id: Int, poiId: String,  completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().editStep(stepId: id, poiId: poiId) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func editStep(id: Int, startTime: String, endTime: String, completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().editStep(stepId: id, startTime: startTime, endTime: endTime) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func reOrderStep(id: Int, order: Int, completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().editStep(stepId: id, order: order) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
    public func reOrderStep(id: Int, poiId: String, order: Int, completion: @escaping (StepResultValue) -> Void) {
        TRPRestKit().editStep(stepId: id, poiId: poiId, order: order) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPStepInfoModel {
                if let converted = StepMapper().map(result) {
                    completion(.success(converted))
                }else {
                    print("[Error] Step model couldn't convert")
                }
            }
        }
    }
    
}
