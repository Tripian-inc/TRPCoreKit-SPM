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
    /// Returns items with unified order, sorted by section then order ascending
    /// This matches the order displayed in the list view (city-based numbering)
    public func getOrderedItemsForMap() -> [(order: Int, section: Int, item: MapDisplayItem)] {
        var result: [(order: Int, section: Int, item: MapDisplayItem)] = []

        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            for item in cityGroup.items {
                // Key format: "sectionIndex_segmentIndex"
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"
                let startingOrder = unifiedOrderMap[key] ?? 1

                switch item.segmentType {
                case .bookedActivity, .reservedActivity:
                    // Single activity item
                    result.append((order: startingOrder, section: sectionIndex, item: .activity(item.segment)))

                case .manualPoi:
                    // Manual POI (no step info available)
                    if let poi = item.manualPoi {
                        result.append((order: startingOrder, section: sectionIndex, item: .poi(poi, item.segment, nil)))
                    }

                case .itinerary:
                    // Recommendations - each step gets sequential order
                    for (index, step) in item.steps.enumerated() {
                        if let poi = step.poi {
                            let stepOrder = startingOrder + index
                            result.append((order: stepOrder, section: sectionIndex, item: .poi(poi, item.segment, step)))
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
        calculator.calculateRoute { route, error, _, _ in
            DispatchQueue.main.async {
                completion(route, error)
            }
        }
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
