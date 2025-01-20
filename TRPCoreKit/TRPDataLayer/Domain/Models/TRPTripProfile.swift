//
//  TRPTripProfile.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation



public class TRPTripProfile: Codable {

    public var cityId: Int
    
    public var arrivalDate: TRPTime?
    public var departureDate: TRPTime?
    public var numberOfAdults: Int = 1
    public var numberOfChildren: Int = 0
    //Trip sorularına verilen cevaplar
    public var tripAnswers: [Int]?
    public var tripAnswersExploreText: [String]?
    //Profile sorularına verilen cevaplar
    public var profileAnswers: [Int]?
    //Tum soruların cevapları. Api dan döner
    public var allAnswers: [Int]?
    
    public var accommodation: TRPAccommodation?
    public var companionIds = [Int]()
    public var pace: TRPPace = .normal
    
    public var theme: TRPPreGeneratedTheme? = .noTheme
    
    public var excludeHash: [String]?
    
    public var withOffers: Bool = true
    
    public var additionalData: String? = nil
    
    /// Create a Trip
    /// - Parameter cityId: CityId
    public init(cityId: Int) {
        self.cityId = cityId
    }
    
    public func getTotalPeopleCount() -> Int {
        let count = numberOfAdults + numberOfChildren + companionIds.count
        return count
    }
    
    public func getDateRange() -> String {
        if let arrivalDate = arrivalDate?.toDate?.toString(format:"MMM dd.yyyy", locale: TRPClient.shared.language),
           let departureDate = departureDate?.toDate?.toString(format:"MMM dd.yyyy", locale: TRPClient.shared.language) {
            return "\(arrivalDate) - \(departureDate)"
        }
        return ""
    }
 
}



public class TRPEditTripProfile: TRPTripProfile {
    
    public var tripHash: String = ""
    public var doNotGenerate: Bool = false
    
    public init(cityId: Int, tripHash: String) {
        self.tripHash = tripHash
        super.init(cityId: cityId)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}


