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


        let onComplete = completion ?? { result, pagination in }

        var params = TourParameters(search: text)
        params.tourCategories = categories.isEmpty ? nil : categories
        params.date = date

        tourRepository.fetchTours(cityId: cityId, parameters: params) { result, pagination in

            switch result {
            case .success(let result):
                onComplete(.success(result), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
    }
    
    public func executeSearchTour(text: String,
                                  categories: [String],
                                  userLocation: TRPLocation,
                                  completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?) -> Void)?) {
        
        let onComplete = completion ?? { result, pagination in }
        
        if ReachabilityUseCases.shared.isOnline {
            var params = TourParameters(search: text)
            params.cityId = cityId
            params.tourCategories = categories.isEmpty ? nil : categories
            params.distance = 50
            tourRepository.fetchTours(coordinate: userLocation, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            // Offline not supported for tours
            onComplete(.failure(GeneralError.customMessage("Tours require online connection")), nil)
        }
    }
    
}

extension TRPTourUseCases: FetchTourUseCase {

    public func executeFetchTours(completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?) -> Void)?) {

        let onComplete = completion ?? { result, pagination in }

        guard let cityId = cityId else {
            onComplete(.failure(GeneralError.customMessage("City id is null")), nil)
            return
        }

        let params = TourParameters()

        if ReachabilityUseCases.shared.isOnline {
            tourRepository.fetchTours(cityId: cityId, parameters: params) { result, pagination in
                switch result {
                case .success(let result):
                    onComplete(.success(result), pagination)
                case .failure(let error):
                    onComplete(.failure(error), pagination)
                }
            }
        } else {
            onComplete(.failure(GeneralError.customMessage("Tours require online connection")), nil)
        }
    }
}
