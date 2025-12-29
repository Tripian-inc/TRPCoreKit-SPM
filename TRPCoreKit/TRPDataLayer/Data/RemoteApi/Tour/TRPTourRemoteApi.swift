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

        // Map search text to keywords
        request.keywords = parameters.search

        // Map tour categories array to comma-separated tagIds
        if let categories = parameters.tourCategories, !categories.isEmpty {
            request.tagIds = categories.joined(separator: ",")
        }

        // Map distance to radius (convert Float to Double if needed)
        if let distance = parameters.distance {
            request.radius = Double(distance)
        }

        // Map date
        request.date = parameters.date

        // Map pagination
        request.limit = parameters.limit ?? 30
        request.offset = parameters.offset ?? 0

        TRPRestKit().searchTours(request: request) { (result, error) in

            if let error = error {
                completion((.failure(error), nil))
                return
            }

            if let result = result as? TRPTourSearchDataModel {
                let mapper = TourMapper()
                let converted = mapper.mapDataModel(result)
                let pagination = mapper.mapPagination(result)
                completion((.success(converted), pagination))
            } else {
                completion((.failure(GeneralError.customMessage("Couldn't convert tour data")), nil))
            }

        }
    }



    public func fetchTours(coordinate: TRPLocation,
                           parameters: TourParameters,
                           completion: @escaping (TourResultsValue) -> Void) {

        guard let cityId = parameters.cityId else {
            completion((.failure(GeneralError.customMessage("City id is required for tour search")), nil))
            return
        }

        var request = TRPTourSearchRequestModel(cityId: cityId)

        // Set provider ID
        request.providerId = 15

        // Set location coordinates
        request.lat = coordinate.lat
        request.lng = coordinate.lon

        // Map search text to keywords
        request.keywords = parameters.search

        // Map tour categories array to comma-separated tagIds
        if let categories = parameters.tourCategories, !categories.isEmpty {
            request.tagIds = categories.joined(separator: ",")
        }

        // Map distance to radius (convert Float to Double if needed)
        if let distance = parameters.distance {
            request.radius = Double(distance)
        }

        // Map date
        request.date = parameters.date

        // Map pagination
        request.limit = parameters.limit ?? 30
        request.offset = parameters.offset ?? 0

        TRPRestKit().searchTours(request: request) { (result, error) in

            if let error = error {
                completion((.failure(error), nil))
                return
            }

            if let result = result as? TRPTourSearchDataModel {
                let mapper = TourMapper()
                let converted = mapper.mapDataModel(result)
                let pagination = mapper.mapPagination(result)
                completion((.success(converted), pagination))
            } else {
                completion((.failure(GeneralError.customMessage("Couldn't convert tour data")), nil))
            }

        }
    }


    public func getTourSchedule(productId: String,
                                date: String,
                                currency: String,
                                lang: String,
                                completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {

        let request = TRPTourScheduleRequestModel(
            productId: productId,
            date: date,
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
}
