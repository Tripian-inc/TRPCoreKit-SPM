//
//  TRPCompanionRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCompanionRepository: CompanionRepository {
    
    public var companions: ValueObserver<[TRPCompanion]> = .init([])
    
    private(set) var remoteApi: CompanionRemoteApi
    private(set) var localStorage: CompanionLocalStorage
    
    public init(remoteApi: CompanionRemoteApi = TRPCompanionRemoteApi(),
         localStorage: CompanionLocalStorage = TRPCompanionLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchCompanions(completion: @escaping (CompanionResultsValue) -> Void) {
        remoteApi.fetchCompanions(completion: completion)
    }
    
    public func addCompanion(name: String,
                      answers: [Int],
                      age: Int,
                      title: String?,
                      completion: @escaping (CompanionResultValue) -> Void) {
        remoteApi.addCompanion(name: name, answers: answers, age: age, title: title, completion: completion)
    }
    
    public func updateCompanion(id: Int,
                         name: String,
                         answers: [Int]?,
                         age: Int?,
                         title: String?,
                         completion: @escaping (CompanionResultValue) -> Void) {
        remoteApi.updateCompanion(id: id, name: name, answers: answers, age: age, title: title, completion: completion)
    }
    
    public func deleteCompanion(id: Int,
                         completion: @escaping (CompanionResultStatus) -> Void) {
        remoteApi.deleteCompanion(id: id, completion: completion)
    }
    
    
}
