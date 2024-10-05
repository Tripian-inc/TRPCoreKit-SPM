//
//  TRPMyProgramInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates information about trip to listin.
/// This model can be used in `MyTip`
public struct TRPUserTripInfoModel: Decodable {
    
    /// An Int value. Id of trip.
    public var id: Int
    
    /// A String value. Unique hash of trip.
    public var tripHash: String
    public var tripType: Int?
    
    public var tripProfile: TRPTripProfileModel
    public var city: TRPCityInfoModel
    public var cruise: TRPUserTripCruiseModel?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case tripHash
        case tripType
        case tripProfile
        case city
        case cruise
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.tripType = try values.decodeIfPresent(Int.self, forKey: .tripType)
        self.tripHash = try values.decode(String.self, forKey: .tripHash)
        self.tripProfile = try values.decode(TRPTripProfileModel.self, forKey: .tripProfile)
        self.city = try values.decode(TRPCityInfoModel.self, forKey: .city)
        self.cruise = try values.decodeIfPresent(TRPUserTripCruiseModel.self, forKey: .cruise)
    }
    
}

public struct TRPUserTripCruiseModel: Decodable {
    
    public var cruiseId: Int?
    
    public var cruiseName: String?
    
    private enum CodingKeys: String, CodingKey {
        case cruiseId
        case cruiseName
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.cruiseId = try values.decodeIfPresent(Int.self, forKey: .cruiseId)
        self.cruiseName = try values.decodeIfPresent(String.self, forKey: .cruiseName)
    }
}
