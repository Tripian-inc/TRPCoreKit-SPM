//
//  TRPGetProgramJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates parameters used when creating a trip.

public struct TRPTripProfileModel: Decodable {
    
    /// An Int value. Id of city.
    public var cityId: Int
    /// A String value. Arrival date of trip.
    public var arrivalDateTime: TRPTime?
    /// A String value. Departure date of trip.
    public var departureDateTime: TRPTime?
    
    /// An Int value. Adult count.
    public var numberOfAdults: Int
    /// An Int value. Count of Children
    public var numberOfChildren: Int?
    /// A String value. Answer of questions.You must convert to Array.
    public var answers = [Int]()
    public var owner: String?
    
    /// A String value. Address of hotel.
    public var accommodation: TRPAccommodationInfoModel?
    /// A String value. Companion of users for the selected trip.You must convert to Array.
    public var companionIds = [Int]()
    //TODO: - Pace Enum haline getirilecek
    public var pace: String?

    public var doNotGenerate: Int
    
    public var theme: String?
    public var excludeHash: [String]?
    public var additionalData: String?
    
    private enum CodingKeys: String, CodingKey {
        case cityId 
        case arrivalDateTime = "arrivalDatetime"
        case departureDateTime = "departureDatetime"
        case numberOfAdults
        case numberOfChildren
        case answers
        case owner
        case accommodation = "accommodation"
        case companionIds
        case pace
        case doNotGenerate
        case theme
        case excludeHash
        case additionalData
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cityId = try values.decode(Int.self, forKey: .cityId)
        let arrivalDT = try values.decode(String.self, forKey: .arrivalDateTime)
        let departureDT = try values.decode(String.self, forKey: .departureDateTime)
       
        if let arrival = TRPTime(dateTime: arrivalDT), let departure = TRPTime(dateTime: departureDT) {
            arrivalDateTime = arrival
            departureDateTime = departure
        }
        
        numberOfAdults = try values.decode(Int.self, forKey: .numberOfAdults)
        numberOfChildren = try values.decodeIfPresent(Int.self, forKey: .numberOfChildren)
    
        if let accommondation = try? values.decodeIfPresent(TRPAccommodationInfoModel.self, forKey: .accommodation) {
            self.accommodation = accommondation
        }
        
        self.answers = try values.decode([Int].self, forKey: .answers)
        self.owner = try values.decodeIfPresent(String.self, forKey: .owner)
        self.companionIds = try values.decode([Int].self, forKey: .companionIds)
        self.pace = try values.decodeIfPresent(String.self, forKey: .pace)
        self.doNotGenerate = try values.decode(Int.self, forKey: .doNotGenerate)
        self.theme = try values.decodeIfPresent(String.self, forKey: .theme)
        self.excludeHash = try values.decodeIfPresent([String].self, forKey: .excludeHash)
        self.additionalData = try values.decodeIfPresent(String.self, forKey: .additionalData)
    }

}

public struct TRPAccommodationInfoModel: Decodable {
    
    public var name: String?
    public var referanceId: String?
    public var address: String?
    public var coordinate: TRPCoordinateModel
    
    private enum CodingKeys: String, CodingKey {
        case name
        case refId = "refID"
        case address
        case coordinate
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.coordinate = try values.decode(TRPCoordinateModel.self, forKey: .coordinate)
        self.name = try values.decodeIfPresent(String.self, forKey: .name)
        self.referanceId = try values.decodeIfPresent(String.self, forKey: .refId)
        self.address = try values.decodeIfPresent(String.self, forKey: .address)
    }
}
