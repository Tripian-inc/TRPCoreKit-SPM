//
//  LastSearchUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchLastSearchUseCase {
    
    func executeFetchSearch(completion: ((Result<[String], Error>) -> Void)?)
}

public protocol DeleteLastSearchUseCase {
    
    func executeDeleteSearch(text: String)
}

public protocol AddLastSearchUseCase {
    
    func executeAddSearch(text: String)
}

public protocol ObserveLastSearchUseCase {
    
    var values: ValueObserver<[String]> { get }
}
