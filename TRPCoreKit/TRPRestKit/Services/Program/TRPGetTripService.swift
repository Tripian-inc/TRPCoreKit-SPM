//
//  TRPGetTripService.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPGetTripServices: TRPRestServices<TRPGenericParser<TRPTripModel>> {
    
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
    
    override func parameters() -> [String : Any]? {
        var parameters = [String: Any]()
//        parameters["withOffers"] = "1"
        return parameters
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
}
