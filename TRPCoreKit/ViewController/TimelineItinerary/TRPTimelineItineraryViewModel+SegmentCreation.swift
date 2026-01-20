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
            // Skip empty placeholder segments
            if isEmptyPlaceholderSegment(segment) { continue }

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

        // 2. Show loading
        delegate?.viewModel(showPreloader: true)

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

        // Only set coordinate and accommodation if NOT city center
        if !isCityCenter {
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
        // If city center: only cityId is sent (via profile.city), no coordinate or accommodation

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

        // FavouriteItems → activityIds
        if let favouriteItems = timeline.favouriteItems, !favouriteItems.isEmpty {
            profile.activityIds = favouriteItems.compactMap { item in
                guard let activityId = item.activityId else { return nil }
                // Validate format: must start with "C_" and contain underscore
                if activityId.hasPrefix("C_") && activityId.contains("_") {
                    return activityId
                }
                return nil
            }
        }

        // Booked Activities → excludedActivityIds
        if let segments = timeline.tripProfile?.segments {
            profile.excludedActivityIds = segments.compactMap { segment in
                // Only collect from booked_activity segments
                guard segment.segmentType == .bookedActivity else { return nil }
                guard let activityId = segment.additionalData?.activityId else { return nil }
                // Validate format: must start with "C_" and contain underscore
                if activityId.hasPrefix("C_") && activityId.contains("_") {
                    return activityId
                }
                return nil
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
                        // Keep loading visible while waiting for generation
                        // Wait for segment generation to complete before refreshing
                        self.waitForSegmentGeneration(tripHash: tripHash)
                    } else {
                        // API returned success=false
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.viewModel(error: NSError(
                            domain: "TRPTimelineItinerary",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create smart recommendation"]
                        ))
                    }

                case .failure(let error):
                    // API error
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Waits for segment generation to complete (polls timeline until generatedStatus != 0)
    public func waitForSegmentGeneration(tripHash: String) {
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
                // Refresh timeline now that generation is complete
                self.refreshTimeline()

                // Clear use case reference after completion
                self.checkAllPlanUseCase = nil
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
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                    // Clear use case reference on error
                    self.checkAllPlanUseCase = nil
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

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Delete segment via repository
        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Refresh timeline to get updated data
                        self.refreshTimeline()
                    } else {
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove segment"]))
                    }
                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }
}
