//
//  TRPCity.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPCity: Codable {
    
    public var id: Int
    public var name: String
    public var displayName: String? = ""
    public var coordinate: TRPLocation
    public var image: String? = ""
    public var countryCode: String = ""
    public var countryName: String = ""
    public var continent: TRPContinent?
    public var countryContinents = [String]()
    public var boundaryNorthEast: TRPLocation?
    public var boundarySouthWest: TRPLocation?
    public var tastes: [TRPTaste] = []
    public var locationType: String = ""
    public var maxTripDays: Int = 13
    public var parentLocationId: Int? = 0
    public var parentLocations: [TRPCity] = []
    public var isPopular: Bool = false
    public var timezone: String? = ""
    public var weathers: [TRPCityWeather]?
//    public var parentCityName: String = ""
    
    init(id: Int,
         name: String,
         coordinate: TRPLocation) {
        
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
}

public struct TRPCityWeather: Codable {
    
    public var date: String?
    public var maxTempC: Double?
    public var minTempC: Double?
    public var maxTempF: Double?
    public var minTempF: Double?
    public var weatherIcon: String?
    public var weatherText: String?
}

public struct TRPContinent: Codable {
    public var name: String?
    public var slug: String?
}
