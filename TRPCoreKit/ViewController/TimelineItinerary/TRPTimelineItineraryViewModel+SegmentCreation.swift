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
            append(TRPActivityIdFormat.make(activity.productId,
                                            providerId: activity.providerId,
                                            cityId: activity.cityId ?? city.id))
        }

        for baseId in TRPFavouriteExclusionStorage.excludedActivityIds(tripHash: timeline.tripHash) {
            let favouriteCityId = timeline.favouriteItems?.first(where: {
                $0.activityId?.cleanedAsActivityId() == baseId
            })?.cityId
            append(TRPActivityIdFormat.make(baseId, cityId: favouriteCityId ?? city.id))
        }

        return ids
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
                return TRPActivityIdFormat.make(activityId, cityId: cityId)
            }
        }

        let excludedActivityIds = collectExcludedActivityIds(for: city, on: profile.startDate ?? "")
        if !excludedActivityIds.isEmpty {
            profile.excludedActivityIds = excludedActivityIds
        }

        let request = TRPCreatedRecommendationRequest(
            key: TRPRecommendationSegmentKey(title: profile.title, startDate: profile.startDate, cityId: city.id),
            preexistingKeys: recommendationSegmentKeys(in: timeline)
        )

        timelineRepository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.awaitRecommendationGeneration(tripHash: tripHash, request: request)
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

    // MARK: - Smart Recommendation Generation

    /// Polls the created recommendation until generation ends, keeping the window loader visible until it is evaluated.
    internal func awaitRecommendationGeneration(tripHash: String, request: TRPCreatedRecommendationRequest) {
        TRPTimelineRefreshState.shared.setRefreshing()

        recommendationGenerationUseCase?.cancelPolling()
        let useCase = makeGenerationCheckUseCase(timelineRepository)
        recommendationGenerationUseCase = useCase

        useCase.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.recommendationGenerationUseCase === useCase {
                    self.recommendationGenerationUseCase = nil
                }
                self.concludeRecommendationGeneration(pollResult: result, request: request)
            }
        }
    }

    /// Ends a failed or empty recommendation: deletes the created segment when known, refreshes, then reports the error.
    /// - Parameters:
    ///   - created: The created segment as located in the timeline it was found in; nil when it could not be identified.
    ///   - message: Text shown to the user; the generation-failed text is used when nil.
    internal func handleRecommendationGenerationFailure(created: TRPLocatedRecommendationSegment?, message: String?) {
        let error = GeneralError.customMessage(
            message ?? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorGenerationFailed)
        )

        guard let created = created, let tripHash = timeline?.tripHash else {
            reportRecommendationGenerationFailure(error)
            return
        }

        deleteSegment(created.segment, at: created.segmentIndex, tripHash: tripHash) { [weak self] _ in
            self?.fetchAndRefreshTimeline(hidesLoader: false) { _ in
                self?.reportRecommendationGenerationFailure(error)
            }
        }
    }

    /// Identifiers of the itinerary segments in `timeline`, used to tell a newly created segment apart from existing ones.
    internal func recommendationSegmentKeys(in timeline: TRPTimeline?) -> Set<TRPRecommendationSegmentKey> {
        let segments = timeline?.tripProfile?.segments ?? []
        return Set(segments.filter { $0.segmentType == .itinerary }.map(TRPRecommendationSegmentKey.init(segment:)))
    }

    /// The segment created by `request` in `timeline`, with its API segment index and matching plan.
    internal func locateCreatedRecommendation(
        _ request: TRPCreatedRecommendationRequest,
        in timeline: TRPTimeline?
    ) -> TRPLocatedRecommendationSegment? {
        guard let segments = timeline?.tripProfile?.segments else { return nil }
        guard let segmentIndex = segments.firstIndex(where: { segment in
            guard segment.segmentType == .itinerary else { return false }
            let key = TRPRecommendationSegmentKey(segment: segment)
            return key == request.key && !request.preexistingKeys.contains(key)
        }) else { return nil }

        let segment = segments[segmentIndex]
        let plan = findMatchingPlan(for: segment, in: timeline?.plans ?? [])
        return TRPLocatedRecommendationSegment(segmentIndex: segmentIndex, segment: segment, plan: plan)
    }

    /// True when the plan finished generating with at least one step to show.
    internal static func hasRenderableRecommendation(_ plan: TRPTimelinePlan?) -> Bool {
        guard let plan = plan else { return false }
        return plan.generatedStatus >= 1 && !plan.steps.isEmpty
    }

    private func concludeRecommendationGeneration(pollResult: Result<TRPTimeline, Error>,
                                                  request: TRPCreatedRecommendationRequest) {
        applyPendingNavigationDay()

        fetchAndRefreshTimeline(hidesLoader: false) { [weak self] _ in
            guard let self = self else { return }

            switch pollResult {
            case .success(let polledTimeline):
                let created = self.locateCreatedRecommendation(request, in: self.timeline)
                    ?? self.locateCreatedRecommendation(request, in: polledTimeline)
                guard let created = created else {
                    Log.w("Created recommendation segment not found after generation")
                    self.finishRecommendationGeneration()
                    return
                }
                if Self.hasRenderableRecommendation(created.plan) {
                    self.finishRecommendationGeneration()
                } else {
                    self.handleRecommendationGenerationFailure(created: created, message: nil)
                }

            case .failure(let error):
                let created = self.locateCreatedRecommendation(request, in: self.timeline)
                self.handleRecommendationGenerationFailure(
                    created: created,
                    message: Self.recommendationPollingFailureMessage(for: error)
                )
            }
        }
    }

    private static func recommendationPollingFailureMessage(for error: Error) -> String? {
        guard case TimelineGenerateError.timeout = error else { return nil }
        return TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorTimeout)
    }

    private func applyPendingNavigationDay() {
        guard let dayIndex = pendingNavigationDayIndex else { return }
        selectedDayIndex = dayIndex
        pendingNavigationDayIndex = nil
    }

    private func finishRecommendationGeneration() {
        delegate?.timelineItineraryViewModel(showLottieLoading: false)
        TRPTimelineRefreshState.shared.setIdle()
    }

    private func reportRecommendationGenerationFailure(_ error: Error) {
        TRPTimelineRefreshState.shared.setFailed(error)
        delegate?.timelineItineraryViewModel(showLottieLoading: false)
        delegate?.viewModel(error: error)
    }

    // MARK: - Remove Segment

    public func removeSegment(_ segment: TRPTimelineSegment) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else { return }

        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
            return
        }

        let removingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.removingFromPlan)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(removingText))

        deleteSegment(segment, at: segmentIndex, tripHash: timeline.tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.fetchAndRefreshTimeline { _ in
                    self.delegate?.viewModel(hideLottie: .bottomSheet)
                }
            case .failure(let error):
                self.hideBottomSheetLottie(thenShow: error)
            }
        }
    }

    /// Deletes the segment at `segmentIndex` on the server and drops its cached availability; completes on the main queue.
    internal func deleteSegment(_ segment: TRPTimelineSegment,
                                at segmentIndex: Int,
                                tripHash: String,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        timelineRepository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(true):
                    self?.clearCachedAvailability(for: segment)
                    completion(.success(()))
                case .success(false):
                    completion(.failure(NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove segment"])))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

/// Day-level identity of an itinerary segment: title, start day (yyyy-MM-dd) and city.
struct TRPRecommendationSegmentKey: Hashable {
    let title: String?
    let day: String?
    let cityId: Int?

    init(title: String?, startDate: String?, cityId: Int?) {
        self.title = title
        self.day = startDate.map { String($0.prefix(10)) }
        self.cityId = cityId
    }

    init(segment: TRPTimelineSegment) {
        self.init(title: segment.title, startDate: segment.startDate, cityId: segment.cityId ?? segment.city?.id)
    }
}

/// What the create flow sent and which itinerary segments existed right before the request.
struct TRPCreatedRecommendationRequest {
    let key: TRPRecommendationSegmentKey
    let preexistingKeys: Set<TRPRecommendationSegmentKey>
}

/// A created recommendation segment, its API segment index and its plan, all taken from the same timeline.
struct TRPLocatedRecommendationSegment {
    let segmentIndex: Int
    let segment: TRPTimelineSegment
    let plan: TRPTimelinePlan?
}
