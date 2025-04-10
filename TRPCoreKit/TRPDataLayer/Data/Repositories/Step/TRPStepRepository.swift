//
//  TRPStepRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPStepRepository: StepRepository {
    
    private(set) var remoteApi: StepRemoteApi
    
    public init(remoteApi: StepRemoteApi = TRPStepRemoteApi()) {
        self.remoteApi = remoteApi
    }
    
    public func addStep(planId: Int, poiId: String, completion: @escaping (StepResultValue) -> Void) {
        remoteApi.addStep(planId: planId, poiId: poiId, completion: completion)
    }
    
    public func addCustomStep(planId: Int, name: String, address: String, description: String, photoUrl: String?, web: String?, latitude: Double?, longitude: Double?, completion: @escaping (StepResultValue) -> Void) {
        remoteApi.addCustomStep(planId: planId, name: name, address: address, description: description, photoUrl: photoUrl, web: web, latitude: latitude, longitude: longitude, completion: completion)
    }
    
    public func deleteStep(id: Int, completion: @escaping (StepStatusValue) -> Void) {
        remoteApi.deleteStep(id: id, completion: completion)
    }
    
    public func editStep(id: Int, poiId: String, completion: @escaping (StepResultValue) -> Void) {
        remoteApi.editStep(id: id, poiId: poiId, completion: completion)
    }
    
    public func editStep(id: Int, startTime: String, endTime: String, completion: @escaping (StepResultValue) -> Void) {
        remoteApi.editStep(id: id, startTime: startTime, endTime: endTime, completion: completion)
    }
    
    public func reOrderStep(id: Int, order: Int, completion: @escaping (StepResultValue) -> Void) {
        remoteApi.reOrderStep(id: id, order: order, completion: completion)
    }
    
}


