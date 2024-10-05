//
//  CompanionRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol CompanionRemoteApi {
    
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
