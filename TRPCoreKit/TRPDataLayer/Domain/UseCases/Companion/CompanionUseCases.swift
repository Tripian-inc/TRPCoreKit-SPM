//
//  CompanionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchCompanionUseCase {
    
    func executeFetchCompanion(completion: ((Result<[TRPCompanion], Error>) -> Void)?)
    
}

public protocol AddCompanionUseCase {
    
    func executeAddCompanion(name: String, title: String?, answers: [Int], age: Int, completion: ((Result<TRPCompanion, Error>) -> Void)?)
}

public protocol UpdateCompanionUseCase {
    
    func executeUpdateCompanion(id: Int, name: String, title: String?, answers: [Int]?, age: Int?, completion: ((Result<TRPCompanion, Error>) -> Void)?)
}

public protocol DeleteCompanionUseCase {
    
    func executeDeleteCompanion(id: Int, completion: ((Result<Bool, Error>) -> Void)?)
}
public protocol ObserveCompanionUseCase {

    var values: ValueObserver<[TRPCompanion]> { get }
}
