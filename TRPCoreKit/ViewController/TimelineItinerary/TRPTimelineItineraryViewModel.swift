//
//  TRPTimelineItineraryViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit
import MapboxDirections

// MARK: - ViewModel Delegate

public protocol TRPTimelineItineraryViewModelDelegate: ViewModelDelegate {
    func timelineItineraryViewModel(didUpdateTimeline: Bool)
    func timelineItineraryViewModel(noCitiesAvailable: Bool)
    func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String])
    /// `textMode` controls what's rendered next to the animation: `.none`, `.single(text)`, or `.rotating([texts])`.
    func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode)
}

// MARK: - Default Implementations
extension TRPTimelineItineraryViewModelDelegate {
    /// Falls back to the standard preloader when the conformer has no Lottie-aware override.
    public func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
        viewModel(showPreloader: showLottieLoading)
    }

    public func timelineItineraryViewModel(showLottieLoading: Bool) {
        timelineItineraryViewModel(showLottieLoading: showLottieLoading, textMode: .defaultRotating)
    }
}

// MARK: - Type Aliases for backward compatibility
public typealias MapDisplayItem = TRPMapDisplayItem

public class TRPTimelineItineraryViewModel {

    // MARK: - Properties
    public weak var delegate: TRPTimelineItineraryViewModelDelegate? {
        didSet {
            // Lazy install so cross-screen refresh triggers propagate into a local `refreshTimeline()` without per-callsite wiring.
            ensureRefreshStateObserverInstalled()
        }
    }
    private var hasObservedRefreshState: Bool = false

    internal var timeline: TRPTimeline?
    internal var itineraryModel: TRPItineraryWithActivities?

    /// Date-grouped timeline — SINGLE SOURCE OF TRUTH.
    internal var mergedTimeline: TRPDateGroupedTimeline?

    /// Items for the currently selected day, grouped by city for section display.
    internal var displayItems: [TRPTimelineCityGroup] = []

    /// `sectionIndex_segmentIndex -> starting order`; resets to 1 per city. Itinerary steps use startingOrder + stepIndex.
    internal var unifiedOrderMap: [String: Int] = [:]

    /// All trip dates start→end (continuous, for day filter display).
    internal var allTripDates: [Date] = []

    public var selectedDayIndex: Int = 0

    /// True when the selected day is strictly before today (calendar-day comparison).
    public var isSelectedDayPast: Bool {
        guard selectedDayIndex >= 0, selectedDayIndex < allTripDates.count else { return false }
        return allTripDates[selectedDayIndex].isPastDay()
    }

    /// Pending day index to navigate to after segment creation/refresh.
    internal var pendingNavigationDayIndex: Int?

    /// Excludes items that are already booked or reserved.
    internal var filteredFavoriteItems: [TRPSegmentFavoriteItem] = []

    internal var destinationItems: [TRPSegmentDestinationItem] = []

    /// Prevents showing the empty state during loading.
    internal var hasLoadedData: Bool = false

    public var showNoCityStateOnLoad: Bool = false

    // MARK: - Availability Check (post-load sweep)
    /// One-shot gate; the sweep runs once after the first successful processing, not on refreshes/edits.
    internal var hasRunInitialAvailabilityCheck: Bool = false
    /// Monotonic cancellation token; in-flight per-day responses bail if it has moved on.
    internal var availabilityCheckGeneration: Int = 0
    /// Re-applied synchronously on every `processTimelineData()` so a "Not available" badge survives refreshes without re-hitting the network (`isAvailabilityExpired` is transient).
    internal var expiredAvailabilityKeys: Set<String> = []

    // MARK: - Public Methods

    public func getTripHash() -> String? {
        return timeline?.tripHash
    }

    /// Matches segment by startDate and activityId.
    public func getSegmentIndex(for segment: TRPTimelineSegment) -> Int? {
        guard let timeline = timeline,
              let tripProfile = timeline.tripProfile else { return nil }
        return tripProfile.segments.firstIndex { s in
            s.startDate == segment.startDate &&
            s.additionalData?.activityId == segment.additionalData?.activityId
        }
    }

    /// section index -> isExpanded.
    internal var sectionCollapseStates: [Int: Bool] = [:]

    /// Retained to prevent deallocation during async operations.
    internal var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    /// Retained to prevent deallocation during async operations.
    internal var activeRouteCalculators: [TRPRouteCalculator] = []

    internal lazy var timelineModeUseCases: TRPTimelineModeUseCases = TRPTimelineModeUseCases()

    /// Set via `init(tripHash:)`; consumed once by `loadInitialTimelineIfNeeded()`.
    internal var pendingInitialTripHash: String?

    /// Profile whose segments/favourites the create flow merges into the fetched timeline on first load.
    internal var pendingMergeProfile: TRPTimelineProfile?

    // MARK: - Initialization

    /// Trip-hash-only init; timeline is fetched on first VC load with the Lottie loader shown by the VC.
    public init(tripHash: String, mergeProfile: TRPTimelineProfile? = nil) {
        print("🟣 [ViewModel Init] init(tripHash:) called")
        self.timeline = nil
        self.pendingInitialTripHash = tripHash
        self.pendingMergeProfile = mergeProfile
    }

