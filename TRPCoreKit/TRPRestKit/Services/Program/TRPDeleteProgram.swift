//
//  TRPDeleteProgram.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPDeleteProgram: TRPRestServices<TRPGenericParser<TRPDeleteUserTripInfo>> {
    
    var hash: String?
    
    internal override init() {}
    
    internal init(hash: String) {
        self.hash = hash
    }
    
    public override func path() -> String {
        var path = TRPConfig.ApiCall.trip.link
        if let hash = hash {
            path += "/\(hash)"
        }
        
        return path
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .delete
    }
    
}
