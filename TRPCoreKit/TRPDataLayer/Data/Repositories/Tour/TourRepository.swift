//
//  TourRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public typealias TourResultValue = (Result<TRPTourProduct, Error>)

public typealias TourResultsValue = (Result<[TRPTourProduct], Error>, TRPTourPagination?)


public protocol TourRepository {

    var tours: [TRPTourProduct] {get set}

    var toursWithParameters: [TourParameters: [TRPTourProduct]] {get set}


    func fetchTours(cityId: Int,
                    parameters: TourParameters,
                    completion: @escaping (TourResultsValue)-> Void)


    func fetchTours(coordinate: TRPLocation,
                    parameters: TourParameters,
                    completion: @escaping (TourResultsValue)-> Void)


    func fetchTours(url: String,
                    completion: @escaping (TourResultsValue)-> Void)

    func addTours(contentsOf: [TRPTourProduct])
}


public struct TourParameters: Hashable {
    public var cityId: Int?
    public var search: String?
    public var tourCategories: [String]?
    public var distance: Float?
    public var limit: Int?
    public var offset: Int?

    public init(search: String? = nil) {
        self.search = search
    }
}
