//
//  TRPTimelineItineraryViewModel+TimelineOperations.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// One item awaiting city resolution: its position in the caller's array, its `product-lookup` keys when the
/// activity id carries them, and its coordinate when it has a real one.
internal struct TRPCityResolutionRequest {
    let index: Int
    let lookupKeys: (productId: String, providerId: Int)?
    let coordinate: TRPLocation?
}

// MARK: - Timeline Creation/Fetch Methods

extension TRPTimelineItineraryViewModel {

    internal func createTimeline(from itineraryModel: TRPItineraryWithActivities) {
        resolveMissingCityIds(in: itineraryModel) { [weak self] resolvedItineraryModel in
            guard let self = self else { return }

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

    internal func createTimelineInternal(from itineraryModel: TRPItineraryWithActivities) {
        let profile = itineraryModel.createTimelineProfileFromBookings()
        profile.favouriteItems = itineraryModel.favouriteItems

        let repository = TRPTimelineRepository()
        let createUseCase = TRPCreateTimelineUseCase(repository: repository)

        createUseCase.executeCreateTimeline(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let createdTimeline):
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

    /// Resolves cityIds for ALL destination items: API first to validate city support, cache fallback on failure. SDK continues even if some cities don't resolve.
    internal func resolveMissingCityIds(in itineraryModel: TRPItineraryWithActivities,
                                        completion: @escaping (TRPItineraryWithActivities) -> Void) {
        var mutableItinerary = itineraryModel

        let allItems = mutableItinerary.destinationItems.enumerated()
            .map { (index: $0.offset, item: $0.element) }

        if allItems.isEmpty {
            completion(mutableItinerary)
            return
        }

        let coordinates = allItems.map { parseCoordinate(from: $0.item.coordinate) }

        let cityRemoteApi = TRPCityRemoteApi()
        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cityIds):
                for (i, (index, _)) in allItems.enumerated() {
                    if i < cityIds.count && cityIds[i] > 0 {
                        mutableItinerary.destinationItems[index].cityId = cityIds[i]
                    } else {
                        mutableItinerary.destinationItems[index].cityId = 0
                    }
                }
                completion(mutableItinerary)

            case .failure(let error):
                self.resolveCityIdsFromCache(items: allItems, itinerary: &mutableItinerary)
                completion(mutableItinerary)
            }
        }
    }

