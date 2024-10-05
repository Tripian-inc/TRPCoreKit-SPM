//
//  TRPTypeJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Parent Json parser model for PoiCategories
internal class TRPPoiCategories: TRPParentJsonModel {
    
    public var data: [TRPCategoryInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let datas = try? values.decodeIfPresent([TRPCategoryInfoModel].self, forKey: .data) {
            self.data = datas
        } else if let data = try? values.decodeIfPresent(TRPCategoryInfoModel.self, forKey: .data), let newAr = [data] as? [TRPCategoryInfoModel] {
            self.data = newAr
        }
        
        try super.init(from: decoder)
    }
}
