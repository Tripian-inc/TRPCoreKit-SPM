//
//  TRPLanguagesController.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit


public class TRPLanguagesController {
     public static let shared = TRPLanguagesController()
    lazy var languagesUseCases: TRPLanguagesUseCases = {
        return TRPLanguagesUseCases()
    }()
    private var languageResult: [String: Any] = [:]
    public var isFetched = false

    public init() {
        loadFromCache()
    }

    private func loadFromCache() {
        let currentLanguage = TRPClient.getLanguage()
        if let cached = TRPLanguagesStorage.shared.getCachedLanguages(for: currentLanguage) {
            self.languageResult = cached
            self.isFetched = true
        }
    }

    /// Prefetch languages - called from TRPCoreKit.initialize()
    /// Always fetches fresh data, cache is used for immediate access
    public func prefetchLanguagesIfNeeded() {
        getLanguages(completion: nil)
    }

    public func getLanguages(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        let currentLanguage = TRPClient.getLanguage()

        languagesUseCases.executeFetchLanguages() { [weak self] result in
            switch(result) {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let results):
                self?.isFetched = true
                let langData = results.translations[currentLanguage] as? [String: Any] ?? [:]
                self?.languageResult = langData
                // Save to cache (for offline fallback)
                TRPLanguagesStorage.shared.saveLanguages(langData, for: currentLanguage)
                completion?(.success(true))
            }
        }
    }
    
    private func getLanguageValueWithKey(_ key: String) -> String {
        if let keyValue = languageResult["keys"] as? [String: String] {
            return keyValue[key] ?? key
        }
        return key
    }
    
    public func getLanguageValue(for key: String) -> String {
        return getLanguageValueWithKey(key)
    }
    
    public func getLanguageValue(for key: String, with strings: String...) -> String {
        return String(format: getLanguageValueWithKey(key).replacingOccurrences(of: "%s", with: "%@"), arguments: strings)
    }
    
    public func getApplyBtnText() -> String {
        return getLanguageValue(for: "trips.myTrips.itinerary.step.addToItinerary.submit.apply")
    }
    
    public func getDoneBtnText() -> String {
        return getLanguageValue(for: "user.travelCompanions.submit")
    }
    
    public func getUpdateBtnText() -> String {
        return getLanguageValue(for: "user.profile.submit")
    }
    
    public func getCancelBtnText() -> String {
        return getLanguageValue(for: "user.profile.cancel")
    }
    
    public func getContinueBtnText() -> String {
        return getLanguageValue(for: "trips.createNewTrip.form.continue")
    }
    
    public func getSuccessText() -> String {
        return getLanguageValue(for: "success")
    }
    
    public func getSearchText() -> String {
        return getLanguageValue(for: "search")
    }
}
