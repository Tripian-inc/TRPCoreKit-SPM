//
//  TasteMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit


/// Taste için model dönüşümü yapar
final class TasteMapper {
    
    func map(_ restModel: TRPTastesInfoModel) -> TRPTaste? {
        guard let restImage = restModel.image else {return nil}
        let image = ImageMapper().map(restImage)
        return TRPTaste(id: restModel.id,
                 name: restModel.name,
                 description: restModel.description,
                 image: image)
    }
    
    func map(_ restModels: [TRPTastesInfoModel]) -> [TRPTaste] {
        return restModels.compactMap{ map($0) }
    }
    
}
