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

    private var allTranslations: [String: Any] = [:]
    private var languageResult: [String: Any] = [:]
    private var lastFetchedAt: Date?
    private var isFetching: Bool = false
    private var pendingCompletions: [(Result<Bool, Error>) -> Void] = []
    private let syncQueue = DispatchQueue(label: "com.tripian.languages.sync")

    public var isFetched: Bool {
        return syncQueue.sync { lastFetchedAt != nil }
    }

    public init() {
        loadFromCache()
    }

    private func loadFromCache() {
        guard let cached = TRPLanguagesStorage.shared.getCachedTranslations() else { return }
        syncQueue.sync {
            self.allTranslations = cached.translations
            self.lastFetchedAt = cached.fetchedAt
            self.applyCurrentLanguageLocked()
        }
    }

    /// Must be called from inside `syncQueue`.
    private func applyCurrentLanguageLocked() {
        let current = TRPClient.getLanguage()
        self.languageResult = (allTranslations[current] as? [String: Any]) ?? [:]
    }

    /// Prefetch languages — called from TRPCoreKit.initialize().
    /// No-op when cache is fresh (within TTL).
    public func prefetchLanguagesIfNeeded() {
        getLanguages(completion: nil)
    }

    public func getLanguages(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        enum Action { case alreadyFresh, queued, startFetch }
        var action: Action = .startFetch

        syncQueue.sync {
            if let lastAt = lastFetchedAt,
               Date().timeIntervalSince(lastAt) < Self.cacheTTL,
               !allTranslations.isEmpty,
               !isFetching {
                applyCurrentLanguageLocked()
                action = .alreadyFresh
                return
            }

            if isFetching {
                if let completion = completion {
                    pendingCompletions.append(completion)
                }
                action = .queued
                return
            }

            isFetching = true
            pendingCompletions.removeAll()
            if let completion = completion {
                pendingCompletions.append(completion)
            }
            action = .startFetch
        }

        switch action {
        case .alreadyFresh:
            DispatchQueue.main.async { completion?(.success(true)) }
        case .queued:
            return
        case .startFetch:
            performFetch()
        }
    }

    private func performFetch() {
        languagesUseCases.executeFetchLanguages { [weak self] result in
            guard let self = self else { return }
            var callbacks: [(Result<Bool, Error>) -> Void] = []
            var finalResult: Result<Bool, Error> = .success(true)

            self.syncQueue.sync {
                switch result {
                case .success(let info):
                    let translations = info.translations
                    let now = Date()
                    self.allTranslations = translations
                    self.lastFetchedAt = now
                    self.applyCurrentLanguageLocked()
                    TRPLanguagesStorage.shared.saveTranslations(translations, at: now)
                    finalResult = .success(true)
                case .failure(let error):
                    finalResult = .failure(error)
                }
                self.isFetching = false
                callbacks = self.pendingCompletions
                self.pendingCompletions.removeAll()
            }

            DispatchQueue.main.async {
                callbacks.forEach { $0(finalResult) }
            }
        }
    }

    /// Called by TRPCoreKit.changeLanguage(_:). Switches in-memory translations
    /// to the new current language WITHOUT making an API request.
    public func applyLanguageChange() {
        syncQueue.sync {
            applyCurrentLanguageLocked()
        }
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
