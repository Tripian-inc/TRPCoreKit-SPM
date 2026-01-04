//
//  TRPStepRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTimelineStepRepository: TimelineStepRepository {
    
    
    private(set) var remoteApi: TimelineStepRemoteApi
    
    public init(remoteApi: TimelineStepRemoteApi = TRPTimelineStepRemoteApi()) {
        self.remoteApi = remoteApi
    }
    
    public func addStep(step: TRPTimelineStepCreate, completion: @escaping (TimelineStepResultValue) -> Void) {
        remoteApi.addStep(step: step, completion: completion)
    }
    
    public func editStep(step: TRPTimelineStepEdit, completion: @escaping (TimelineStepResultValue) -> Void) {
        remoteApi.editStep(step: step, completion: completion)
    }
    
    public func deleteStep(id: Int, completion: @escaping (TimelineStepStatusValue) -> Void) {
        remoteApi.deleteStep(id: id, completion: completion)
    }
    
}


