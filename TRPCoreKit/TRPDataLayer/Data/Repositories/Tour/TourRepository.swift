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

    func addTours(contentsOf: [TRPTourProduct])

    func getTourSchedule(productId: String,
                        date: String,
                        currency: String,
                        lang: String,
                        completion: @escaping (Result<TRPTourSchedule, Error>) -> Void)
}


public struct TourParameters: Hashable {
    public var cityId: Int?
    public var search: String?
    public var tourCategories: [String]?
    public var distance: Float?
    public var limit: Int?
    public var offset: Int?
    public var date: String? // Format: "yyyy-MM-dd"
    public var minPrice: Double?
    public var maxPrice: Double?
    public var minRating: Double?
    public var minDuration: Double?
    public var maxDuration: Double?
    public var sortingBy: String?
    public var sortingType: String?

    public init(search: String? = nil) {
        self.search = search
    }
}
