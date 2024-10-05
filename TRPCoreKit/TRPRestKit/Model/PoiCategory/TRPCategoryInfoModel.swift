//
//  TRPTypeInfoJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provide you to use full information of poi category.
public struct TRPCategoryInfoModel: Decodable {
    
    /// An Int value. Unique id of a poi category.
    public var id: Int
    
    /// A String value. Name of a poi category.
    public var name: String
    
    /// A String value. Description of a poi category. Description can be used in search bar that is in AddPlace.
    public var description: String?
    
    public var parent: TRPPoiCategoryParent?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case parent
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)
        if let parent = try? values.decodeIfPresent(TRPPoiCategoryParent.self, forKey: .parent) {
            self.parent = parent
        }
    }
    
}
