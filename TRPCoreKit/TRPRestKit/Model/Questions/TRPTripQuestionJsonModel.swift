//
//  TRPQuestionJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 23.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
/// Parent Json parser model for TripQuestion
internal class TRPQuestionJsonModel: TRPParentJsonModel {
    
    /// Question datas.
    public var data: [TRPQuestionInfoModel]?
    
    private enum CodingKeys: String, CodingKey { case data }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let datas = try? values.decodeIfPresent([TRPQuestionInfoModel].self, forKey: .data) {
            self.data = datas
        } else if let mdata = try? values.decodeIfPresent(TRPQuestionInfoModel.self, forKey: .data), let convertedData = [mdata] as? [TRPQuestionInfoModel] {
            self.data = convertedData
        }
        
        try super.init(from: decoder)
    }
    
}
