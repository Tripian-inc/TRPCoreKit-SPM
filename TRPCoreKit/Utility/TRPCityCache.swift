//
//  TRPCityCache.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// Singleton class that caches city data fetched from the API.
/// Cities are fetched once after login and stored in memory for quick access.
public class TRPCityCache {

    // MARK: - Singleton
    public static let shared = TRPCityCache()

    // MARK: - Properties
    private static let cacheTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    private var cities: [TRPCity] = []
    private var isFetching: Bool = false
    private var lastFetchedAt: Date?
    private var didLoadFromDisk: Bool = false
    private var fetchWaiters: [(Bool) -> Void] = []
    private var unknownCityIds: Set<Int> = []

    private let cityRemoteApi: CityRemoteApi
    private let storage: TRPCityStoring
    private let queue = DispatchQueue(label: "com.tripian.cityCache", attributes: .concurrent)

    // MARK: - Init
    private convenience init() {
        self.init(cityRemoteApi: TRPCityRemoteApi(), storage: TRPCityStorage.shared)
    }

    /// Serves the persisted cities from the start, so a lookup never has to wait for the network
    /// when the city was seen on an earlier launch.
    init(cityRemoteApi: CityRemoteApi, storage: TRPCityStoring) {
        self.cityRemoteApi = cityRemoteApi
        self.storage = storage
        loadFromDiskLocked()
    }

    // MARK: - Public Methods

    /// Loads the persisted cities and refreshes them from the API when the stored
    /// copy is missing or older than the TTL. Safe to call multiple times — a fresh
    /// cache short-circuits it, and a call made during a fetch waits for that fetch.
    /// A stale cache keeps serving lookups while the refresh runs.
    /// - Parameter completion: Called on the main queue; `true` when the cache holds a usable list.
    public func fetchCitiesIfNeeded(completion: ((Bool) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            self.loadFromDiskLocked()

            if let fetchedAt = self.lastFetchedAt,
               Date().timeIntervalSince(fetchedAt) < Self.cacheTTL,
               !self.cities.isEmpty {
                DispatchQueue.main.async { completion?(true) }
                return
            }

            self.fetchLocked(completion: completion)
        }
    }

