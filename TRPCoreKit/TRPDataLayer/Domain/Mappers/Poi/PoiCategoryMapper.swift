//
//  PoiCategoryMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.02.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class PoiCategoryMapper {
    
    func map(_ restModel: TRPCategoriesInfoModel) -> [TRPPoiCategoyGroup] {
        
        return restModel.groups?.compactMap { map($0) } ?? []
    }
    
    func map(_ restModel: TRPCategoryGroupModel) -> TRPPoiCategoyGroup {
        return TRPPoiCategoyGroup(name: restModel.name, categories: restModel.categories?.compactMap {map($0)})
    }
    
    func map(_ restModels: [TRPCategoryInfoModel]) -> [TRPPoiCategory] {
        return restModels.compactMap { map($0)}
    }
    
    func map(_ restModel: TRPCategoryInfoModel) -> TRPPoiCategory {
        return TRPPoiCategory(id: restModel.id, name: restModel.name, isCustom: restModel.isCustom)
    }
    
}
