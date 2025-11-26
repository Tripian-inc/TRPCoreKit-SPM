//
//  TRPFavoriteRemoveApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final public class TRPFavoriteRemoveApi: FavoriteRemoteApi {
    
    public init() {}
    
    public func fetchFavorites(cityId: Int, completion: @escaping (FavoriteResultsValue) -> Void) {
        TRPRestKit().getUserFavorite(cityId: cityId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPFavoritesInfoModel] {
                let convertedModel = FavoriteMapper().map(result)
                completion(.success(convertedModel))
            }
        }
    }
    
    public func addFavorite(poiId: String, completion: @escaping (FavoriteResultValue) -> Void) {
    
        TRPRestKit().addUserFavorite(poiId: poiId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPFavoritesInfoModel {
                let convertedModel = FavoriteMapper().map(result)
                completion(.success(convertedModel))
            }
        }
    }
    
    public func removeFavorite(favoriteId: Int, completion: @escaping (FavoriteResultStatus) -> Void) {
        TRPRestKit().deleteUserFavorite(favoriteId: favoriteId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let _ = result as? TRPParentJsonModel {
                completion(.success(true))
            }
        }
    }

}
