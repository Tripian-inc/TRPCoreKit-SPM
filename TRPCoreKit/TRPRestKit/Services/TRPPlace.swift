//
//  TRPPlace.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 7.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPPoiService: TRPRestServices<TRPPoiJsonModel> {
    
    //Must
    var cityId: Int?
    var coordinate: TRPLocation?
    var poiId: String?
    //Optinal
    var searchText: String?
    var placeIds: [String]?
    var mustTryIds: [Int]?
    var poiCategories: [Int]?
    var distance: Float?
    var bounds: LocationBounds?
    var limit: Int = 25
    var page: Int = 1
    
    internal override init() {}
    
    override func userOAuth() -> Bool {
        return true
    }
    
    internal init(cityId: Int) {
        self.cityId = cityId
    }
    
    internal init(poiId: String) {
        self.poiId = poiId
    }
    
    internal init(coordinate: TRPLocation) {
        self.coordinate = coordinate
    }
    
    override func parameters() -> [String: Any]? {
        return getParameters()
    }
    
    private func getParameters() -> [String: Any] {
        var params: [String: Any] = [:]
        if poiId != nil {
            return params
        }
        //City
        if let cityId = cityId {
            params["cityId"] = cityId
        }
        
        //Coordinate
        if let location = coordinate {
            params["coordinate"] = "\(location.lat),\(location.lon)"
        }
        
        if let places = placeIds, places.count > 0 {
            params["poiIds"] = places.toString()
        }
        
        if let searchText = searchText {
            params["search"] = searchText
        }

        if let bounds = bounds {
            let minLat = min(bounds.northEast.lat, bounds.southWest.lat)
            let maxLat = max(bounds.northEast.lat, bounds.southWest.lat)
            let minLng = min(bounds.northEast.lon, bounds.southWest.lon)
            let maxLng = max(bounds.northEast.lon, bounds.southWest.lon)
            params["bounds"] = "\(minLat),\(maxLat),\(minLng),\(maxLng)"
        }
        
        if let typeIds = poiCategories, typeIds.count > 0 {
            params["poiCategories"] = typeIds.toString()
        }
        
        if let mustTries = mustTryIds {
            params["mustTryIDs"] = mustTries.toString()
        }
        
        if let distance = distance {
            params["distance"] = distance
        }
        
        params["limit"] = String(limit)
        params["page"] = String(page)
        
        return params
    }
    
    public override func path() -> String {
        if poiId != nil {
           var url = TRPConfig.ApiCall.poi.link
           if let poiId = poiId {
               url += "/\(poiId)"
           }
           return url
        }
        return TRPConfig.ApiCall.poi.link
    }
    
}
