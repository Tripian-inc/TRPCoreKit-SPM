//
//  TRPTourRemoteApi.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit

public class TRPTourRemoteApi: TourRemoteApi {


    public init() {}


    public func fetchTours(cityId: Int,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        var request = TRPTourSearchRequestModel(cityId: cityId)

        // Set provider ID
        request.providerId = 15

        // Always require instant availability
        request.instantAvailability = 1

        // Set city center coordinates from cache
        if let cityCoordinate = TRPCityCache.shared.getCityCoordinate(cityId: cityId) {
            request.lat = cityCoordinate.lat
            request.lng = cityCoordinate.lon
        }

        // Map search text to keywords
        request.keywords = parameters.search

        // Map tour categories array to comma-separated tagIds (legacy keyword path)
        if let categories = parameters.tourCategories, !categories.isEmpty {
            request.tagIds = categories.joined(separator: ",")
        }

        // Map facet category IDs to comma-separated `categories` parameter
        if let categoryIds = parameters.categoryIds, !categoryIds.isEmpty {
            request.categories = categoryIds.joined(separator: ",")
        }

        // Map distance to radius (convert Float to Double if needed)
        if let distance = parameters.distance {
            request.radius = Double(distance)
        }

        // Map date range
        request.date = parameters.date
        request.to = parameters.dateTo

        // Hardcoded request limit (server requires it; pagination still disabled client-side)
        request.limit = 10

        // Map price filters
        request.minPrice = parameters.minPrice
        request.maxPrice = parameters.maxPrice

        // Map rating filter
        request.minRating = parameters.minRating

        // Map duration filters
        request.minDuration = parameters.minDuration
        request.maxDuration = parameters.maxDuration

        // Map sorting (default to score descending)
        request.sortingBy = parameters.sortingBy ?? "rating"
        request.sortingType = parameters.sortingType ?? "desc"

        // Map currency and adults
        request.currency = parameters.currency
        request.adults = parameters.adults

        TRPRestKit().searchTours(request: request) { (result, error) in

            if let error = error {
                completion(.failure(error))
                return
            }

            if let result = result as? TRPTourSearchDataModel {
                let outcome = TourMapper().mapDataModel(result)
                completion(.success(outcome))
            } else {
                completion(.failure(GeneralError.customMessage("Couldn't convert tour data")))
            }

        }
    }



    public func fetchTours(coordinate: TRPLocation,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        guard let cityId = parameters.cityId else {
            completion(.failure(GeneralError.customMessage("City id is required for tour search")))
            return
        }

        var request = TRPTourSearchRequestModel(cityId: cityId)

        // Set provider ID
        request.providerId = 15

        // Always require instant availability
        request.instantAvailability = 1

        // Set location coordinates
        request.lat = coordinate.lat
        request.lng = coordinate.lon

        // Map search text to keywords
        request.keywords = parameters.search

        // Map tour categories array to comma-separated tagIds (legacy keyword path)
        if let categories = parameters.tourCategories, !categories.isEmpty {
            request.tagIds = categories.joined(separator: ",")
        }

        // Map facet category IDs to comma-separated `categories` parameter
        if let categoryIds = parameters.categoryIds, !categoryIds.isEmpty {
            request.categories = categoryIds.joined(separator: ",")
        }

        // Map distance to radius (convert Float to Double if needed)
        if let distance = parameters.distance {
            request.radius = Double(distance)
        }

        // Map date range
        request.date = parameters.date
        request.to = parameters.dateTo

        // Hardcoded request limit (server requires it; pagination still disabled client-side)
        request.limit = 10

        // Map price filters
        request.minPrice = parameters.minPrice
        request.maxPrice = parameters.maxPrice

        // Map rating filter
        request.minRating = parameters.minRating

        // Map duration filters
        request.minDuration = parameters.minDuration
        request.maxDuration = parameters.maxDuration

        // Map sorting (default to score descending)
        request.sortingBy = parameters.sortingBy ?? "score"
        request.sortingType = parameters.sortingType ?? "desc"

        // Map currency and adults
        request.currency = parameters.currency
        request.adults = parameters.adults

        TRPRestKit().searchTours(request: request) { (result, error) in

            if let error = error {
                completion(.failure(error))
                return
            }

            if let result = result as? TRPTourSearchDataModel {
                let outcome = TourMapper().mapDataModel(result)
                completion(.success(outcome))
            } else {
                completion(.failure(GeneralError.customMessage("Couldn't convert tour data")))
            }

        }
    }


    public func getTourSchedule(productId: String,
                                date: String,
                                to: String?,
                                currency: String,
                                lang: String,
                                completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {

        let request = TRPTourScheduleRequestModel(
            productId: productId,
            date: date,
            to: to,
            currency: currency,
            lang: lang
        )

        TRPRestKit().getTourSchedule(request: request) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let schedule = result as? TRPTourScheduleModel {
                let mapper = TourMapper()
                let converted = mapper.mapSchedule(schedule)
                completion(.success(converted))
            } else {
                completion(.failure(GeneralError.customMessage("Couldn't convert tour schedule data")))
            }
        }
    }


    public func lookupTourProduct(providerId: Int,
                                  productId: String,
                                  completion: @escaping (TourResultValue) -> Void) {

        let request = TRPTourProductLookupRequestModel(providerId: providerId, productId: productId)

        TRPRestKit().lookupTourProduct(request: request) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let info = result as? TRPTourProductInfoModel,
               let product = TourMapper().map(info) {
                completion(.success(product))
            } else {
                completion(.failure(GeneralError.customMessage("Couldn't convert tour product data")))
            }
        }
    }


    public func getTourScheduleAvailability(items: [String],
                                            date: String,
                                            currency: String?,
                                            lang: String?,
                                            completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {

        let request = TRPTourScheduleAvailabilityRequestModel(
            items: items,
            date: date,
            currency: currency,
            lang: lang
        )

        TRPRestKit().getTourScheduleAvailability(request: request) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = result as? TRPTourScheduleAvailabilityDataModel {
                let mapped = TourMapper().mapAvailability(data)
                completion(.success(mapped))
            } else {
                completion(.failure(GeneralError.customMessage("Couldn't convert tour schedule availability data")))
            }
        }
    }
}
