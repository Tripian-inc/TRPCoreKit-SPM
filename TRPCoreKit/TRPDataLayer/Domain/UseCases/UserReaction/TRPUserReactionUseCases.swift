//
//  TRPUserReactionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public final class TRPUserReactionUseCases {
    
    private(set) var repository: UserReactionRepository
    
    
    public init(repository: UserReactionRepository = TRPUserReactionRepository()) {
        self.repository = repository
    }
    
    private func addReactionInValues(_ item: TRPUserReaction) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        repository.results.value!.append(item)
    }
    
    private func deleteReactionInValues(_ reactionId: Int) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        if let index = repository.results.value!.firstIndex(where: {$0.id == reactionId}) {
            repository.results.value!.remove(at: index)
        }
    }
    
    private func appendReactionsInValues(_ items: [TRPUserReaction]) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        repository.results.value!.append(contentsOf: items)
    }
    
    private func clearValuesInRepository() {
        repository.results.value = []
    }
    
    public func remove() {
        repository.results.removeObservers()
    }
    
}

extension TRPUserReactionUseCases: ObserveUserReactionUseCase {
    
    public var values: ValueObserver<[TRPUserReaction]> {
        return repository.results
    }
    
}

extension TRPUserReactionUseCases: FetchUserReactionUseCase {
    
    public func executeFetchUserReaction(tripHash: String, completion: ((Result<[TRPUserReaction], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.fetchUserReaction(tripHash: tripHash) {[weak self] result in
            switch result {
            case .success(let reactions):
                self?.repository.results.value = reactions
                onComplete(.success(reactions))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}


extension TRPUserReactionUseCases: AddUserReactionUseCase {
    
    public func executeAddUserReaction(poiId: String, stepId: Int, reaction: TRPUserReactionType?, comment: String?, completion: ((Result<TRPUserReaction, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.addUserReaction(poiId: poiId, stepId: stepId, reaction: reaction, comment: comment) { [weak self] result in
            switch result {
            case .success(let reaction):
                self?.addReactionInValues(reaction)
                onComplete(.success(reaction))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPUserReactionUseCases: DeleteUserReactionUseCase {
    
    public func executeDeleteUserReaction(id: Int, completion: ((Result<Bool, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        repository.removeUserReaction(id: id) { [weak self] result in
            switch result {
            case .success(let status):
                self?.deleteReactionInValues(id)
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
    }
    
}

extension TRPUserReactionUseCases: UpdateUserReactionUseCase {
    
    public func executeUpdateUserReaction(id: Int,
                                          reaction: TRPUserReactionType?,
                                          comment: String?, completion: ((Result<TRPUserReaction, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        repository.updateUserReaction(id: id, reaction: reaction, comment: comment) { result in
            switch result {
            case .success(let reaction):
                onComplete(.success(reaction))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
    }
    
}
