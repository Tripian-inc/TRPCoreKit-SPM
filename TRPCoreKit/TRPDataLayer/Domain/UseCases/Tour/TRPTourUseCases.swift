//
//  TRPTourUseCases.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


final public class TRPTourUseCases {

    private(set) var tourRepository: TourRepository
    public var cityId: Int?


    public init(repository: TourRepository = TRPTourRepository()){
        self.tourRepository = repository
    }

}

extension TRPTourUseCases: SearchTourUseCase {

    public func executeSearchTour(text: String,
                                  categories: [String],
                                  date: String? = nil,
                                  completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?)-> Void)?
    ) {

        guard let cityId = cityId else {
            completion?(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }


        let onComplete = completion ?? { _, _ in }

        var params = TourParameters(search: text)
        params.tourCategories = categories.isEmpty ? nil : categories
        params.date = date

        tourRepository.fetchTours(cityId: cityId, parameters: params) { result in
            switch result {
            case .success(let outcome):
                onComplete(.success(outcome.products), nil)
            case .failure(let error):
                onComplete(.failure(error), nil)
            }
        }
    }

    public func executeSearchTour(text: String,
                                  categories: [String],
                                  userLocation: TRPLocation,
                                  completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?) -> Void)?) {

        let onComplete = completion ?? { _, _ in }

        if ReachabilityUseCases.shared.isOnline {
            var params = TourParameters(search: text)
            params.cityId = cityId
            params.tourCategories = categories.isEmpty ? nil : categories
            params.distance = 50
            tourRepository.fetchTours(coordinate: userLocation, parameters: params) { result in
                switch result {
                case .success(let outcome):
                    onComplete(.success(outcome.products), nil)
                case .failure(let error):
                    onComplete(.failure(error), nil)
                }
            }
        } else {
            // Offline not supported for tours
            onComplete(.failure(GeneralError.customMessage("Tours require online connection")), nil)
        }
    }

}

extension TRPTourUseCases: LookupTourProductUseCase {

    public func executeLookupTourProduct(providerId: Int,
                                         productId: String,
                                         completion: @escaping (TourResultValue) -> Void) {

        guard ReachabilityUseCases.shared.isOnline else {
            completion(.failure(GeneralError.customMessage("Tours require online connection")))
            return
        }

        tourRepository.lookupTourProduct(providerId: providerId,
                                         productId: productId,
                                         completion: completion)
    }

    /// Convenience overload for callers that already have a `TRPAdditionalData`
    /// (e.g. `step.additionalData` for activity-type timeline steps, or
    /// `segment.additionalData` for booked/reserved activities).
    public func executeLookupTourProduct(additionalData: TRPAdditionalData?,
                                         completion: @escaping (TourResultValue) -> Void) {

        guard let providerId = additionalData?.providerId,
              let productId = additionalData?.productId, !productId.isEmpty else {
            completion(.failure(GeneralError.customMessage("Missing providerId/productId")))
            return
        }

        executeLookupTourProduct(providerId: providerId,
                                 productId: productId,
                                 completion: completion)
    }
}

extension TRPTourUseCases: FetchTourUseCase {

    public func executeFetchTours(completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?) -> Void)?) {

        let onComplete = completion ?? { _, _ in }

        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }

        let params = TourParameters()

        if ReachabilityUseCases.shared.isOnline {
            tourRepository.fetchTours(cityId: cityId, parameters: params) { result in
                switch result {
                case .success(let outcome):
                    onComplete(.success(outcome.products), nil)
                case .failure(let error):
                    onComplete(.failure(error), nil)
                }
            }
        } else {
            onComplete(.failure(GeneralError.customMessage("Tours require online connection")), nil)
        }
    }
}
