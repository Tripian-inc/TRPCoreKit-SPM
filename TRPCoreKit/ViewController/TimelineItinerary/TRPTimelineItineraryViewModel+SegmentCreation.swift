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

    /// True when `location` matches the city center within a small floating-point tolerance.
    internal func isCityCenterLocation(_ location: TRPLocation, city: TRPCity) -> Bool {
        let cityCenter = city.coordinate
        let tolerance = 0.0001

        let latMatch = abs(location.lat - cityCenter.lat) < tolerance
        let lonMatch = abs(location.lon - cityCenter.lon) < tolerance

        return latMatch && lonMatch
    }

    /// Converts a plain or `C_`-prefixed activity ID to "C_{id}_{providerId}_{cityId}".
    internal func formatActivityId(_ activityId: String, cityId: Int, providerId: Int = 15) -> String {
        let coreId: String
        if activityId.hasPrefix("C_") {
            let withoutPrefix = String(activityId.dropFirst(2))
            let components = withoutPrefix.split(separator: "_")
            coreId = components.first.map(String.init) ?? activityId
        } else {
            coreId = activityId
        }
        return "C_\(coreId)_\(providerId)_\(cityId)"
    }

    /// Activity ids the engine must not suggest: booked/reserved activities anywhere in the trip,
    /// activity steps already planned on `date`, and favourites the user removed from the timeline.
    /// - Parameter date: "yyyy-MM-dd" or "yyyy-MM-dd HH:mm"; only the day part is compared.
    internal func collectExcludedActivityIds(for city: TRPCity, on date: String) -> [String] {
        guard let timeline = timeline else { return [] }

        let targetDay = String(date.prefix(10))
        var ids: [String] = []
        var seen = Set<String>()

        func append(_ id: String) {
            guard seen.insert(id).inserted else { return }
            ids.append(id)
        }

        for activity in plannedActivities() where activity.source == .booking || activity.day == targetDay {
            append(formatActivityId(activity.productId,
                                    cityId: activity.cityId ?? city.id,
                                    providerId: activity.providerId))
        }

        for baseId in TRPFavouriteExclusionStorage.excludedActivityIds(tripHash: timeline.tripHash) {
            let favouriteCityId = timeline.favouriteItems?.first(where: {
                $0.activityId?.cleanedAsActivityId() == baseId
            })?.cityId
            append(formatActivityId(baseId, cityId: favouriteCityId ?? city.id))
        }

        return ids
    }

    /// Bare product id → the "yyyy-MM-dd" days it already occupies. Feeds the AddPlan flow so a day
    /// can't take the same activity twice.
    public func addedActivityDaysByProductId() -> [String: Set<String>] {
        var daysByProductId: [String: Set<String>] = [:]

        for activity in plannedActivities() {
            guard let day = activity.day else { continue }
            daysByProductId[activity.productId, default: []].insert(day)
        }

        return daysByProductId
    }

    /// "Recommendations", "Recommendations 2", … unique per day/city. Only applies to `.itinerary` segments.
    internal func generateSegmentTitle(for city: TRPCity, on startDate: String) -> String {
        guard let timeline = timeline else {
            return "Recommendations"
        }

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

        let targetDate = String(startDate.prefix(10))

        var existingNumbers: [Int] = []

        for segment in allSegments {
            if isDateBoundarySegment(segment) { continue }

            guard segment.segmentType == .itinerary else { continue }

            guard segment.city?.id == city.id else { continue }

            guard let segmentStartDate = segment.startDate,
                  String(segmentStartDate.prefix(10)) == targetDate else { continue }

            guard let title = segment.title else { continue }

            if title == "Recommendations" {
                existingNumbers.append(1)
            } else if title.hasPrefix("Recommendations ") {
                let numberPart = title.replacingOccurrences(of: "Recommendations ", with: "")
                if let number = Int(numberPart) {
                    existingNumbers.append(number)
                }
            }
        }

        if existingNumbers.isEmpty {
            return "Recommendations"
        }

        let maxNumber = existingNumbers.max() ?? 0
        let nextNumber = maxNumber + 1

        return "Recommendations \(nextNumber)"
    }

    public func createSmartRecommendationSegment(from data: AddPlanData) {
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

        if let selectedDay = data.selectedDay,
           let index = data.availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            pendingNavigationDayIndex = index
        }

        delegate?.timelineItineraryViewModel(showLottieLoading: true)

        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        profile.segmentType = .itinerary
        profile.distinctPlan = true
        profile.smartRecommendation = true
        profile.city = city
        profile.adults = data.travelers
        profile.children = 0
        profile.pets = 0

        let isCityCenter = isCityCenterLocation(startingPointLocation, city: city)

        // Send coordinate/accommodation only for a non-city-center, usable starting point; otherwise the server uses the city.
        if !isCityCenter && !startingPointLocation.isMissingOrZero {
            profile.coordinate = startingPointLocation

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

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        profile.startDate = dateFormatter.string(from: startTime)
        profile.endDate = dateFormatter.string(from: endTime)

        profile.title = generateSegmentTitle(for: city, on: profile.startDate ?? "")

        if !data.selectedCategories.isEmpty {
            profile.activityFreeText = data.selectedCategories.joined(separator: ",")
        }

        if !filteredFavoriteItems.isEmpty {
            let cityId = city.id
            profile.activityIds = filteredFavoriteItems.compactMap { item in
                guard let activityId = item.activityId else { return nil }
                guard item.cityId == cityId else { return nil }
                return formatActivityId(activityId, cityId: cityId)
            }
        }

        let excludedActivityIds = collectExcludedActivityIds(for: city, on: profile.startDate ?? "")
        if !excludedActivityIds.isEmpty {
            profile.excludedActivityIds = excludedActivityIds
        }

        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.waitForSegmentGeneration(tripHash: tripHash)
                    } else {
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.viewModel(error: NSError(
                            domain: "TRPTimelineItinerary",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create smart recommendation"]
                        ))
                    }

                case .failure(let error):
                    self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Polls until `generatedStatus != 0`. When `silent`, the window loader and error alert are suppressed but refresh state is still broadcast.
    public func waitForSegmentGeneration(tripHash: String, silent: Bool = false) {
        if !silent {
            delegate?.timelineItineraryViewModel(showLottieLoading: true)
        }
        TRPTimelineRefreshState.shared.setRefreshing()

        let repository = TRPTimelineRepository()
        let modelRepository = TRPTimelineModelRepository()

        // Stored as instance var to prevent deallocation mid-poll.
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: repository,
            timelineModelRepository: modelRepository
        )

        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }
            guard isGenerated else { return }

            DispatchQueue.main.async {
                self.checkAllPlanUseCase = nil

                // The VM's own `TRPTimelineRefreshState` observer applies the pending day + refreshTimeline, shared with silent sibling paths.
                TRPTimelineRefreshState.shared.setCompleted()
            }
        }

        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                break

            case .failure(let error):
                DispatchQueue.main.async {
                    if !silent {
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.viewModel(error: error)
                    }
                    self.checkAllPlanUseCase = nil

                    // Broadcast regardless of silent — subscribers decide UX.
                    TRPTimelineRefreshState.shared.setFailed(error)
                }
            }
        }
    }

    // MARK: - Remove Segment

    public func removeSegment(_ segment: TRPTimelineSegment) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else { return }

        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
            return
        }

        let tripHash = timeline.tripHash

        let removingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.removingFromPlan)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(removingText))

        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Drop the cached availability decision so a later re-add starts clean.
                        self.clearCachedAvailability(for: segment)
                        // Keep the sheet up through the refresh so the loader covers the full operation.
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
