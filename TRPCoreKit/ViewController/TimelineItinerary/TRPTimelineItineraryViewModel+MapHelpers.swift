//
//  TRPTimelineItineraryViewModel+MapHelpers.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Map helper methods extracted from main ViewModel
//

import Foundation
import TRPFoundationKit
import MapboxDirections

// MARK: - Map Helper Methods

extension TRPTimelineItineraryViewModel {

    /// Get ordered items for map display (collection view and annotations)
    /// Returns items with unified order, cityIndex for marker coloring, sorted by section then order ascending
    /// This matches the order displayed in the list view (city-based numbering)
    public func getOrderedItemsForMap() -> [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] {
        var result: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] = []

        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            let cityIndex = sectionIndex  // Each section is a different city
            for item in cityGroup.items {
                // Key format: "sectionIndex_segmentIndex"
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"
                let startingOrder = unifiedOrderMap[key] ?? 1

                switch item.segmentType {
                case .bookedActivity, .reservedActivity:
                    // isNoLocation activities are kept in the result so the bottom
                    // preview collection can still surface them (with a "no exact
                    // location" tag). Map annotations skip them separately.
                    result.append((order: startingOrder, section: sectionIndex, cityIndex: cityIndex, item: .activity(item.segment)))

                case .manualPoi:
                    // Manual POI (no step info available)
                    if let poi = item.manualPoi {
                        result.append((order: startingOrder, section: sectionIndex, cityIndex: cityIndex, item: .poi(poi, item.segment, nil)))
                    }

                case .itinerary:
                    // Recommendations - each step gets sequential order
                    for (index, step) in item.steps.enumerated() {
                        if let poi = step.poi {
                            let stepOrder = startingOrder + index
                            result.append((order: stepOrder, section: sectionIndex, cityIndex: cityIndex, item: .poi(poi, item.segment, step)))
                        }
                    }
                }
            }
        }

        // Sort by section first, then by order within section
        return result.sorted { ($0.section, $0.order) < ($1.section, $1.order) }
    }

    /// Get all POIs for the currently selected day
    public func getPoisForSelectedDay() -> [TRPPoi] {
        var pois: [TRPPoi] = []
        for cityGroup in displayItems {
            for item in cityGroup.items {
                pois.append(contentsOf: item.getAllPois())
            }
        }
        return pois
    }

    /// Get POIs grouped by segments for the selected day
    /// Each inner array represents a separate segment that should have its own route
    public func getSegmentsWithPoisForSelectedDay() -> [[TRPPoi]] {
        var segmentGroups: [[TRPPoi]] = []
        for cityGroup in displayItems {
            for item in cityGroup.items {
                let pois = item.getAllPois()
                if !pois.isEmpty {
                    segmentGroups.append(pois)
                }
            }
        }
        return segmentGroups
    }

    /// Get booked and reserved activities for the selected day
    public func getBookedActivitiesForSelectedDay() -> [TRPTimelineSegment] {
        return displayItems.flatMap { cityGroup in
            cityGroup.items.filter { $0.isBookedActivity || $0.isReservedActivity }.map { $0.segment }
        }
    }

    /// Get all booked and reserved activities (for all days, used in POI selection)
    public func getAllBookedActivities() -> [TRPTimelineSegment] {
        return mergedTimeline?.allBookedActivities ?? []
    }

    /// Get count of reserved activities (saved plans that haven't been purchased)
    public func getReservedActivitiesCount() -> Int {
        return mergedTimeline?.reservedActivitiesCount ?? 0
    }

    /// Get count of favorite items from timeline (filtered, excludes booked/reserved)
    public func getFavoriteItemsCount() -> Int {
        return filteredFavoriteItems.count
    }

    /// Check if timeline has favorite items (filtered, excludes booked/reserved)
    public func hasFavoriteItems() -> Bool {
        return !filteredFavoriteItems.isEmpty
    }

    /// Get favourite items from timeline (filtered, excludes booked/reserved)
    public func getFavoriteItems() -> [TRPSegmentFavoriteItem] {
        return filteredFavoriteItems
    }

    /// Get POI by ID
    public func getPoi(byId id: String) -> TRPPoi? {
        for cityGroup in displayItems {
            for item in cityGroup.items {
                for poi in item.getAllPois() {
                    if poi.id == id {
                        return poi
                    }
                }
            }
        }
        return nil
    }

    /// Get booked or reserved activity by activity ID
    public func getBookedActivity(byId activityId: String) -> TRPTimelineSegment? {
        for cityGroup in displayItems {
            for item in cityGroup.items {
                if item.isBookedActivity || item.isReservedActivity {
                    if let additionalData = item.segment.additionalData,
                       additionalData.activityId == activityId {
                        return item.segment
                    }
                }
            }
        }
        return nil
    }

    /// Get step for a specific POI ID
    public func getStep(forPoiId id: String) -> TRPTimelineStep? {
        for cityGroup in displayItems {
            for item in cityGroup.items {
                // Get steps from merged item
                for step in item.steps {
                    if let poi = step.poi, poi.id == id {
                        return step
                    }
                }
            }
        }
        return nil
    }

    /// Get first plan from timeline
    public func getFirstPlan() -> TRPTimelinePlan? {
        return timeline?.plans?.first
    }

    /// Check if the selected day has multiple cities
    public func hasMultipleCities() -> Bool {
        return displayItems.count > 1
    }

    /// Get cities with coordinates for the selected day (for city marker annotations)
    /// Prefers `TRPCity.coordinate` so the city marker doesn't collide with the auto-selected
    /// step marker (which uses the first item's coordinate). Falls back to the first item only
    /// when the city has no coordinate set (lat/lon both zero).
    public func getCitiesWithCoordinatesForSelectedDay() -> [(city: TRPCity, coordinate: TRPLocation)] {
        var result: [(city: TRPCity, coordinate: TRPLocation)] = []

        for cityGroup in displayItems {
            guard let city = cityGroup.city else { continue }

            if city.coordinate.lat != 0 || city.coordinate.lon != 0 {
                result.append((city: city, coordinate: city.coordinate))
            } else if let firstItemCoordinate = cityGroup.items.first?.coordinate {
                result.append((city: city, coordinate: firstItemCoordinate))
            }
        }

        return result
    }

    /// Get cities for the selected day (for city marker annotations)
    /// Note: Cities may not have coordinates set - use getCitiesWithCoordinatesForSelectedDay() instead
    public func getCitiesForSelectedDay() -> [TRPCity] {
        return displayItems.compactMap { $0.city }
    }

    /// Get the preferred city coordinate for map centering
    /// Priority: selected day's first city > timeline.city > first plan city > nil
    public func getPreferredCityCoordinate() -> TRPLocation? {
        // 1. O gün bulunan ilk plan'ın şehri (seçili gün)
        if let city = displayItems.first?.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        // 2. Timeline'ın ana city'si
        if let city = timeline?.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        // 3. İlk plan'ın city'si (tüm günlerde)
        if let firstPlan = getFirstPlan(),
           let city = firstPlan.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        return nil
    }

    /// Calculate route for given locations
    public func calculateRoute(for locations: [TRPLocation], completion: @escaping (Route?, Error?) -> Void) {
        guard locations.count > 1 else {
            completion(nil, nil)
            return
        }

        guard let accessToken = TRPApiKeyController.getKey(TRPApiKeys.mglMapboxAccessToken) else {
            completion(nil, NSError(domain: "MapBox", code: -1, userInfo: [NSLocalizedDescriptionKey: "MapBox access token not found"]))
            return
        }

        let calculator = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: locations, dailyPlanId: 0)
        // Retain calculator to prevent deallocation during async operation
        activeRouteCalculators.append(calculator)
        calculator.calculateRoute { [weak self] route, error, _, _ in
            DispatchQueue.main.async {
                // Remove calculator from active list after completion
                self?.activeRouteCalculators.removeAll { $0 === calculator }
                completion(route, error)
            }
        }
    }

    /// Cancel all active route calculations (e.g., when switching days)
    public func cancelActiveRouteCalculations() {
        activeRouteCalculators.removeAll()
    }

    // MARK: - Segment Route Calculation

    /// Returns itinerary segments with multiple steps for route calculation
    /// - Returns: Array of segment index and POI locations tuples
    public func getItinerarySegmentsForRouteCalculation() -> [(segmentIndex: Int, locations: [TRPLocation])] {
        var result: [(segmentIndex: Int, locations: [TRPLocation])] = []
        var segmentIndex = 0

        for cityGroup in displayItems {
            for item in cityGroup.items {
                // Only itinerary type segments
                if item.isItinerary {
                    // Only segments with more than 1 step
                    let steps = item.steps
                    if steps.count > 1 {
                        // Collect POI coordinates
                        let locations = steps.compactMap { $0.poi?.coordinate }
                        if locations.count > 1 {
                            result.append((segmentIndex: segmentIndex, locations: locations))
                        }
                    }
                }
                segmentIndex += 1
            }
        }

        return result
    }
}
