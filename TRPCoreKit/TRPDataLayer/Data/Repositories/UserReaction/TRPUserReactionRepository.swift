//
//  TRPUserReactionRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPUserReactionRepository: UserReactionRepository {
    
    public var results: ValueObserver<[TRPUserReaction]> = .init([])
    
    public var remoteApi: UserReactionRemoteApi
    public var localStorage: UserReactionLocalStorage
    
    
    public init(remoteApi: UserReactionRemoteApi = TRPUserReactionRemoteApi(),
                localStorage: UserReactionLocalStorage = TRPUserReactionLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchUserReaction(tripHash: String,
                                  completion: @escaping (UserReactionResultsValue) -> Void) {
        remoteApi.fetchUserReaction(tripHash: tripHash, completion: completion)
    }
    
    public func addUserReaction(poiId: String,
                                stepId: Int,
                                reaction: TRPUserReactionType?,
                                comment: String?,
                                completion: @escaping (UserReactionResultValue) -> Void) {
        remoteApi.addUserReaction(poiId: poiId,
                                  stepId: stepId,
                                  reaction: reaction,
                                  comment: comment,
                                  completion: completion)
    }
    
    public func removeUserReaction(id: Int,
                                   completion: @escaping (UserReactionResultStatus) -> Void) {
        remoteApi.removeUserReaction(id: id,
                                     completion: completion)
    }
    

    public func updateUserReaction(id: Int,
                                   reaction: TRPUserReactionType?,
                                   comment: String?,
                                   completion: @escaping (UserReactionResultValue) -> Void) {
        remoteApi.updateUserReaction(id: id,
                                     reaction: reaction,
                                     comment: comment,
                                     completion: completion)
    }
    

}
