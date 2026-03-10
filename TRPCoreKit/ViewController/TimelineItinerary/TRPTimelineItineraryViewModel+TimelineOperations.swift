//
//  TRPTimelineItineraryViewModel+TimelineOperations.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Timeline creation, fetch, and refresh methods extracted from main ViewModel
//

import Foundation
import TRPFoundationKit

// MARK: - Timeline Creation/Fetch Methods

extension TRPTimelineItineraryViewModel {

    /// Creates a new timeline from itinerary model
    internal func createTimeline(from itineraryModel: TRPItineraryWithActivities) {
        // First, resolve missing cityIds in destination items
        resolveMissingCityIds(in: itineraryModel) { [weak self] resolvedItineraryModel in
            guard let self = self else { return }
            self.createTimelineInternal(from: resolvedItineraryModel)
        }
    }

    /// Internal method to create timeline after city resolution
    internal func createTimelineInternal(from itineraryModel: TRPItineraryWithActivities) {
        // Create timeline profile from itinerary
        let profile = itineraryModel.createTimelineProfileFromBookings()

        // Also add favourite items to profile
        profile.favouriteItems = itineraryModel.favouriteItems

        // Create timeline using repository
        let repository = TRPTimelineRepository()
        let createUseCase = TRPCreateTimelineUseCase(repository: repository)

        createUseCase.executeCreateTimeline(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let createdTimeline):
                // Wait for timeline generation to complete
                self.waitForTimelineGeneration(tripHash: createdTimeline.tripHash, itineraryModel: itineraryModel)

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    // MARK: - City Resolution

    /// Resolves missing or invalid cityIds in destination items
    /// Checks: cityId is nil, <= 0, OR not found in cache
    /// Uses API first, then falls back to local cache if API fails
    /// SDK continues even if some cities cannot be resolved
    internal func resolveMissingCityIds(in itineraryModel: TRPItineraryWithActivities,
                                        completion: @escaping (TRPItineraryWithActivities) -> Void) {
        var mutableItinerary = itineraryModel

        // Find items that need city resolution:
        // 1. cityId is nil or <= 0
        // 2. cityId > 0 but not found in cache (invalid/unknown city)
        let itemsNeedingResolution = mutableItinerary.destinationItems.enumerated()
            .filter { item in
                let cityId = item.element.cityId
                // Need resolution if: no cityId or invalid cityId
                if cityId == nil || (cityId ?? 0) <= 0 {
                    return true
                }
                // Also need resolution if cityId exists but not found in cache
                if let id = cityId, TRPCityCache.shared.getCity(byId: id) == nil {
                    return true
                }
                return false
            }
            .map { (index: $0.offset, item: $0.element) }

        Log.i("TRPTimelineItineraryViewModel: Checking destination items for city resolution")
        Log.i("TRPTimelineItineraryViewModel: Total destinations: \(mutableItinerary.destinationItems.count), needing resolution: \(itemsNeedingResolution.count)")

        // If all have valid cityId in cache, proceed directly
        if itemsNeedingResolution.isEmpty {
            Log.i("TRPTimelineItineraryViewModel: All destination items have valid cityIds in cache, proceeding")
            completion(mutableItinerary)
            return
        }

        // Parse coordinates for API call
        let coordinates = itemsNeedingResolution.map { parseCoordinate(from: $0.item.coordinate) }

        Log.i("TRPTimelineItineraryViewModel: Resolving \(itemsNeedingResolution.count) cityIds via API")
        for (i, coord) in coordinates.enumerated() {
            let item = itemsNeedingResolution[i].item
            Log.i("TRPTimelineItineraryViewModel: coordinate[\(i)] = lat: \(coord.lat), lon: \(coord.lon), currentCityId: \(item.cityId ?? -1)")
        }

        // Try API first (more accurate)
        let cityRemoteApi = TRPCityRemoteApi()
        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cityIds):
                Log.i("TRPTimelineItineraryViewModel: resolveCities API success - cityIds: \(cityIds)")
                // Update destination items with resolved cityIds
                for (i, (index, _)) in itemsNeedingResolution.enumerated() {
                    if i < cityIds.count && cityIds[i] > 0 {
                        mutableItinerary.destinationItems[index].cityId = cityIds[i]
                        Log.i("TRPTimelineItineraryViewModel: Set destinationItems[\(index)].cityId = \(cityIds[i])")
                    } else {
                        Log.w("TRPTimelineItineraryViewModel: Could not resolve cityId for destinationItems[\(index)] - API returned invalid id")
                    }
                }
                // Continue even if some cities could not be resolved
                completion(mutableItinerary)

            case .failure(let error):
                Log.e("TRPTimelineItineraryViewModel: resolveCities API failed - \(error.localizedDescription)")
                // Fallback: Use TRPCityCache (local Haversine distance calculation)
                Log.i("TRPTimelineItineraryViewModel: Using cache fallback")
                self.resolveCityIdsFromCache(items: itemsNeedingResolution, itinerary: &mutableItinerary)
                // Continue even if some cities could not be resolved
                completion(mutableItinerary)
            }
        }
    }

    /// Fallback method to resolve cities from local cache using coordinate proximity
    private func resolveCityIdsFromCache(items: [(index: Int, item: TRPSegmentDestinationItem)],
                                         itinerary: inout TRPItineraryWithActivities) {
        for (index, item) in items {
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate, maxDistanceKm: 100) {
                itinerary.destinationItems[index].cityId = city.id
                Log.i("TRPTimelineItineraryViewModel: Cache resolved destinationItems[\(index)].cityId = \(city.id) (\(city.name))")
            } else {
                Log.w("TRPTimelineItineraryViewModel: Could not resolve cityId for destinationItems[\(index)] from cache")
            }
        }
    }


    /// Waits for timeline generation to complete
    internal func waitForTimelineGeneration(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        let repository = TRPTimelineRepository()
        let modelRepository = TRPTimelineModelRepository()
        TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)

        // Store use case as instance variable to prevent deallocation
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: repository,
            timelineModelRepository: modelRepository
        )

        // Observe when all segments are generated
        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }
            guard isGenerated else { return }

            // Fetch the complete timeline
            self.fetchTimeline(tripHash: tripHash, itineraryModel: itineraryModel)

            // Clear use case reference after completion
            self.checkAllPlanUseCase = nil
        }

        // Start checking generation status
        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                break

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                    // Clear use case reference on error
                    self.checkAllPlanUseCase = nil
                }
            }
        }
    }

    /// Fetches existing timeline by tripHash
    internal func fetchTimeline(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var timeline):
                // Merge itinerary model data (only favouriteItems - segments handled via API)
                timeline = self.mergeItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                // NOTE: Do NOT sync segments - use API response as-is
                // tripProfile.segments is the single source of truth
                // Populate city information in segments BEFORE processing
                self.populateCitiesInSegments(&timeline)

                // Update timeline
                self.timeline = timeline

                // Resolve favourite item city IDs, then process data
                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.processTimelineData()

                        // Notify delegate - UI is ready
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                        // Check for missing booked activities and add via API if needed
                        // This runs in background after UI is shown
                        self.addMissingBookedActivities(from: itineraryModel)
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Merges itinerary model data into timeline
    /// IMPORTANT: Does NOT modify segments - only adds favouriteItems
    /// Missing booked activities should be added via addMissingBookedActivities() which calls API
    internal func mergeItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) -> TRPTimeline {
        var updatedTimeline = timeline

        // Add favourite items only - segments are handled separately via API
        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        return updatedTimeline
    }

    // MARK: - Add Missing Booked Activities

    /// Adds missing booked activities from itineraryModel to timeline via API
    /// Compares itineraryModel.tripItems with timeline segments and adds only missing ones
    /// - Parameter itineraryModel: Itinerary model containing tripItems to check
    public func addMissingBookedActivities(from itineraryModel: TRPItineraryWithActivities) {
        guard let timeline = timeline,
              let tripItems = itineraryModel.tripItems,
              !tripItems.isEmpty else {
            return
        }

        let tripHash = timeline.tripHash

        // Collect existing activity IDs from timeline (both segments and tripProfile.segments)
        var existingActivityIds = Set<String>()

        if let segments = timeline.segments {
            for segment in segments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId)
                }
            }
        }

        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId)
                }
            }
        }

        // Find tripItems that are NOT in timeline
        let missingTripItems = tripItems.filter { tripItem in
            guard let activityId = tripItem.activityId else { return false }
            return !existingActivityIds.contains(activityId)
        }

        // If no missing items, nothing to do
        guard !missingTripItems.isEmpty else {
            return
        }

        Log.i("TRPTimelineItineraryViewModel: Found \(missingTripItems.count) missing booked activities to add via API")

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Add each missing tripItem via API (sequentially)
        addMissingTripItemsSequentially(tripItems: missingTripItems, tripHash: tripHash, index: 0)
    }

    /// Recursively adds missing tripItems one by one via API
    internal func addMissingTripItemsSequentially(tripItems: [TRPSegmentActivityItem], tripHash: String, index: Int) {
        // Base case: all items added
        guard index < tripItems.count else {
            Log.i("TRPTimelineItineraryViewModel: All missing booked activities added successfully")
            // Wait for generation and refresh timeline
            waitForSegmentGeneration(tripHash: tripHash)
            return
        }

        let tripItem = tripItems[index]

        // Create segment profile from tripItem
        let profile = createSegmentProfileFromTripItem(tripItem, tripHash: tripHash)

        // Call API to add segment
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let success):
                if success {
                    Log.i("TRPTimelineItineraryViewModel: Added booked activity \(tripItem.activityId ?? "unknown") via API")
                    // Continue with next item
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                } else {
                    Log.e("TRPTimelineItineraryViewModel: Failed to add booked activity \(tripItem.activityId ?? "unknown")")
                    // Continue anyway to try remaining items
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                }

            case .failure(let error):
                Log.e("TRPTimelineItineraryViewModel: Error adding booked activity: \(error.localizedDescription)")
                // Continue anyway to try remaining items
                self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
            }
        }
    }

    /// Creates a TRPCreateEditTimelineSegmentProfile from a TRPSegmentActivityItem
    internal func createSegmentProfileFromTripItem(_ tripItem: TRPSegmentActivityItem, tripHash: String) -> TRPCreateEditTimelineSegmentProfile {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        // Set segment type
        profile.segmentType = .bookedActivity

        // Set basic properties
        profile.title = tripItem.title
        profile.description = tripItem.description
        profile.available = false // Booking products are fixed activities
        profile.distinctPlan = true

        // Set dates
        profile.startDate = tripItem.startDatetime
        profile.endDate = tripItem.endDatetime

        // Set coordinate
        profile.coordinate = tripItem.coordinate

        // Set traveler counts
        profile.adults = tripItem.adultCount
        profile.children = tripItem.childCount
        profile.pets = 0

        // Set additional data (this is CRITICAL for booked activities)
        profile.additionalData = tripItem

        // Don't generate recommendations for booked activities
        profile.doNotGenerate = 1

        return profile
    }

    /// Populates city information in segments using index-based mapping with plans
    /// CRITICAL: ONLY tripProfile.segments[i] and plans[i] represent the SAME segment (same order)
    /// timeline.segments has DIFFERENT order/content, so we DON'T use index mapping for it
    internal func populateCitiesInSegments(_ timeline: inout TRPTimeline, destinationItems: [TRPSegmentDestinationItem] = []) {
        guard let plans = timeline.plans, !plans.isEmpty else {
            return
        }

        // ONLY populate city info for tripProfile.segments using index-based mapping
        // timeline.segments has different order/content than plans, so we skip it
        if let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for (index, segment) in profileSegments.enumerated() {
                // Skip if segment already has complete city info
                if let existingCity = segment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                // Get corresponding plan city (same index)
                if index < plans.count, let planCity = plans[index].city, planCity.id > 0 {
                    segment.city = planCity
                }
            }
        }

        // For timeline.segments: Copy city from corresponding tripProfile.segments by matching unique ID
        if let segments = timeline.segments, !segments.isEmpty,
           let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for timelineSegment in segments {
                // Skip if already has city
                if let existingCity = timelineSegment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                // Find matching segment in tripProfile.segments by unique ID
                let timelineSegmentId = getSegmentUniqueId(timelineSegment)

                for profileSegment in profileSegments {
                    let profileSegmentId = getSegmentUniqueId(profileSegment)

                    if timelineSegmentId == profileSegmentId {
                        // Found matching segment, copy city
                        if let profileCity = profileSegment.city, profileCity.id > 0 {
                            timelineSegment.city = profileCity
                        }
                        break
                    }
                }
            }
        }
    }

    // MARK: - Timeline Refresh (Unified)

    /// Refreshes the timeline from server
    /// Use this after any operation that might affect timeline ordering
    public func refreshTimeline() {
        fetchAndRefreshTimeline(completion: nil)
    }

    /// Unified method for fetching and refreshing timeline from server
    /// - Parameter completion: Optional completion handler called after refresh (success: Bool)
    internal func fetchAndRefreshTimeline(completion: ((Bool) -> Void)?) {
        guard let tripHash = timeline?.tripHash else {
            delegate?.viewModel(showPreloader: false)
            completion?(true)
            return
        }

        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var updatedTimeline):
                // Preserve favouriteItems from previous timeline (API doesn't return these)
                updatedTimeline.favouriteItems = self.timeline?.favouriteItems
                // Populate city information in segments BEFORE processing
                self.populateCitiesInSegments(&updatedTimeline)
                self.timeline = updatedTimeline

                // Resolve favourite item city IDs, then process data
                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.delegate?.viewModel(showPreloader: false)
                        self.processTimelineData()
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                        completion?(true)
                    }
                }

            case .failure:
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    // Even if refresh fails, notify UI to reload with local data
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    completion?(true)
                }
            }
        }
    }
}
