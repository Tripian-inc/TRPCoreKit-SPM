//
//  TRPLanguagesRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public final class TRPLanguagesRepository:  LanguagesRepository {
    public var currentLanguageResults: [String : Any] = [:]
    
    public var results: TRPLanguagesInfoModel? = nil
    
    public init() {}
    
     public func fetchLanguages(completion: @escaping ((Result<TRPLanguagesInfoModel, Error>) -> Void)) {
        TRPRestKit().getFrontendLanguages() { [weak self] (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPLanguagesInfoModel {
                self?.currentLanguageResults = result.translations[TRPClient.getLanguage()] as? [String : Any] ?? [:]
                self?.results = result
                completion(.success(result))
            }
        }
    }
    
}
