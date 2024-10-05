//
//  UserReactionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchUserReactionUseCase {
    
    func executeFetchUserReaction(tripHash: String, completion: ((Result<[TRPUserReaction], Error>) -> Void)?)

}

public protocol AddUserReactionUseCase {
    
    func executeAddUserReaction(poiId: String,
                                stepId: Int,
                                reaction: TRPUserReactionType?,
                                comment: String?,
                                completion: ((Result<TRPUserReaction, Error>) -> Void)?)
    
}


public protocol UpdateUserReactionUseCase {
    
    func executeUpdateUserReaction(id: Int,
                                   reaction: TRPUserReactionType?,
                                   comment: String?,
                                   completion: ((Result<TRPUserReaction, Error>) -> Void)?)
    
}


public protocol DeleteUserReactionUseCase {
    
    func executeDeleteUserReaction(id: Int, completion: ((Result<Bool, Error>) -> Void)? )
    
}

public protocol ObserveUserReactionUseCase {
    
    var values: ValueObserver<[TRPUserReaction]> { get }

}
