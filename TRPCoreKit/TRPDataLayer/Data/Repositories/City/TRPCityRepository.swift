//
//  TRPCityRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCityRepository: CityRepository {
    public var popularResults: [TRPCity] = []
    
    public var shorexResults: [TRPCity] = []
    
    public var results: [TRPCity] = []
    
    public var remoteApi: CityRemoteApi
    
    public var localStorage: CityLocalStorage
    
    public init(remoteApi: CityRemoteApi = TRPCityRemoteApi(),
                localStorage: CityLocalStorage = TRPCityLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    
    public func fetchCities(completion: @escaping (CityResultsValue) -> Void) {
        //Local Storage eklenecek
        remoteApi.fetchCities(completion: completion)
    }
    
    
    public func fetchPopularCities(completion: @escaping (CityResultsValue) -> Void) {
        //Local Storage eklenecek
        remoteApi.fetchCities(completion: completion)
    }
    
    public func fetchCity(id: Int, completion: @escaping (CityResultValue) -> Void) {
        //Local Storage eklenecek
        remoteApi.fetchCity(cityId: id, completion: completion)
    }
    
    public func fetchLocalCity(id: Int, completion: @escaping (CityResultValue) -> Void) {
        
    }
    
    public func fetchShorexCities(completion: @escaping (CityResultsValue) -> Void) {
        remoteApi.fetchShorexCities(completion: completion)
    }
    
    public func fetchCityInformation(id: Int, completion: @escaping (CityInformationResultValue) -> Void) {
        remoteApi.fetchCityInformation(cityId: id, completion: completion)
    }
    
}
