//
//  TRPAddUserReservationServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPAddUpadateUserReservationServices: TRPRestServices<TRPGenericParser<TRPReservationInfoModel>> {
    
    private(set) var key: String
    private(set) var provider: String
    var tripHash: String?
    var poiId: String?
    var value: [String: Any]?
    var reservationId: Int?
    
    init(key: String, provider: String, tripHash: String? = nil, poiId: String? = nil, value: [String: Any]? = nil) {
        self.key = key
        self.provider = provider
        self.tripHash = tripHash
        self.poiId = poiId
        self.value = value
    }
    
    init(reservationId: Int, key: String, provider: String, tripHash: String? = nil, poiId: String? = nil, value: [String: Any]? = nil) {
        self.reservationId = reservationId
        self.key = key
        self.provider = provider
        self.tripHash = tripHash
        self.poiId = poiId
        self.value = value
    }
    
    public override func path() -> String {
        
        var url = TRPConfig.ApiCall.userReservation.link
        
        if let reservationId = reservationId {
            url += "/\(reservationId)"
        }
        
        return url
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        if reservationId != nil {
            return .put
        }
        return .post
    }
    
    override func bodyParameters() -> [String: Any]? {
        var params = [String: Any]()
        params["key"] = key
        params["provider"] = provider
        
        if let tripHash = tripHash {
            params["tripHash"] = tripHash
        }
        
        if let poiId = poiId {
            params["poiId"] = poiId
        }
        
        if let value = value {
            params["value"] = value
        }
        return params
    }
    
}
