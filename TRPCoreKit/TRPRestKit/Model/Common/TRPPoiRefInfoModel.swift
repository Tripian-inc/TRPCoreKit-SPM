//
//  TRPPoiRefInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public class TRPPoiRefInfoModel: Decodable {
    
    /// An Int value. Unique id of a city.
    public var id: Int
    public var name: String
    public var coordinate: TRPCoordinateModel?
    public var category: [TRPCategoryInfoModel]?
    public var image: TRPImageModel?
   
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinate
        case image
        case category
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.coordinate = try values.decodeIfPresent(TRPCoordinateModel.self, forKey: .coordinate)
        self.category = try values.decodeIfPresent([TRPCategoryInfoModel].self, forKey: .category)
        self.image = try values.decodeIfPresent(TRPImageModel.self, forKey: .image)
    }
    
}
