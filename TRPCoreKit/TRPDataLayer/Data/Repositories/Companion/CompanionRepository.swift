//
//  CompanionRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias CompanionResultsValue = (Result<[TRPCompanion], Error>)

public typealias CompanionResultValue = (Result<TRPCompanion, Error>)

public typealias CompanionResultStatus = (Result<Bool, Error>)

public protocol CompanionRepository {
    
    var companions: ValueObserver<[TRPCompanion]> { get set }
    
    func fetchCompanions(completion: @escaping (CompanionResultsValue) -> Void)
    
    func addCompanion(name: String,
                      answers: [Int],
                      age: Int,
                      title: String?,
                      completion: @escaping (CompanionResultValue) -> Void)
    
    func updateCompanion(id: Int,
                         name: String,
                         answers: [Int]?,
                         age: Int?,
                         title: String?,
                         completion: @escaping (CompanionResultValue) -> Void)
    
    func deleteCompanion(id: Int,
                         completion: @escaping (CompanionResultStatus) -> Void)
}
