//
//  StepRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol StepRemoteApi {
    
    func addStep(planId: Int, poiId: String,
                 completion: @escaping (StepResultValue) -> Void)
    
    func deleteStep(id: Int,
                    completion: @escaping (StepStatusValue) -> Void)
 
    func editStep(id: Int,
                  poiId: String,
                  completion: @escaping (StepResultValue) -> Void)
    
    func reOrderStep(id: Int,
                     order: Int,
                     completion: @escaping (StepResultValue) -> Void)
}

