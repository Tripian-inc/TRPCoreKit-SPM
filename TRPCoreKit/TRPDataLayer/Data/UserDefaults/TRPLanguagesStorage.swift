//
//  TRPLanguagesStorage.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Persists the translations of each language separately, so switching language
/// does not invalidate what is already cached for the others.
final class TRPLanguagesStorage {
    static let shared = TRPLanguagesStorage()

    private let translationsKey = "trp_translations_by_language"
    private let fetchedAtKey = "trp_translations_fetched_at_by_language"

    private let legacyKeys = [
        "trp_languages_translations",
        "trp_languages_fetched_at",
        "trp_languages_data",
        "trp_languages_cached_lang"
    ]

    private let userDefaults = UserDefaults.standard

    private init() {
        legacyKeys.forEach { userDefaults.removeObject(forKey: $0) }
    }

    func getCachedTranslations() -> (translations: [String: [String: Any]], fetchedAt: [String: Date]) {
        let translations = storedTranslations().compactMapValues { $0 as? [String: Any] }
        let fetchedAt = (userDefaults.dictionary(forKey: fetchedAtKey) as? [String: Double] ?? [:])
            .compactMapValues { interval -> Date? in
                interval > 0 ? Date(timeIntervalSince1970: interval) : nil
            }
        return (translations, fetchedAt)
    }

    func saveTranslations(_ translations: [String: Any], for language: String, at date: Date) {
        var stored = storedTranslations()
        stored[language] = translations

        guard JSONSerialization.isValidJSONObject(stored),
              let data = try? JSONSerialization.data(withJSONObject: stored) else {
            Log.e("Translations cache could not be serialized for language \(language)")
            return
        }

        userDefaults.set(data, forKey: translationsKey)
        var timestamps = userDefaults.dictionary(forKey: fetchedAtKey) as? [String: Double] ?? [:]
        timestamps[language] = date.timeIntervalSince1970
        userDefaults.set(timestamps, forKey: fetchedAtKey)
    }

    func clearCache() {
        userDefaults.removeObject(forKey: translationsKey)
        userDefaults.removeObject(forKey: fetchedAtKey)
    }

    private func storedTranslations() -> [String: Any] {
        guard let data = userDefaults.data(forKey: translationsKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
