//
//  LastSearchRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias LastSearchResultsValue = (Result<[String], Error>)

public protocol LastSearchRepository {
    
    var results: ValueObserver<[String]> {get set}
    
    var poiCategoryId: Int? {get set}
    
    func fetchLastSearch(completion: @escaping (LastSearchResultsValue) -> Void)
    
    func addLastSearch(text: String)
    
    func deleteLastSearch(text: String)
}

