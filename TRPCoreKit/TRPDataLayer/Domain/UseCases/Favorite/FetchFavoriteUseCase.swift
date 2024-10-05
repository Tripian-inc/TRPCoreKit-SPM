//
//  FavoriteUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchFavoriteUseCase {
    
    /// Get user all favorite POI list
    /// - Parameters:
    ///   - cityId: City Id
    ///   - completion:
    func executeFetchFavorites(cityId: Int, completion: ((Result<[TRPFavorite], Error>) -> Void)? )

}



public protocol AddFavoriteUseCase {

    
    /// Add user favorite POI
    /// - Parameters:
    ///   - poiId: Place id
    ///   - completion:
    func executeAddFavorite(_ poiId: String, completion: ((Result<TRPFavorite, Error>) -> Void)?)
    
}

public protocol DeleteFavoriteUseCase {
    
    
    /// Delete user favorite POI
    /// You should called FetchFavoriteUseCase before DeleteFavoriteUseCase
    /// - Parameters:
    ///   - poiId: Place Id
    ///   - completion:
    func executeDeleteFavorite(_ poiId: String, completion: ((Result<Bool, Error>) -> Void)?)
}



public protocol ObserveFavoritesUseCase {
    
    
    /// Observe favorites list.
    /// When User fetch, add or delete favorite, observer will be changed.
    var values: ValueObserver<[TRPFavorite]> { get }

}

public protocol CheckFavoriteUseCase {
    
    /// Check POI is exist in favorite list.
    ///  You should called FetchFavoriteUseCase before CheckFavoriteUseCase
    /// - Parameters:
    ///   - poiId: Place id
    ///   - completion:
    func executeCheckFavorite(_ poiId: String, completion: ((Bool) -> Void)?)
}
