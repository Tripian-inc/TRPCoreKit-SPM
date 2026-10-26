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

    /// Full responses cached alongside `toursWithParameters` so a cache hit returns the same
    /// products, facets and pagination as the network response it replays.
    private var outcomesWithParameters: [TourParameters : TRPTourSearchOutcome] = [:]

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
            completion(.success(cachedOutcome(for: parametersWithCity, products: toursInCache)))
            return
        }

        remoteApi.fetchTours(cityId: cityId, parameters: parametersWithCity) { [weak self] result in
            switch result {
            case .success(let outcome):
                guard let strongSelf = self else { return }
                let uniqueOutcome = TRPTourSearchOutcome(products: outcome.products.unique(),
                                                         facets: outcome.facets,
                                                         pagination: outcome.pagination)
                strongSelf.tours.append(contentsOf: outcome.products)
                strongSelf.storeInCache(uniqueOutcome, for: parametersWithCity)
                completion(.success(uniqueOutcome))
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
            completion(.success(cachedOutcome(for: parametersWithCity, products: toursInCache)))
            return
        }

        remoteApi.fetchTours(coordinate: coordinate, parameters: parametersWithCity) { [weak self] result in
            switch result {
            case .success(let outcome):
                guard let strongSelf = self else { return }
                let uniqueOutcome = TRPTourSearchOutcome(products: outcome.products.unique(),
                                                         facets: outcome.facets,
                                                         pagination: outcome.pagination)
                strongSelf.tours.append(contentsOf: outcome.products)
                strongSelf.storeInCache(uniqueOutcome, for: parametersWithCity)
                completion(.success(uniqueOutcome))
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
                                to: String?,
                                currency: String,
                                lang: String,
                                completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {
        remoteApi.getTourSchedule(productId: productId,
                                 date: date,
                                 to: to,
                                 currency: currency,
                                 lang: lang,
                                 completion: completion)
    }

    public func lookupTourProduct(providerId: Int,
                                  productId: String,
                                  completion: @escaping (TourResultValue) -> Void) {
        remoteApi.lookupTourProduct(providerId: providerId,
                                    productId: productId,
                                    completion: completion)
    }

    public func getTourScheduleAvailability(items: [String],
                                            date: String,
                                            currency: String?,
                                            lang: String?,
                                            completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {
        remoteApi.getTourScheduleAvailability(items: items,
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

    /// Replays the cached response for `parameters`; `products` wins when `toursWithParameters`
    /// was set without a matching response.
    private func cachedOutcome(for parameters: TourParameters, products: [TRPTourProduct]) -> TRPTourSearchOutcome {
        let outcome = outcomesWithParameters[parameters]
        return TRPTourSearchOutcome(products: products,
                                    facets: outcome?.facets,
                                    pagination: outcome?.pagination)
    }

    private func storeInCache(_ outcome: TRPTourSearchOutcome, for parameters: TourParameters) {
        guard USE_CACHE, !toursWithParameters.contains(where: { $0.key == parameters }) else { return }
        toursWithParameters[parameters] = outcome.products
        outcomesWithParameters[parameters] = outcome
    }
}
