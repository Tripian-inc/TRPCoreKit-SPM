//
//  TRPFavoriteLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class TRPFavoriteLocalStorage: FavoriteLocalStorage {
    
    private(set) var file = FileIO.shared
    
    public init() {}
    
    public func fetchLocalPoi(completion: @escaping (FavoriteResultsValue) -> Void) {
        do {
            let city = CruiseDataHolderUseCase.shared.cityId ?? 0
            let json = try file.read([TRPFavorite].self, "city_favorite_\(city)", false)
            completion(.success(json))
        }catch let error {
            completion(.failure(error))
        }
    }
    
    public func saveFavorites(cityId: String, data: [TRPFavorite]) {
        do {
            let fileName = "city_favorite_\(cityId)"
            try file.write(data, fileName)
        }catch let _error {
            print("[ERROR] \(_error)")
        }
    }
}
