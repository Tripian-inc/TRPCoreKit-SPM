//
//  TRPTripModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
// NOTE: - App için aktif kullanıldığı için CreateTrip yapmadım adını

/// Indicates information of a trip.
public struct TRPTripModel: Decodable {
    
    /// An Int value. Id of trip.
    public var id: Int
    /// A String value. Unique hash of trip.
    public var tripHash: String
    public var tripProfile: TRPTripProfileModel
    public var city: TRPCityInfoModel
    public var plans: [TRPPlansInfoModel]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case tripHash 
        case tripProfile
        case city
        case plans
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.tripHash = try values.decode(String.self, forKey: .tripHash)
        self.tripProfile = try values.decode(TRPTripProfileModel.self, forKey: .tripProfile)
        self.plans = try values.decodeIfPresent([TRPPlansInfoModel].self, forKey: .plans) ?? []
        self.city = try values.decode(TRPCityInfoModel.self, forKey: .city)
    }
    
}
