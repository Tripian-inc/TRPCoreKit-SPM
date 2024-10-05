//
//  CityUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchCitiesUseCase {
    
    /// Get city list
    /// - Parameters:
    ///   - completion:
    func executeFetchCities(completion: ((Result<[TRPCity], Error>) -> Void)?)
    func executeFetchPopularCities(completion: ((Result<[TRPCity], Error>) -> Void)?)
    func executeFetchShorexCities(completion: ((Result<[TRPCity], Error>) -> Void)?)
    
   
}

public protocol FetchCityUseCase {
    
    /// Get city
    /// - Parameters:
    ///   - id: CityId
    ///   - completion:
    func executeFetchCity(id: Int, completion: ((Result<TRPCity, Error>) -> Void)?)
    
}
