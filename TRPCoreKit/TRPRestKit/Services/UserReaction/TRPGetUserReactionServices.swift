//
//  TRPGetUserReactionServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 9.06.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPGetUserReactionServices: TRPRestServices<TRPGenericParser<[TRPReactionModel]>> {
    
    private let tripHash: String
    
    init(tripHash: String) {
        self.tripHash = tripHash
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.userReaction.link
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .get
    }
    
    override func parameters() -> [String: Any]? {
        var params = [String: Any]()
        params["tripHash"] = tripHash
        return params
    }
    
}
