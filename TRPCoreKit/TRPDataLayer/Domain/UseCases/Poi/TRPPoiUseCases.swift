//
//  TRPPoiUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// Category types for POI listing filtering
public enum POIListingCategoryType: String {
    case placesOfInterest = "places_of_interest"
    case eatAndDrink = "eat_and_drink"
}

final public class TRPPoiUseCases {

    // MARK: - Singleton for Category Management
    public static let shared = TRPPoiUseCases()

    private(set) var poiRepository: PoiRepository
    public var cityId: Int?

    // MARK: - Cached Categories
    private static var cachedCategoryGroups: [TRPPoiCategoyGroup] = []
    private static var cachedEatAndDrinkCategoryIds: Set<Int> = []
    private static var cachedPlacesOfInterestCategoryIds: Set<Int> = []
    private static var isCategoriesFetched: Bool = false

    public init(repository: PoiRepository = TRPPoiRepository()){
        self.poiRepository = repository
    }

    // MARK: - Category Prefetch (Call at App Startup)

    /// Prefetches POI categories in background. Call this at app startup.
    public static func prefetchCategories() {
        guard !isCategoriesFetched else { return }

        // Use shared instance to prevent deallocation before completion
        shared.executeFetchPoiCategories { result in
            switch result {
            case .success(let groups):
                processCategoryGroups(groups)
            case .failure:
                // Silent failure - will retry when needed
                break
            }
        }
    }

    /// Process and cache category groups
    private static func processCategoryGroups(_ groups: [TRPPoiCategoyGroup]) {
        cachedCategoryGroups = groups

        var eatAndDrinkIds = Set<Int>()
        var placesOfInterestIds = Set<Int>()

        for group in groups {
            guard let categories = group.categories else { continue }

            let categoryIds = categories.getIds()

            // Check if this group contains any Eat & Drink group ID (3, 4, 24)
            let isEatAndDrinkGroup = categoryIds.contains { TRPPoiCategoyGroup.eatAndDrinkGroupIds.contains($0) }

            if isEatAndDrinkGroup {
                eatAndDrinkIds.formUnion(categoryIds)
            } else {
                placesOfInterestIds.formUnion(categoryIds)
            }
        }

        cachedEatAndDrinkCategoryIds = eatAndDrinkIds
        cachedPlacesOfInterestCategoryIds = placesOfInterestIds

        // Also update TRPPoiCategoyGroup cache for backward compatibility
        TRPPoiCategoyGroup.cachedEatAndDrinkCategoryIds = eatAndDrinkIds

        isCategoriesFetched = true
    }

    // MARK: - Category Accessors

    /// Returns cached category groups. Empty if not yet fetched.
    public static func getCategoryGroups() -> [TRPPoiCategoyGroup] {
        return cachedCategoryGroups
    }

    /// Returns all category IDs for Eat & Drink (restaurants, cafes, nightlife, etc.)
    public static func getEatAndDrinkCategoryIds() -> [Int] {
        return Array(cachedEatAndDrinkCategoryIds)
    }

    /// Returns all category IDs for Places of Interest (museums, attractions, etc.)
    public static func getPlacesOfInterestCategoryIds() -> [Int] {
        return Array(cachedPlacesOfInterestCategoryIds)
    }

    /// Checks if a category ID belongs to Eat & Drink
    public static func isEatAndDrinkCategory(_ categoryId: Int) -> Bool {
        return cachedEatAndDrinkCategoryIds.contains(categoryId)
    }

    /// Checks if a category ID belongs to Places of Interest
    public static func isPlacesOfInterestCategory(_ categoryId: Int) -> Bool {
        return cachedPlacesOfInterestCategoryIds.contains(categoryId)
    }

    /// Returns true if categories have been fetched and cached
    public static func areCategoriesCached() -> Bool {
        return isCategoriesFetched
    }

