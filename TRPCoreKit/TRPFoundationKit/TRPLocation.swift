//
//  TRPLocation.swift
//  TRPFoundationKit
//
//  Created by Evren Yaşar on 13.12.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

@objc public class TRPLocation:NSObject, Codable {
    
    public var lat: Double;
    public var lon: Double;
    
    public init(lat:Double, lon:Double) {
        self.lat = lat;
        self.lon = lon;
    }
    
    enum CodingKeys: String, CodingKey {
        case lat
        case lon = "lng"
    }
    
    public func prnt() -> Void {
        print("Lat \(lat) Lon: \(lon)")
    }
    
    public func json() -> [String: Any] {
        return ["lat": lat, "lng": lon]
    }
    
}
