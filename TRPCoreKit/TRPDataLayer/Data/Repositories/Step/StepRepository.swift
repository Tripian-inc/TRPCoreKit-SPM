//
//  StepRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias StepResultValue = (Result<TRPStep, Error>)

public typealias StepStatusValue = (Result<Bool, Error>)

public protocol StepRepository {
    
    func addStep(planId: Int, poiId: String,
                 completion: @escaping (StepResultValue) -> Void)
    
    func addCustomStep(planId: Int,
                       name: String,
                       address: String,
                       description: String,
                       photoUrl: String?,
                       web: String?,
                       latitude: Double?,
                       longitude: Double?,
                       completion: @escaping (StepResultValue) -> Void)
    
    func deleteStep(id: Int,
                    completion: @escaping (StepStatusValue) -> Void)
 
    func editStep(id: Int,
                  poiId: String,
                  completion: @escaping (StepResultValue) -> Void)
    
    func editStep(id: Int,
                  startTime: String,
                  endTime: String,
                  completion: @escaping (StepResultValue) -> Void)
    
    func reOrderStep(id: Int,
                     order: Int,
                     completion: @escaping (StepResultValue) -> Void)
}

