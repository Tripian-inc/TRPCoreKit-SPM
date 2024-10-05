//
//  TRPDeleteUserReactionServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPDeleteUserReactionServices: TRPRestServices<TRPParentJsonModel> {
    
    private let id: Int
    
    internal init(id: Int) {
        self.id = id
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.userReaction.link + "/\(id)"
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .delete
    }
    
}
