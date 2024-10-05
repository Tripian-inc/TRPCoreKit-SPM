//
//  FavoriteLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FavoriteLocalStorage {
    func fetchLocalPoi(completion: @escaping (FavoriteResultsValue) -> Void)
    
    func saveFavorites(cityId: String, data: [TRPFavorite])
}
