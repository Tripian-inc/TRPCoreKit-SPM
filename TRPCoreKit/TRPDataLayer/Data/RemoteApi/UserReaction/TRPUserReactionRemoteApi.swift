//
//  TRPUserReactionRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final public class TRPUserReactionRemoteApi: UserReactionRemoteApi {
    
    
    
    public init() {}
    
    
    public func fetchUserReaction(tripHash: String, completion: @escaping (UserReactionResultsValue) -> Void) {
        
        TRPRestKit().getUserReaction(withTripHash: tripHash) { result, error, pagination in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? [TRPReactionModel] {
                
                let converted = UserReactionMapper().map(result)
                completion(.success(converted))
                
            }
            
        }
        
    }
    
    public func addUserReaction(poiId: String, stepId: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void) {
        
        var restReaction: UserReactionType?
        
        switch reaction {
        case .thumbsUp:
            restReaction = .thumbsUp
        case .thumbsDown:
            restReaction = .thumbsDown
        case .neutral:
            restReaction = .neutral
        case .none:
            restReaction = .none
        }
        
        TRPRestKit().addUserReaction(poiId: poiId,
                                     stepId: stepId,
                                     reaction: restReaction,
                                     comment: comment) { (result, error) in
                                        
                                        if let error = error {
                                            completion(.failure(error))
                                            return
                                        }
                                        
                                        if let result = result as? TRPReactionModel {
                                            
                                            let converted = UserReactionMapper().map(result)
                                            completion(.success(converted))
                                            
                                        }
        }
        
    }
    
    
    
    public func removeUserReaction(id: Int, completion: @escaping (UserReactionResultStatus) -> Void) {
        
        TRPRestKit().deleteUserReaction(id: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPParentJsonModel {
        
                completion(.success(result.success))
                
            }
        }
        
    }
    
    public func updateUserReaction(id: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void) {
        var restReaction: UserReactionType?
        
        switch reaction {
        case .thumbsUp:
            restReaction = .thumbsUp
        case .thumbsDown:
            restReaction = .thumbsDown
        case .neutral:
            restReaction = .neutral
        case .none:
            restReaction = .none
        }
        
        TRPRestKit().updateUserReaction(id: id, reaction: restReaction, comment: comment) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPReactionModel {
                let converted = UserReactionMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
}
