//
//  TRPOfferRemoteApi.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit

final public class TRPOfferRemoteApi: OfferRemoteApi {
    
    public init() {}
    
    public func fetchOffers(dateFrom: String, dateTo: String, northEast: TRPLocation?, southWest: TRPLocation?, typeId: [Int]?, excludeOptIn: Bool?, completion: @escaping (OfferResultsValue) -> Void) {
        
        var bounds: LocationBounds?
        
        if let ne = northEast, let sw = southWest {
            bounds = LocationBounds(northEast: ne, southWest: sw)
        }
        TRPRestKit().getOffers(dateFrom: dateFrom, dateTo: dateTo, poiIds: nil, typeId: typeId, boundary: bounds, page: nil, limit: nil, excludeOptIn: excludeOptIn) { (result, error, pagination) in
            
            var _pagination: TRPPagination?
            
            if let pagination = pagination {
                _pagination = PaginationMapper().map(pagination)
            }
            
            if let error = error {
                completion((.failure(error), _pagination))
                return
            }
            
            if let result = result as? [TRPOfferInfoModel] {
                let convertedModel = OfferMapper().map(result)
                completion((.success(convertedModel), _pagination))
            }
            
        }
    }
    
    public func fetchOffer(offerId: Int, completion: @escaping (OfferResultValue) -> Void) {
        TRPRestKit().getOffer(id: offerId) { (result, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPOfferInfoModel {
                let converted = OfferMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func fetchOptInOffers(dateFrom: String?, dateTo: String?, completion: @escaping (OptInOfferResultsValue) -> Void) {
        TRPRestKit().getOptInOffers(dateFrom: dateFrom, dateTo: dateTo, page: nil, limit: nil) {(result, error, pagination) in
            
            var _pagination: TRPPagination?
            
            if let pagination = pagination {
                _pagination = PaginationMapper().map(pagination)
            }
            
            if let error = error {
                completion((.failure(error), _pagination))
                return
            }
            
            if let result = result as? [TRPPoiInfoModel] {
                let convertedModel = PoiMapper().map(result)
                completion((.success(convertedModel), _pagination))
            }
        }
    }
    
    public func addOptInOffer(offerId: Int, claimDate: String?, completion: @escaping (OptInOfferResultStatus) -> Void) {
        
        TRPRestKit().addOptInOffer(offerId: offerId, claimDate: claimDate) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if result is TRPParentJsonModel {
                completion(.success(true))
            }
        }
    }
    
    public func deleteOptInOffer(offerId: Int, completion: @escaping (OptInOfferResultStatus) -> Void) {
        
        TRPRestKit().deleteOptInOffer(offerId: offerId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if result is TRPParentJsonModel {
                completion(.success(true))
            }
        }
    }
    
    
}
