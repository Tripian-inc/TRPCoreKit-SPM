//
//  TRPLanguagesUseCases.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public final class TRPLanguagesUseCases {
    private(set) var repository: LanguagesRepository
    
    private var retryCount = 0
    public init(repository: LanguagesRepository = TRPLanguagesRepository()) {
        self.repository = repository
    }
}

extension TRPLanguagesUseCases : FetchLanguagesUseCase {
    public func getLanguageValue(for key: String) -> String {
        if repository.currentLanguageResults.isEmpty {
            return ""
        } 
        return getLanguageValueWithKey(key)
    }
    
    public func executeGetLanguageValue(for key: String, completion: ((Result<String, any Error>) -> Void)?) {
        let onComplete = completion ?? {  result in }
        if repository.currentLanguageResults.isEmpty {
            executeFetchLanguages() { [weak self] result in
                switch(result) {
                case .success(_):
                    onComplete(.success(self?.getLanguageValueWithKey(key) ?? ""))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        } else {
            
        }
    }
    
    private func getLanguageValueWithKey(_ key: String) -> String {
        if let keyValue = repository.currentLanguageResults["keys"] as? [String: String] {
            return keyValue[key] ?? key
        }
        return key
    }
    
    
    public func executeFetchLanguages(completion: ((Result<TRPLanguagesInfoModel, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.fetchLanguages {  result in
            switch(result) {
            case .success(let result):
                onComplete(.success(result))
                self.repository.currentLanguageResults = result.translations[TRPClient.getLanguage()] as? [String : Any] ?? [:]
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}