    public init(timeline: TRPTimeline?) {
        print("🟡 [ViewModel Init] init(timeline:) called")
        if var mutableTimeline = timeline {
            // Do NOT sync segments — tripProfile.segments is the single source of truth.
            populateCitiesInSegments(&mutableTimeline)
            self.timeline = mutableTimeline
        } else {
            self.timeline = timeline
        }

        processTimelineData()

        resolveFavouriteItemCities { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.filterFavoriteItems()
                self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            }
        }
    }

    /// Checks for missing booked activities and adds them via API.
    public init(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) {
        print("🔵 [ViewModel Init] init(timeline:itinerary:) called")
        var mutableTimeline = timeline

        self.destinationItems = itineraryModel.destinationItems

        mutableTimeline.favouriteItems = itineraryModel.favouriteItems

        // Do NOT sync segments — tripProfile.segments is the single source of truth.
        populateCitiesInSegments(&mutableTimeline)

        self.timeline = mutableTimeline
        self.itineraryModel = itineraryModel

        processTimelineData()

        // `addMissingBookedActivities` runs once the DELETE cascade settles so new segments aren't inserted while indices shift.
        reconcileSegmentsWithItinerary { [weak self] in
            guard let self = self else { return }
            self.addMissingBookedActivities(from: itineraryModel)
        }

        resolveFavouriteItemCities { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.filterFavoriteItems()
                self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            }
        }
    }

    /// Creates or fetches the timeline from the itinerary model.
    public init(itineraryModel: TRPItineraryWithActivities, tripHash: String? = nil) {
        print("🟢 [ViewModel Init] init(itineraryModel:tripHash:) called with tripHash: \(tripHash ?? "nil")")
        self.destinationItems = itineraryModel.destinationItems

        // Deferred so the delegate can be set up first.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let initialLoadText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingYourItineraryPlan)
            self.delegate?.timelineItineraryViewModel(showLottieLoading: true, textMode: .single(initialLoadText))

            // Resolve ALL cityIds first (both create and fetch paths).
            self.resolveMissingCityIds(in: itineraryModel) { [weak self] resolvedItinerary in
                guard let self = self else { return }

                self.destinationItems = resolvedItinerary.destinationItems

                let invalidItems = resolvedItinerary.destinationItems.filter { item in
                    guard let cityId = item.cityId else { return true }
                    return cityId <= 0
                }

                let validItems = resolvedItinerary.destinationItems.filter { item in
                    guard let cityId = item.cityId else { return false }
                    return cityId > 0
                }

                if validItems.isEmpty {
                    DispatchQueue.main.async {
                        self.delegate?.timelineItineraryViewModel(showLottieLoading: false)
                        self.delegate?.timelineItineraryViewModel(noCitiesAvailable: true)
                    }
                    return
                }

                if !invalidItems.isEmpty {
                    let unavailableCityNames = invalidItems.map { $0.title }

                    var filteredItinerary = resolvedItinerary
                    filteredItinerary.destinationItems = validItems

                    self.destinationItems = validItems

                    // Non-blocking, fire and forget.
                    DispatchQueue.main.async {
                        self.delegate?.timelineItineraryViewModel(someCitiesUnavailable: unavailableCityNames)
                    }

                    if let tripHash = tripHash {
                        self.fetchTimeline(tripHash: tripHash, itineraryModel: filteredItinerary)
                    } else {
                        self.createTimelineInternal(from: filteredItinerary)
                    }
                    return
                }

                if let tripHash = tripHash {
                    self.fetchTimeline(tripHash: tripHash, itineraryModel: resolvedItinerary)
                } else {
                    self.createTimelineInternal(from: resolvedItinerary)
                }
            }
        }
    }

    // MARK: - Public Methods
    public func updateTimeline(_ timeline: TRPTimeline) {
        var mutableTimeline = timeline

        // Do NOT sync segments — tripProfile.segments is the single source of truth.
        populateCitiesInSegments(&mutableTimeline)

        self.timeline = mutableTimeline
        processTimelineData()

        resolveFavouriteItemCities { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.filterFavoriteItems()
                self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            }
        }
    }
    
    public func selectDay(at index: Int) {
        selectedDayIndex = index
        sectionCollapseStates.removeAll()

        updateDisplayItems()
    }

    /// Drives the "Time Overlap" banner shown above the timeline list.
    public func hasConflictOnSelectedDay() -> Bool {
        for cityGroup in displayItems {
            for item in cityGroup.items {
                if item.hasConflict { return true }
            }
        }
        return false
    }

    // MARK: - Collapse State Management

    public func getSectionCollapseState(for section: Int) -> Bool {
        return sectionCollapseStates[section] ?? true
    }

    public func setSectionCollapseState(for section: Int, isExpanded: Bool) {
        sectionCollapseStates[section] = isExpanded
    }

    public func getDays() -> [String] {
        guard let boundaries = getTimelineDateBoundaries() else { return [] }

        // Zero-hour dates for accurate day counting.
        let startDay = boundaries.startDate.getDateWithZeroHour()
        let endDay = boundaries.endDate.getDateWithZeroHour()
        var numberOfDays = startDay.numberOfDaysBetween(endDay)

        // Same-day activities yield 0; show at least 1.
        if numberOfDays == 0 {
            numberOfDays = 1
        }

        var days: [String] = []

        let appLanguage = TRPClient.getLanguage()
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: appLanguage)
        dayFormatter.dateFormat = "EEEE"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"

        for dayIndex in 0..<numberOfDays {
            if let currentDate = boundaries.startDate.addDay(dayIndex) {
                let dayName = dayFormatter.string(from: currentDate).capitalized
                let dateString = dateFormatter.string(from: currentDate)
                days.append("\(dayName) \(dateString)")
            }
        }

        return days
    }
    
    /// All days from the min to max segment date (inclusive).
    public func getDayDates() -> [Date] {
        guard let boundaries = getTimelineDateBoundaries() else { return [] }

        let numberOfDays = boundaries.startDate.numberOfDaysBetween(boundaries.endDate)

        var dates: [Date] = []
        for dayIndex in 0..<numberOfDays {
            if let currentDate = boundaries.startDate.addDay(dayIndex) {
                dates.append(currentDate)
            }
        }

        return dates
    }
    
    public func getTripDateRange() -> (start: Date, end: Date)? {
        guard let boundaries = getTimelineDateBoundaries() else { return nil }
        return (start: boundaries.startDate, end: boundaries.endDate)
    }

    public func getCities() -> [TRPCity] {
        var cities: [TRPCity] = []
        var cityIds = Set<Int>()
        var cityNames = Set<String>()

        if let timelineCity = timeline?.city, timelineCity.id > 0 {
            cities.append(timelineCity)
            cityIds.insert(timelineCity.id)
            cityNames.insert(timelineCity.name.lowercased())
        }

        if let plans = timeline?.plans {
            for plan in plans {
                if let city = plan.city, city.id > 0 {
                    let normalizedName = city.name.lowercased()
                    if cityNames.contains(normalizedName) {
                        continue
                    }
                    cities.append(city)
                    cityIds.insert(city.id)
                    cityNames.insert(normalizedName)
                }
            }
        }

        if let segments = timeline?.segments {
            for segment in segments {
                if let city = segment.city, city.id > 0 {
                    let normalizedName = city.name.lowercased()
                    if cityNames.contains(normalizedName) {
                        continue
                    }
                    cities.append(city)
                    cityIds.insert(city.id)
                    cityNames.insert(normalizedName)
                }
            }
        }

        for item in destinationItems {
            let coordinate = parseCoordinate(from: item.coordinate)

            if let cityId = item.cityId, cityId > 0 {
                if cityIds.contains(cityId) { continue }
                if let city = TRPCityCache.shared.getCity(byId: cityId) {
                    if !cityNames.contains(city.name.lowercased()) {
                        cities.append(city)
                        cityIds.insert(city.id)
                        cityNames.insert(city.name.lowercased())
                    }
                    continue
                }
            }

            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                if cityIds.contains(city.id) { continue }
                if cityNames.contains(city.name.lowercased()) { continue }
                cities.append(city)
                cityIds.insert(city.id)
                cityNames.insert(city.name.lowercased())
            }
        }

        // Constrain to the host's CURRENT destinations: a removed city's plan can linger in `timeline.plans` and reappear as selectable. `destinationItems` is the up-to-date source of truth. Guarded so create-flow keeps the full list.
        guard !destinationItems.isEmpty else { return cities }

        var allowedCityIds = Set<Int>()
        var allowedCityNames = Set<String>()
        for item in destinationItems {
            if let cityId = item.cityId, cityId > 0 {
                allowedCityIds.insert(cityId)
                if let cachedCity = TRPCityCache.shared.getCity(byId: cityId) {
                    allowedCityNames.insert(cachedCity.name.lowercased())
                }
            }
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                allowedCityIds.insert(city.id)
                allowedCityNames.insert(city.name.lowercased())
            }
        }

        return cities.filter {
            allowedCityIds.contains($0.id) || allowedCityNames.contains($0.name.lowercased())
        }
    }

    /// Parse a "lat,lon" string to TRPLocation.
    internal func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
    }

    /// One-time subscribe to `TRPTimelineRefreshState`: on `.completed` from any flow, apply pending day navigation and refresh local data.
    private func ensureRefreshStateObserverInstalled() {
        guard !hasObservedRefreshState else { return }
        hasObservedRefreshState = true
        TRPTimelineRefreshState.shared.status.addObserver(self, getDefaultValues: false) { [weak self] status in
            guard let self = self, case .completed = status else { return }
            DispatchQueue.main.async {
                if let dayIndex = self.pendingNavigationDayIndex {
                    self.selectedDayIndex = dayIndex
                    self.pendingNavigationDayIndex = nil
                }
                self.refreshTimeline()
            }
        }
    }
}
