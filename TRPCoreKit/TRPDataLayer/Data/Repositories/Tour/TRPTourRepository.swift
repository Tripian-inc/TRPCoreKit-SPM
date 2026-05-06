//
//  TRPTourRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

final public class TRPTourRepository: TourRepository {

    private let USE_CACHE = true

    public var tours: [TRPTourProduct] = []

    public var toursWithParameters: [TourParameters : [TRPTourProduct]] = [:]

    public var remoteApi: TourRemoteApi


    public init(remoteApi: TourRemoteApi = TRPTourRemoteApi()) {
        self.remoteApi = remoteApi
    }


    public func fetchTours(cityId: Int,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        var parametersWithCity = parameters
        parametersWithCity.cityId = cityId

        let checkWithParams = checkParameters(parametersWithCity)

        if let toursInCache = checkWithParams.tours, checkWithParams.continue == false {
            completion(.success(TRPTourSearchOutcome(products: toursInCache, facets: nil)))
            return
        }

        remoteApi.fetchTours(cityId: cityId, parameters: parametersWithCity) { [weak self] result in
            switch result {
            case .success(let outcome):
                guard let strongSelf = self else { return }
                let uniqueProducts = outcome.products.unique()
                strongSelf.tours.append(contentsOf: outcome.products)

                if strongSelf.USE_CACHE, !strongSelf.toursWithParameters.contains(where: { $0.key == parametersWithCity }) {
                    strongSelf.toursWithParameters[parametersWithCity] = uniqueProducts
                }
                completion(.success(TRPTourSearchOutcome(products: uniqueProducts, facets: outcome.facets)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    public func fetchTours(coordinate: TRPLocation,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        let parametersWithCity = parameters

        let checkWithParams = checkParameters(parametersWithCity)

        if let toursInCache = checkWithParams.tours, checkWithParams.continue == false {
            completion(.success(TRPTourSearchOutcome(products: toursInCache, facets: nil)))
            return
        }

        remoteApi.fetchTours(coordinate: coordinate, parameters: parametersWithCity) { [weak self] result in
            switch result {
            case .success(let outcome):
                guard let strongSelf = self else { return }
                let uniqueProducts = outcome.products.unique()
                strongSelf.tours.append(contentsOf: outcome.products)

                if strongSelf.USE_CACHE, !strongSelf.toursWithParameters.contains(where: { $0.key == parametersWithCity }) {
                    strongSelf.toursWithParameters[parametersWithCity] = uniqueProducts
                }
                completion(.success(TRPTourSearchOutcome(products: uniqueProducts, facets: outcome.facets)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func addTours(contentsOf: [TRPTourProduct]) {
        tours.append(contentsOf: contentsOf)
    }

    public func getTourSchedule(productId: String,
                                date: String,
                                currency: String,
                                lang: String,
                                completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {
        remoteApi.getTourSchedule(productId: productId,
                                 date: date,
                                 currency: currency,
                                 lang: lang,
                                 completion: completion)
    }
}


extension TRPTourRepository {

    private func checkParameters(_ parameters: TourParameters) -> (tours: [TRPTourProduct]?, continue: Bool) {
        if toursWithParameters.contains(where: {$0.key == parameters}) {
            return (toursWithParameters[parameters] ?? [], false)
        }
        return (nil, true)
    }
}
