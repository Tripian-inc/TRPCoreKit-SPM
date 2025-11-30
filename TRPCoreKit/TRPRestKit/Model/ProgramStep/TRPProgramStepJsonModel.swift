//
//  TRPProgramStepJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 29.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPProgramStepJsonModel: TRPParentJsonModel {
    
    internal var data: TRPStepInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required internal init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let data = ((try? values.decodeIfPresent(TRPStepInfoModel.self, forKey: .data)) as TRPStepInfoModel??) {
            self.data = data
        }
        try super.init(from: decoder)
    }
}
