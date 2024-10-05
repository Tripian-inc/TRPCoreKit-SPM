//
//  TRPUserReactionServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPUserReactionServices: TRPRestServices<TRPGenericParser<TRPReactionModel>> {
    
    private var id: Int?
    private let stepId: Int?
    private let poiId: String?
    private var reaction: UserReactionType?
    private var comment: String?
    
    //Add Reaction
    internal init(stepId: Int, poiId: String, reaction: UserReactionType? = nil, comment: String? = nil) {
        self.stepId = stepId
        self.poiId = poiId
        self.reaction = reaction
        self.comment = comment
    }
    
    //Update Reaction
    internal init(id: Int, stepId: Int? = nil, poiId: String? = nil, reaction: UserReactionType? = nil, comment: String? = nil) {
        self.id = id
        self.stepId = stepId
        self.poiId = poiId
        self.reaction = reaction
        self.comment = comment
    }
    
    public override func path() -> String {
        var url = TRPConfig.ApiCall.userReaction.link
        if let id = id {
            url += "/\(id)"
        }
        return url
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        if id != nil {
            return .put
        }
        return .post
    }
    
    override func bodyParameters() -> [String: Any]? {
        
        var params = [String: Any]()
        if let poiId = poiId {
            params["poiId"] = poiId
        }
        if let stepId = stepId {
            params["stepId"] = stepId
        }
        if let reaction = reaction {
            params["reaction"] = reaction.rawValue
        }
        if let comment = comment {
            params["comment"] = comment
        }
        return params
    }
}
