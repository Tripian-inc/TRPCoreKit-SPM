//
//  GYGAvailability.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct GYGAvailability: Decodable {
    public var participantsRange: GYGAvailabilityIntegerRange
    public var categories: [GYGAvailableCategory]
    public var addons: [GYGAvailableAddon]?
    public var availableDates: [GYGAvailableDate]

    enum CodingKeys: String, CodingKey {
        case participantsRange = "participants_range"
        case availableDates = "available_dates"
        case categories, addons
    }
    
    init() {
        participantsRange = GYGAvailabilityIntegerRange(min: -1, max: -1)
        categories = []
        availableDates = []
    }
}

public struct GYGAvailableCategory: Codable {
    public let ticketCategory: String
    public let name: String
    public let ageRange: GYGAvailabilityIntegerRange?
    public let independentlyBookable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case ticketCategory = "ticket_category"
        case ageRange = "age_range"
        case name
        case independentlyBookable = "independently_bookable"
    }
}

public struct GYGAvailableAddon: Codable {
    public let id: Int
    public let name: String
    public let maxQuantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case maxQuantity = "max_quantity"
    }
}

public struct GYGAvailableDate: Codable {
    public let date: String
    
    enum CodingKeys: String, CodingKey {
        case date
    }
}

public struct GYGAvailabilityIntegerRange: Codable {
    public var min: Int = -1
    public var max: Int = -1
    
    enum CodingKeys: String, CodingKey {
        case min, max
    }
}

//public struct GYGAvailability: Codable {
//    public let startTime: String
//    public let pricingID, vacancies: Int
//    public let discount: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case startTime = "start_time"
//        case pricingID = "pricing_id"
//        case vacancies, discount
//    }
//}
//
//internal class GYGAvailabilities: Decodable {
//
//    public var availabilities: [GYGAvailability]?
//
//    private enum CodingKeys: String, CodingKey {
//        case availabilities
//    }
//
//}
