//
//  TRPRecommendationSettings.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 9.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This struct provide us with necessary settings to create Quick Recommendation.
public struct TRPRecommendationSettings {
    
    /// An Int value. Id of city
    private(set) var cityId: Int?
    /// A String value. Hash of trip.
    private(set) var hash: String?
    /// A Int array. ids of Pois categories
    public var poiCategoryIds: [Int]?
    /// An Int value. Count of Adult
    public var adultsCount: Int?
    /// An Int value. Adults age range such as 32
    public var adultAgeRange: String?
    /// An Int value. Count of Children
    public var childrenCount: Int?
    /// An Int value. Children age range such as 12
    public var childrenAgeRange: String?
    /// An Int value. Center of user coordinate.
    public var currentCoordinate: String?
    /// An Int array. Options of TripQuestions.
    public var answer: [Int]?
    
    /// Initiating a setting using City Id.
    /// We suggest that you can use City id with currentCoordinate in `Localy Mode`.
    ///
    /// - Parameter cityId: City Id
    public init(cityId: Int) {
        self.cityId = cityId
    }
    
    /// Initiating a setting using hash of Trip.
    /// We suggest that you can use hash in Add Place.
    /// If you don't send other parameters such as adultCount, api takes all parameters from trip.
    ///
    /// - Parameter hash: Hash of trip
    public init(hash: String) {
        self.hash = hash
    }
    
    /// Center coordination
    ///
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lon: Longitude
    public mutating func currentCoordinate(lat: Double, lon: Double) {
        currentCoordinate = String(lat) + "," + String(lon)
    }
}
