//
//  TRPUserReservationServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 14.07.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPUserReservationServices: TRPRestServices<TRPGenericParser<[TRPReservationInfoModel]>> {
    
    var cityId: Int?
    var tripHash: String?
    var poiId: String?
    var from: String?
    var to: String?
    var provider: String?
    var limit: Int?
    
    public override func path() -> String {
        let url = TRPConfig.ApiCall.userReservation.link
        
        return url
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .get
    }
    
    override func parameters() -> [String: Any]? {
        var params = [String: Any]()
        
        if let cityId = cityId {
            params["cityId"] = cityId
        }
        
        if let tripHash = tripHash {
            params["tripHash"] = tripHash
        }
        
        if let poiId = poiId {
            params["poiId"] = poiId
        }
        
        if let from = from {
            params["dateFrom"] = from
        }
        
        if let mto = to {
            params["dateTo"] = mto
        }
        
        if let provider = provider {
            params["provider"] = provider
        }
        
        if let limit = limit {
            params["limit"] = limit
        }
    
        return params
    }
    
}
