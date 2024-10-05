//
//  TRPFavoriteUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 27.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

//TODO: TEKRAR ÇEKME İLE İLGİLİ LOGİC TARTIŞILACAK. ÇOK KOTÜ BU KISIM VE TÜM SİSTEME UYGULANACAK

/// Includes all relevant UseCases of Favorite
/// We suggest that firstly you call FetchFavoriteUseCases
public final class TRPFavoriteUseCases: ObserverController {
    
    
    private(set) var repository: FavoriteRepository
    private(set) var poiRepository: PoiRepository

    
    public init(favoriteRepository: FavoriteRepository = TRPFavoriteRepository(), poiRepository: PoiRepository = TRPPoiRepository()) {
        self.repository = favoriteRepository
        self.poiRepository = poiRepository
    }
    
    
    /// Repositorydeki result a favoriyi ekler
    /// - Parameter item: new favorite poi
    private func addFavoritesInValues(_ item: TRPFavorite) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        repository.results.value!.append(item)
    }
    
    
    /// Repsoitorydeki resultdan eğer varsa favoriyi çıkarır.
    /// - Parameter favoriteId: Favorite Id
    private func deleteFavoritesInValues(_ favoriteId: Int) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        if let index = repository.results.value!.firstIndex(where: {$0.favoriteId == favoriteId}) {
            repository.results.value!.remove(at: index)
        }
    }
    
    
    /// Repositorydeki result a favoriyi ekler
    /// - Parameter item: new favorite poi
    private func appendFavoritesInValues(_ items: [TRPFavorite]) {
        if repository.results.value == nil {
            repository.results.value = []
        }
        repository.results.value!.append(contentsOf: items)
    }
    
    
    /// Repository içinde tutulan sonucları temizler
    private func clearValuesInRepository() {
        repository.results.value = []
    }
    
    public func remove() {
        repository.results.removeObservers()
    }
    
    deinit {
        repository.results.removeObservers()
    }
    
    
}

extension TRPFavoriteUseCases: FetchFavoriteUseCase {
    
    public func executeFetchFavorites(cityId: Int, completion: ((Result<[TRPFavorite], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        clearValuesInRepository()
        if ReachabilityUseCases.shared.isOnline {
            repository.fetchFavorites(cityId: cityId) { [weak self](result) in
                switch(result) {
                case .success(let favorites):
                    self?.repository.saveFavorites(cityId: "\(cityId)", data: favorites)
                    self?.repository.results.value = favorites
                    onComplete(.success(favorites))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }else {
            repository.fetchLocalFavorites { [weak self](result) in
                switch(result) {
                case .success(let favorites):
                    self?.repository.results.value = favorites
                    onComplete(.success(favorites))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
        
    }
    
}


extension TRPFavoriteUseCases: ObserveFavoritesUseCase {
    
    public var values: ValueObserver<[TRPFavorite]> {
        return repository.results
    }
    
}

extension TRPFavoriteUseCases: AddFavoriteUseCase {
    
    public func executeAddFavorite(_ poiId: String, completion: ((Result<TRPFavorite, Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        
        //Todo: - Error döndür.
        if let favorites = values.value, favorites.contains(where: {$0.poiId == poiId}) {
            print("[Error] This place already added in favorites")
            return
        }
        repository.addFavorite(poiId: poiId) {[weak self] (result) in
            switch(result) {
            case .success(let favorite):
                self?.addFavoritesInValues(favorite)
                onComplete(.success(favorite))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
    }
    
}

extension TRPFavoriteUseCases: DeleteFavoriteUseCase {
    
    public func executeDeleteFavorite(_ poiId: String, completion: ((Result<Bool, Error>) -> Void)?){
        let onComplete = completion ?? {result in }
        guard let favorites = repository.results.value else {
            print("[Error] Favorites is nil. Place fetch all favorites for city")
            return
        }
        
        if let favorite = favorites.first(where: {$0.poiId == poiId}) {
            repository.removeFavorite(favoriteId: favorite.favoriteId) { [weak self] (result) in
                switch(result) {
                case .success(let status):
                    self?.deleteFavoritesInValues(favorite.favoriteId)
                    onComplete(.success(status))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
            
        }else {
            print("[Error] Favorite place cannot be found.")
        }
    }
    
}

extension TRPFavoriteUseCases: CheckFavoriteUseCase {
    
    public func executeCheckFavorite(_ poiId: String, completion: ((Bool) -> Void)?) {
        guard let favorites = repository.results.value else {
            print("[Error] Favorites is nil. Place fetch all favorites for city")
            return
        }
        let contaion = favorites.contains(where: {$0.poiId == poiId})
        completion?(contaion)
    }
}
