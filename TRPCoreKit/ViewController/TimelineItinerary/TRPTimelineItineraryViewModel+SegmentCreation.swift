//
//  TRPTimelineItineraryViewModel+SegmentCreation.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Smart recommendations segment creation methods extracted from main ViewModel
//

import Foundation
import TRPFoundationKit

// MARK: - Smart Recommendations Segment Creation

extension TRPTimelineItineraryViewModel {

    /// Checks if a given location is the city center
    /// Returns true if the coordinates match the city's center coordinates (with small tolerance)
    internal func isCityCenterLocation(_ location: TRPLocation, city: TRPCity) -> Bool {
        let cityCenter = city.coordinate
        let tolerance = 0.0001 // Small tolerance for floating point comparison

        let latMatch = abs(location.lat - cityCenter.lat) < tolerance
        let lonMatch = abs(location.lon - cityCenter.lon) < tolerance

        return latMatch && lonMatch
    }

    /// Converts activity ID to full format: C_{id}_15_{cityId}
    /// - Parameters:
    ///   - activityId: Original activity ID (can be plain "12345", "C_12345_15", or "C_12345_15_109")
    ///   - cityId: City ID to append
    /// - Returns: Formatted activity ID in format "C_{id}_15_{cityId}"
    internal func formatActivityId(_ activityId: String, cityId: Int) -> String {
        // Extract the core ID (handles both plain and C_ formats)
        let coreId: String
        if activityId.hasPrefix("C_") {
            // Extract ID from "C_12345_15" or "C_12345_15_109" → "12345"
            let withoutPrefix = String(activityId.dropFirst(2)) // Remove "C_"
            let components = withoutPrefix.split(separator: "_")
            coreId = components.first.map(String.init) ?? activityId
        } else {
            // Plain ID like "12345"
            coreId = activityId
        }
        // Always build full format with cityId: C_{id}_15_{cityId}
        return "C_\(coreId)_15_\(cityId)"
    }

