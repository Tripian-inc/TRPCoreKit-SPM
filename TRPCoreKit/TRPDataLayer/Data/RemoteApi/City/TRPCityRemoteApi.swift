//
//  TRPCityRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

/// Sehir bilgilenirini API den getiri.
final public class TRPCityRemoteApi: CityRemoteApi {
    
    public init() {}
    
    
    /// Tüm sehirleri getirir.
    ///  AutoPagination true dur. Pagination tamamlandığında sonuc dondururlur
    /// - Parameter completion: Pagination iceride kontrol edilir.
     public func fetchCities(completion: @escaping (CityResultsValue) -> Void) {
        var cities = [TRPCity]()
        
        TRPRestKit().cities(limit: 1000, isAutoPagination: true) { (result, error, pagination) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let resultCities = result as? [TRPCityInfoModel] {
                
                let convertedModels = CityMapper().map(resultCities)
                cities.append(contentsOf: convertedModels)
                
                if let pag = pagination, pag == Pagination.completed{
                    completion(.success(cities))
                }
            }
        }
    }
    
    
    /// Tüm shorex sehirleri getirir.
    ///  AutoPagination true dur. Pagination tamamlandığında sonuc dondururlur
    /// - Parameter completion: Pagination iceride kontrol edilir.
     public func fetchShorexCities(completion: @escaping (CityResultsValue) -> Void) {
        var cities = [TRPCity]()
        
        TRPRestKit().shorexCities() { (result, error, pagination) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let resultCities = result as? [TRPCityInfoModel] {
                
                let convertedModels = CityMapper().map(resultCities)
                cities.append(contentsOf: convertedModels)
                completion(.success(cities))
            }
        }
    }
    
    
    /// Tek bir sehrin bilgisini getirir.
    /// - Parameters:
    ///   - cityId: CityId
    public func fetchCity(cityId: Int, completion: @escaping (CityResultValue) -> Void) {
        
        TRPRestKit().city(with: cityId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let city = result as? TRPCityInfoModel {
                let convertedModel = CityMapper().map(city)
                completion(.success(convertedModel))
            }
        }
        
    }
    
}
