//
//  TRPCompanionRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class TRPCompanionRemoteApi: CompanionRemoteApi {
    
    public init() {}
    
    public func fetchCompanions(completion: @escaping (CompanionResultsValue) -> Void) {
        TRPRestKit().getUsersCompanions { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPCompanionModel] {
                let converted = CompanionMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func addCompanion(name: String,
                             answers: [Int],
                             age: Int,
                             title: String?,
                             completion: @escaping (CompanionResultValue) -> Void) {
        TRPRestKit().addCompanion(name: name, answers: answers, age: age, title: title) { (result, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPCompanionModel {
                let converted = CompanionMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func updateCompanion(id: Int,
                                name: String,
                                answers: [Int]?,
                                age: Int?,
                                title: String?,
                                completion: @escaping (CompanionResultValue) -> Void) {
        TRPRestKit().updateCompanion(id: id, name: name, answers: answers, age: age, title: title) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPCompanionModel {
                let converted = CompanionMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func deleteCompanion(id: Int,
                                completion: @escaping (CompanionResultStatus) -> Void) {
        TRPRestKit().removeCompanion(companionId: id) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let status = result as? TRPParentJsonModel{
                completion(.success(true))
            }
        }
    }
    
    
}
