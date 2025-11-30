//
//  TRPTypeJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Parent Json parser model for PoiCategories
internal class TRPPoiCategoryJsonModel: TRPParentJsonModel {
    
    /// Categories data
    public var data: TRPCategoriesInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let data = try? values.decodeIfPresent(TRPCategoriesInfoModel.self, forKey: .data) {
            self.data = data
        }
        
        try super.init(from: decoder)
    }
}
