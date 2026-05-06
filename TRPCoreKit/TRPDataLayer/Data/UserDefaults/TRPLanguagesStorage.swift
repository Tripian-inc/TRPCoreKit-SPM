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

    private let translationsKey = "trp_languages_translations"
    private let fetchedAtKey = "trp_languages_fetched_at"

    // Legacy keys — cleared in clearCache() for hygiene
    private let legacyDataKey = "trp_languages_data"
    private let legacyLangKey = "trp_languages_cached_lang"

    private let userDefaults = UserDefaults.standard

    private init() {}

    func getCachedTranslations() -> (translations: [String: Any], fetchedAt: Date)? {
        guard let data = userDefaults.data(forKey: translationsKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              !dict.isEmpty else {
            return nil
        }
        let interval = userDefaults.double(forKey: fetchedAtKey)
        guard interval > 0 else { return nil }
        return (dict, Date(timeIntervalSince1970: interval))
    }

    func saveTranslations(_ translations: [String: Any], at date: Date) {
        guard let data = try? JSONSerialization.data(withJSONObject: translations) else { return }
        userDefaults.set(data, forKey: translationsKey)
        userDefaults.set(date.timeIntervalSince1970, forKey: fetchedAtKey)
    }

    func clearCache() {
        userDefaults.removeObject(forKey: translationsKey)
        userDefaults.removeObject(forKey: fetchedAtKey)
        userDefaults.removeObject(forKey: legacyDataKey)
        userDefaults.removeObject(forKey: legacyLangKey)
    }
}