    /// Answers with the city from the stored list. A city the list does not hold makes it fetch
    /// the list once more, since the city may have been added since it was stored; `nil` means
    /// the city does not exist even then, and it is not fetched for again until the list is.
    /// - Parameter completion: Called on the main queue; fails only when the list could not be fetched.
    public func city(withId cityId: Int, completion: @escaping (Result<TRPCity?, Error>) -> Void) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(.success(nil)) }
                return
            }

            self.loadFromDiskLocked()

            if let city = self.cities.first(where: { $0.id == cityId }) {
                DispatchQueue.main.async { completion(.success(city)) }
                return
            }

            if self.unknownCityIds.contains(cityId) {
                DispatchQueue.main.async { completion(.success(nil)) }
                return
            }

            self.fetchLocked { [weak self] succeeded in
                guard let self = self else { completion(.success(nil)); return }
                guard succeeded else {
                    completion(.failure(GeneralError.customMessage("Cities could not be loaded")))
                    return
                }
                let city = self.getCity(byId: cityId)
                if city == nil {
                    self.queue.async(flags: .barrier) { self.unknownCityIds.insert(cityId) }
                }
                completion(.success(city))
            }
        }
    }

    /// Must be called from inside a `queue` barrier block. Joins the fetch already running, if any,
    /// and calls every waiter on the main queue, outside `queue`, so they can read the cache.
    private func fetchLocked(completion: ((Bool) -> Void)?) {
        if let completion = completion {
            fetchWaiters.append(completion)
        }
        guard !isFetching else { return }
        isFetching = true

        cityRemoteApi.fetchCities { [weak self] result in
            guard let self = self else { return }

            self.queue.async(flags: .barrier) {
                var succeeded = false
                switch result {
                case .success(let fetchedCities):
                    let now = Date()
                    self.cities = fetchedCities
                    self.lastFetchedAt = now
                    self.unknownCityIds.removeAll()
                    let storage = self.storage
                    DispatchQueue.global(qos: .utility).async {
                        storage.save(fetchedCities, at: now)
                    }
                    Log.i("TRPCityCache: Successfully cached \(fetchedCities.count) cities")
                    succeeded = true

                case .failure(let error):
                    Log.e("TRPCityCache: Failed to fetch cities - \(error.localizedDescription)")
                }
                self.isFetching = false
                let waiters = self.fetchWaiters
                self.fetchWaiters = []
                DispatchQueue.main.async {
                    waiters.forEach { $0(succeeded) }
                }
            }
        }
    }

    /// Must be called from inside a `queue` barrier block, or before the cache is shared.
    private func loadFromDiskLocked() {
        guard !didLoadFromDisk else { return }
        didLoadFromDisk = true

        guard cities.isEmpty, let cached = storage.load() else { return }
        cities = cached.cities
        lastFetchedAt = cached.fetchedAt
        Log.i("TRPCityCache: Loaded \(cached.cities.count) cities from disk")
    }

    /// Returns the city with the given ID from cache.
    /// - Parameter cityId: The city ID to look up
    /// - Returns: The TRPCity if found, nil otherwise
    public func getCity(byId cityId: Int) -> TRPCity? {
        var result: TRPCity?
        queue.sync {
            result = cities.first { $0.id == cityId }
        }
        return result
    }

    /// Returns the coordinate of the city with the given ID.
    /// - Parameter cityId: The city ID to look up
    /// - Returns: The TRPLocation coordinate if city found, nil otherwise
    public func getCityCoordinate(cityId: Int) -> TRPLocation? {
        return getCity(byId: cityId)?.coordinate
    }

    /// Returns the nearest city to the given coordinate.
    /// Uses simple distance calculation (suitable for finding nearby cities).
    /// - Parameter coordinate: The coordinate to search near
    /// - Parameter maxDistanceKm: Maximum distance in kilometers (default 100km)
    /// - Returns: The nearest TRPCity if found within maxDistance, nil otherwise
    public func getCityByCoordinate(_ coordinate: TRPLocation, maxDistanceKm: Double = 100) -> TRPCity? {
        var result: TRPCity?
        queue.sync {
            var minDistance = Double.greatestFiniteMagnitude
            for city in cities {
                let distance = calculateDistance(from: coordinate, to: city.coordinate)
                if distance < minDistance && distance <= maxDistanceKm {
                    minDistance = distance
                    result = city
                }
            }
        }
        return result
    }

    /// Calculate distance between two coordinates in kilometers using Haversine formula
    private func calculateDistance(from: TRPLocation, to: TRPLocation) -> Double {
        let earthRadiusKm: Double = 6371.0

        let lat1Rad = from.lat * .pi / 180
        let lat2Rad = to.lat * .pi / 180
        let deltaLatRad = (to.lat - from.lat) * .pi / 180
        let deltaLonRad = (to.lon - from.lon) * .pi / 180

        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKm * c
    }

    /// Returns all cached cities.
    /// - Returns: Array of TRPCity objects
    public func getAllCities() -> [TRPCity] {
        var result: [TRPCity] = []
        queue.sync {
            result = cities
        }
        return result
    }

    /// Checks if cities have been fetched and cached.
    /// - Returns: true if cities are cached, false otherwise
    public func isCacheReady() -> Bool {
        var result: Bool = false
        queue.sync {
            result = !cities.isEmpty
        }
        return result
    }

    /// Clears the cache, in memory and on disk. Useful for logout scenarios.
    public func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cities = []
            self?.lastFetchedAt = nil
            self?.didLoadFromDisk = false
            self?.unknownCityIds.removeAll()
            self?.storage.clear()
            Log.i("TRPCityCache: Cache cleared")
        }
    }

    // MARK: - Search by Name

    /// Searches for a city by name. First checks local cache, then calls API if not found.
    /// - Parameters:
    ///   - name: City name to search for
    ///   - completion: Completion handler with optional TRPCity result
    public func getCityByName(_ name: String, completion: @escaping (TRPCity?) -> Void) {
        // First check local cache (case insensitive)
        var cachedCity: TRPCity?
        queue.sync {
            cachedCity = cities.first { $0.name.lowercased() == name.lowercased() }
        }

        if let city = cachedCity {
            Log.i("TRPCityCache: Found city '\(name)' in cache")
            completion(city)
            return
        }

        // Not in cache, fetch from API
        Log.i("TRPCityCache: City '\(name)' not in cache, fetching from API...")
        cityRemoteApi.fetchCityByName(name) { [weak self] result in
            switch result {
            case .success(let city):
                // Add to cache for future use
                self?.queue.async(flags: .barrier) {
                    // Check if already exists (avoid duplicates)
                    if !(self?.cities.contains(where: { $0.id == city.id }) ?? false) {
                        self?.cities.append(city)
                        Log.i("TRPCityCache: Added city '\(city.name)' to cache from API search")
                    }
                }
                completion(city)

            case .failure(let error):
                Log.e("TRPCityCache: Failed to fetch city '\(name)' - \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    /// Fetches multiple cities by names in parallel.
    /// - Parameters:
    ///   - names: Array of city names to search for
    ///   - completion: Completion handler with dictionary of [cityName: TRPCity]
    public func getCitiesByNames(_ names: [String], completion: @escaping ([String: TRPCity]) -> Void) {
        let uniqueNames = Array(Set(names)) // Remove duplicates
        var results: [String: TRPCity] = [:]
        let dispatchGroup = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.tripian.cityCache.results")

        for name in uniqueNames {
            dispatchGroup.enter()
            getCityByName(name) { city in
                if let city = city {
                    resultsQueue.async {
                        results[name] = city
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
}
