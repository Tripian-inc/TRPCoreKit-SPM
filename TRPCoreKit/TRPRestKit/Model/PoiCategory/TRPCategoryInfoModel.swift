//
//  TRPTypeInfoJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPCategoriesInfoModel: Decodable {
    public var groups: [TRPCategoryGroupModel]?
    public var categories: [TRPCategoryInfoModel]?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case groups
        case categories
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let groups = try? values.decodeIfPresent([TRPCategoryGroupModel].self, forKey: .groups) {
            self.groups = groups
        }
        if let categories = try? values.decodeIfPresent([TRPCategoryInfoModel].self, forKey: .categories) {
            self.categories = categories
        }
    }
}

/// This model provide you to use full information of poi category.
public struct TRPCategoryInfoModel: Decodable {
    
    /// An Int value. Unique id of a poi category.
    public var id: Int
    
    /// A String value. Name of a poi category.
    public var name: String
    
    /// A String value. Description of a poi category. Description can be used in search bar that is in AddPlace.
    public var isCustom: Bool?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isCustom
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.isCustom = try values.decodeIfPresent(Bool.self, forKey: .isCustom)
    }
    
}

/// This model provide you to use full information of poi category.
public struct TRPCategoryGroupModel: Decodable {
    /// A String value. Name of a poi category.
    public var name: String?
    public var categories: [TRPCategoryInfoModel]?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case name
        case categories
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decodeIfPresent(String.self, forKey: .name)
        if let categories = try? values.decodeIfPresent([TRPCategoryInfoModel].self, forKey: .categories) {
            self.categories = categories
        }
    }
    
}
