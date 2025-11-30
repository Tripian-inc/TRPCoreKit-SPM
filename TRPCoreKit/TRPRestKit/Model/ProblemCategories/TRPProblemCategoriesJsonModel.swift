//
//  TRPProblemCategoriesJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.03.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPProblemCategoriesJsonModel: TRPParentJsonModel {
    
    internal var datas: [TRPProblemCategoriesInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required internal init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        datas = try values.decodeIfPresent([TRPProblemCategoriesInfoModel].self, forKey: .data)
        try super.init(from: decoder)
    }
    
}

