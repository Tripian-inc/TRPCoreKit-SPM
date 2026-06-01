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

            // Check if ALL cities are unresolved (no valid cityId found for any destination)
            let allCitiesInvalid = resolvedItineraryModel.destinationItems.allSatisfy { item in
                guard let cityId = item.cityId else { return true }
                return cityId <= 0
            }

            if allCitiesInvalid {
                DispatchQueue.main.async {
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.timelineItineraryViewModel(noCitiesAvailable: true)
                }
                return
            }

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
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    // MARK: - City Resolution

    /// Resolves cityIds for ALL destination items via API
    /// ALL destinations are sent to the API to validate city support
    /// Uses API first, then falls back to local cache if API fails
    /// SDK continues even if some cities cannot be resolved
    internal func resolveMissingCityIds(in itineraryModel: TRPItineraryWithActivities,
                                        completion: @escaping (TRPItineraryWithActivities) -> Void) {
        var mutableItinerary = itineraryModel

        // Get ALL destination items for resolution (not just ones with missing cityIds)
        let allItems = mutableItinerary.destinationItems.enumerated()
            .map { (index: $0.offset, item: $0.element) }

        // If no destinations, proceed directly
        if allItems.isEmpty {
            completion(mutableItinerary)
            return
        }

        // Parse coordinates for ALL items
        let coordinates = allItems.map { parseCoordinate(from: $0.item.coordinate) }

        // Try API first (more accurate)
        let cityRemoteApi = TRPCityRemoteApi()
        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cityIds):
                // Update ALL destination items with resolved cityIds
                for (i, (index, _)) in allItems.enumerated() {
                    if i < cityIds.count && cityIds[i] > 0 {
                        mutableItinerary.destinationItems[index].cityId = cityIds[i]
                    } else {
                        // API returned 0 or invalid - city not supported
                        mutableItinerary.destinationItems[index].cityId = 0
                    }
                }
                // Continue even if some cities could not be resolved
                completion(mutableItinerary)

            case .failure(let error):
                self.resolveCityIdsFromCache(items: allItems, itinerary: &mutableItinerary)
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
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
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

                self.populateCitiesInSegments(&timeline)
                self.timeline = timeline
                self.itineraryModel = itineraryModel

                // Resolve favourite item city IDs, then process data
                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.processTimelineData()

                        // Sync TimelineDate range
                        self.syncTimelineDateRange()

                        // Sync reserved activities (wait for completion before adding booked)
                        self.syncReservedActivitiesWithTripItems { [weak self] in
                            guard let self = self else { return }

                            // After reserved deletion completes, add missing booked activities
                            print("🔄 [Sync] Reserved deletion completed, now adding missing booked activities")
                            self.addMissingBookedActivities(from: itineraryModel)
                        }

                        // Sync removed city segments (parallel with reserved sync)
                        self.syncRemovedCitySegments()

                        // Notify delegate - UI is ready
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Merges itinerary model data into timeline
    /// Missing booked activities should be added via addMissingBookedActivities() which calls API
    internal func mergeItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) -> TRPTimeline {
        var updatedTimeline = timeline

        // Add favourite items only - segments are handled separately via API
        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        return updatedTimeline
    }

    // MARK: - CityId Resolution

    /// Resolves cityIds for tripItems. Items with a real coordinate go through
    /// cities/resolve (existing path). Items missing a coordinate are resolved via
    /// tour-api/product-lookup using their `activityId` so we can still place them
    /// in the right city section instead of dropping to `cityId = 0`.
    /// - Parameters:
    ///   - tripItems: Array of tripItems to resolve
    ///   - completion: Called with updated tripItems (cityId fields populated)
    internal func resolveTripItemsCityIds(
        tripItems: [TRPSegmentActivityItem],
        completion: @escaping ([TRPSegmentActivityItem]) -> Void
    ) {
        guard !tripItems.isEmpty else {
            completion(tripItems)
            return
        }

        let indexed = tripItems.enumerated().map { (index: $0.offset, item: $0.element) }
        let withLocation = indexed.filter { !$0.item.lacksLocation }
        let noLocation = indexed.filter { $0.item.lacksLocation }

        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.tripian.timeline.tripItems.cityResolve")
        var resolved: [Int: Int] = [:]  // index -> cityId

        // With-location branch: cities-resolve + cache fallback (unchanged semantics).
        if !withLocation.isEmpty {
            group.enter()
            let coordinates = withLocation.map { $0.item.coordinate }
            TRPCityRemoteApi().resolveCities(coordinates: coordinates) { result in
                switch result {
                case .success(let cityIds):
                    resultsQueue.async {
                        for (i, entry) in withLocation.enumerated() where i < cityIds.count {
                            resolved[entry.index] = cityIds[i] > 0 ? cityIds[i] : 0
                        }
                        group.leave()
                    }
                case .failure:
                    resultsQueue.async {
                        for entry in withLocation {
                            let coord = entry.item.coordinate
                            if let city = TRPCityCache.shared.getCityByCoordinate(coord) {
                                resolved[entry.index] = city.id
                            } else {
                                resolved[entry.index] = 0
                            }
                        }
                        group.leave()
                    }
                }
            }
        }

        // No-location branch: lookup-by-product per item.
        var lookupTriples: [(index: Int, productId: String, providerId: Int)] = []
        var unlookableIndices: [Int] = []
        for entry in noLocation {
            if let keys = entry.item.tourLookupKeys {
                lookupTriples.append((entry.index, keys.productId, keys.providerId))
            } else {
                unlookableIndices.append(entry.index)
            }
        }

        if !unlookableIndices.isEmpty {
            group.enter()
            resultsQueue.async {
                for idx in unlookableIndices { resolved[idx] = 0 }
                group.leave()
            }
        }

        if !lookupTriples.isEmpty {
            group.enter()
            lookupCityIds(for: lookupTriples) { lookupResults in
                resultsQueue.async {
                    for triple in lookupTriples {
                        resolved[triple.index] = lookupResults[triple.index] ?? 0
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            var updated = tripItems
            resultsQueue.sync {
                for (index, cityId) in resolved where index < updated.count {
                    updated[index].cityId = cityId
                }
            }
            completion(updated)
        }
    }

    /// Fans out `lookupTourProduct` calls for the given items and returns the
    /// resolved cityIds keyed by input index. Missing keys mean the lookup failed
    /// or returned `cityId == 0` — callers should default those to `0`.
    internal func lookupCityIds(
        for items: [(index: Int, productId: String, providerId: Int)],
        completion: @escaping ([Int: Int]) -> Void
    ) {
        guard !items.isEmpty else { completion([:]); return }

        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.tripian.timeline.lookupCity.results")
        var resolved: [Int: Int] = [:]

        for triple in items {
            group.enter()
            TRPTourUseCases().executeLookupTourProduct(
                providerId: triple.providerId,
                productId: triple.productId
            ) { result in
                resultsQueue.async {
                    switch result {
                    case .success(let product) where product.cityId > 0:
                        resolved[triple.index] = product.cityId
                    case .success:
                        Log.i("lookupCityIds: cityId=0 for product \(triple.productId)")
                    case .failure(let error):
                        Log.e("lookupCityIds: failed for product \(triple.productId) — \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            resultsQueue.sync {
                Log.i("lookupCityIds: resolved \(resolved.count)/\(items.count) items")
                completion(resolved)
            }
        }
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

        // Show loading (Lottie loader inside the VC)
        delegate?.timelineItineraryViewModel(showLottieLoading: true)

        // Resolve cityIds for ALL missing tripItems BEFORE sequential addition
        resolveTripItemsCityIds(tripItems: missingTripItems) { [weak self] resolvedTripItems in
            guard let self = self else { return }

            // Now add items sequentially with resolved cityIds
            self.addMissingTripItemsSequentially(tripItems: resolvedTripItems, tripHash: tripHash, index: 0)
        }
    }

    /// Recursively adds missing tripItems one by one via API
    internal func addMissingTripItemsSequentially(tripItems: [TRPSegmentActivityItem], tripHash: String, index: Int) {
        // Base case: all items added
        guard index < tripItems.count else {
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
                    // Continue with next item
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                } else {
                    // Continue anyway to try remaining items
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                }

            case .failure(let error):
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

        // Resolve city first so we can fall back to its coordinate when the trip item
        // arrives without a usable one (isNoLocation or (0, 0)).
        var resolvedCity: TRPCity? = nil
        if let cityId = tripItem.cityId, cityId > 0 {
            if let city = TRPCityCache.shared.getCity(byId: cityId) {
                resolvedCity = city
            } else if !tripItem.coordinate.isMissingOrZero,
                      let cityByCoordinate = TRPCityCache.shared.getCityByCoordinate(tripItem.coordinate) {
                // Fallback: Try to find city by coordinate to get the name
                // Use the resolved cityId but take the name from coordinate lookup
                var city = cityByCoordinate
                city.id = cityId  // Use the resolved cityId from API
                resolvedCity = city
            } else {
                // Last resort: Create minimal city object with just ID and coordinate
                // API will have full city data on server side
                let city = TRPCity(id: cityId, name: "", coordinate: tripItem.coordinate)
                resolvedCity = city
            }
        }
        profile.city = resolvedCity

        // Set coordinate — if the trip item has no usable position, fall back to the
        // resolved city's coordinate. Without this, segments for no-location booked
        // activities would be POSTed with `(0, 0)` and break map/route rendering.
        // When we do fall back we also stamp `isNoLocation = true` and overwrite the
        // additionalData's coordinate, so the UI's no-location badge and the segment
        // body stay consistent (additionalData is the cell's source of truth for the
        // flag — `TRPMergedTimelineItem.isNoLocation` reads `additionalData.isNoLocation`).
        var enrichedTripItem = tripItem
        if !tripItem.coordinate.isMissingOrZero {
            profile.coordinate = tripItem.coordinate
        } else if let cityCoordinate = resolvedCity?.coordinate, !cityCoordinate.isMissingOrZero {
            profile.coordinate = cityCoordinate
            enrichedTripItem.coordinate = cityCoordinate
            enrichedTripItem.isNoLocation = true
        } else {
            profile.coordinate = tripItem.coordinate
            // No usable coordinate anywhere — still flag the item so the UI doesn't
            // try to pin it on the map at `(0, 0)`.
            enrichedTripItem.isNoLocation = true
        }

        // Set traveler counts
        profile.adults = tripItem.adultCount
        profile.children = tripItem.childCount
        profile.pets = 0

        // Set additional data (this is CRITICAL for booked activities)
        profile.additionalData = enrichedTripItem

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

    // MARK: - Initial Load (GetTimeline)

    /// Performs the initial GetTimeline request when the ViewModel was created with `init(tripHash:)`.
    /// Called by the VC in `viewDidLoad` after the delegate is wired up so that the Lottie loader
    /// can be presented from the VC itself (not from the coordinator).
    public func loadInitialTimelineIfNeeded() {
        guard let tripHash = pendingInitialTripHash else { return }
        // Consume so we don't refetch on subsequent view appearances
        pendingInitialTripHash = nil
        let mergeProfile = pendingMergeProfile
        pendingMergeProfile = nil

        // First GetTimeline on SDK open — show the localized "Getting your itinerary
        // plan" message alongside the animation so the user has explicit feedback
        // about what's happening rather than a silent spinner.
        let initialLoadText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingYourItineraryPlan)
        delegate?.timelineItineraryViewModel(showLottieLoading: true, textMode: .single(initialLoadText))

        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var fetchedTimeline):
                // Merge segments/favourites from the create-flow profile if provided
                if let profile = mergeProfile {
                    if !profile.segments.isEmpty {
                        fetchedTimeline.segments = profile.segments
                    }
                    if let favouriteItems = profile.favouriteItems, !favouriteItems.isEmpty {
                        fetchedTimeline.favouriteItems = favouriteItems
                    }
                }

                self.populateCitiesInSegments(&fetchedTimeline)
                self.timeline = fetchedTimeline

                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.processTimelineData()
                        self.filterFavoriteItems()
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
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
            delegate?.timelineItineraryViewModel(showLottieLoading: false)
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
                        // Hide both loaders (standard and Lottie)
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.processTimelineData()
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                        completion?(true)
                    }
                }

            case .failure:
                DispatchQueue.main.async {
                    // Hide both loaders (standard and Lottie)
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    // Even if refresh fails, notify UI to reload with local data
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    completion?(true)
                }
            }
        }
    }

    // MARK: - Destination Sync

    /// Formats a datetime string by replacing the time component
    /// - Parameters:
    ///   - dateString: Input datetime string in "yyyy-MM-dd HH:mm" format
    ///   - hour: Hour to set (0-23)
    ///   - minute: Minute to set (0-59)
    /// - Returns: Formatted datetime string with specified time
    private func formatDateWithTime(_ dateString: String, hour: Int, minute: Int) -> String {
        // Extract date part (yyyy-MM-dd)
        let components = dateString.components(separatedBy: " ")
        guard let datePart = components.first else {
            return dateString
        }

        // Format time part with zero padding
        let hourStr = String(format: "%02d", hour)
        let minuteStr = String(format: "%02d", minute)

        return "\(datePart) \(hourStr):\(minuteStr)"
    }

    /// Syncs TimelineDate segment's date range with itinerary date range
    /// Updates via API if dates don't match
    internal func syncTimelineDateRange() {
        print("📅 [Sync] syncTimelineDateRange() called")

        guard let itineraryModel = itineraryModel else {
            print("📅 [Sync] Early return: itineraryModel is nil")
            return
        }

        guard let tripHash = getTripHash() else {
            print("📅 [Sync] Early return: tripHash is nil")
            return
        }

        guard var segments = timeline?.tripProfile?.segments else {
            print("📅 [Sync] Early return: segments is nil")
            return
        }

        // Find TimelineDate segment
        guard let timelineDateIndex = segments.firstIndex(where: {
            $0.title == "TimelineDate" && $0.available == false
        }) else {
            print("📅 [Sync] TimelineDate segment not found")
            return
        }

        let timelineDateSegment = segments[timelineDateIndex]
        print("📅 [Sync] Found TimelineDate segment at index \(timelineDateIndex)")
        print("📅 [Sync] Current TimelineDate: \(timelineDateSegment.startDate ?? "nil") - \(timelineDateSegment.endDate ?? "nil")")
        print("📅 [Sync] Itinerary dates: \(itineraryModel.startDatetime) - \(itineraryModel.endDatetime)")

        // Extract date part and set specific times
        // startDate should be "yyyy-MM-dd 00:00"
        // endDate should be "yyyy-MM-dd 23:59"
        let startDateWithTime = formatDateWithTime(itineraryModel.startDatetime, hour: 0, minute: 0)
        let endDateWithTime = formatDateWithTime(itineraryModel.endDatetime, hour: 23, minute: 59)

        print("📅 [Sync] Formatted dates: \(startDateWithTime) - \(endDateWithTime)")

        // Compare dates
        let needsUpdate = timelineDateSegment.startDate != startDateWithTime ||
                         timelineDateSegment.endDate != endDateWithTime

        guard needsUpdate else {
            print("📅 [Sync] Dates match, no update needed")
            return
        }

        print("📅 [Sync] Dates don't match, updating TimelineDate segment...")

        // STEP 1: Update LOCAL timeline first (optimistic update)
        var updatedSegment = timelineDateSegment
        updatedSegment.startDate = startDateWithTime
        updatedSegment.endDate = endDateWithTime
        segments[timelineDateIndex] = updatedSegment

        // Update timeline
        if var mutableTimeline = timeline {
            mutableTimeline.tripProfile?.segments = segments
            self.timeline = mutableTimeline

            // STEP 2: Refresh UI immediately
            processTimelineData()
            delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            print("📅 [Sync] Local TimelineDate updated, UI refreshed")
        }

        // STEP 3: Update via API in background (fire and forget)
        let profile = TRPCreateEditTimelineSegmentProfile(from: updatedSegment, tripHash: tripHash, segmentIndex: timelineDateIndex)
        profile.startDate = startDateWithTime
        profile.endDate = endDateWithTime

        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { result in
            switch result {
            case .success:
                print("📅 [Background Update] TimelineDate segment updated successfully")
            case .failure(let error):
                print("📅 [Background Update] Failed to update TimelineDate segment: \(error)")
            }
        }
    }

    /// Removes reserved_activity segments that are now booked (exist in tripItems)
    /// - Optimistic update: removes from local timeline first, then deletes via API in background
    /// - Parameter completion: Called when all deletions are complete (or immediately if nothing to delete)
    internal func syncReservedActivitiesWithTripItems(completion: @escaping () -> Void) {
        print("🔄 [Reserved Sync] syncReservedActivitiesWithTripItems() called")

        guard let itineraryModel = itineraryModel else {
            print("🔄 [Reserved Sync] Early return: itineraryModel is nil")
            completion()
            return
        }

        guard let tripItems = itineraryModel.tripItems, !tripItems.isEmpty else {
            print("🔄 [Reserved Sync] Early return: no tripItems")
            completion()
            return
        }

        guard var mutableTimeline = timeline else {
            print("🔄 [Reserved Sync] Early return: timeline is nil")
            completion()
            return
        }

        guard var segments = mutableTimeline.tripProfile?.segments else {
            print("🔄 [Reserved Sync] Early return: segments is nil")
            completion()
            return
        }

        print("🔄 [Reserved Sync] Total segments: \(segments.count), tripItems: \(tripItems.count)")

        // Extract activityIds from tripItems
        let bookedActivityIds = Set(tripItems.compactMap { $0.activityId })
        print("🔄 [Reserved Sync] Booked activity IDs: \(bookedActivityIds.sorted())")

        // Find reserved_activity segments that are now booked
        var segmentsToRemove: [(index: Int, segment: TRPTimelineSegment)] = []

        for (index, segment) in segments.enumerated() {
            // Only check reserved_activity type
            guard segment.segmentType == .reservedActivity else { continue }

            let segmentInfo = "[\(index)] \(segment.title ?? "nil") - activityId: \(segment.additionalData?.activityId ?? "nil")"

            // Check if this reserved activity is now booked
            guard let activityId = segment.additionalData?.activityId else {
                print("🔄 [Reserved Sync] Skipping (no activityId): \(segmentInfo)")
                continue
            }

            if bookedActivityIds.contains(activityId) {
                print("🔄 [Reserved Sync] Will remove (now booked): \(segmentInfo)")
                segmentsToRemove.append((index, segment))
            } else {
                print("🔄 [Reserved Sync] Keeping (still reserved): \(segmentInfo)")
            }
        }

        guard !segmentsToRemove.isEmpty else {
            print("🔄 [Reserved Sync] No reserved activities to remove")
            completion()
            return
        }

        print("🔄 [Reserved Sync] Found \(segmentsToRemove.count) reserved activities to remove")

        // STEP 1: Remove from LOCAL timeline (reverse order to preserve indices)
        let sortedIndices = segmentsToRemove.map { $0.index }.sorted(by: >)
        for index in sortedIndices {
            segments.remove(at: index)
        }

        // Update local timeline
        mutableTimeline.tripProfile?.segments = segments
        self.timeline = mutableTimeline

        // STEP 2: Update UI immediately (optimistic update)
        processTimelineData()
        delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
        print("🔄 [Reserved Sync] Local timeline updated, UI refreshed")

        // STEP 3: Delete via API in background, call completion when done
        guard let tripHash = getTripHash() else {
            completion()
            return
        }
        deleteReservedActivitiesInBackground(segmentsToRemove: segmentsToRemove, tripHash: tripHash, completion: completion)
    }

    /// Deletes reserved activities via API sequentially (highest index first)
    /// - Parameters:
    ///   - segmentsToRemove: Array of segments to delete (already sorted by index descending)
    ///   - tripHash: Trip hash
    ///   - completion: Called when all deletions are complete
    private func deleteReservedActivitiesInBackground(
        segmentsToRemove: [(index: Int, segment: TRPTimelineSegment)],
        tripHash: String,
        completion: @escaping () -> Void
    ) {
        // Delete in reverse order to preserve indices (highest index first)
        let sorted = segmentsToRemove.sorted { $0.index > $1.index }
        deleteReservedActivitiesSequentially(sorted: sorted, tripHash: tripHash, currentIndex: 0, completion: completion)
    }

    /// Recursively deletes reserved activities one by one, waiting for each to complete
    /// - Parameters:
    ///   - sorted: Sorted array of segments (highest index first)
    ///   - tripHash: Trip hash
    ///   - currentIndex: Current position in the array
    ///   - completion: Called when all deletions are complete
    private func deleteReservedActivitiesSequentially(
        sorted: [(index: Int, segment: TRPTimelineSegment)],
        tripHash: String,
        currentIndex: Int,
        completion: @escaping () -> Void
    ) {
        // Base case: all deletions completed
        guard currentIndex < sorted.count else {
            print("🔄 [Background Delete] All reserved activity deletions completed")
            completion()
            return
        }

        let (segmentIndex, segment) = sorted[currentIndex]
        let activityId = segment.additionalData?.activityId ?? "nil"
        print("🔄 [Background Delete] [\(currentIndex + 1)/\(sorted.count)] Deleting reserved_activity: \(segment.title ?? "Unknown") (activityId: \(activityId), index: \(segmentIndex))")

        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("🔄 [Background Delete] Success: index \(segmentIndex)")
            case .failure(let error):
                print("🔄 [Background Delete] Failed: index \(segmentIndex), error: \(error)")
            }

            // Continue to next deletion regardless of success/failure
            self.deleteReservedActivitiesSequentially(sorted: sorted, tripHash: tripHash, currentIndex: currentIndex + 1, completion: completion)
        }
    }

    /// Syncs destinations by removing segments for cities no longer in itinerary
    /// - Optimistic update: removes from local timeline first, then deletes via API in background
    internal func syncRemovedCitySegments() {
        print("🗑️ [Sync] syncRemovedCitySegments() called")

        guard let itineraryModel = itineraryModel else {
            print("🗑️ [Sync] Early return: itineraryModel is nil")
            return
        }
        print("🗑️ [Sync] itineraryModel exists, destinationItems count: \(itineraryModel.destinationItems.count)")

        guard var mutableTimeline = timeline else {
            print("🗑️ [Sync] Early return: timeline is nil")
            return
        }

        guard var segments = mutableTimeline.tripProfile?.segments else {
            print("🗑️ [Sync] Early return: tripProfile.segments is nil")
            return
        }
        print("🗑️ [Sync] Total segments count: \(segments.count)")

        // Extract valid city IDs from itinerary
        let itineraryCityIds = Set(itineraryModel.destinationItems.compactMap { item -> Int? in
            guard let cityId = item.cityId, cityId > 0 else { return nil }
            return cityId
        })
        print("🗑️ [Sync] Itinerary city IDs: \(itineraryCityIds.sorted())")

        // Find segments to remove (by cityId)
        var segmentsToRemove: [(index: Int, segment: TRPTimelineSegment)] = []

        for (index, segment) in segments.enumerated() {
            let segmentInfo = "[\(index)] \(segment.title ?? "nil") - type: \(segment.segmentType.rawValue) - cityId: \(segment.city?.id ?? -1) - cityName: \(segment.city?.name ?? "nil")"

            // Skip TimelineDate (trip-level, not city-specific)
            if segment.title == "TimelineDate" && segment.available == false {
                print("🗑️ [Sync] Skipping TimelineDate: \(segmentInfo)")
                continue
            }

            // Only process deletable types
            let isDeletable = [.bookedActivity, .reservedActivity, .manualPoi, .itinerary].contains(segment.segmentType)
            guard isDeletable else {
                print("🗑️ [Sync] Skipping non-deletable type: \(segmentInfo)")
                continue
            }

            // Check if city should be removed
            guard let city = segment.city, city.id > 0 else {
                print("🗑️ [Sync] Will remove (no valid city): \(segmentInfo)")
                segmentsToRemove.append((index, segment))
                continue
            }

            if !itineraryCityIds.contains(city.id) {
                print("🗑️ [Sync] Will remove (city not in itinerary): \(segmentInfo)")
                segmentsToRemove.append((index, segment))
            } else {
                print("🗑️ [Sync] Keeping (city in itinerary): \(segmentInfo)")
            }
        }

        guard !segmentsToRemove.isEmpty else {
            print("🗑️ [Sync] No segments to remove, exiting")
            return
        }

        print("🗑️ [Sync] Found \(segmentsToRemove.count) segments to remove")

        // STEP 1: Remove from LOCAL timeline (reverse order to preserve indices)
        let sortedIndices = segmentsToRemove.map { $0.index }.sorted(by: >)
        for index in sortedIndices {
            segments.remove(at: index)
        }

        // Update local timeline
        mutableTimeline.tripProfile?.segments = segments
        self.timeline = mutableTimeline

        // STEP 2: Update UI immediately (optimistic update)
        processTimelineData()
        delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

        // STEP 3: Delete via API in background (async, non-blocking)
        guard let tripHash = getTripHash() else { return }
        deleteRemovedCitySegmentsInBackground(segmentsToRemove: segmentsToRemove, tripHash: tripHash)
    }

    /// Deletes segments via API sequentially (highest index first)
    /// - Parameters:
    ///   - segmentsToRemove: Array of segments to delete (already sorted by index descending)
    ///   - tripHash: Trip hash
    private func deleteRemovedCitySegmentsInBackground(
        segmentsToRemove: [(index: Int, segment: TRPTimelineSegment)],
        tripHash: String
    ) {
        // Delete in reverse order to preserve indices (highest index first)
        let sorted = segmentsToRemove.sorted { $0.index > $1.index }
        deleteRemovedCitySegmentsSequentially(sorted: sorted, tripHash: tripHash, currentIndex: 0)
    }

    /// Recursively deletes segments one by one, waiting for each to complete
    /// - Parameters:
    ///   - sorted: Sorted array of segments (highest index first)
    ///   - tripHash: Trip hash
    ///   - currentIndex: Current position in the array
    private func deleteRemovedCitySegmentsSequentially(
        sorted: [(index: Int, segment: TRPTimelineSegment)],
        tripHash: String,
        currentIndex: Int
    ) {
        // Base case: all deletions completed
        guard currentIndex < sorted.count else {
            print("🗑️ [Background Delete] All city segment deletions completed")
            return
        }

        let (segmentIndex, segment) = sorted[currentIndex]
        let cityName = segment.city?.name ?? "Unknown"
        print("🗑️ [Background Delete] [\(currentIndex + 1)/\(sorted.count)] Deleting segment: \(segment.title ?? "Unknown") (city: \(cityName), index: \(segmentIndex))")

        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("🗑️ [Background Delete] Success: index \(segmentIndex)")
            case .failure(let error):
                print("🗑️ [Background Delete] Failed: index \(segmentIndex), error: \(error)")
            }

            // Continue to next deletion regardless of success/failure
            self.deleteRemovedCitySegmentsSequentially(sorted: sorted, tripHash: tripHash, currentIndex: currentIndex + 1)
        }
    }
}
