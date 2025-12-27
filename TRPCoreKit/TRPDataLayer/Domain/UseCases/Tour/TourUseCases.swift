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
