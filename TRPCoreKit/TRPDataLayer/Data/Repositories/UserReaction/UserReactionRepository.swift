//
//  UserReactionRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias UserReactionResultsValue = (Result<[TRPUserReaction], Error>)

public typealias UserReactionResultValue = (Result<TRPUserReaction, Error>)

public typealias UserReactionResultStatus = (Result<Bool, Error>)


public protocol UserReactionRepository {
     
    var results: ValueObserver<[TRPUserReaction]> {get set}
    
    func fetchUserReaction(tripHash: String, completion: @escaping (UserReactionResultsValue) -> Void)
    
    func addUserReaction(poiId: String, stepId: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void)
    
    func removeUserReaction(id: Int, completion: @escaping (UserReactionResultStatus) -> Void)
    
    func updateUserReaction(id: Int, reaction: TRPUserReactionType?, comment: String?, completion: @escaping (UserReactionResultValue) -> Void)
}
