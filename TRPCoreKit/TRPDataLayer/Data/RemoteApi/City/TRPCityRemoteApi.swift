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
    
    public func fetchCityInformation(cityId: Int, completion: @escaping (CityInformationResultValue) -> Void) {

        TRPRestKit().cityInformation(with: cityId) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let cityInformation = result as? TRPCityInformationDataJsonModel {
                let convertedModel = CityInformationMapper().map(cityInformation)
                completion(.success(convertedModel))
            }
        }

    }

    /// Fetches a city by name using search parameter
    /// - Parameters:
    ///   - name: City name to search for
    ///   - completion: Completion handler with TRPCity result
    public func fetchCityByName(_ name: String, completion: @escaping (CityResultValue) -> Void) {

        TRPRestKit().cities(search: name, limit: 1) { (result, error, _) in

            if let error = error {
                completion(.failure(error))
                return
            }

            if let resultCities = result as? [TRPCityInfoModel], let firstCity = resultCities.first {
                let convertedModel = CityMapper().map(firstCity)
                completion(.success(convertedModel))
            } else {
                completion(.failure(GeneralError.customMessage("City not found: \(name)")))
            }
        }
    }

}
