//
//  TRPFavoritesJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 9.10.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Parent Json parser model for City
internal class TRPFavoritesJsonModel: TRPParentJsonModel {
    
    ///Favorite's list
    internal var data: [TRPFavoritesInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required internal init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let data = try? values.decodeIfPresent(TRPFavoritesInfoModel.self, forKey: .data) {
            self.data = [data] as? [TRPFavoritesInfoModel]
        } else if let datas = try? values.decodeIfPresent([TRPFavoritesInfoModel].self, forKey: .data) {
            self.data = datas
        }
        try super.init(from: decoder)
    }
    
}

/// This model provides you information of Favorites Poi.
public struct TRPFavoritesInfoModel: Decodable {
    
    public var id: Int
    
    /// An Int value. Unique id of a poi.
    public var poiId: String
    
    /// An Int value. Id of city where the poi is located.
    public var cityId: Int
    
    public var tripHash: String?
    
    private enum CodingKeys: String, CodingKey {
        case poiId = "poiId"
        case cityId = "cityId"
        case id
        case tripHash = "tripHash"
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.poiId = try values.decode(String.self, forKey: .poiId)
        self.cityId = try values.decode(Int.self, forKey: .cityId)
        self.id = try values.decode(Int.self, forKey: .id)
        self.tripHash = try values.decodeIfPresent(String.self, forKey: .tripHash)
    }
}
