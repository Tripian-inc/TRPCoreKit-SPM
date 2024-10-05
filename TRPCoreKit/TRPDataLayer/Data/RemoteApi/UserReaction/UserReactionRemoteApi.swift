//
//  UserReactionRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol UserReactionRemoteApi {
     
    func fetchUserReaction(tripHash: String, completion: @escaping (UserReactionResultsValue) -> Void)
    
    func addUserReaction(poiId: String, stepId: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void)
    
    func removeUserReaction(id: Int, completion: @escaping (UserReactionResultStatus) -> Void)
    
    func updateUserReaction(id: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void)
}
