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

extension TRPTourUseCases: TourScheduleAvailabilityUseCase {

    public func executeGetTourScheduleAvailability(items: [String],
                                                   date: String,
                                                   currency: String? = nil,
                                                   lang: String? = nil,
                                                   completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {

        guard ReachabilityUseCases.shared.isOnline else {
            completion(.failure(GeneralError.customMessage("Tours require online connection")))
            return
        }

        guard !items.isEmpty else {
            completion(.success([]))
            return
        }

        tourRepository.getTourScheduleAvailability(items: items,
                                                   date: date,
                                                   currency: currency,
                                                   lang: lang,
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

extension TRPTourUseCases {

    /// Products attached to a single poi. Narrowing by poiId means no coordinates or
    /// radius are sent, so the result is the poi's own products rather than what is nearby.
    /// - Parameters:
    ///   - date: "yyyy-MM-dd". The search asks for instant availability, which is only
    ///           meaningful against a day, so a page comes back near empty without it.
    ///   - dateTo: "yyyy-MM-dd" end of the range; falls back to `date`.
    public func executeFetchTours(poiId: String,
                                  cityId: Int,
                                  date: String,
                                  dateTo: String? = nil,
                                  currency: String? = nil,
                                  completion: @escaping (Result<[TRPTourProduct], Error>) -> Void) {

        var params = TourParameters()
        params.poiId = poiId
        params.currency = currency
        params.date = date
        params.dateTo = dateTo ?? date

        tourRepository.fetchTours(cityId: cityId, parameters: params) { result in
            switch result {
            case .success(let outcome):
                completion(.success(outcome.products))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
