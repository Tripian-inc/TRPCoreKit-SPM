//
//  TRPLastSearchRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPLastSearchRepository: LastSearchRepository {
    
    private let userDefault = UserDefaults.standard
    private let keyPrefix = "last_storage_search"
    
    
    public var poiCategoryId: Int? = nil

    public var results: ValueObserver<[String]> = .init([])
    
    public init() {}
    
    
    public func fetchLastSearch(completion: @escaping (LastSearchResultsValue) -> Void) {
        let result = getParameters()
        results.value = result
        completion(.success(result))
    }
    
    public func addLastSearch(text: String) {
        var result = getParameters()
        if result.contains(text) {return}
        
        if result.count >= 10 {
            result.removeFirst()
        }
        
        if let sonAranan = result.last {
            if text.contains(sonAranan) {
                result.removeLast()
            }
        }
        
        result.append(text)
        saveParameters(result)
        results.value = result
    }
    
    public func deleteLastSearch(text: String) {
        var result = getParameters()
        if let index = result.firstIndex(where: {$0.lowercased() == text.lowercased()}) {
            result.remove(at: index)
        }
        saveParameters(result)
        results.value = result
    }
    
    private func saveParameters(_ params:[String]) {
        let category = poiCategoryId != nil ? poiCategoryId! : 0
        let key: String = "\(keyPrefix)\(category)"
        userDefault.setValue(params, forKey: key)
    }
    
    private func getParameters() -> [String] {
        let category = poiCategoryId != nil ? poiCategoryId! : 0
        let key: String = "\(keyPrefix)\(category)"
        return userDefault.object(forKey: key) as? [String] ?? []
    }
}
