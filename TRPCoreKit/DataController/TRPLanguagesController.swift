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

    private static let cacheTTL: TimeInterval = 8 * 60 * 60 // 8 hours

    lazy var languagesUseCases: TRPLanguagesUseCases = {
        return TRPLanguagesUseCases()
    }()

    private var translationsByLanguage: [String: [String: Any]] = [:]
    private var fetchedAtByLanguage: [String: Date] = [:]
    private var languageResult: [String: Any] = [:]
    private var fetchingLanguages: Set<String> = []
    private var pendingCompletions: [String: [(Result<Bool, Error>) -> Void]] = [:]
    private let syncQueue = DispatchQueue(label: "com.tripian.languages.sync")

    public var isFetched: Bool {
        return syncQueue.sync { !languageResult.isEmpty }
    }

    public init() {
        loadFromCache()
    }

    private func loadFromCache() {
        let cached = TRPLanguagesStorage.shared.getCachedTranslations()
        guard !cached.translations.isEmpty else { return }
        syncQueue.sync {
            self.translationsByLanguage = cached.translations
            self.fetchedAtByLanguage = cached.fetchedAt
            self.applyCurrentLanguageLocked()
        }
    }

    /// Must be called from inside `syncQueue`.
    private func applyCurrentLanguageLocked() {
        self.languageResult = translationsByLanguage[TRPClient.getLanguage()] ?? [:]
    }

    /// Prefetch translations — called from TRPCoreKit.initialize().
    /// Hits the API only when the current language has never been cached; a stale
    /// cache is refreshed later by `getLanguages()` when the SDK is actually opened.
    public func prefetchLanguagesIfNeeded() {
        let hasCache = syncQueue.sync { translationsByLanguage[TRPClient.getLanguage()]?.isEmpty == false }
        guard !hasCache else { return }
        getLanguages(completion: nil)
    }

    public func getLanguages(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        let language = TRPClient.getLanguage()
        enum Action { case alreadyFresh, queued, startFetch }
        var action: Action = .startFetch

        syncQueue.sync {
            if !fetchingLanguages.contains(language),
               let fetchedAt = fetchedAtByLanguage[language],
               Date().timeIntervalSince(fetchedAt) < Self.cacheTTL,
               translationsByLanguage[language]?.isEmpty == false {
                applyCurrentLanguageLocked()
                action = .alreadyFresh
                return
            }

            if let completion = completion {
                pendingCompletions[language, default: []].append(completion)
            }

            if fetchingLanguages.contains(language) {
                action = .queued
                return
            }

            fetchingLanguages.insert(language)
            action = .startFetch
        }

        switch action {
        case .alreadyFresh:
            DispatchQueue.main.async { completion?(.success(true)) }
        case .queued:
            return
        case .startFetch:
            performFetch(for: language)
        }
    }

    private func performFetch(for language: String) {
        languagesUseCases.executeFetchCurrentLanguageTranslations { [weak self] result in
            guard let self = self else { return }
            var callbacks: [(Result<Bool, Error>) -> Void] = []
            var finalResult: Result<Bool, Error> = .success(true)

            self.syncQueue.sync {
                switch result {
                case .success(let translations):
                    let now = Date()
                    self.translationsByLanguage[language] = translations
                    self.fetchedAtByLanguage[language] = now
                    self.applyCurrentLanguageLocked()
                    TRPLanguagesStorage.shared.saveTranslations(translations, for: language, at: now)
                    finalResult = .success(true)
                case .failure(let error):
                    finalResult = .failure(error)
                }
                self.fetchingLanguages.remove(language)
                callbacks = self.pendingCompletions.removeValue(forKey: language) ?? []
            }

            DispatchQueue.main.async {
                callbacks.forEach { $0(finalResult) }
            }
        }
    }

    /// Called by TRPCoreKit.changeLanguage(_:). Applies the cached translations of the
    /// new language, and fetches them only when that language has never been cached.
    public func applyLanguageChange() {
        let hasCache: Bool = syncQueue.sync {
            applyCurrentLanguageLocked()
            return !languageResult.isEmpty
        }
        guard !hasCache else { return }
        getLanguages(completion: nil)
    }

    private func getLanguageValueWithKey(_ key: String) -> String {
        let snapshot = syncQueue.sync { languageResult }
        if let keyValue = snapshot["keys"] as? [String: String] {
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
