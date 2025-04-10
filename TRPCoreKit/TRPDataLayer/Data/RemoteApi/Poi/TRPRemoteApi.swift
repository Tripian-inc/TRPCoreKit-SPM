//
//  TRPRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation




public class TRPPoiRemoteApi: PoiRemoteApi {
    
    
    public init() {}
    
    
    public func fetchPoi(poiId: String,
                         completion: @escaping (PoiResultValue) -> Void) {
       
        TRPRestKit().poi(poiId: poiId) { (result, error) in
                            
            if let error = error {
                completion((.failure(error)))
                return
            }
                            
            if let result = result as? [TRPPoiInfoModel], !result.isEmpty {
                //let convertedPagination = PaginationMapper().map(pagination)
                let converted = PoiMapper().map(result.first!)
                completion((.success(converted!)))
            } else {
                completion((.failure(GeneralError.customMessage("Couldn't convert data"))))
            }
                            
        }
    }
    
    
    public func fetchPoi(cityId: Int,
                         parameters: PoiParameters,
                         completion: @escaping (PoiResultsValue) -> Void) {
        
        
        var bounds: LocationBounds?
        
        if let ne = parameters.boundaryNorthEast, let sw = parameters.boundarySouthWest {
            bounds = LocationBounds(northEast: ne, southWest: sw)
        }
       
        TRPRestKit().poi(cityId: cityId,
                         search: parameters.search,
                         poiIds: parameters.poiIds?.unique(),
                         poiCategoies: parameters.poiCategoies,
                         mustTryIds: parameters.mustTryIds,
                         distance: parameters.distance,
                         bounds: bounds,
                         limit: parameters.limit,
                         autoPagination: parameters.autoPagination) { (result, error, pagination) in
                            
                            var _pagination: TRPPagination?
                            
                            if let pagination = pagination {
                                _pagination = PaginationMapper().map(pagination)
                            }
                            
                            if let error = error {
                                completion((.failure(error), _pagination))
                                return
                            }
                            
                            if let result = result as? [TRPPoiInfoModel] {
                                //let convertedPagination = PaginationMapper().map(pagination)
                                let converted = PoiMapper().map(result)
                                completion((.success(converted), _pagination))
                            }
                            
        }
    }
    
    
    
    public func fetchPoi(coordinate: TRPLocation, parameters: PoiParameters, completion: @escaping (PoiResultsValue) -> Void) {
        var bounds: LocationBounds?
        
        if let ne = parameters.boundaryNorthEast, let sw = parameters.boundarySouthWest {
            bounds = LocationBounds(northEast: ne, southWest: sw)
        }
        
        TRPRestKit().poi(coordinate: coordinate,
                         cityId: parameters.cityId,
                         search: parameters.search,
                         poiIds: parameters.poiIds?.unique(),
                         poiCategoies: parameters.poiCategoies,
                         mustTryIds: parameters.mustTryIds,
                         distance: parameters.distance,
                         bounds: bounds,
                         limit: parameters.limit,
                         autoPagination: parameters.autoPagination) { (result, error, pagination) in
                            
                            var _pagination: TRPPagination?
                            
                            if let pagination = pagination {
                                _pagination = PaginationMapper().map(pagination)
                            }
                            
                            
                            if let error = error {
                                completion((.failure(error), _pagination))
                                return
                            }
                            
                            if let result = result as? [TRPPoiInfoModel] {
                                let converted = PoiMapper().map(result)
                                completion((.success(converted), _pagination))
                            }
                            
        }
    }
    
    
    
    
    
    
    public func fetchPoi(url: String, completion: @escaping (PoiResultsValue) -> Void) {
        TRPRestKit().poi(url: url) { (result, error, pagination) in
            var _pagination: TRPPagination?
            
            if let pagination = pagination {
                _pagination = PaginationMapper().map(pagination)
            }
            
            
            if let error = error {
                completion((.failure(error), _pagination))
                return
            }
            
            if let result = result as? [TRPPoiInfoModel] {
                let converted = PoiMapper().map(result)
                completion((.success(converted), _pagination))
            }
        }
    }
    
    public func fetchPoiCategories(completion: @escaping (PoiCategoriesResultValue) -> Void) {
        TRPRestKit().poiCategory() { (result, error) in
            
            if let error = error {
                completion((.failure(error)))
                return
            }
            
            if let result = result as? TRPCategoriesInfoModel {
                let converted = PoiCategoryMapper().map(result)
                completion((.success(converted)))
            } else {
                completion((.failure(GeneralError.customMessage("Couldn't convert data"))))
            }
        }
    }
}

