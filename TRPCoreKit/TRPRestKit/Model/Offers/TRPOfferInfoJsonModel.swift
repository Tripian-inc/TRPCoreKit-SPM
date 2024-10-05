//
//  TRPOfferInfoJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 24.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPOfferInfoJsonModel: TRPParentJsonModel {
    
    /// User data
    public var data: TRPOfferInfoModel
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decode(TRPOfferInfoModel.self, forKey: .data)
        try super.init(from: decoder)
    }
}
