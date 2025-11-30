//
//  TRPCityJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 7.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Parent Json parser model for City
internal class TRPCityJsonModel: TRPParentJsonModel {
    
    /// Cities data
    internal var data: [TRPCityInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let datas = try? values.decodeIfPresent([TRPCityInfoModel].self, forKey: .data) {
            self.data = datas
        } else if let data = try? values.decodeIfPresent(TRPCityInfoModel.self, forKey: .data), let datas =  [data] as? [TRPCityInfoModel] {
            self.data = datas
        }
        try super.init(from: decoder)
    }
    
}
