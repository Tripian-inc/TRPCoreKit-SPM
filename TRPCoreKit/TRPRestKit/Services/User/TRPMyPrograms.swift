//
//  TRPMyPrograms.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPUserTripsServices: TRPRestServices<TRPGenericParser<[TRPUserTripInfoModel]>> {
    
    public var limit: Int = 50
   
    private var from: String?
    private var to: String?
    
    init(from: String? = nil, to:String? = nil) {
        self.from = from
        self.to = to
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    override func parameters() -> [String: Any]? {
        var parameters = [String: Any]()
        if let from = from {
            parameters["dateFrom"] = from
        }
        if let to = to {
            parameters["dateTo"] = to
        }
        parameters["limit"] = limit
        return parameters
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.userTrips.link
    }
    
}
