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
    public var toursParametersNextLink: [TourParameters : TRPTourPagination?] = [:]

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
            completion((.success(toursInCache), checkNextLink(parametersWithCity)))
            return
        }

        remoteApi.fetchTours(cityId: cityId, parameters: parametersWithCity) { [weak self] result in
            switch result.0 {
            case .success(let apiTours):
                guard let strongSelf = self else {return}
                strongSelf.tours.append(contentsOf: apiTours)

                if strongSelf.USE_CACHE, !strongSelf.toursWithParameters.contains(where: {$0.key == parametersWithCity}) {
                    if let pagination = result.1, pagination.hasMore {
                        strongSelf.toursParametersNextLink[parametersWithCity] = pagination
                    }
                    strongSelf.toursWithParameters[parametersWithCity] = apiTours.unique()
                }
                completion((.success(apiTours.unique()), result.1))
            case .failure(let error):
                completion((.failure(error), result.1))
            }
        }
    }


    public func fetchTours(coordinate: TRPLocation,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        var parametersWithCity = parameters

        let checkWithParams = checkParameters(parametersWithCity)

        if let toursInCache = checkWithParams.tours, checkWithParams.continue == false {
            completion((.success(toursInCache), checkNextLink(parametersWithCity)))
            return
        }

        remoteApi.fetchTours(coordinate: coordinate, parameters: parametersWithCity) { [weak self] result in
            switch result.0 {
            case .success(let apiTours):
                guard let strongSelf = self else {return}
                strongSelf.tours.append(contentsOf: apiTours)

                if strongSelf.USE_CACHE, !strongSelf.toursWithParameters.contains(where: {$0.key == parametersWithCity}) {
                    if let pagination = result.1, pagination.hasMore {
                        strongSelf.toursParametersNextLink[parametersWithCity] = pagination
                    }
                    strongSelf.toursWithParameters[parametersWithCity] = apiTours.unique()
                }
                completion((.success(apiTours.unique()), result.1))
            case .failure(let error):
                completion((.failure(error), result.1))
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

    private func checkNextLink(_ parameters: TourParameters) -> TRPTourPagination? {
        return toursParametersNextLink[parameters] ?? nil
    }
}
