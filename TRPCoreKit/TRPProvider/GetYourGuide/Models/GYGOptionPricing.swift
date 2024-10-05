//
//  GYGOptionPricing.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct GYGPricingWithCategoryParser: Codable {
    
    public var tourOptions: [GYGOptionPricing]?
    
    private enum CodingKeys: String, CodingKey {
        case tourOptions = "tour_options"
    }
    
}


// MARK: - Pricing
public struct GYGOptionPricing: Codable {
    public let timeSlots: [PriceTimeSlots]
    public let optionId: Int
    public let nextAvailableDate: String?

    enum CodingKeys: String, CodingKey {
        case timeSlots = "time_slots"
        case nextAvailableDate = "next_available_date"
        case optionId = "option_id"
    }
}


public struct PriceTimeSlots: Codable {
    public let dateTime: String
    public let vacancies: Int
    public let unavailabilityReason: OptionPriceUnavailibilityReason?
    public let priceBreakdown: OptionPriceBreakdown?
    
    enum CodingKeys: String, CodingKey {
        case dateTime = "date_time"
        case vacancies
        case unavailabilityReason = "unavailability_reason"
        case priceBreakdown = "price_breakdown"
    }
}

public struct OptionPriceUnavailibilityReason: Codable {
    public let reasonGroup: String
    
    enum CodingKeys: String, CodingKey {
        case reasonGroup = "reason_group"
    }
}

public struct OptionPriceBreakdown: Codable {
    public let individuals: [OptionPriceBreakdownIndividual]?
    public let groups: [OptionPriceBreakdownGroup]?
    public let addons: [OptionPriceBreakdownAddonBreakdown]?
    public let priceSummary: OptionPriceBreakdownPriceSummary
    
    enum CodingKeys: String, CodingKey {
        case individuals
        case groups
        case addons
        case priceSummary = "price_summary"
    }
}

public struct OptionPriceBreakdownIndividual: Codable {
    public let categoryId: Int
    public let quantity: Int
    public let price: PriceBreakdownPrice
    public let ticketCategory: String
    public let minAge: Int?
    public let maxAge: Int?
    public let independentlyBookable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case quantity
        case price
        case ticketCategory = "ticket_category"
        case minAge = "min_age"
        case maxAge = "max_age"
        case independentlyBookable = "independently_bookable"
    }
}

public struct OptionPriceBreakdownGroup: Codable {
    public let categoryId: Int
    public let groupBreakdown: OptionPriceBreakdownGroupBreakdown
    public let additionalPaxBreakdown: OptionPriceBreakdownAdditionalPaxBreakdown?
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case groupBreakdown = "group_breakdown"
        case additionalPaxBreakdown = "additional_pax_breakdown"
    }
}

public struct OptionPriceBreakdownGroupBreakdown: Codable {
    public let quantity: Int
    public let price: PriceBreakdownPrice
    public let maxGroupSize: Int?
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case price
        case maxGroupSize = "max_group_size"
    }
}

public struct OptionPriceBreakdownAdditionalPaxBreakdown: Codable {
    public let quantity: Int
    public let price: PriceBreakdownPrice
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case price
    }
}

public struct PriceBreakdownPrice: Codable {
    public let currency: String
    public let retailPrice: Double
    public let customerBasePrice: Double?

    enum CodingKeys: String, CodingKey {
        case currency
        case customerBasePrice = "customer_base_price"
        case retailPrice = "retail_price"
    }
}

public struct OptionPriceBreakdownAddonBreakdown: Codable {
    public let categoryId: Int
    public let quantity: Int
    public let price: PriceBreakdownPrice
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case quantity
        case price
    }
}

public struct OptionPriceBreakdownPriceSummary: Codable {
    public let currency: String
    public let retailPrice: Double

    enum CodingKeys: String, CodingKey {
        case currency
        case retailPrice = "retail_price"
    }
}

//// MARK: - Pricing
//public struct GYGOptionPricing: Codable {
//    public let categories: [PricingCategory]
//    public let pricingID, totalMinimumParticipants: Int
//
//    enum CodingKeys: String, CodingKey {
//        case categories
//        case pricingID = "pricing_id"
//        case totalMinimumParticipants = "total_minimum_participants"
//    }
//}

//// MARK: - Category
//public struct PricingCategory: Codable {
//    public let maxAge: Int?
//    public let addon: Bool
//    public let scale: [PricingScale]
//    public let id: Int
//    public let standAlone: Bool
//    public let name: String
//    public let minAge: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case maxAge = "max_age"
//        case addon, scale, id
//        case standAlone = "stand_alone"
//        case name
//        case minAge = "min_age"
//    }
//}

//// MARK: - Scale
//public struct PricingScale: Codable {
//    public let type: String
//    public let minParticipants, maxParticipants: Int?
//    public let retailPrice, netPrice: Double?
//
//    enum CodingKeys: String, CodingKey {
//        case type
//        case minParticipants = "min_participants"
//        case maxParticipants = "max_participants"
//        case retailPrice = "retail_price"
//        case netPrice = "net_price"
//    }
//}
