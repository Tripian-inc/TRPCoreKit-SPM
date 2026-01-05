//
//  FavoriteMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

/// Favorite için model dönüşümü yapar
final class FavoriteMapper {
    
    func map(_ restModel: TRPFavoritesInfoModel) -> TRPFavorite {
        return TRPFavorite(favoriteId: restModel.id, poiId: restModel.poiId)
    }
    
    func map(_ restModels: [TRPFavoritesInfoModel]) -> [TRPFavorite] {
        return restModels.compactMap{ map($0) }
    }
    
}
