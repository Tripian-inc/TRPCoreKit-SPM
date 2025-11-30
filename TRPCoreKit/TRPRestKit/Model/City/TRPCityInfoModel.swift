//
//  TRPCityInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provide you to use full information of City to creating a trip
public class TRPCityInfoModel: NSObject, Decodable {
    
    /// An Int value. Unique id of a city.
    public var id: Int
    /// A String value. Name of a city
    public var name: String
    /// A TRPCoordinateModel object that refers center coordinate(lat,lon) of a city.
    public var coordinate: TRPCoordinateModel
    /// A TRPCountryJsonModel object that indicates a country information that which the city is in.
    public var country: TRPCountryJsonModel
    /// A string value that indicate a featured image of City
    public var image: TRPImageModel?
    /// A double array that indicate a boundary of City
    public var boundary: [Double] = []
    public var tastes: [TRPTastesInfoModel]?
    public var parentLocations: [TRPCityInfoModel]?
//    public var status: Bool
    public var cityDescription: String?
    public var locationType: String?
    public var parentLocationId: Int?
    public var maxTripDays: Int?
    public var displayName: String?
    public var timezone: String?
    public var isPopular: Bool = false
    public var weathers: [TRPCityWeatherModel]?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinate
        case country
        case image
        case boundary
        case mustTries
        case description
        case status
        case locationType
        case parentLocationId
        case maxTripDays
        case displayName
        case isPopular
        case timezone
        case weathers
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.image = try values.decodeIfPresent(TRPImageModel.self, forKey: .image)
        self.boundary = try values.decode([Double].self, forKey: .boundary)
        self.coordinate = try values.decode(TRPCoordinateModel.self, forKey: .coordinate)
        self.country = try values.decode(TRPCountryJsonModel.self, forKey: .country)
        if let taste = try? values.decodeIfPresent([TRPTastesInfoModel].self, forKey: .mustTries) {
            self.tastes = taste ?? []
        }
        if let weathers = try? values.decodeIfPresent([TRPCityWeatherModel].self, forKey: .weathers) {
            self.weathers = weathers ?? []
        }
//        self.status = try values.decode(Bool.self, forKey: .status)
        self.cityDescription = try values.decodeIfPresent(String.self, forKey: .description)
        self.locationType = try values.decodeIfPresent(String.self, forKey: .locationType)
        self.parentLocationId = try values.decodeIfPresent(Int.self, forKey: .parentLocationId)
        self.maxTripDays = try values.decodeIfPresent(Int.self, forKey: .maxTripDays)
        self.displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
        self.timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
        self.isPopular = try values.decodeIfPresent(Bool.self, forKey: .isPopular) ?? false
    }
    
}
