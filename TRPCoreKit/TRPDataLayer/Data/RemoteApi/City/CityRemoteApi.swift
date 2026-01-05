//
//  CityRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol CityRemoteApi {

    func fetchCities(completion: @escaping (CityResultsValue) -> Void)

    func fetchCity(cityId: Int, completion: @escaping (CityResultValue) -> Void)

    func fetchShorexCities(completion: @escaping (CityResultsValue) -> Void)

    func fetchCityInformation(cityId: Int, completion: @escaping (CityInformationResultValue) -> Void)

    /// Fetches a city by name using search parameter
    /// - Parameters:
    ///   - name: City name to search for
    ///   - completion: Completion handler with optional TRPCity result
    func fetchCityByName(_ name: String, completion: @escaping (CityResultValue) -> Void)

}
