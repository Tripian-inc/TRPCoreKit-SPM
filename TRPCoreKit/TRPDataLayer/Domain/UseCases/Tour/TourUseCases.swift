//
//  TourUseCases.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol SearchTourUseCase {

    func executeSearchTour(text: String,
                           categories: [String],
                           date: String?,
                           completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?)-> Void)?
                          )

    func executeSearchTour(text: String,
                           categories: [String],
                           userLocation: TRPLocation,
                           completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?)-> Void)?
                          )
}


public protocol FetchTourUseCase {

    func executeFetchTours(completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?)-> Void)?)
}


public protocol FetchTourNextUrlUseCase {

    func executeFetchTour(url: String,
                          completion: ((Result<[TRPTourProduct], Error>, TRPTourPagination?)-> Void)?
                         )
}


public protocol LookupTourProductUseCase {

    /// Fetches a single tour product by provider + product id (tour-api/product-lookup).
    /// Use this when you have a `providerId` + `productId` (e.g. from a timeline step's
    /// `additionalData`) and need full product details without paging through search.
    func executeLookupTourProduct(providerId: Int,
                                  productId: String,
                                  completion: @escaping (TourResultValue) -> Void)
}
