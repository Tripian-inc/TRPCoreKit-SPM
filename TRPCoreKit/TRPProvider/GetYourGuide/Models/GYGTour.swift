//
//  GYGTour.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 11.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGTour: Codable {
    
    public let tourID: Int
    public let tourCode: String?
    public let condLanguage: [String]?
    public let title, abstract: String?
    public let bestseller, certified: Bool?
    public let overallRating: Double?
    public let numberOfRatings: Int?
    public let pictures: [GYGPicture]?
//    public let coordinates: GYGCoordinates?
    public let price: GYGPrice?
    public let categories: [GYGCategory]?
    public let locations: [GYGLocation]?
    public let url: String?
    public let durations: [GYGDuration]?
    public let description: String?
    public let inclusions:  String?
    public let exclusions:  String?
    public let highlights:  [String]?
    public let cancellationText: String?
    public let additionalInformation: String?
    
    enum CodingKeys: String, CodingKey {
        case tourID = "tour_id"
        case tourCode = "tour_code"
        case condLanguage = "cond_language"
        case title, abstract, bestseller, certified
        case overallRating = "overall_rating"
        case numberOfRatings = "number_of_ratings"
        case pictures, price, categories, locations, url, durations, description,inclusions, exclusions, highlights
        case cancellationText = "cancellation_policy_text"
        case additionalInformation = "additional_information"
    }
}



// MARK: - Coordinates
public struct GYGCoordinates: Codable {
    public let lat, long: Double?
}

// MARK: - Duration
public struct GYGDuration: Codable {
    public let duration: Double?
    public let unit: String?
}



// MARK: - Location
public struct GYGLocation: Codable {
    public let locationID: Int?
    public let type: String?
    public let name, englishName: String?
    public let city: String?
    public let country: String?
    public let coordinates: GYGCoordinates?
    public let viewport: GYGViewport?

    enum CodingKeys: String, CodingKey {
        case locationID = "location_id"
        case type, name
        case englishName = "english_name"
        case city, country, coordinates, viewport
    }
}


// MARK: - Viewport
public struct GYGViewport: Codable {
    public let swLat, swLong, neLat, neLong: Double?

    enum CodingKeys: String, CodingKey {
        case swLat = "sw_lat"
        case swLong = "sw_long"
        case neLat = "ne_lat"
        case neLong = "ne_long"
    }
}

// MARK: - Picture
public struct GYGPicture: Codable {
    public let url, sslURL: String?
    public let verified: Bool?

    enum CodingKeys: String, CodingKey {
        case url
        case sslURL = "ssl_url"
        case verified
    }
}

extension GYGPicture {
    
    public func getPictureUrl() -> String {
        return self.url?.replacingOccurrences(of: "[format_id]", with: "21") ?? ""
    }
}

// MARK: - Price
public struct GYGPrice: Codable {
    public let values: GYGValues?
    public let description: String?

    enum CodingKeys: String, CodingKey {
        case values
        case description 
    }
}


// MARK: - Values
public struct GYGValues: Codable {
    public let amount: Double?
    public let special: GYGSpecial?
}

// MARK: - Special
public struct GYGSpecial: Codable {
    public let originalPrice: Double?
    public let savings: Double?

    enum CodingKeys: String, CodingKey {
        case originalPrice = "original_price"
        case savings
    }
}