    /// Cache fallback: resolve cities by coordinate proximity.
    private func resolveCityIdsFromCache(items: [(index: Int, item: TRPSegmentDestinationItem)],
                                         itinerary: inout TRPItineraryWithActivities) {
        for (index, item) in items {
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate, maxDistanceKm: 100) {
                itinerary.destinationItems[index].cityId = city.id
            }
        }
    }


    internal func waitForTimelineGeneration(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        let repository = TRPTimelineRepository()
        let modelRepository = TRPTimelineModelRepository()
        TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)

        // Held as an instance var to prevent deallocation during the poll.
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: repository,
            timelineModelRepository: modelRepository
        )

        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }
            guard isGenerated else { return }

            self.fetchTimeline(tripHash: tripHash, itineraryModel: itineraryModel)

            self.checkAllPlanUseCase = nil
        }

        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                break

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
                    self.checkAllPlanUseCase = nil
                }
            }
        }
    }

    internal func fetchTimeline(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var timeline):
                // Merge only favouriteItems — segments are handled via API.
                timeline = self.mergeItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                self.populateCitiesInSegments(&timeline)
                self.timeline = timeline
                self.itineraryModel = itineraryModel

                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.processTimelineData()

                        // Edit-only: updates the TimelineDate segment's date range (no DELETE, no index conflict with the cascade below).
                        self.syncTimelineDateRange()

                        self.reconcileSegmentsWithItinerary { [weak self] in
                            guard let self = self else { return }
                            print("🔁 [Reconcile] Cascade completed, adding missing booked activities")
                            self.addMissingBookedActivities(from: itineraryModel)
                        }

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

    /// Merges only favouriteItems into the timeline; missing booked activities are added via the API in `addMissingBookedActivities()`.
    internal func mergeItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) -> TRPTimeline {
        var updatedTimeline = timeline

        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        return updatedTimeline
    }

    // MARK: - CityId Resolution

    /// Resolves cityIds for tripItems via `resolveCityIds`; anything left unresolved gets `cityId = 0`.
    internal func resolveTripItemsCityIds(
        tripItems: [TRPSegmentActivityItem],
        completion: @escaping ([TRPSegmentActivityItem]) -> Void
    ) {
        guard !tripItems.isEmpty else {
            completion(tripItems)
            return
        }

        let requests = tripItems.enumerated().map { offset, item in
            TRPCityResolutionRequest(
                index: offset,
                lookupKeys: item.tourLookupKeys,
                coordinate: item.lacksLocation ? nil : item.coordinate
            )
        }

        resolveCityIds(for: requests) { resolved in
            var updated = tripItems
            for index in updated.indices {
                updated[index].cityId = resolved[index] ?? 0
            }
            completion(updated)
        }
    }

    /// Resolves cityIds with `tour-api/product-lookup` as the primary source — our product records carry the
    /// authoritative cityId — and a single `cities/resolve` batch (then the coordinate cache) only for the items
    /// the lookup couldn't answer. Completes on the main queue with just the indices resolved to a positive cityId.
    internal func resolveCityIds(
        for requests: [TRPCityResolutionRequest],
        completion: @escaping ([Int: Int]) -> Void
    ) {
        guard !requests.isEmpty else {
            DispatchQueue.main.async { completion([:]) }
            return
        }

        let lookupTriples = requests.compactMap { request -> (index: Int, productId: String, providerId: Int)? in
            guard let keys = request.lookupKeys else { return nil }
            return (request.index, keys.productId, keys.providerId)
        }

        lookupCityIds(for: lookupTriples) { [weak self] lookupResults in
            let unresolved = requests.filter { lookupResults[$0.index] == nil }

            guard let self = self, !unresolved.isEmpty else {
                DispatchQueue.main.async { completion(lookupResults) }
                return
            }

            self.resolveCityIdsByCoordinate(for: unresolved) { coordinateResults in
                DispatchQueue.main.async {
                    completion(lookupResults.merging(coordinateResults) { lookup, _ in lookup })
                }
            }
        }
    }

    /// Batched `cities/resolve` for requests carrying a real coordinate, falling back to the local city cache when the request fails.
    private func resolveCityIdsByCoordinate(
        for requests: [TRPCityResolutionRequest],
        completion: @escaping ([Int: Int]) -> Void
    ) {
        let located = requests.compactMap { request -> (index: Int, coordinate: TRPLocation)? in
            guard let coordinate = request.coordinate else { return nil }
            return (request.index, coordinate)
        }

        guard !located.isEmpty else {
            completion([:])
            return
        }

        TRPCityRemoteApi().resolveCities(coordinates: located.map { $0.coordinate }) { result in
            var resolved: [Int: Int] = [:]

            switch result {
            case .success(let cityIds):
                for (offset, entry) in located.enumerated() where offset < cityIds.count && cityIds[offset] > 0 {
                    resolved[entry.index] = cityIds[offset]
                }
                Log.i("resolveCityIds: cities/resolve covered \(resolved.count)/\(located.count) leftovers")
            case .failure(let error):
                Log.e("resolveCityIds: cities/resolve failed — \(error.localizedDescription)")
                for entry in located {
                    if let city = TRPCityCache.shared.getCityByCoordinate(entry.coordinate) {
                        resolved[entry.index] = city.id
                    }
                }
            }

            completion(resolved)
        }
    }

    /// Fans out `lookupTourProduct` and returns cityIds keyed by input index. Indices missing from the result
    /// (lookup failed or `cityId == 0`) are left for the caller's coordinate fallback.
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

    /// Adds tripItems that aren't already on the timeline (by activityId) via the API.
    public func addMissingBookedActivities(from itineraryModel: TRPItineraryWithActivities) {
        guard let timeline = timeline,
              let tripItems = itineraryModel.tripItems,
              !tripItems.isEmpty else {
            return
        }

        let tripHash = timeline.tripHash

        var existingActivityIds = Set<String>()

        // Normalize to the core id so format differences (plain vs `C_`-prefixed) don't re-add an already-present activity.
        if let segments = timeline.segments {
            for segment in segments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId.cleanedAsActivityId())
                }
            }
        }

        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId.cleanedAsActivityId())
                }
            }
        }

        let missingTripItems = tripItems.filter { tripItem in
            guard let activityId = tripItem.activityId else { return false }
            return !existingActivityIds.contains(activityId.cleanedAsActivityId())
        }

        guard !missingTripItems.isEmpty else {
            return
        }

        delegate?.timelineItineraryViewModel(showLottieLoading: true)

        // Resolve cityIds for ALL missing tripItems before sequential addition.
        resolveTripItemsCityIds(tripItems: missingTripItems) { [weak self] resolvedTripItems in
            guard let self = self else { return }

            self.addMissingTripItemsSequentially(tripItems: resolvedTripItems, tripHash: tripHash, index: 0)
        }
    }

    internal func addMissingTripItemsSequentially(tripItems: [TRPSegmentActivityItem], tripHash: String, index: Int) {
        guard index < tripItems.count else {
            waitForSegmentGeneration(tripHash: tripHash)
            return
        }

        let tripItem = tripItems[index]

        let profile = createSegmentProfileFromTripItem(tripItem, tripHash: tripHash)

        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let success):
                if success {
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                } else {
                    // Continue anyway to try remaining items.
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                }

            case .failure(let error):
                // Continue anyway to try remaining items.
                self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
            }
        }
    }

    internal func createSegmentProfileFromTripItem(_ tripItem: TRPSegmentActivityItem, tripHash: String) -> TRPCreateEditTimelineSegmentProfile {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        profile.segmentType = .bookedActivity

        profile.title = tripItem.title
        profile.available = false
        profile.distinctPlan = true

        profile.startDate = tripItem.startDatetime
        profile.endDate = tripItem.endDatetime

        // Resolve city first so we can fall back to its coordinate when the trip item has none (isNoLocation or (0, 0)).
        var resolvedCity: TRPCity? = nil
        if let cityId = tripItem.cityId, cityId > 0 {
            if let city = TRPCityCache.shared.getCity(byId: cityId) {
                resolvedCity = city
            } else if !tripItem.coordinate.isMissingOrZero,
                      let cityByCoordinate = TRPCityCache.shared.getCityByCoordinate(tripItem.coordinate) {
                // Use the API's cityId but take the name from the coordinate lookup.
                var city = cityByCoordinate
                city.id = cityId
                resolvedCity = city
            } else {
                // Minimal stub; the server has full city data.
                let city = TRPCity(id: cityId, name: "", coordinate: tripItem.coordinate)
                resolvedCity = city
            }
        }
        profile.city = resolvedCity

        // Fall back to the city's coordinate when the trip item has none, stamping isNoLocation so the UI badge stays consistent (additionalData is the cell's source of truth for the flag).
        var enrichedTripItem = tripItem
        if !tripItem.coordinate.isMissingOrZero {
            profile.coordinate = tripItem.coordinate
        } else if let cityCoordinate = resolvedCity?.coordinate, !cityCoordinate.isMissingOrZero {
            profile.coordinate = cityCoordinate
            enrichedTripItem.coordinate = cityCoordinate
            enrichedTripItem.isNoLocation = true
        } else {
            profile.coordinate = tripItem.coordinate
            // No usable coordinate anywhere — flag so the UI won't pin it at (0, 0).
            enrichedTripItem.isNoLocation = true
        }

        profile.adults = tripItem.adultCount
        profile.children = tripItem.childCount
        profile.pets = 0

        profile.additionalData = enrichedTripItem

        return profile
    }

    /// Populates segment cities. `tripProfile.segments` resolves via `resolveSegmentCity`; `timeline.segments` then copies from the `tripProfile.segments` entry with the matching unique ID (the two arrays have different order and content).
    internal func populateCitiesInSegments(_ timeline: inout TRPTimeline, destinationItems: [TRPSegmentDestinationItem] = []) {
        let plans = timeline.plans ?? []
        let timelineCity = timeline.city

        if let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for segment in profileSegments {
                if let existingCity = segment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                if let resolved = resolveSegmentCity(segment, plans: plans, timelineCity: timelineCity) {
                    segment.city = resolved
                }
            }
        }

        // timeline.segments: copy city from the tripProfile.segments with the matching unique ID.
        if let segments = timeline.segments, !segments.isEmpty,
           let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for timelineSegment in segments {
                if let existingCity = timelineSegment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                let timelineSegmentId = getSegmentUniqueId(timelineSegment)

                for profileSegment in profileSegments {
                    let profileSegmentId = getSegmentUniqueId(profileSegment)

                    if timelineSegmentId == profileSegmentId {
                        if let profileCity = profileSegment.city, profileCity.id > 0 {
                            timelineSegment.city = profileCity
                        }
                        break
                    }
                }
            }
        }
    }

    /// Resolves a segment's city: `dayIds` → plan first (the only reliable segment↔plan link — booked and reserved activities produce no plan, so the two arrays never line up positionally), then the segment's own `cityId` against the plans, the trip city and the city cache.
    private func resolveSegmentCity(
        _ segment: TRPTimelineSegment,
        plans: [TRPTimelinePlan],
        timelineCity: TRPCity
    ) -> TRPCity? {
        if let planCity = findMatchingPlan(for: segment, in: plans)?.city, planCity.id > 0 {
            return planCity
        }

        guard let cityId = segment.cityId, cityId > 0 else { return nil }

        if let planCity = plans.compactMap({ $0.city }).first(where: { $0.id == cityId }) {
            return planCity
        }
        if timelineCity.id == cityId {
            return timelineCity
        }
        return TRPCityCache.shared.getCity(byId: cityId)
    }

    // MARK: - Initial Load (GetTimeline)

    /// Initial GetTimeline for a ViewModel created with `init(tripHash:)`. Called from `viewDidLoad` so the Lottie loader is presented by the VC, not the coordinator.
    public func loadInitialTimelineIfNeeded() {
        guard let tripHash = pendingInitialTripHash else { return }
        // Consume so we don't refetch on subsequent view appearances.
        pendingInitialTripHash = nil
        let mergeProfile = pendingMergeProfile
        pendingMergeProfile = nil

        let initialLoadText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingYourItineraryPlan)
        delegate?.timelineItineraryViewModel(showLottieLoading: true, textMode: .single(initialLoadText))

        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var fetchedTimeline):
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

    /// Refreshes the timeline from server; use after any operation that may affect ordering.
    public func refreshTimeline() {
        fetchAndRefreshTimeline(completion: nil)
    }

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
                // API doesn't return favouriteItems — preserve them from the previous timeline.
                updatedTimeline.favouriteItems = self.timeline?.favouriteItems
                self.populateCitiesInSegments(&updatedTimeline)
                self.timeline = updatedTimeline

                self.resolveFavouriteItemCities { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.processTimelineData()
                        self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                        completion?(true)
                    }
                }

            case .failure:
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    // Refresh failed — reload with local data anyway.
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                    completion?(true)
                }
            }
        }
    }

    // MARK: - Destination Sync

    /// Replaces the time component of a "yyyy-MM-dd HH:mm" string with the given hour/minute.
    private func formatDateWithTime(_ dateString: String, hour: Int, minute: Int) -> String {
        let components = dateString.components(separatedBy: " ")
        guard let datePart = components.first else {
            return dateString
        }

        let hourStr = String(format: "%02d", hour)
        let minuteStr = String(format: "%02d", minute)

        return "\(datePart) \(hourStr):\(minuteStr)"
    }

    /// Syncs the TimelineDate segment's date range with the itinerary's, updating via API on mismatch.
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

        // startDate → "yyyy-MM-dd 00:00", endDate → "yyyy-MM-dd 23:59".
        let startDateWithTime = formatDateWithTime(itineraryModel.startDatetime, hour: 0, minute: 0)
        let endDateWithTime = formatDateWithTime(itineraryModel.endDatetime, hour: 23, minute: 59)

        print("📅 [Sync] Formatted dates: \(startDateWithTime) - \(endDateWithTime)")

        let needsUpdate = timelineDateSegment.startDate != startDateWithTime ||
                         timelineDateSegment.endDate != endDateWithTime

        guard needsUpdate else {
            print("📅 [Sync] Dates match, no update needed")
            return
        }

        print("📅 [Sync] Dates don't match, updating TimelineDate segment...")

        // Optimistic local update first, then fire-and-forget API update below.
        var updatedSegment = timelineDateSegment
        updatedSegment.startDate = startDateWithTime
        updatedSegment.endDate = endDateWithTime
        segments[timelineDateIndex] = updatedSegment

        if var mutableTimeline = timeline {
            mutableTimeline.tripProfile?.segments = segments
            self.timeline = mutableTimeline

            processTimelineData()
            delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            print("📅 [Sync] Local TimelineDate updated, UI refreshed")
        }

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

    // MARK: - Unified segment-removal cascade

    /// A segment slated for removal on SDK init. Reason is informational (log only) — the cascade treats every entry the same.
    internal struct SegmentRemovalCandidate {
        let index: Int
        let segment: TRPTimelineSegment
        let reason: Reason

        enum Reason {
            case reservedNowBooked   // reserved activity that host now reports as booked
            case cityRemoved         // segment's city is not in the incoming destinations
            case outOfDateRange      // segment's day falls outside the new trip range
        }
    }

    /// TimelineDate is never removed (its range is EDITed by `syncTimelineDateRange`); only content-carrying segment types are deletable.
    private func isSegmentEligibleForRemoval(_ segment: TRPTimelineSegment) -> Bool {
        if segment.title == "TimelineDate" && segment.available == false { return false }
        let deletable: [TRPTimelineSegmentType] = [.bookedActivity, .reservedActivity, .manualPoi, .itinerary]
        return deletable.contains(segment.segmentType)
    }

    /// Reserved activities the host now reports as booked in `tripItems`. Pure: no mutation, no I/O.
    internal func collectReservedNowBookedSegments(
        in segments: [TRPTimelineSegment],
        itinerary: TRPItineraryWithActivities
    ) -> [SegmentRemovalCandidate] {
        guard let tripItems = itinerary.tripItems, !tripItems.isEmpty else { return [] }
        // Normalize to the core id so a plain booked id ("11223") matches a `C_`-prefixed reserved id ("C_11223_15").
        let bookedActivityIds = Set(tripItems.compactMap { $0.activityId?.cleanedAsActivityId() })

        var out: [SegmentRemovalCandidate] = []
        for (index, segment) in segments.enumerated() {
            guard segment.segmentType == .reservedActivity else { continue }
            guard let activityId = segment.additionalData?.activityId else { continue }
            if bookedActivityIds.contains(activityId.cleanedAsActivityId()) {
                out.append(.init(index: index, segment: segment, reason: .reservedNowBooked))
            }
        }
        return out
    }

    /// Segments whose city is known and no longer in the host's incoming destinations. Pure: no mutation, no I/O.
    ///
    /// A segment with no resolvable city is never a candidate: `populateCitiesInSegments` maps
    /// `tripProfile.segments[i]` onto `plans[i]`, and the two arrays don't line up (booked activities
    /// produce no plan), so every segment past `plans.count` legitimately ends up city-less. An unknown
    /// city is not a removed city — deleting on it destroys valid server data.
    internal func collectSegmentsForRemovedCities(
        in segments: [TRPTimelineSegment],
        itinerary: TRPItineraryWithActivities
    ) -> [SegmentRemovalCandidate] {
        let itineraryCityIds = Set(itinerary.destinationItems.compactMap { item -> Int? in
            guard let cityId = item.cityId, cityId > 0 else { return nil }
            return cityId
        })

        // Without a resolved destination list there is nothing to compare against.
        guard !itineraryCityIds.isEmpty else { return [] }

        var out: [SegmentRemovalCandidate] = []
        for (index, segment) in segments.enumerated() {
            guard isSegmentEligibleForRemoval(segment) else { continue }
            guard let city = segment.city, city.id > 0 else { continue }

            if !itineraryCityIds.contains(city.id) {
                out.append(.init(index: index, segment: segment, reason: .cityRemoved))
            }
        }
        return out
    }

    /// Segments whose day falls outside the incoming `[startDatetime, endDatetime]` range. Compares the `yyyy-MM-dd` prefix lex-wise (the server format sorts correctly under string compare); unparseable dates are left alone. Pure: no mutation, no I/O.
    internal func collectSegmentsOutOfDateRange(
        in segments: [TRPTimelineSegment],
        itinerary: TRPItineraryWithActivities
    ) -> [SegmentRemovalCandidate] {
        let allowedStartDay = String(itinerary.startDatetime.prefix(10))
        let allowedEndDay   = String(itinerary.endDatetime.prefix(10))

        var out: [SegmentRemovalCandidate] = []
        for (index, segment) in segments.enumerated() {
            guard isSegmentEligibleForRemoval(segment) else { continue }
            guard let raw = segment.startDate, raw.count >= 10 else { continue }
            let day = String(raw.prefix(10))
            if day < allowedStartDay || day > allowedEndDay {
                out.append(.init(index: index, segment: segment, reason: .outOfDateRange))
            }
        }
        return out
    }

    /// Single-pass reconciliation: union all removal reasons by index, apply one optimistic local remove + one refresh, then run one sequential DELETE cascade. The only segment-deletion entry point in SDK init — parallel cascades would race on the backend's `segmentIndex` and corrupt the descending-delete invariant.
    internal func reconcileSegmentsWithItinerary(completion: @escaping () -> Void) {
        print("🔁 [Reconcile] reconcileSegmentsWithItinerary() called")

        guard let itinerary = itineraryModel else {
            print("🔁 [Reconcile] Early return: itineraryModel is nil")
            completion()
            return
        }
        guard var mutableTimeline = timeline,
              var segments = mutableTimeline.tripProfile?.segments else {
            print("🔁 [Reconcile] Early return: timeline or segments is nil")
            completion()
            return
        }
        guard let tripHash = getTripHash() else {
            print("🔁 [Reconcile] Early return: tripHash is nil")
            completion()
            return
        }

        let reserved = collectReservedNowBookedSegments(in: segments, itinerary: itinerary)
        let cities   = collectSegmentsForRemovedCities(in: segments, itinerary: itinerary)
        let dates    = collectSegmentsOutOfDateRange(in: segments, itinerary: itinerary)
        print("🔁 [Reconcile] candidates — reserved→booked: \(reserved.count), cityRemoved: \(cities.count), outOfDateRange: \(dates.count)")

        // Union by index (one DELETE per segment even if it matches multiple reasons); first-wins matches source priority above.
        var byIndex: [Int: SegmentRemovalCandidate] = [:]
        for candidate in (reserved + cities + dates) where byIndex[candidate.index] == nil {
            byIndex[candidate.index] = candidate
        }
        let unified = byIndex.values.sorted { $0.index > $1.index }   // highest index first

        guard !unified.isEmpty else {
            print("🔁 [Reconcile] No segments to remove, exiting")
            completion()
            return
        }
        print("🔁 [Reconcile] Found \(unified.count) unique segments to remove")

        // Descending indices stay valid as we shrink.
        for candidate in unified {
            segments.remove(at: candidate.index)
        }
        mutableTimeline.tripProfile?.segments = segments
        self.timeline = mutableTimeline

        processTimelineData()
        delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
        print("🔁 [Reconcile] Local removal applied, UI refreshed")

        deleteSegmentsSequentially(unified, tripHash: tripHash, currentIndex: 0, completion: completion)
    }

    /// DELETEs segments one by one, waiting for each response. Caller must pass them highest-index-first (see `reconcileSegmentsWithItinerary`).
    private func deleteSegmentsSequentially(
        _ sorted: [SegmentRemovalCandidate],
        tripHash: String,
        currentIndex: Int,
        completion: @escaping () -> Void
    ) {
        guard currentIndex < sorted.count else {
            print("🔁 [Background Delete] All segment deletions completed (\(sorted.count) total)")
            completion()
            return
        }

        let candidate = sorted[currentIndex]
        let reasonTag: String
        switch candidate.reason {
        case .reservedNowBooked: reasonTag = "reservedNowBooked"
        case .cityRemoved:       reasonTag = "cityRemoved"
        case .outOfDateRange:    reasonTag = "outOfDateRange"
        }
        print("🔁 [Background Delete] [\(currentIndex + 1)/\(sorted.count)] reason=\(reasonTag) index=\(candidate.index) title=\(candidate.segment.title ?? "nil")")

        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: candidate.index) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("🔁 [Background Delete] Success: index \(candidate.index)")
            case .failure(let error):
                print("🔁 [Background Delete] Failed: index \(candidate.index), error: \(error)")
            }

            // Continue regardless of success/failure — partial progress beats aborting on a transient failure.
            self.deleteSegmentsSequentially(sorted, tripHash: tripHash, currentIndex: currentIndex + 1, completion: completion)
        }
    }
}
