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
    private var cities: [TRPCity] = []
    private var isFetching: Bool = false
    private var hasFetched: Bool = false

    private let cityRemoteApi: TRPCityRemoteApi
    private let queue = DispatchQueue(label: "com.tripian.cityCache", attributes: .concurrent)

    // MARK: - Init
    private init() {
        self.cityRemoteApi = TRPCityRemoteApi()
    }

    // MARK: - Public Methods

    /// Fetches cities from API if not already fetched.
    /// This method is safe to call multiple times - it will only fetch once.
    /// - Parameter completion: Optional completion handler called when fetch completes
    public func fetchCitiesIfNeeded(completion: ((Bool) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }

            // Already fetched or currently fetching
            if self.hasFetched {
                completion?(true)
                return
            }

            if self.isFetching {
                // Already fetching, wait for it to complete
                completion?(false)
                return
            }

            self.isFetching = true

            self.cityRemoteApi.fetchCities { [weak self] result in
                guard let self = self else {
                    completion?(false)
                    return
                }

                self.queue.async(flags: .barrier) {
                    switch result {
                    case .success(let fetchedCities):
                        self.cities = fetchedCities
                        self.hasFetched = true
                        self.isFetching = false
                        Log.i("TRPCityCache: Successfully cached \(fetchedCities.count) cities")
                        completion?(true)

                    case .failure(let error):
                        self.isFetching = false
                        Log.e("TRPCityCache: Failed to fetch cities - \(error.localizedDescription)")
                        completion?(false)
                    }
                }
            }
        }
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
            result = hasFetched
        }
        return result
    }

    /// Clears the cache. Useful for logout scenarios.
    public func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cities = []
            self?.hasFetched = false
            self?.isFetching = false
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
