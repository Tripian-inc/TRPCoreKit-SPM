//
//  TRPOptedInOfferJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPOptInOfferJsonModel: TRPParentJsonModel {
    
    /// User data
    public var data: [TRPPoiInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let models = try? values.decodeIfPresent([TRPPoiInfoModel].self, forKey: .data) {
            self.data = models
        } else if let model = try? values.decodeIfPresent(TRPPoiInfoModel.self, forKey: .data), let data = [model] as? [TRPPoiInfoModel] {
            self.data = data
        }
        
        // Yukarıdaki mekanizma throws özelliğini kapatıyor.
        // Eğer json yapısında bir sorun varsa burası yakalasın diye ekledim.
        if self.data == nil {
            self.data = try values.decodeIfPresent([TRPPoiInfoModel].self, forKey: .data)
        }
        try super.init(from: decoder)
    }
}
