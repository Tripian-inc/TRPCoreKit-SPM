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

    /// Updates a step's start/end times (format "HH:mm"), first widening the owning segment when the new times fall outside it.
    public func updateStepTime(step: TRPTimelineStep, startTime: String, endTime: String, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(changingTimeText))

        guard let widenedSegmentProfile = widenedSegmentProfile(for: step, startTime: startTime, endTime: endTime) else {
            editStepHour(step: step, startTime: startTime, endTime: endTime, segmentWasWidened: false, completion: completion)
            return
        }

        submitSegmentEdit(widenedSegmentProfile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.editStepHour(step: step, startTime: startTime, endTime: endTime, segmentWasWidened: true, completion: completion)
            case .failure(let error):
                self.hideBottomSheetLottie(thenShow: error)
                completion(.failure(error))
            }
        }
    }

    private func editStepHour(step: TRPTimelineStep, startTime: String, endTime: String, segmentWasWidened: Bool, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        timelineModeUseCases.executeEditStepHour(id: step.id, startTime: startTime, endTime: endTime) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let updatedStep):
                    self.fetchAndRefreshTimeline { _ in
                        completion(.success(updatedStep))
                    }

                case .failure(let error):
                    self.hideBottomSheetLottie(thenShow: error)
                    if segmentWasWidened {
                        self.fetchAndRefreshTimeline(completion: nil)
                    }
                    completion(.failure(error))
                }
            }
        }
    }

    /// Edit profile that grows the step's owning segment to cover the new step times; `nil` when no widening is needed or the segment cannot be resolved.
    private func widenedSegmentProfile(for step: TRPTimelineStep, startTime: String, endTime: String) -> TRPCreateEditTimelineSegmentProfile? {
        guard let segment = mergedItem(containing: step)?.segment,
              let segmentStart = TRPDateHelper.parseDateTime(segment.startDate),
              let segmentEnd = TRPDateHelper.parseDateTime(segment.endDate),
              let stepRange = TRPSegmentTimeRangeAdjustment.stepRange(onDayOf: step.startDateTimes, startTime: startTime, endTime: endTime),
              let widenedRange = TRPSegmentTimeRangeAdjustment.widenedRange(segmentStart: segmentStart,
                                                                             segmentEnd: segmentEnd,
                                                                             stepStart: stepRange.start,
                                                                             stepEnd: stepRange.end),
              case .success(let profile) = makeSegmentEditProfile(for: segment) else {
            return nil
        }

        profile.startDate = TRPDateHelper.formatDateTime(widenedRange.start)
        profile.endDate = TRPDateHelper.formatDateTime(widenedRange.end)
        return profile
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
                    self.hideBottomSheetLottie(thenShow: error)
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
        let profile: TRPCreateEditTimelineSegmentProfile
        switch makeSegmentEditProfile(for: segment) {
        case .success(let segmentProfile):
            profile = segmentProfile
        case .failure(let error):
            completion(.failure(error))
            return
        }

        guard let existingStartDate = segment.startDate,
              let datePart = extractDatePart(from: existingStartDate) else {
            completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid segment date"])))
            return
        }

        profile.startDate = "\(datePart) \(startTime)"
        profile.endDate = "\(datePart) \(endTime)"

        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(changingTimeText))

        submitSegmentEdit(profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.fetchAndRefreshTimeline { _ in
                    completion(.success(true))
                }
            case .failure(let error):
                self.hideBottomSheetLottie(thenShow: error)
                completion(.failure(error))
            }
        }
    }

    /// Edit profile for `segment` at its index in `tripProfile.segments`, carrying over all of its current values.
    private func makeSegmentEditProfile(for segment: TRPTimelineSegment) -> Result<TRPCreateEditTimelineSegmentProfile, Error> {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else {
            return .failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeline not available"]))
        }

        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            return .failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
        }

        return .success(TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: timeline.tripHash, segmentIndex: segmentIndex))
    }

    /// Sends the segment edit and reports on the main queue; an `updated: false` answer is reported as a failure.
    private func submitSegmentEdit(_ profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        timelineRepository.createEditTimelineSegment(profile: profile) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(true):
                    completion(.success(()))
                case .success(false):
                    completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update segment time"])))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Shows `error` only once the bottom-sheet loader has finished dismissing, so the banner is not attached to the closing sheet.
    internal func hideBottomSheetLottie(thenShow error: Error) {
        delegate?.viewModel(hideLottie: .bottomSheet) { [weak self] in
            self?.delegate?.viewModel(error: error)
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

        let dateString = TRPDateHelper.formatDateString(date)

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
