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

    /// Base of the server-side title of smart-recommendation segments; the card header is derived at display time.
    static let recommendationSegmentTitleBase = "Recommendations"

    /// Unique server-side title of a new smart-recommendation segment, `Recommendations-<token>`; it identifies the created segment after the PUT.
    internal func makeRecommendationSegmentTitle() -> String {
        return Self.recommendationSegmentTitleBase + "-" + makeRecommendationTitleToken()
    }

    /// True from the PUT of a smart recommendation until its generation result has been applied; a new one is refused meanwhile.
    public var isRecommendationGenerationPending: Bool {
        return activeRecommendationGeneration != nil
    }

    public func createSmartRecommendationSegment(from data: AddPlanData) {
        guard !isRecommendationGenerationPending else {
            showRecommendationGenerationContinuesNotice()
            return
        }

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

        let targetDayIndex = data.selectedDay.flatMap { selectedDay in
            data.availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) })
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

        profile.title = makeRecommendationSegmentTitle()

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

        let request = TRPRecommendationGenerationRequest(
            tripHash: tripHash,
            key: TRPRecommendationSegmentKey(title: profile.title, startDate: profile.startDate, cityId: city.id),
            preexistingKeys: recommendationSegmentKeys(in: timeline),
            targetDayIndex: targetDayIndex
        )
        activeRecommendationGeneration = request

        timelineRepository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.awaitRecommendationGeneration(tripHash: tripHash, request: request)
                    } else {
                        self.endRecommendationGeneration(request)
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.viewModel(error: NSError(
                            domain: "TRPTimelineItinerary",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create smart recommendation"]
                        ))
                    }

                case .failure(let error):
                    self.endRecommendationGeneration(request)
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

        let registry = backgroundGenerationRegistry
        // Stored as instance var to prevent deallocation mid-poll.
        checkAllPlanUseCase = makeGenerationCheckUseCase(
            timelineRepository,
            TimelineGenerateController.defaultMaxAttempts,
            { timeline in registry.ignoredPlanIds(in: timeline) }
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

    /// Number of polls during which the window loader stays up.
    static let recommendationForegroundAttempts = 20

    /// Total poll attempts of the smart-recommendation create flow, foreground and background together.
    static let recommendationMaxAttempts = 60

    /// Polls the created recommendation until generation ends. The window loader stays up for the first
    /// `recommendationForegroundAttempts` polls; after that the screen is released and polling continues in the background.
    internal func awaitRecommendationGeneration(tripHash: String, request: TRPRecommendationGenerationRequest) {
        TRPTimelineRefreshState.shared.setRefreshing()

        recommendationGenerationUseCase?.cancelPolling()
        let useCase = makeGenerationCheckUseCase(timelineRepository,
                                                 Self.recommendationMaxAttempts,
                                                 TimelineGenerateController.ignoresNoPlan)
        recommendationGenerationUseCase = useCase

        useCase.executeFetchTimelineCheckAllPlanGenerate(
            tripHash: tripHash,
            onAttemptCompleted: { [weak self] attempt in
                guard attempt == Self.recommendationForegroundAttempts else { return }
                DispatchQueue.main.async {
                    self?.moveRecommendationGenerationToBackground(request)
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if self.recommendationGenerationUseCase === useCase {
                        self.recommendationGenerationUseCase = nil
                    }
                    self.concludeRecommendationGeneration(pollResult: result, request: request)
                }
            }
        )
    }

    /// Ends a failed or empty foreground recommendation: deletes the created segment when known, refreshes, then reports the error.
    /// - Parameters:
    ///   - created: The created segment as located in the timeline it was found in; nil when it could not be identified.
    ///   - message: Text shown to the user; the generation-failed text is used when nil.
    internal func handleRecommendationGenerationFailure(created: TRPLocatedRecommendationSegment?,
                                                        request: TRPRecommendationGenerationRequest,
                                                        message: String?) {
        let error = GeneralError.customMessage(
            message ?? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorGenerationFailed)
        )

        guard let created = created, let tripHash = timeline?.tripHash else {
            reportRecommendationGenerationFailure(error, request: request)
            return
        }

        let mustRelocate = isSegmentMutationInFlight
        performSegmentMutation { [weak self] done in
            guard let self = self else { return done() }
            let target = mustRelocate ? self.locateCreatedRecommendation(request, in: self.timeline) : created
            guard let target = target else {
                done()
                self.reportRecommendationGenerationFailure(error, request: request)
                return
            }
            self.deleteSegment(target.segment, at: target.segmentIndex, tripHash: tripHash) { [weak self] _ in
                self?.fetchAndRefreshTimeline(hidesLoader: false) { _ in
                    done()
                    self?.reportRecommendationGenerationFailure(error, request: request)
                }
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
        _ request: TRPRecommendationGenerationRequest,
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

    private func moveRecommendationGenerationToBackground(_ request: TRPRecommendationGenerationRequest) {
        guard activeRecommendationGeneration === request, request.phase == .foreground else { return }
        request.phase = .background
        backgroundGenerationRegistry.register(request.key, tripHash: request.tripHash)
        delegate?.timelineItineraryViewModel(showLottieLoading: false)
        TRPTimelineRefreshState.shared.setIdle()
        if isViewVisible {
            showRecommendationGenerationContinuesNotice()
        }
    }

    private func concludeRecommendationGeneration(pollResult: Result<TRPTimeline, Error>,
                                                  request: TRPRecommendationGenerationRequest) {
        switch request.phase {
        case .foreground:
            concludeForegroundRecommendationGeneration(pollResult: pollResult, request: request)
        case .background:
            concludeBackgroundRecommendationGeneration(pollResult: pollResult, request: request)
        }
    }

    private func concludeForegroundRecommendationGeneration(pollResult: Result<TRPTimeline, Error>,
                                                            request: TRPRecommendationGenerationRequest) {
        fetchAndRefreshTimeline(hidesLoader: false) { [weak self] _ in
            guard let self = self else { return }

            switch pollResult {
            case .success(let polledTimeline):
                let created = self.locateCreatedRecommendation(request, in: self.timeline)
                    ?? self.locateCreatedRecommendation(request, in: polledTimeline)
                guard let created = created else {
                    Log.w("Created recommendation segment not found after generation")
                    self.finishRecommendationGeneration(request)
                    return
                }
                if Self.hasRenderableRecommendation(created.plan) {
                    self.openTargetDay(of: request)
                    self.finishRecommendationGeneration(request)
                } else {
                    self.handleRecommendationGenerationFailure(created: created, request: request, message: nil)
                }

            case .failure:
                let created = self.locateCreatedRecommendation(request, in: self.timeline)
                self.handleRecommendationGenerationFailure(created: created, request: request, message: nil)
            }
        }
    }

    /// Applies a result that arrived after the screen was released: waits for any running segment delete, re-reads the
    /// timeline, keeps a renderable recommendation and deletes an empty or unfinished one. When the segment is not found it
    /// stays silent after a successful poll and shows the error notice after a failed one, since the timeline may then be stale.
    /// Never moves the selected day and never shows a blocking alert.
    private func concludeBackgroundRecommendationGeneration(pollResult: Result<TRPTimeline, Error>,
                                                            request: TRPRecommendationGenerationRequest) {
        performSegmentMutation { [weak self] done in
            guard let self = self else { return done() }
            self.fetchAndRefreshTimeline(hidesLoader: false) { [weak self] _ in
                guard let self = self else { return done() }
                guard let created = self.locateCreatedRecommendation(request, in: self.timeline),
                      let tripHash = self.timeline?.tripHash else {
                    done()
                    self.endRecommendationGeneration(request)
                    if case .failure = pollResult {
                        self.showRecommendationNoticeIfVisible(TimelineLocalizationKeys.errorGenerationFailed, type: .error)
                    }
                    return
                }
                guard !Self.hasRenderableRecommendation(created.plan) else {
                    done()
                    self.endRecommendationGeneration(request)
                    self.showRecommendationNoticeIfVisible(TimelineLocalizationKeys.infoRecommendationGenerationReady, type: .info)
                    return
                }
                self.deleteSegment(created.segment, at: created.segmentIndex, tripHash: tripHash) { [weak self] _ in
                    self?.fetchAndRefreshTimeline(hidesLoader: false) { _ in
                        done()
                        self?.endRecommendationGeneration(request)
                        self?.showRecommendationNoticeIfVisible(TimelineLocalizationKeys.errorGenerationFailed, type: .error)
                    }
                }
            }
        }
    }

    private func openTargetDay(of request: TRPRecommendationGenerationRequest) {
        guard let dayIndex = request.targetDayIndex, dayIndex != selectedDayIndex else { return }
        selectDay(at: dayIndex)
        delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
    }

    private func finishRecommendationGeneration(_ request: TRPRecommendationGenerationRequest) {
        endRecommendationGeneration(request)
        delegate?.timelineItineraryViewModel(showLottieLoading: false)
        TRPTimelineRefreshState.shared.setIdle()
    }

    private func reportRecommendationGenerationFailure(_ error: Error, request: TRPRecommendationGenerationRequest) {
        endRecommendationGeneration(request)
        TRPTimelineRefreshState.shared.setFailed(error)
        delegate?.timelineItineraryViewModel(showLottieLoading: false)
        delegate?.viewModel(error: error)
    }

    /// Clears the flow's pending state and, once it ran in the background, stops excluding its segment from generic pollers.
    private func endRecommendationGeneration(_ request: TRPRecommendationGenerationRequest) {
        if request.phase == .background {
            backgroundGenerationRegistry.unregister(request.key, tripHash: request.tripHash)
        }
        guard activeRecommendationGeneration === request else { return }
        activeRecommendationGeneration = nil
    }

    private func showRecommendationGenerationContinuesNotice() {
        delegate?.viewModel(
            showMessage: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.infoRecommendationGenerationContinues),
            type: .info
        )
    }

    private func showRecommendationNoticeIfVisible(_ key: String, type: EvrAlertLevel) {
        guard isViewVisible else { return }
        delegate?.viewModel(showMessage: TimelineLocalizationKeys.localized(key), type: type)
    }

    // MARK: - Remove Segment

    public func removeSegment(_ segment: TRPTimelineSegment) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else { return }

        guard segments.contains(where: { $0 === segment }) else {
            delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
            return
        }

        let removingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.removingFromPlan)
        delegate?.viewModel(showLottie: .bottomSheet, textMode: .single(removingText))

        performSegmentMutation { [weak self] done in
            guard let self = self else { return done() }
            guard let tripHash = self.timeline?.tripHash,
                  let segmentIndex = self.currentIndex(of: segment) else {
                done()
                self.delegate?.viewModel(hideLottie: .bottomSheet)
                return
            }

            self.deleteSegment(segment, at: segmentIndex, tripHash: tripHash) { [weak self] result in
                guard let self = self else { return done() }

                switch result {
                case .success:
                    self.fetchAndRefreshTimeline { _ in
                        done()
                        self.delegate?.viewModel(hideLottie: .bottomSheet)
                    }
                case .failure(let error):
                    done()
                    self.hideBottomSheetLottie(thenShow: error)
                }
            }
        }
    }

    /// Runs `send` through `performSegmentEdit` and, when it reports success, refreshes the timeline before the next segment
    /// mutation may start and then calls `onRefreshed`. A failed `send` releases the next mutation at once.
    internal func performRefreshingSegmentEdit(of segment: TRPTimelineSegment,
                                               onSegmentGone: @escaping () -> Void,
                                               send: @escaping (_ segmentIndex: Int, _ finished: @escaping (_ succeeded: Bool) -> Void) -> Void,
                                               onRefreshed: @escaping () -> Void) {
        performSegmentEdit(of: segment, onSegmentGone: onSegmentGone) { [weak self] segmentIndex, done in
            send(segmentIndex) { succeeded in
                guard succeeded, let self = self else { return done() }
                self.fetchAndRefreshTimeline { _ in
                    done()
                    onRefreshed()
                }
            }
        }
    }

    /// Runs an index-based edit of `segment` behind any running segment delete, with the API index the segment has once
    /// that delete and its refresh have finished; `edit` must call `done` once its follow-up refresh has finished, or right
    /// after a failed request. When the segment is no longer in the timeline nothing is sent: `onSegmentGone` runs, an
    /// error notice is shown and the timeline is refreshed.
    internal func performSegmentEdit(of segment: TRPTimelineSegment,
                                     onSegmentGone: @escaping () -> Void,
                                     edit: @escaping (_ segmentIndex: Int, _ done: @escaping () -> Void) -> Void) {
        performSegmentMutation { [weak self] done in
            guard let self = self else { return done() }
            guard let segmentIndex = self.currentIndex(of: segment) else {
                done()
                onSegmentGone()
                self.delegate?.viewModel(
                    showMessage: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.errorSomethingWentWrong),
                    type: .error
                )
                self.refreshTimeline()
                return
            }
            edit(segmentIndex, done)
        }
    }

    /// Runs segment deletes and index-based segment edits one at a time on the main queue, in request order. `operation`
    /// must call `done` when it has finished, including its follow-up refresh; extra calls are ignored.
    internal func performSegmentMutation(_ operation: @escaping TRPSegmentMutation) {
        guard !isSegmentMutationInFlight else {
            queuedSegmentMutations.append(operation)
            return
        }
        runSegmentMutation(operation)
    }

    private func runSegmentMutation(_ operation: @escaping TRPSegmentMutation) {
        isSegmentMutationInFlight = true
        var isDone = false
        operation { [weak self] in
            guard !isDone else { return }
            isDone = true
            self?.runNextSegmentMutation()
        }
    }

    private func runNextSegmentMutation() {
        guard !queuedSegmentMutations.isEmpty else {
            isSegmentMutationInFlight = false
            return
        }
        runSegmentMutation(queuedSegmentMutations.removeFirst())
    }

    /// API index of `segment` in the current timeline: the same instance, or after a refresh the segment with the same identity.
    private func currentIndex(of segment: TRPTimelineSegment) -> Int? {
        guard let segments = timeline?.tripProfile?.segments else { return nil }
        if let index = segments.firstIndex(where: { $0 === segment }) {
            return index
        }
        return segments.firstIndex { candidate in
            candidate.segmentType == segment.segmentType &&
            candidate.title == segment.title &&
            candidate.startDate == segment.startDate &&
            candidate.endDate == segment.endDate &&
            (candidate.cityId ?? candidate.city?.id) == (segment.cityId ?? segment.city?.id) &&
            candidate.poiId == segment.poiId &&
            candidate.additionalData?.activityId == segment.additionalData?.activityId
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

/// Whether a smart-recommendation create flow still holds the window loader or has released the screen.
enum TRPRecommendationGenerationPhase {
    case foreground
    case background
}

/// One smart-recommendation create flow: its trip, what was sent, which itinerary segments existed right before the
/// request, the day to open on a foreground success and the current phase. Main-queue confined.
final class TRPRecommendationGenerationRequest {
    let tripHash: String
    let key: TRPRecommendationSegmentKey
    let preexistingKeys: Set<TRPRecommendationSegmentKey>
    let targetDayIndex: Int?
    var phase: TRPRecommendationGenerationPhase = .foreground

    init(tripHash: String, key: TRPRecommendationSegmentKey, preexistingKeys: Set<TRPRecommendationSegmentKey>, targetDayIndex: Int?) {
        self.tripHash = tripHash
        self.key = key
        self.preexistingKeys = preexistingKeys
        self.targetDayIndex = targetDayIndex
    }
}

/// A queued segment delete or index-based edit; it receives a `done` closure to call once it has finished.
typealias TRPSegmentMutation = (_ done: @escaping () -> Void) -> Void

/// A created recommendation segment, its API segment index and its plan, all taken from the same timeline.
struct TRPLocatedRecommendationSegment {
    let segmentIndex: Int
    let segment: TRPTimelineSegment
    let plan: TRPTimelinePlan?
}
