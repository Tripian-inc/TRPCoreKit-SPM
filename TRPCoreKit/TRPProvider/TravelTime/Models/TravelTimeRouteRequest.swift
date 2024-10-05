//
//  TravelTimeRouteRequest.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 17.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public struct TravelTimeRouteRequest: Codable {
    let locations: [RouteRequestLocation]
    let departureSearches : [RouteRequestDepartureSearch]?
    let arrivalSearches : [RouteRequestArrivalSearch]?
    
    enum CodingKeys: String, CodingKey {
        case locations
        case departureSearches = "departure_searches"
        case arrivalSearches = "arrival_searches"
    }
}

public struct RouteRequestLocation: Codable {
    let id: String
    let coords: TravelTimeCoord
    
    public init(id: String, coords: TravelTimeCoord) {
        self.id = id
        self.coords = coords
    }
    
    public init(id: String, lat: Float, lng: Float) {
        self.id = id
        self.coords = TravelTimeCoord(lat: lat, lng: lng)
    }
}

public struct TravelTimeCoord: Codable {
    public let lat: Float
    public let lng: Float
    
    public init(lat: Float, lng: Float) {
        self.lat = lat
        self.lng = lng
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decode(Float.self, forKey: .lat)
        self.lng = try container.decode(Float.self, forKey: .lng)
    }
}

///departure_searches
public struct RouteRequestDepartureSearch: Codable {
    let id: String
    let departureLocationId: String
    let arrivalLocationIds: [String]
    let transportation: RouteRequestSearchTransportation
    let departureTime: String?
    let properties: [String]?
    let range: RouteRequestSearchRange?
    
    enum CodingKeys: String, CodingKey {
        case id
        case departureLocationId = "departure_location_id"
        case arrivalLocationIds = "arrival_location_ids"
        case transportation
        case departureTime = "departure_time"
        case properties
        case range
    }
}

public struct RouteRequestArrivalSearch: Codable {
    let id: String
    let arrivalLocationId: String
    let departureLocationIds: [String]
    let transportation: RouteRequestSearchTransportation
    let arrivalTime: String?
    let properties: String?
    let range: RouteRequestSearchRange?
    
    enum CodingKeys: String, CodingKey {
        case id
        case arrivalLocationId = "arrival_location_id"
        case departureLocationIds = "departure_location_ids"
        case transportation
        case arrivalTime = "arrival_time"
        case properties
        case range
    }
}

public struct RouteRequestSearchTransportation: Codable {
    let type: String
}

public struct RouteRequestSearchRange: Codable {
    let enabled: Bool
    let maxResults: Int
    let width: Int
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case maxResults = "max_results"
        case width
    }
}
