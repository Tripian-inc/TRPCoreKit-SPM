//
//  TRPCompanionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCompanionUseCases {
    
    private(set) var repository: CompanionRepository
    
    public init(repository: CompanionRepository = TRPCompanionRepository()) {
        self.repository = repository
    }
    
}

extension TRPCompanionUseCases: FetchCompanionUseCase {
    
    public func executeFetchCompanion(completion: ((Result<[TRPCompanion], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if let companions = repository.companions.value, !companions.isEmpty {
            onComplete(.success(companions))
            return
        }
        
        repository.fetchCompanions {[weak self] result in
            switch result {
            case .success(let companions):
                self?.repository.companions.value = companions
                onComplete(.success(companions))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPCompanionUseCases: AddCompanionUseCase {
    
    public func executeAddCompanion(name: String, title: String?, answers: [Int], age: Int, completion: ((Result<TRPCompanion, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.addCompanion(name: name, answers: answers, age: age, title: title) { [weak self] result in
            switch result {
            case .success(let companion):
                if self?.repository.companions.value == nil {
                    self?.repository.companions.value = []
                }
                self?.repository.companions.value!.append(companion)
                onComplete(.success(companion))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPCompanionUseCases: DeleteCompanionUseCase {
    
    public func executeDeleteCompanion(id: Int, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.deleteCompanion(id: id) { [weak self] result in
            switch result {
            case .success(let status):
                if self?.repository.companions.value == nil {
                    self?.repository.companions.value = []
                }
                
                if let index = self?.repository.companions.value!.firstIndex(where: {$0.id == id}) {
                    self?.repository.companions.value!.remove(at: index)
                }
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
        
}

extension TRPCompanionUseCases: UpdateCompanionUseCase {
    public func executeUpdateCompanion(id: Int, name: String, title: String?, answers: [Int]?, age: Int?, completion: ((Result<TRPCompanion, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.updateCompanion(id: id, name: name, answers: answers, age: age, title: title) { [weak self] result in
            switch result {
            case .success(let updatedCompanion):
                if self?.repository.companions.value == nil {
                    self?.repository.companions.value = []
                }
                if let index = self?.repository.companions.value!.firstIndex(where: {$0.id == id}) {
                    self?.repository.companions.value![index] = updatedCompanion
                }
                onComplete(.success(updatedCompanion))
            case .failure(let error):
                onComplete(.failure(error))
            }
            
        }
    }
}


extension TRPCompanionUseCases: ObserveCompanionUseCase {
    public var values: ValueObserver<[TRPCompanion]> {
        return repository.companions
    }
}


