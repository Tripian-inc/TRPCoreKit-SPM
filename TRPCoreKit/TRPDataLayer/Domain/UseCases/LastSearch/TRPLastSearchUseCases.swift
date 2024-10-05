//
//  TRPLastSearchUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public final class TRPLastSearchUseCases {
    
    private(set) var repository: LastSearchRepository
    public var poiCategory: Int? {
        didSet {
            repository.poiCategoryId = poiCategory
        }
    }
    
    public init(repository: LastSearchRepository = TRPLastSearchRepository()) {
        self.repository = repository
    }
    
}


extension TRPLastSearchUseCases: FetchLastSearchUseCase {
    public func executeFetchSearch(completion: ((Result<[String], Error>) -> Void)?) {
        repository.fetchLastSearch { result in
            switch result {
            case .success(let array):
                completion?(.success(array))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    
}

extension TRPLastSearchUseCases: AddLastSearchUseCase {
    public func executeAddSearch(text: String) {
        repository.addLastSearch(text: text)
    }
    
    
}

extension TRPLastSearchUseCases: DeleteLastSearchUseCase {
    public func executeDeleteSearch(text: String) {
        repository.deleteLastSearch(text: text)
    }
    
    
}

extension TRPLastSearchUseCases: ObserveLastSearchUseCase {
    public var values: ValueObserver<[String]> {
        return repository.results
    }
    
    
}