    /// Fetch categories if not already cached, then call completion with requested type
    public func fetchCategoryIdsIfNeeded(
        type: POIListingCategoryType,
        completion: @escaping ([Int]) -> Void
    ) {
        if TRPPoiUseCases.isCategoriesFetched {
            let ids = type == .eatAndDrink
                ? TRPPoiUseCases.getEatAndDrinkCategoryIds()
                : TRPPoiUseCases.getPlacesOfInterestCategoryIds()
            completion(ids)
            return
        }

        executeFetchPoiCategories { result in
            switch result {
            case .success(let groups):
                TRPPoiUseCases.processCategoryGroups(groups)
                let ids = type == .eatAndDrink
                    ? TRPPoiUseCases.getEatAndDrinkCategoryIds()
                    : TRPPoiUseCases.getPlacesOfInterestCategoryIds()
                completion(ids)
            case .failure:
                completion([])
            }
        }
    }

}

extension TRPPoiUseCases: SearchPoiUseCase {
    //TODO: - OFFLİNE //Kullanılmıyor olabilir
    public func executeSearchPoi(text: String,
                                 categoies: [Int],
                                 boundaryNorthEast: TRPLocation,
                                 boundarySouthWest: TRPLocation,
                                 completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                                ) {
        
        guard let cityId = cityId else {
            completion?(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }
        
        
        let onComplete = completion ?? { result, pagination in }
        
        let params = PoiParameters(search: text, poiCategoies: categoies, boundaryNorthEast: boundaryNorthEast, boundarySouthWest: boundarySouthWest)
        
        poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
            
            switch result {
            case .success(let result):
                onComplete(.success(result), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
    }
    
    public func executeSearchPoi(text: String,
                                 categoies: [Int],
                                 userLocation: TRPLocation,
                                 completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {

        let onComplete = completion ?? { result, pagination in }

        if ReachabilityUseCases.shared.isOnline {
            var params = PoiParameters(search: text)
            params.cityId = cityId
            params.poiCategoies = categoies
            params.distance = 50
            poiRepository.fetchPoi(coordinate: userLocation, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            poiRepository.fetchLocalPoi { result, pagination in
                switch result {
                case .success(let result):
                    let filteredData = result.filter { pois in
                        var isContaine = false
                        for cat in pois.categories {
                            if categoies.contains(cat.id) {
                                isContaine = true
                            }
                        }
                        return isContaine
                    }

                    let textFilter = filteredData.filter { poi in
                        if poi.name.contains(text) {
                            return true
                        }
                        return false
                    }
                    onComplete(.success(textFilter), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        }
    }

    public func executeSearchPoi(text: String,
                                 categories: [Int],
                                 cityId: Int,
                                 completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        executeSearchPoi(text: text, categories: categories, cityId: cityId, page: nil, completion: completion)
    }

    public func executeSearchPoi(text: String,
                                 categories: [Int],
                                 cityId: Int,
                                 page: Int?,
                                 completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {

        let onComplete = completion ?? { result, pagination in }

        if ReachabilityUseCases.shared.isOnline {
            var params = PoiParameters(search: text)
            params.cityId = cityId
            params.poiCategoies = categories
            params.page = page

            poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            poiRepository.fetchLocalPoi { result, pagination in
                switch result {
                case .success(let result):
                    let filteredData = result.filter { pois in
                        var isContaine = false
                        for cat in pois.categories {
                            if categories.contains(cat.id) {
                                isContaine = true
                            }
                        }
                        return isContaine
                    }

                    let textFilter = filteredData.filter { poi in
                        if poi.name.lowercased().contains(text.lowercased()) {
                            return true
                        }
                        return false
                    }
                    onComplete(.success(textFilter), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        }
    }

}

extension TRPPoiUseCases: FetchPoiUseCase {
    
    public func executeFetchPoi(ids: [String], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }
        
        let params = PoiParameters(poiIds: ids)
        
        if ReachabilityUseCases.shared.isOnline {
            poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        }else {
            poiRepository.fetchLocalPoi { result, _ in
                switch result {
                case .success(let result):
                    let filteredData = result.filter { pois in
                        return ids.contains(pois.id)
                    }
                    onComplete(.success(filteredData), nil)
                case .failure(let error):
                    onComplete(.failure(error), nil)
                }
            }
        }
    }
    
    public func executeFetchPoi(id: String, completion: ((Result<TRPPoi?, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        if ReachabilityUseCases.shared.isOnline {
            poiRepository.fetchPoi(poiId: id) { result in
                switch result {
                case .success(let result):
                    onComplete(.success(result))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        } else {
            poiRepository.fetchLocalPoi { result, _ in
                switch result {
                case .success(let result):
                    let filteredData = result.first { pois in
                        return pois.id == id
                    }
                    onComplete(.success(filteredData))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
}

extension TRPPoiUseCases: FethCategoryPoisUseCase {
    
    public func executeFetchCategoryPois(categoryIds: [Int],
                                         completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }
        
        if ReachabilityUseCases.shared.isOnline {
            let params = PoiParameters(poiCategoies: categoryIds)
            poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            poiRepository.fetchLocalPoi { result, pagination in
                switch result {
                case .success(let result):
                    let filteredData = result.filter { pois in
                        var isContaine = false
                        for cat in pois.categories {
                            if categoryIds.contains(cat.id) {
                                isContaine = true
                            }
                        }
                        return isContaine
                    }
                    onComplete(.success(filteredData), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        }
    }
    
}

extension TRPPoiUseCases: FetchNearByPoiUseCase {
    
    public func executeFetchNearByPois(location: TRPLocation, categoryIds: [Int], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        let onComplete = completion ?? { result, pagination in }
    
        var params = PoiParameters(poiCategoies: categoryIds)
        params.cityId = cityId
        poiRepository.fetchPoi(coordinate: location, parameters: params) {  result, pagination in
            switch result {
            case .success(let result):
                onComplete(.success(result), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
    }
    
}



extension TRPPoiUseCases: FetchBoundsPoisUseCase {
    
    public func executeFetchNearByPois(northEast: TRPLocation, southWest: TRPLocation, categoryIds: [Int]?, completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }
        
        
        if ReachabilityUseCases.shared.isOnline {
            let params = PoiParameters(poiCategoies: categoryIds,
                                       boundaryNorthEast: northEast,
                                       boundarySouthWest: southWest)
            
            poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            poiRepository.fetchLocalPoi { result, pagination in
                switch result {
                case .success(let result):
                    
                    let filteredData = result.filter { pois in
                        var isContaine = false
                        if let catetory = categoryIds, !catetory.isEmpty {
                            for cat in pois.categories {
                                if catetory.contains(cat.id) {
                                    isContaine = true
                                }
                            }
                        }else {
                            return true
                        }
                        return isContaine
                    }
                    
                    let locationFilter = filteredData.filter { pois in
                        guard let coordinate = pois.coordinate else { return false }
                        if northEast.lat > coordinate.lat &&
                            coordinate.lat > southWest.lat &&
                            northEast.lon > coordinate.lon &&
                            coordinate.lon > southWest.lon {
                            return true
                        }
                        return false
                    }
                    
                    onComplete(.success(locationFilter), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
            
        }
    }
    
    
}

extension TRPPoiUseCases: FetchPoiNextUrlUseCase {
    
    public func executeFetchPoi(url: String, completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        let onComplete = completion ?? { result, pagination in }
        poiRepository.fetchPoi(url: url) { result, pagination in
            switch result {
            case .success(let result):
                onComplete(.success(result), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
            
        }
    }
    
}

extension TRPPoiUseCases: FetchPoiWithMustTries {
    
    //TODO: - OFFLİNE
    public func executeFetchPoiWithMustTries(ids: [Int], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }
        
        let params = PoiParameters(mustTryIds: ids)
        
        poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
            switch result {
            case .success(let result):
                onComplete(.success(result), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
    }
    
    
}

extension TRPPoiUseCases: FetchPoiCategoriesUseCase {
    
    public func executeFetchPoiCategories(completion: ((Result<[TRPPoiCategoyGroup], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        poiRepository.fetchPoiCategories { result in
            onComplete(result)
        }
    }
}
