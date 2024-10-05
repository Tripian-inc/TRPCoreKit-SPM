//
//  NearByJsonInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 29.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates alternative of the plan poi.
public struct TRPStepAlternativeInfoModel: Decodable {
    
    /// An Int value. Id of Alternative
    public var id: Int

    public var name: String
    
    public var image: TRPImageModel
    
    public var markerCoordinate: TRPCoordinateModel
    
    public var category: TRPCategoryInfoModel

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case markerCoordinate = "marker_coordinate"
        case category
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        image = try values.decode(TRPImageModel.self, forKey: .image)
        markerCoordinate = try values.decode(TRPCoordinateModel.self, forKey: .markerCoordinate)
        category = try values.decode(TRPCategoryInfoModel.self, forKey: .category)
    }
    
}
