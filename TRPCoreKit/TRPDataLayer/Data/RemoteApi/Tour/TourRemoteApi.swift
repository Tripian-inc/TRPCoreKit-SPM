//
//  TourRemoteApi.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


public protocol TourRemoteApi {

    func fetchTours(cityId: Int,
                    parameters: TourParameters,
                    completion: @escaping (TourResultsValue)-> Void)


    func fetchTours(coordinate: TRPLocation,
                    parameters: TourParameters,
                    completion: @escaping (TourResultsValue)-> Void)

    func getTourSchedule(productId: String,
                        date: String,
                        currency: String,
                        lang: String,
                        completion: @escaping (Result<TRPTourSchedule, Error>) -> Void)
}
