//
//  PoiParameters.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

import CoreLocation


public struct PoiParameters {
    
    var cityId: Int? = nil
    var userLocation: TRPLocation? = nil
    
    var search: String? = nil
    var poiIds: [String]? = nil
    var poiCategoies: [Int]? = nil
    var mustTryIds: [Int]? = nil
    var distance: Float? = nil
    var boundaryNorthEast: TRPLocation? = nil
    var boundarySouthWest: TRPLocation? = nil
    
    var limit: Int? = nil
    var autoPagination: Bool = false
    
    var url: String?
    
    var createdTime: Int = Int(Date().timeIntervalSince1970)
}

extension PoiParameters: Hashable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        
        //-------   City
        if let lhsCity = lhs.cityId, let rhsCity = rhs.cityId {
        
            return  lhsCity == rhsCity &&
                    lhs.poiCategoies == rhs.poiCategoies &&
                    lhs.userLocation == rhs.userLocation &&
                    lhs.search == rhs.search &&
                    lhs.poiIds == rhs.poiIds &&
                    lhs.poiCategoies == rhs.poiCategoies &&
                    lhs.distance == rhs.distance &&
                    lhs.boundaryNorthEast == rhs.boundaryNorthEast &&
                    lhs.boundarySouthWest == rhs.boundarySouthWest &&
                    lhs.limit == rhs.limit &&
                    lhs.autoPagination == rhs.autoPagination &&
                    lhs.mustTryIds == rhs.mustTryIds
        }
        
        
        
        //-------   Boundary
        
        if lhs.boundaryNorthEast != nil,  lhs.boundarySouthWest != nil,
            rhs.boundaryNorthEast != nil, rhs.boundarySouthWest != nil {
            
            
            let newOld = self.getNewParameters(lhsParams: lhs, rhsParams: rhs)
            
            let newLocations = newOld.new
            let oldLocations = newOld.old
            
            
            //let isContaion = isContainBoundary(newNE: newLocations.boundaryNorthEast!, newSW: newLocations.boundarySouthWest!, oldNE: oldLocations.boundaryNorthEast!, oldSW: oldLocations.boundarySouthWest!)
            
            
            if let lhsCategory = lhs.poiCategoies, let rhsCategory = rhs.poiCategoies { //SEARCH THİS AREA
                
                let boudryDif = distance(newLocations.boundaryNorthEast!, oldLocations.boundaryNorthEast!)
                
                if lhsCategory == rhsCategory, boudryDif < 100 {
                    return true
                }
            }
        }
        
        // -------- User Location
        if let lhsLocation = lhs.userLocation,  let rhsLocation = rhs.userLocation {
            
            let dis = distance(lhsLocation, rhsLocation)
            
            if let lhsText = lhs.search, let rhsText = rhs.search {
                if dis < 100 && lhsText.lowercased() == rhsText.lowercased() {
                    return true
                }
            }
            
        }
        
        
        if let lhsURL = lhs.url, let rhsURL = rhs.url {
            if lhsURL == rhsURL {
                return true
            }
        }
        
        return false
    }
    
    
    private static func getRadius(newNE: TRPLocation, newSW: TRPLocation, oldNE: TRPLocation, oldSW: TRPLocation) -> Double {
        let newCenter = getCenter(ne: newNE, sw: newSW)
        let oldCenter = getCenter(ne: oldNE, sw: oldSW)
        return distance(newCenter, oldCenter)
    }
    
    
    private static func distance(_ lhsLocation: TRPLocation,_ rhsLocation: TRPLocation) -> Double {
        let lhs = CLLocation(latitude: lhsLocation.lat, longitude: lhsLocation.lon)
        let rhs = CLLocation(latitude: rhsLocation.lat, longitude: rhsLocation.lon)
        return lhs.distance(from: rhs)
    }
    
    private static func isContainBoundary(newNE: TRPLocation, newSW: TRPLocation, oldNE: TRPLocation, oldSW: TRPLocation) -> Bool {
        
        let newCenter = getCenter(ne: newNE, sw: newSW)
        if oldNE.lat < newCenter.lat && newCenter.lat < oldSW.lat || oldNE.lat > newCenter.lat && newCenter.lat > oldSW.lat {
            if oldNE.lon < newCenter.lon && newCenter.lon < oldSW.lon || oldNE.lon > newCenter.lon && newCenter.lon > oldSW.lon {
                return true
            }
        }
        
        return false
    }
    
    
    private static func getCenter(ne: TRPLocation, sw: TRPLocation) -> TRPLocation {
        let lat = (ne.lat + sw.lat) / 2
        let lon = (ne.lon + sw.lon) / 2
        return TRPLocation(lat: lat, lon: lon)
    }
    
    private static func getNewParameters(lhsParams: PoiParameters, rhsParams: PoiParameters) -> (new: PoiParameters, old: PoiParameters) {
        if lhsParams.createdTime > rhsParams.createdTime {
            return (new: lhsParams, old:rhsParams)
        }
        
        return (new: rhsParams, old: lhsParams)
    }
    
    
}
