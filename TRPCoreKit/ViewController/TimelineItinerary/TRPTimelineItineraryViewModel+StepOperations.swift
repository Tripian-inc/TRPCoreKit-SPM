//
//  TRPTimelineItineraryViewModel+StepOperations.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Step and segment time operations extracted from main ViewModel
//

import Foundation
import TRPFoundationKit

// MARK: - Step Time Update

extension TRPTimelineItineraryViewModel {

    /// Updates a step's start and end times
    /// - Parameters:
    ///   - step: The step to update
    ///   - startTime: New start time in "yyyy-MM-dd HH:mm" format
    ///   - endTime: New end time in "yyyy-MM-dd HH:mm" format
    ///   - completion: Completion handler with success/failure result
    public func updateStepTime(step: TRPTimelineStep, startTime: String, endTime: String, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Use the UseCase for step editing
        timelineModeUseCases.executeEditStepHour(id: step.id, startTime: startTime, endTime: endTime) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let updatedStep):
                    // Refresh timeline from server to get correct ordering
                    // (first step time change can affect segment position)
                    self.fetchAndRefreshTimeline { _ in
                        completion(.success(updatedStep))
                    }

                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Updates a step within the timeline data structure
    internal func updateStepInTimeline(_ updatedStep: TRPTimelineStep) {
        guard var timeline = timeline, var plans = timeline.plans else { return }

        // Find and update the step in plans
        for (planIndex, plan) in plans.enumerated() {
            if let stepIndex = plan.steps.firstIndex(where: { $0.id == updatedStep.id }) {
                plans[planIndex].steps[stepIndex] = updatedStep
                break
            }
        }

        // Update timeline with modified plans
        timeline.plans = plans
        self.timeline = timeline

        // Reprocess timeline data to update UI
        processTimelineData()
    }

    // MARK: - Step Removal

    /// Removes a step from the timeline
    /// - Parameters:
    ///   - step: The step to remove
    ///   - completion: Completion handler with success/failure result
    public func removeStep(_ step: TRPTimelineStep, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Use the UseCase for step deletion
        timelineModeUseCases.executeDeleteStep(id: step.id) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Refresh timeline from server to get correct ordering
                    self.fetchAndRefreshTimeline { _ in
                        completion?(.success(true))
                    }

                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Removes a step from the timeline data structure
    internal func removeStepFromTimeline(_ step: TRPTimelineStep) {
        guard var timeline = timeline, var plans = timeline.plans else { return }

        // Find and remove the step from plans
        for (planIndex, plan) in plans.enumerated() {
            if let stepIndex = plan.steps.firstIndex(where: { $0.id == step.id }) {
                plans[planIndex].steps.remove(at: stepIndex)
                break
            }
        }

        // Update timeline with modified plans
        timeline.plans = plans
        self.timeline = timeline

        // Reprocess timeline data to update UI
        processTimelineData()
    }

    // MARK: - Segment Time Update

    /// Updates a segment's start and end times
    /// - Parameters:
    ///   - segment: The segment to update
    ///   - startTime: New start time in "HH:mm" format
    ///   - endTime: New end time in "HH:mm" format
    ///   - completion: Completion handler with success/failure result
    public func updateSegmentTime(segment: TRPTimelineSegment, startTime: String, endTime: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeline not available"])))
            return
        }

        // Find segment index
        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"])))
            return
        }

        // Extract date from existing segment startDate/endDate (format: "yyyy-MM-dd HH:mm")
        guard let existingStartDate = segment.startDate,
              let datePart = extractDatePart(from: existingStartDate) else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid segment date"])))
            return
        }

        // Build new datetime strings (format: "yyyy-MM-dd HH:mm")
        let newStartDateTime = "\(datePart) \(startTime)"
        let newEndDateTime = "\(datePart) \(endTime)"

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Create edit profile from existing segment with updated times
        let profile = TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: timeline.tripHash, segmentIndex: segmentIndex)
        profile.startDate = newStartDateTime
        profile.endDate = newEndDateTime

        // Update segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Refresh timeline to get updated data with correct ordering
                        self.fetchAndRefreshTimeline { _ in
                            completion(.success(true))
                        }
                    } else {
                        self.delegate?.viewModel(showPreloader: false)
                        let error = NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update segment time"])
                        self.delegate?.viewModel(error: error)
                        completion(.failure(error))
                    }
                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Extracts date part from datetime string
    /// - Parameter dateTimeString: Format "yyyy-MM-dd HH:mm" or "yyyy-MM-dd HH:mm:ss"
    /// - Returns: Date part in "yyyy-MM-dd" format
    internal func extractDatePart(from dateTimeString: String) -> String? {
        let components = dateTimeString.components(separatedBy: " ")
        return components.first
    }
}

// MARK: - Date-City Mapping

extension TRPTimelineItineraryViewModel {

    /// Get destination items for AddPlan flow (date-city mapping)
    /// - Returns: Array of destination items from itinerary
    public func getDestinationItems() -> [TRPSegmentDestinationItem] {
        return destinationItems
    }

    /// Get cities filtered by date for AddPlan
    /// - Parameter date: The selected date
    /// - Returns: Tuple with (mapped: cities mapped to this date, other: remaining cities)
    public func getCitiesForDate(_ date: Date) -> (mapped: [TRPCity], other: [TRPCity]) {
        let allCities = getCities()

        // If no destination items, return all as other
        guard !destinationItems.isEmpty else {
            return (mapped: [], other: allCities)
        }

        // Format date for comparison
        let dateString = date.toString(format: "yyyy-MM-dd")

        // Find city IDs mapped to this date (by cityId or coordinate)
        var mappedCityIds = Set<Int>()
        for item in destinationItems {
            guard let dates = item.dates, dates.contains(dateString) else { continue }

            // Try cityId first
            if let cityId = item.cityId, cityId > 0 {
                mappedCityIds.insert(cityId)
                continue
            }

            // Fallback: Find city by coordinate
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                mappedCityIds.insert(city.id)
            }
        }

        // No mapping for this date → return all as other
        guard !mappedCityIds.isEmpty else {
            return (mapped: [], other: allCities)
        }

        // Split cities into mapped and other
        var mapped: [TRPCity] = []
        var other: [TRPCity] = []
        for city in allCities {
            if mappedCityIds.contains(city.id) {
                mapped.append(city)
            } else {
                other.append(city)
            }
        }

        return (mapped: mapped, other: other)
    }

    /// Check if any destination items have date mappings
    /// - Returns: True if at least one destination has dates property set
    public func hasDateCityMapping() -> Bool {
        return destinationItems.contains { $0.dates != nil && !($0.dates?.isEmpty ?? true) }
    }
}
