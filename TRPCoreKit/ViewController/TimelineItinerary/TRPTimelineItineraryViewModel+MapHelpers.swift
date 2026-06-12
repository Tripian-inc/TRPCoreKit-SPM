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

    /// Ordered items for map display, matching the list view's city-based numbering, sorted by section then order.
    public func getOrderedItemsForMap() -> [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] {
        var result: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] = []

        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            let cityIndex = sectionIndex
            for item in cityGroup.items {
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"
                let startingOrder = unifiedOrderMap[key] ?? 1

                switch item.segmentType {
                case .bookedActivity, .reservedActivity:
                    // Kept here so the preview collection can surface isNoLocation items; map annotations skip them separately.
                    result.append((order: startingOrder, section: sectionIndex, cityIndex: cityIndex, item: .activity(item.segment)))

                case .manualPoi:
                    if let poi = item.manualPoi {
                        result.append((order: startingOrder, section: sectionIndex, cityIndex: cityIndex, item: .poi(poi, item.segment, nil)))
                    }

                case .itinerary:
                    for (index, step) in item.steps.enumerated() {
                        if let poi = step.poi {
                            let stepOrder = startingOrder + index
                            result.append((order: stepOrder, section: sectionIndex, cityIndex: cityIndex, item: .poi(poi, item.segment, step)))
                        }
                    }
                }
            }
        }

        return result.sorted { ($0.section, $0.order) < ($1.section, $1.order) }
    }

    /// Get all POIs for the currently selected day.
    public func getPoisForSelectedDay() -> [TRPPoi] {
        var pois: [TRPPoi] = []
        for cityGroup in displayItems {
            for item in cityGroup.items {
                pois.append(contentsOf: item.getAllPois())
            }
        }
        return pois
    }

    /// POIs grouped by segment for the selected day; each inner array gets its own route.
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

    /// Get booked and reserved activities for the selected day.
    public func getBookedActivitiesForSelectedDay() -> [TRPTimelineSegment] {
        return displayItems.flatMap { cityGroup in
            cityGroup.items.filter { $0.isBookedActivity || $0.isReservedActivity }.map { $0.segment }
        }
    }

    /// Get all booked and reserved activities (all days, used in POI selection).
    public func getAllBookedActivities() -> [TRPTimelineSegment] {
        return mergedTimeline?.allBookedActivities ?? []
    }

    /// Count of reserved activities (saved plans not yet purchased).
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

    public func getStep(forPoiId id: String) -> TRPTimelineStep? {
        for cityGroup in displayItems {
            for item in cityGroup.items {
                for step in item.steps {
                    if let poi = step.poi, poi.id == id {
                        return step
                    }
                }
            }
        }
        return nil
    }

    public func getFirstPlan() -> TRPTimelinePlan? {
        return timeline?.plans?.first
    }

    public func hasMultipleCities() -> Bool {
        return displayItems.count > 1
    }

    /// Prefers `TRPCity.coordinate` (avoids colliding with the auto-selected step marker); falls back to the first item only when the city coordinate is zero.
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

    /// Cities for the selected day. They may lack coordinates — use getCitiesWithCoordinatesForSelectedDay() for markers.
    public func getCitiesForSelectedDay() -> [TRPCity] {
        return displayItems.compactMap { $0.city }
    }

    /// Preferred city coordinate for map centering. Priority: selected day's first city > timeline.city > first plan city > nil.
    public func getPreferredCityCoordinate() -> TRPLocation? {
        if let city = displayItems.first?.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        if let city = timeline?.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        if let firstPlan = getFirstPlan(),
           let city = firstPlan.city,
           city.coordinate.lat != 0 || city.coordinate.lon != 0 {
            return city.coordinate
        }

        return nil
    }

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
        // Retain calculator to prevent deallocation during the async operation.
        activeRouteCalculators.append(calculator)
        calculator.calculateRoute { [weak self] route, error, _, _ in
            DispatchQueue.main.async {
                self?.activeRouteCalculators.removeAll { $0 === calculator }
                completion(route, error)
            }
        }
    }

    /// Cancel all active route calculations (e.g. when switching days).
    public func cancelActiveRouteCalculations() {
        activeRouteCalculators.removeAll()
    }

    // MARK: - Segment Route Calculation

    /// Returns itinerary segments with multiple steps for route calculation, as (segmentIndex, POI locations) tuples.
    public func getItinerarySegmentsForRouteCalculation() -> [(segmentIndex: Int, locations: [TRPLocation])] {
        var result: [(segmentIndex: Int, locations: [TRPLocation])] = []
        var segmentIndex = 0

        for cityGroup in displayItems {
            for item in cityGroup.items {
                if item.isItinerary {
                    let steps = item.steps
                    if steps.count > 1 {
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
