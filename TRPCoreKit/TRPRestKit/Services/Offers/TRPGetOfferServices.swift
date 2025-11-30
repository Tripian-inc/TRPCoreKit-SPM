//
//  TRPGetOfferServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 24.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPGetOfferServices: TRPRestServices<TRPGenericParser<[TRPOfferInfoModel]>> {
    
    private enum RequestType {
        case offer
        case offers
    }
    private var requestType: RequestType = .offers
    
    private var offerId: Int?
    private var dateFrom: String?
    private var dateTo: String?
    var poiIds: [String]?
    var boundary: LocationBounds?
//    var boundary: String?
    var typeId: [Int]?
    var excludeOptIn: Bool?
    var page: Int?
    var limit: Int?
    
    init(offerId: Int) {
        self.requestType = .offer
        self.offerId = offerId
    }
    init(dateFrom: String, dateTo: String) {
        self.requestType = .offers
        self.dateFrom = dateFrom
        self.dateTo = dateTo
    }
    override init() {
        self.requestType = .offers
    }

    
    public override func path() -> String {
        if requestType == .offers {
            return TRPConfig.ApiCall.offers.link
        } else {
            var url = TRPConfig.ApiCall.offers.link
            if let offerId = offerId {
                url += "/\(offerId)"
            }
            return url
        }
        
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .get
    }
    
    override func parameters() -> [String: Any]? {
        var params = [String: Any]()
        
        if let dateFrom = dateFrom {
            params["dateFrom"] = dateFrom
        }
        
        if let dateTo = dateTo {
            params["dateTo"] = dateTo
        }
        
        if let poiIds = poiIds{
            params["poiIds"] = poiIds.toString(",")
        }
        

        if let bounds = boundary {
            let minLat = min(bounds.northEast.lat, bounds.southWest.lat)
            let maxLat = max(bounds.northEast.lat, bounds.southWest.lat)
            let minLng = min(bounds.northEast.lon, bounds.southWest.lon)
            let maxLng = max(bounds.northEast.lon, bounds.southWest.lon)
            params["boundary"] = "\(minLat),\(maxLat),\(minLng),\(maxLng)"
        }
//        if let boundary = boundary {
//            params["boundary"] = boundary
//        }
        
        if let typeId = typeId {
            params["typeId"] = typeId.toString(",")
        }
        
        if let page = page {
            params["page"] = page
        }
        
        if let limit = limit {
            params["limit"] = limit
        }
        
        if let excludeOptIn = excludeOptIn {
            params["excludeOptIn"] = excludeOptIn ? 1 : 0
        }
        
        return params
    }
    
}
