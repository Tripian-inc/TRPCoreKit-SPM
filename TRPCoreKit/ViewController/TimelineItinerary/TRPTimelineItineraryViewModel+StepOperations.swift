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

    /// Updates a step's start/end times (format "yyyy-MM-dd HH:mm").
    public func updateStepTime(step: TRPTimelineStep, startTime: String, endTime: String, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(changingTimeText))

        timelineModeUseCases.executeEditStepHour(id: step.id, startTime: startTime, endTime: endTime) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let updatedStep):
                    // Bottom sheet stays visible through the refresh; dismissed on didUpdateTimeline.
                    self.fetchAndRefreshTimeline { _ in
                        completion(.success(updatedStep))
                    }

                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .bottomSheet)
                    self.delegate?.viewModel(error: error)
                    completion(.failure(error))
                }
            }
        }
    }

    internal func updateStepInTimeline(_ updatedStep: TRPTimelineStep) {
        guard var timeline = timeline, var plans = timeline.plans else { return }

        for (planIndex, plan) in plans.enumerated() {
            if let stepIndex = plan.steps.firstIndex(where: { $0.id == updatedStep.id }) {
                plans[planIndex].steps[stepIndex] = updatedStep
                break
            }
        }

        timeline.plans = plans
        self.timeline = timeline

        processTimelineData()
    }

    // MARK: - Step Removal

    public func removeStep(_ step: TRPTimelineStep, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        let removingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.removingFromPlan)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(removingText))

        timelineModeUseCases.executeDeleteStep(id: step.id) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Keep the sheet visible through the refresh, then dismiss for one continuous loader.
                    self.fetchAndRefreshTimeline { _ in
                        self.delegate?.viewModel(hideLottie: .bottomSheet)
                        completion?(.success(true))
                    }

                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .bottomSheet)
                    self.delegate?.viewModel(error: error)
                    completion?(.failure(error))
                }
            }
        }
    }

    internal func removeStepFromTimeline(_ step: TRPTimelineStep) {
        guard var timeline = timeline, var plans = timeline.plans else { return }

        for (planIndex, plan) in plans.enumerated() {
            if let stepIndex = plan.steps.firstIndex(where: { $0.id == step.id }) {
                plans[planIndex].steps.remove(at: stepIndex)
                break
            }
        }

        timeline.plans = plans
        self.timeline = timeline

        processTimelineData()
    }

    // MARK: - Segment Time Update

    /// Updates a segment's start/end times (format "HH:mm").
    public func updateSegmentTime(segment: TRPTimelineSegment, startTime: String, endTime: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeline not available"])))
            return
        }

        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"])))
            return
        }

        guard let existingStartDate = segment.startDate,
              let datePart = extractDatePart(from: existingStartDate) else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid segment date"])))
            return
        }

        let newStartDateTime = "\(datePart) \(startTime)"
        let newEndDateTime = "\(datePart) \(endTime)"

        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(changingTimeText))

        let profile = TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: timeline.tripHash, segmentIndex: segmentIndex)
        profile.startDate = newStartDateTime
        profile.endDate = newEndDateTime

        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Bottom sheet stays visible through the refresh; dismissed on didUpdateTimeline.
                        self.fetchAndRefreshTimeline { _ in
                            completion(.success(true))
                        }
                    } else {
                        self.delegate?.viewModel(hideLottie: .bottomSheet)
                        let error = NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update segment time"])
                        self.delegate?.viewModel(error: error)
                        completion(.failure(error))
                    }
                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .bottomSheet)
                    self.delegate?.viewModel(error: error)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Extracts the "yyyy-MM-dd" date part from a datetime string.
    internal func extractDatePart(from dateTimeString: String) -> String? {
        let components = dateTimeString.components(separatedBy: " ")
        return components.first
    }
}

// MARK: - Date-City Mapping

extension TRPTimelineItineraryViewModel {

    public func getDestinationItems() -> [TRPSegmentDestinationItem] {
        return destinationItems
    }

    /// Returns (cities mapped to `date`, remaining cities).
    public func getCitiesForDate(_ date: Date) -> (mapped: [TRPCity], other: [TRPCity]) {
        let allCities = getCities()

        guard !destinationItems.isEmpty else {
            return (mapped: [], other: allCities)
        }

        let dateString = date.toString(format: "yyyy-MM-dd")

        var mappedCityIds = Set<Int>()
        for item in destinationItems {
            guard let dates = item.dates, dates.contains(dateString) else { continue }

            if let cityId = item.cityId, cityId > 0 {
                mappedCityIds.insert(cityId)
                continue
            }

            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                mappedCityIds.insert(city.id)
            }
        }

        guard !mappedCityIds.isEmpty else {
            return (mapped: [], other: allCities)
        }

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

    public func hasDateCityMapping() -> Bool {
        return destinationItems.contains { $0.dates != nil && !($0.dates?.isEmpty ?? true) }
    }
}
