//
//  FavoriteRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FavoriteRemoteApi {
        
    func fetchFavorites(cityId: Int, completion: @escaping (FavoriteResultsValue) -> Void)
    
    func addFavorite(poiId: String, completion: @escaping (FavoriteResultValue) -> Void)
    
    func removeFavorite(favoriteId: Int, completion: @escaping (FavoriteResultStatus) -> Void)
}
