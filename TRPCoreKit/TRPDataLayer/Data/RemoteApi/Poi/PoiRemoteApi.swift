//
//  PoiRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


public protocol PoiRemoteApi {
    
    func fetchPoi(poiId: String,
                    completion: @escaping (PoiResultValue)-> Void)
    
    func fetchPoi(cityId: Int,
                    parameters: PoiParameters,
                    completion: @escaping (PoiResultsValue)-> Void)
    
    
    func fetchPoi(coordinate: TRPLocation,
                    parameters: PoiParameters,
                    completion: @escaping (PoiResultsValue)-> Void)
    
    
    func fetchPoi(url: String,
             completion: @escaping (PoiResultsValue) -> Void)
    
    func fetchPoiCategories(completion: @escaping (PoiCategoriesResultValue) -> Void)
}

