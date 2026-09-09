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

    /// Located items of the selected day in display order, grouped per city, for drawing the day's route.
    /// Cities with fewer than two located items are omitted.
    func getRouteGroupsForMap() -> [(cityIndex: Int, locations: [TRPLocation])] {
        var locationsByCity: [Int: [TRPLocation]] = [:]
        var cityOrder: [Int] = []

        for entry in getOrderedItemsForMap() {
            guard !entry.item.isNoLocation, let coordinate = entry.item.coordinate,
                  coordinate.lat != 0 || coordinate.lon != 0 else { continue }
            if locationsByCity[entry.cityIndex] == nil {
                cityOrder.append(entry.cityIndex)
            }
            locationsByCity[entry.cityIndex, default: []].append(coordinate)
        }

        return cityOrder.compactMap { cityIndex in
            guard let locations = locationsByCity[cityIndex], locations.count > 1 else { return nil }
            return (cityIndex: cityIndex, locations: locations)
        }
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

    /// Get count of favorite items from timeline (filtered, excludes already-planned)
    public func getFavoriteItemsCount() -> Int {
        return filteredFavoriteItems.count
    }

    /// Check if timeline has favorite items (filtered, excludes already-planned)
    public func hasFavoriteItems() -> Bool {
        return !filteredFavoriteItems.isEmpty
    }

    /// Get favourite items from timeline (filtered, excludes already-planned)
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

    /// Cities (for the selected day) paired with a coordinate to drop their map marker on.
    /// A city is only omitted if NO usable coordinate can be found anywhere (see `resolveCityMarkerCoordinate`).
    public func getCitiesWithCoordinatesForSelectedDay() -> [(city: TRPCity, coordinate: TRPLocation)] {
        var result: [(city: TRPCity, coordinate: TRPLocation)] = []

        for cityGroup in displayItems {
            guard let city = cityGroup.city else { continue }

            if let coordinate = resolveCityMarkerCoordinate(for: city, items: cityGroup.items) {
                result.append((city: city, coordinate: coordinate))
            }
        }

        return result
    }

    /// Best-effort coordinate for a city's map marker, tried in priority order. Prevents a
    /// city from losing its marker just because its first item is no-location (the old code
    /// only looked at `items.first` and accepted a (0,0) coordinate). Returns nil only when
    /// every source is exhausted.
    private func resolveCityMarkerCoordinate(for city: TRPCity, items: [TRPMergedTimelineItem]) -> TRPLocation? {
        // 1) The city's own coordinate.
        if isUsableCoordinate(city.coordinate) { return city.coordinate }

        // 2) The first item — any item, not just `items.first` — that carries a real coordinate.
        //    No-location items expose a nil/zero coordinate, so they're skipped here.
        if let itemCoordinate = items.compactMap({ $0.coordinate }).first(where: { isUsableCoordinate($0) }) {
            return itemCoordinate
        }

        // 3) A plan for this city: its city coordinate, then any step POI coordinate.
        if let plans = timeline?.plans {
            for plan in plans where plan.city?.id == city.id {
                if let planCity = plan.city?.coordinate, isUsableCoordinate(planCity) { return planCity }
                if let stepCoordinate = plan.steps.compactMap({ $0.poi?.coordinate }).first(where: { isUsableCoordinate($0) }) {
                    return stepCoordinate
                }
            }
        }

        // 4) Last resort: the shared city cache (resolved from the /cities API by id).
        if let cached = TRPCityCache.shared.getCityCoordinate(cityId: city.id), isUsableCoordinate(cached) {
            return cached
        }

        return nil
    }

    /// A coordinate is usable for a marker only if it isn't the (0,0) null-island placeholder.
    private func isUsableCoordinate(_ coordinate: TRPLocation) -> Bool {
        return coordinate.lat != 0 || coordinate.lon != 0
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

    public func calculateRoute(for locations: [TRPLocation],
                               profile: TRPRouteCalculator.DirectionProfile = .walking,
                               completion: @escaping (Route?, Error?) -> Void) {
        guard locations.count > 1 else {
            completion(nil, nil)
            return
        }

        guard let accessToken = TRPApiKeyController.getKey(TRPApiKeys.mglMapboxAccessToken) else {
            completion(nil, NSError(domain: "MapBox", code: -1, userInfo: [NSLocalizedDescriptionKey: "MapBox access token not found"]))
            return
        }

        let calculator = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: locations, dailyPlanId: 0, profile: profile)
        // Retain calculator to prevent deallocation during the async operation.
        activeRouteCalculators.append(calculator)
        calculator.calculateRoute { [weak self] route, error, _, _ in
            DispatchQueue.main.async {
                self?.activeRouteCalculators.removeAll { $0 === calculator }
                completion(route, error)
            }
        }
    }

    /// Routes each consecutive pair in `locations`: every pair is walked first, and pairs whose walking
    /// distance reaches `TRPStepRouteInfo.walkingThresholdMeters` are re-routed by car in a second request.
    /// Completes on the main thread with one entry per pair (`legs[i]` is `locations[i]` → `locations[i+1]`),
    /// or nil when the walking request fails.
    func calculateStepRoutes(for locations: [TRPLocation], completion: @escaping ([TRPStepRouteInfo]?) -> Void) {
        calculateRoute(for: locations, profile: .walking) { [weak self] walkingRoute, _ in
            guard let self = self, let walkingLegs = walkingRoute?.legs else {
                completion(nil)
                return
            }

            let needsDriving = walkingLegs.contains { $0.distance >= TRPStepRouteInfo.walkingThresholdMeters }
            guard needsDriving else {
                completion(walkingLegs.map { TRPStepRouteInfo(leg: $0, isWalking: true) })
                return
            }

            self.calculateRoute(for: locations, profile: .automobile) { drivingRoute, _ in
                let routes = walkingLegs.enumerated().map { index, walkingLeg -> TRPStepRouteInfo in
                    guard walkingLeg.distance >= TRPStepRouteInfo.walkingThresholdMeters else {
                        return TRPStepRouteInfo(leg: walkingLeg, isWalking: true)
                    }
                    guard let drivingLeg = drivingRoute?.legs[safe: index] else {
                        return TRPStepRouteInfo.estimatedDriving(from: walkingLeg)
                    }
                    return TRPStepRouteInfo(leg: drivingLeg, isWalking: false)
                }
                completion(routes)
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
