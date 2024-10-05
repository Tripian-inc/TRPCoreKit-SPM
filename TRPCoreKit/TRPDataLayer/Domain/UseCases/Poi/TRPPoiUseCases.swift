//
//  TRPPoiUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation



final public class TRPPoiUseCases {
    
    private(set) var poiRepository: PoiRepository
    public var cityId: Int?
    
    
    public init(repository: PoiRepository = TRPPoiRepository()){
        self.poiRepository = repository
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
            print("[Error] City id is nil")
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
        }else {
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
    
}

enum GeneralError: Error {
    case customMessage(String)
}

extension GeneralError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .customMessage(let message):
            return message
        }
    }
}

extension TRPPoiUseCases: FetchPoiUseCase {
    
    public func executeFetchPoi(ids: [String], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        guard let cityId = cityId else {
            print("[Error] City id is nil")
            onComplete(.failure(GeneralError.customMessage("City id is nil")), nil)
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
        }else {
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
//        executeFetchPoi(ids: [id]) { result, _ in
//            switch result {
//            case .success(let pois):
//                onComplete(.success(pois.first))
//            case .failure(let error):
//                onComplete(.failure(error))
//            }
//        }
    }
    
}

extension TRPPoiUseCases: FethCategoryPoisUseCase {
    
    public func executeFetchCategoryPois(categoryIds: [Int],
                                         completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        guard let cityId = cityId else {
            print("[Error] City id is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
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
        }else {
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
    
    
    //TODO: - OFFLİNE
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
    
    //TODO: - OFFLİNE
    public func executeFetchNearByPois(northEast: TRPLocation, southWest: TRPLocation, categoryIds: [Int]?, completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        
        guard let cityId = cityId else {
            print("[Error] City id is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
        
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
        }else {
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
                        if northEast.lat > pois.coordinate.lat &&
                            pois.coordinate.lat > southWest.lat &&
                            northEast.lon > pois.coordinate.lon &&
                            pois.coordinate.lon > southWest.lon {
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
        
        guard let cityId = cityId else {
            print("[Error] City id is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
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