    /// Generates a unique segment title based on existing segments
    /// Returns "Recommendations" or "Recommendations 2", "Recommendations 3", etc.
    /// Only applies to segments with segmentType = .itinerary
    internal func generateSegmentTitle(for city: TRPCity, on startDate: String) -> String {
        guard let timeline = timeline else {
            return "Recommendations"
        }

        // Collect segments from both sources (avoid duplicates)
        var allSegments: [TRPTimelineSegment] = []
        var addedSegmentIds = Set<String>()

        if let segments = timeline.segments {
            for segment in segments {
                let segmentId = getSegmentUniqueId(segment)
                if !addedSegmentIds.contains(segmentId) {
                    allSegments.append(segment)
                    addedSegmentIds.insert(segmentId)
                }
            }
        }

        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                let segmentId = getSegmentUniqueId(segment)
                if !addedSegmentIds.contains(segmentId) {
                    allSegments.append(segment)
                    addedSegmentIds.insert(segmentId)
                }
            }
        }

        // Extract date portion (ignore time) for comparison
        let targetDate = String(startDate.prefix(10)) // "yyyy-MM-dd"

        // Find all segments with "Recommendations" title on same date and city
        var existingNumbers: [Int] = []

        for segment in allSegments {
            // Skip date boundary segments (Empty or TimelineDate)
            if isDateBoundarySegment(segment) { continue }

            // Only check itinerary type segments
            guard segment.segmentType == .itinerary else { continue }

            // Check if same city
            guard segment.city?.id == city.id else { continue }

            // Check if same date (compare only date portion)
            guard let segmentStartDate = segment.startDate,
                  String(segmentStartDate.prefix(10)) == targetDate else { continue }

            // Check if title matches "Recommendations" pattern
            guard let title = segment.title else { continue }

            if title == "Recommendations" {
                existingNumbers.append(1) // "Recommendations" = 1
            } else if title.hasPrefix("Recommendations ") {
                // Extract number from "Recommendations 2", "Recommendations 3", etc.
                let numberPart = title.replacingOccurrences(of: "Recommendations ", with: "")
                if let number = Int(numberPart) {
                    existingNumbers.append(number)
                }
            }
        }

        // If no existing segments, use "Recommendations"
        if existingNumbers.isEmpty {
            return "Recommendations"
        }

        // Find highest number and increment
        let maxNumber = existingNumbers.max() ?? 0
        let nextNumber = maxNumber + 1

        return "Recommendations \(nextNumber)"
    }

    /// Creates a smart recommendation segment from AddPlanData
    public func createSmartRecommendationSegment(from data: AddPlanData) {
        // 1. Validate required data
        guard let timeline = timeline,
              let city = data.selectedCity,
              let startTime = data.startTime,
              let endTime = data.endTime,
              let startingPointLocation = data.startingPointLocation else {

            delegate?.viewModel(error: NSError(
                domain: "TRPTimelineItinerary",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing required data for segment creation"]
            ))
            return
        }

        let tripHash = timeline.tripHash

        // Store day index for navigation after segment creation
        if let selectedDay = data.selectedDay,
           let index = data.availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            pendingNavigationDayIndex = index
        }

        // 2. Show Lottie loading
        delegate?.timelineItineraryViewModel(showLottieLoading: true)

        // 3. Build segment profile
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        // Basic properties
        profile.segmentType = .itinerary
        profile.distinctPlan = true
        profile.smartRecommendation = true
        profile.city = city
        profile.adults = data.travelers
        profile.children = 0
        profile.pets = 0

        // Check if starting point is city center
        let isCityCenter = isCityCenterLocation(startingPointLocation, city: city)

        // Only set coordinate and accommodation if NOT city center AND the starting
        // point has a usable coordinate. A missing/zero starting point falls through
        // to the city-center path so the server can use the city's own coordinate.
        if !isCityCenter && !startingPointLocation.isMissingOrZero {
            profile.coordinate = startingPointLocation

            // Accommodation from starting point
            if let startingPointName = data.startingPointName {
                let accommodation = TRPAccommodation(
                    name: startingPointName,
                    referanceId: nil,
                    address: startingPointName,
                    coordinate: startingPointLocation
                )
                profile.accommodation = accommodation
            }
        }
        // If city center or missing/zero starting point: only cityId is sent
        // (via profile.city), no coordinate or accommodation

        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        profile.startDate = dateFormatter.string(from: startTime)
        profile.endDate = dateFormatter.string(from: endTime)

        // Generate unique title for segment
        profile.title = generateSegmentTitle(for: city, on: profile.startDate ?? "")

        // Categories → activityFreeText (comma-separated)
        if !data.selectedCategories.isEmpty {
            profile.activityFreeText = data.selectedCategories.joined(separator: ",")
        }

        // FavouriteItems → activityIds (filtered favorites with format conversion)
        if !filteredFavoriteItems.isEmpty {
            let cityId = city.id
            profile.activityIds = filteredFavoriteItems.compactMap { item in
                guard let activityId = item.activityId else { return nil }
                // Only include favourite items matching the segment's city
                guard item.cityId == cityId else { return nil }
                // Convert to full format: C_{id}_15_{cityId}
                return formatActivityId(activityId, cityId: cityId)
            }
        }

        // Booked & Reserved Activities → excludedActivityIds
        if let segments = timeline.tripProfile?.segments {
            profile.excludedActivityIds = segments.compactMap { segment in
                // Collect from both booked_activity and reserved_activity segments
                guard segment.segmentType == .bookedActivity || segment.segmentType == .reservedActivity else { return nil }
                guard let activityId = segment.additionalData?.activityId else { return nil }
                // Get cityId from segment for format conversion
                let cityId = segment.city?.id ?? city.id
                // Convert to full format: C_{id}_15_{cityId}
                return formatActivityId(activityId, cityId: cityId)
            }
        }

        // 4. Create segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Segment created successfully
                        // Keep Lottie loading visible while waiting for generation
                        // Wait for segment generation to complete before refreshing
                        self.waitForSegmentGeneration(tripHash: tripHash)
                    } else {
                        // API returned success=false
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.viewModel(error: NSError(
                            domain: "TRPTimelineItinerary",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create smart recommendation"]
                        ))
                    }

                case .failure(let error):
                    // API error
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Waits for segment generation to complete (polls timeline until generatedStatus != 0).
    ///
    /// - Parameters:
    ///   - tripHash: Trip identifier for the polling endpoint.
    ///   - silent: When `true`, the window-level Lottie loader and the error alert
    ///     are suppressed. The shared `TRPTimelineRefreshState` publisher is still
    ///     updated for every transition, so screens initiating a silent refresh
    ///     (e.g. manual activity add from `AddPlanActivityListingVC`) can subscribe
    ///     for completion without hijacking the foreground UX. Defaults to `false`
    ///     so existing flows (Smart Recommendations, edit modes) keep their loader.
    public func waitForSegmentGeneration(tripHash: String, silent: Bool = false) {
        if !silent {
            // Show Lottie loading (manual POI/Activity — smart recommendations already
            // show it; VC ignores duplicate calls if loading is already visible).
            delegate?.timelineItineraryViewModel(showLottieLoading: true)
        }
        TRPTimelineRefreshState.shared.setRefreshing()

        let repository = TRPTimelineRepository()
        let modelRepository = TRPTimelineModelRepository()

        // Store use case as instance variable to prevent deallocation
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: repository,
            timelineModelRepository: modelRepository
        )

        // Observe when all segments are generated
        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }
            guard isGenerated else { return }

            DispatchQueue.main.async {
                // Clear use case reference after completion
                self.checkAllPlanUseCase = nil

                // Broadcast completion — the VM's own observer on
                // `TRPTimelineRefreshState` (installed on delegate set) applies
                // `pendingNavigationDayIndex` and runs `refreshTimeline()` in a
                // single place, so this path and silent paths from sibling VMs
                // share the same post-completion handler.
                TRPTimelineRefreshState.shared.setCompleted()
            }
        }

        // Start checking generation status
        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                // Polling started successfully
                break

            case .failure(let error):
                DispatchQueue.main.async {
                    if !silent {
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.viewModel(error: error)
                    }
                    // Clear use case reference on error
                    self.checkAllPlanUseCase = nil

                    // Broadcast failure regardless of silent — subscribers decide UX.
                    TRPTimelineRefreshState.shared.setFailed(error)
                }
            }
        }
    }

    // MARK: - Remove Segment

    /// Removes a segment from the timeline
    /// - Parameter segment: The segment to remove
    public func removeSegment(_ segment: TRPTimelineSegment) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else { return }

        // Find segment index
        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
            return
        }

        let tripHash = timeline.tripHash

        let removingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.removingFromPlan)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(removingText))

        // Delete segment via repository
        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Keep the "Removing from plan" sheet visible through the
                        // refresh; dismiss after the timeline data is reloaded so the
                        // loader covers the full operation.
                        self.fetchAndRefreshTimeline { _ in
                            self.delegate?.viewModel(hideLottie: .bottomSheet)
                        }
                    } else {
                        self.delegate?.viewModel(hideLottie: .bottomSheet)
                        self.delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove segment"]))
                    }
                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .bottomSheet)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }
}
