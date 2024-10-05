//
//  TravelTimeRouteResult.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 17.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public struct TravelTimeRouteResult: Codable {
    public let results: [TravelTimeRoute]
    
}

public struct TravelTimeRoute: Codable {
    public let search_id: String
    public let locations: [TravelTimeRouteLocation]
    public let unreachable: [String]
    
    enum CodinKeys: String, CodingKey {
        case search_id = "search_id"
        case locations, unreachable
    }
}

extension TravelTimeRoute {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        search_id = try values.decode(String.self, forKey: .search_id)
        locations = try values.decode([TravelTimeRouteLocation].self, forKey: .locations)
        unreachable = try values.decode([String].self, forKey: .unreachable)

    }
}

public struct TravelTimeRouteLocation: Codable {
    public let id: String
    public let properties: [TravelTimeRouteLocationProperties]
}

public struct TravelTimeRouteLocationProperties: Codable {
    public let travel_time: Int?
    public let distance: Int?
    public let route: TravleTimeRouteLocationPropertiesRoute
    
    enum CodinKeys: String, CodingKey {
        case travelTime = "travel_time"
        case distance, parts
    }
}

public struct TravleTimeRouteLocationPropertiesRoute: Codable {
    public let departure_time: String?
    public let arrival_time: String?
    public let parts: [TravleTimeRouteLocationPropertiesRouteParts]?
    
    enum CodinKeys: String, CodingKey {
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case parts
    }
}

public struct TravleTimeRouteLocationPropertiesRouteParts: Codable {
    public let id: Int
    public let type: String
    public let mode: String
    public let directions: String
    public let distance: Int
    public let travel_time: Int
    public let coords: [TravelTimeCoord]
    public let direction: String?
    public let road: String?
    public let turn: String?
    public let line: String?
    public let departure_station: String?
    public let arrival_station: String?
    public let departs_at: String?
    public let arrives_at: String?
    public let num_stops: Int?
    
    enum CodinKeys: String, CodingKey {
        case id, type, mode, directions, distance
        case travelTime = "travel_time"
        case coords, direction, road, turn, line
        case departureStation = "departure_station"
        case arrivalStation = "arrival_station"
        case departsAt = "departs_at"
        case arrivesAt = "arrives_at"
        case numStops = "num_stops"
    }
}
