//
//  FavoriteRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias FavoriteResultsValue = (Result<[TRPFavorite], Error>)

public typealias FavoriteResultValue = (Result<TRPFavorite, Error>)

public typealias FavoriteResultStatus = (Result<Bool, Error>)

public typealias FavoriteNew = (Result<Bool, Error>) -> Void

/// Kullanıcıların Favori mekanlarını kontrol eden Repository
public protocol FavoriteRepository {

    //Tum favorileri mekanların idlerini tutar ve observabledır.
    var results: ValueObserver<[TRPFavorite]> {get set}
    
    //Oluşan oluşan hataları yayınlayan observable yapıdır.
    var error: ValueObserver<Error> {get set}
    
    
    /// Kullanıcının referans şehirde bulanan favorilerini getiri.
    /// - Parameter cityId: CityId
    func fetchFavorites(cityId: Int,
                        completion: @escaping (FavoriteResultsValue) -> Void)
    
    
    /// Kullanıcıya yeni favori mekan ekler
    /// - Parameter placeId: PlaceId
    func addFavorite(poiId: String,
                     completion: @escaping (FavoriteResultValue) -> Void)
    
    
    /// Kullanıcıdan var ise mevcur favori mekanını siler
    /// - Parameter placeId: Place Id
    func removeFavorite(favoriteId: Int,
                        completion: @escaping (FavoriteResultStatus) -> Void)
    
    
    func fetchLocalFavorites(completion: @escaping (FavoriteResultsValue) -> Void)
   
    func saveFavorites(cityId: String, data: [TRPFavorite])
    
    
}
