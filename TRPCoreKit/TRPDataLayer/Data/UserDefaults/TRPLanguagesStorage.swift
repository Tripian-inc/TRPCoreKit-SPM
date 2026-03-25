//
//  TRPLanguagesStorage.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

final class TRPLanguagesStorage {
    static let shared = TRPLanguagesStorage()

    private let languageDataKey = "trp_languages_data"
    private let cachedLanguageKey = "trp_languages_cached_lang"

    private let userDefaults = UserDefaults.standard

    private init() {}

    // Read from cache (only for same language)
    func getCachedLanguages(for language: String) -> [String: Any]? {
        guard let cachedLang = userDefaults.string(forKey: cachedLanguageKey),
              cachedLang == language else { return nil }
        guard let data = userDefaults.data(forKey: languageDataKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }

    // Save to cache (translations[language] part)
    func saveLanguages(_ languageData: [String: Any], for language: String) {
        if let data = try? JSONSerialization.data(withJSONObject: languageData) {
            userDefaults.set(data, forKey: languageDataKey)
            userDefaults.set(language, forKey: cachedLanguageKey)
        }
    }

    // Manual cache clear
    func clearCache() {
        userDefaults.removeObject(forKey: languageDataKey)
        userDefaults.removeObject(forKey: cachedLanguageKey)
    }
}
