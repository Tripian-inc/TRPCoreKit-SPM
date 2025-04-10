//
//  PoiRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias PoiResultValue = (Result<TRPPoi, Error>)

public typealias PoiResultsValue = (Result<[TRPPoi], Error>, TRPPagination?)

public typealias PoiCategoriesResultValue = (Result<[TRPPoiCategoyGroup], Error>)


public protocol PoiRepository {
    
    var pois: [TRPPoi] {get set}
    
    var poisWithParameters: [PoiParameters: [TRPPoi]] {get set}
    
    var poiCategories: [TRPPoiCategoyGroup] {get set}
    
    
    func fetchPoi(poiId: String,
                  completion: @escaping (PoiResultValue)-> Void)
    
    
    func fetchPoi(cityId: Int,
                  parameters: PoiParameters,
                  completion: @escaping (PoiResultsValue)-> Void)
    
    
    func fetchPoi(coordinate: TRPLocation,
                  parameters: PoiParameters,
                  completion: @escaping (PoiResultsValue)-> Void)
    
    
    func fetchPoi(url: String,
                  completion: @escaping (PoiResultsValue)-> Void)
    
    func addPois(contentsOf: [TRPPoi]) 
    
    func fetchLocalPoi(completion: @escaping (PoiResultsValue) -> Void)
    
    func fetchPoiCategories(completion: @escaping (PoiCategoriesResultValue) -> Void)
}


