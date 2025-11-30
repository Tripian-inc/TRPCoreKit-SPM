//
//  TRPFeedbackJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 26.04.2023.
//  Copyright © 2023 Evren Yaşar. All rights reserved.
//

import Foundation

/// Parent Json parser model for City
internal class TRPFeedbackJsonModel: TRPParentJsonModel {
    
    /// Cities data
    internal var data: [TRPFeedbackInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let datas = try? values.decodeIfPresent([TRPFeedbackInfoModel].self, forKey: .data) {
            self.data = datas
        } else if let data = try? values.decodeIfPresent(TRPFeedbackInfoModel.self, forKey: .data), let datas =  [data] as? [TRPFeedbackInfoModel] {
            self.data = datas
        }
        try super.init(from: decoder)
    }
    
}
