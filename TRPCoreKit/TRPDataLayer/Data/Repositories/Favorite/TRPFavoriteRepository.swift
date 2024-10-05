//
//  TRPFavoriteRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 20.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final public class TRPFavoriteRepository: FavoriteRepository {
    
    public var results: ValueObserver<[TRPFavorite]> = .init([])
    
    public var error: ValueObserver<Error> = .init(nil)
    
    public var remoteApi: FavoriteRemoteApi
    
    public var localStorage: FavoriteLocalStorage
    
    public init(remoteApi: FavoriteRemoteApi = TRPFavoriteRemoveApi(),
                localStorage: FavoriteLocalStorage = TRPFavoriteLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchFavorites(cityId: Int, completion: @escaping (FavoriteResultsValue) -> Void) {
        //Local Storage eklenecek
        remoteApi.fetchFavorites(cityId: cityId, completion: completion)
    }
    
    public func addFavorite(poiId: String, completion: @escaping (FavoriteResultValue) -> Void) {
        //Local Storage eklenecek
        remoteApi.addFavorite(poiId: poiId, completion: completion)
    }
    
    public func removeFavorite(favoriteId: Int, completion: @escaping (FavoriteResultStatus) -> Void) {
        //Local Storage eklenecek
        remoteApi.removeFavorite(favoriteId: favoriteId, completion: completion)
    }
    
    public func fetchLocalFavorites(completion: @escaping (FavoriteResultsValue) -> Void) {
        localStorage.fetchLocalPoi(completion: completion)
    }
    
    public func saveFavorites(cityId: String, data: [TRPFavorite]) {
        localStorage.saveFavorites(cityId: cityId, data: data)
    }
}




