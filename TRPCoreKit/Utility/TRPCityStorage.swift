//
//  TRPCityStorage.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 4.08.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Persists the city list on disk so a cold launch can serve `TRPCityCache`
/// without waiting for the network. Backing file lives in the caches directory.
final class TRPCityStorage {
    static let shared = TRPCityStorage()

    private struct CachedCities: Codable {
        let cities: [TRPCity]
        let fetchedAt: Date
    }

    private let fileName = "trp_cities_cache.json"

    private var fileURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    private init() {}

    func load() -> (cities: [TRPCity], fetchedAt: Date)? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let cached = try? JSONDecoder().decode(CachedCities.self, from: data),
              !cached.cities.isEmpty else {
            return nil
        }
        return (cached.cities, cached.fetchedAt)
    }

    func save(_ cities: [TRPCity], at date: Date) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(CachedCities(cities: cities, fetchedAt: date))
            try data.write(to: url, options: .atomic)
        } catch {
            Log.e("TRPCityStorage: cities could not be persisted - \(error.localizedDescription)")
        }
    }

    func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
