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

    public func fetchCurrentLanguageTranslations(completion: @escaping ((Result<[String: Any], Error>) -> Void)) {
        let language = TRPClient.getLanguage()
        TRPRestKit().getFrontendLanguagesV2 { [weak self] (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let result = result as? TRPLanguagesV2InfoModel else {
                completion(.failure(GeneralError.customMessage("Translations could not be parsed")))
                return
            }

            let payload = result.translations[language] ?? result.translations.values.first
            guard let translations = payload as? [String: Any] else {
                completion(.failure(GeneralError.customMessage("Translations are empty")))
                return
            }

            self?.currentLanguageResults = translations
            completion(.success(translations))
        }
    }

}
