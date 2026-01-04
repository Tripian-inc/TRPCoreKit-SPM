//
//  CityRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public typealias CityResultValue = (Result<TRPCity, Error>)

public typealias CityResultsValue = (Result<[TRPCity], Error>)

public typealias CityInformationResultValue = (Result<TRPCityInformationData, Error>)


/// Sehir bilgilerini kontrol eden Repository
public protocol CityRepository {
    
    
    /// Sehir bilgileri getirildiğinde bu dizide saklanır
    var results: [TRPCity] {get set}
    var popularResults: [TRPCity] {get set}
    var shorexResults: [TRPCity] {get set}
    
    
    /// Tüm sehir bilgilerini getirir.
    /// Pagination kapalıdır. Tamammı geldiğinde çalışır
    /// - Parameter completion:
    func fetchCities(completion: @escaping (CityResultsValue) -> Void)
    
    func fetchShorexCities(completion: @escaping (CityResultsValue) -> Void)
    
    
    /// Tek bir sehiri getirir.
    /// - Parameter completion:
    func fetchCity(id: Int, completion: @escaping (CityResultValue) -> Void)
    
    func fetchLocalCity(id: Int, completion: @escaping (CityResultValue) -> Void)
    
    func fetchCityInformation(id: Int, completion: @escaping (CityInformationResultValue) -> Void)
}
