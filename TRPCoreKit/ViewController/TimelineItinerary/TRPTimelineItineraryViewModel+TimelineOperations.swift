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

            DispatchQueue.main.async {
                switch result {
                case .success(var timeline):
                    // Merge itinerary model data (only favouriteItems - segments handled via API)
                    timeline = self.mergeItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                    // NOTE: Do NOT sync segments - use API response as-is
                    // tripProfile.segments is the single source of truth
                    // Populate city information in segments BEFORE processing
                    self.populateCitiesInSegments(&timeline)

                    // Update timeline and process data
                    self.timeline = timeline
                    self.processTimelineData()

                    // Notify delegate - UI is ready
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                    // Check for missing booked activities and add via API if needed
                    // This runs in background after UI is shown
                    self.addMissingBookedActivities(from: itineraryModel)

                case .failure(let error):
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

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(var updatedTimeline):
                    // Preserve favouriteItems from previous timeline (API doesn't return these)
                    updatedTimeline.favouriteItems = self.timeline?.favouriteItems
                    // Populate city information in segments BEFORE processing
                    self.populateCitiesInSegments(&updatedTimeline)
                    self.timeline = updatedTimeline
                    self.processTimelineData()
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    completion?(true)

                case .failure:
                    // Even if refresh fails, notify UI to reload with local data
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    completion?(true)
                }
            }
        }
    }
}
