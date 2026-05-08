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
    /// Show or hide the Lottie loader. The `textMode` controls what (if anything) is rendered
    /// next to the animation: `.none`, `.single(text)`, or `.rotating([texts])`.
    func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode)
}

// MARK: - Default Implementations
extension TRPTimelineItineraryViewModelDelegate {
    /// Default implementation falls back to the standard preloader (text mode is ignored
    /// when the conformer doesn't provide a Lottie-aware override).
    public func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
        viewModel(showPreloader: showLottieLoading)
    }

    /// Convenience wrapper that uses the default rotating timeline texts. Existing call sites
    /// that don't care about the text content can keep calling this.
    public func timelineItineraryViewModel(showLottieLoading: Bool) {
        timelineItineraryViewModel(showLottieLoading: showLottieLoading, textMode: .defaultRotating)
    }
}

// MARK: - Type Aliases for backward compatibility
// Models moved to TRPDataLayer/Domain/Models/Timeline/ (SOLID: SRP)
public typealias MapDisplayItem = TRPMapDisplayItem

public class TRPTimelineItineraryViewModel {

    // MARK: - Properties
    public weak var delegate: TRPTimelineItineraryViewModelDelegate? {
        didSet {
            // Lazy subscription to the shared refresh state — installed on first
            // delegate assignment so any cross-screen refresh trigger (e.g. manual
            // activity add from `AddPlanTimeSelectionVC`) propagates back into a
            // local `refreshTimeline()` without each call site having to wire it.
            ensureRefreshStateObserverInstalled()
        }
    }
    /// Whether the shared `TRPTimelineRefreshState` observer has been installed for
    /// this VM. One-shot — multiple delegate set/clears don't re-subscribe.
    private var hasObservedRefreshState: Bool = false

    internal var timeline: TRPTimeline?
    internal var itineraryModel: TRPItineraryWithActivities?

    /// Merged timeline with date-grouped items - SINGLE SOURCE OF TRUTH
    internal var mergedTimeline: TRPDateGroupedTimeline?

    /// Items for currently selected day, grouped by city for section display
    internal var displayItems: [TRPTimelineCityGroup] = []

    /// Unified order map for current day (sectionIndex_segmentIndex -> starting order)
    /// Order resets to 1 for each city (section)
    /// For single-item segments (booked/reserved/manualPoi): the order value
    /// For itinerary segments: the starting order (steps use startingOrder + stepIndex)
    internal var unifiedOrderMap: [String: Int] = [:]

    /// All trip dates from start to end (continuous, for day filter display)
    internal var allTripDates: [Date] = []

    public var selectedDayIndex: Int = 0

    /// True when the currently selected day is strictly before today (calendar-day comparison).
    /// Used by cells to render past-day items in muted colors.
    public var isSelectedDayPast: Bool {
        guard selectedDayIndex >= 0, selectedDayIndex < allTripDates.count else { return false }
        return allTripDates[selectedDayIndex].isPastDay()
    }

    /// Pending day index to navigate to after segment creation/refresh
    internal var pendingNavigationDayIndex: Int?

    // Filtered favorite items (excludes items that are already booked or reserved)
    internal var filteredFavoriteItems: [TRPSegmentFavoriteItem] = []

    // Destination items from itinerary (for date-city mapping in AddPlan)
    internal var destinationItems: [TRPSegmentDestinationItem] = []

    // Track if initial data has been loaded (prevents showing empty state during loading)
    internal var hasLoadedData: Bool = false

    // Flag to show no city state immediately on VC load
    public var showNoCityStateOnLoad: Bool = false

    // MARK: - Public Methods

    /// Get the trip hash from timeline
    public func getTripHash() -> String? {
        return timeline?.tripHash
    }

    /// Get segment index for update API (edit mode)
    /// Matches segment by startDate and activityId
    public func getSegmentIndex(for segment: TRPTimelineSegment) -> Int? {
        guard let timeline = timeline,
              let tripProfile = timeline.tripProfile else { return nil }
        return tripProfile.segments.firstIndex { s in
            s.startDate == segment.startDate &&
            s.additionalData?.activityId == segment.additionalData?.activityId
        }
    }

    // Track collapse state for each section (section index -> isExpanded)
    internal var sectionCollapseStates: [Int: Bool] = [:]

    // Keep reference to use case to prevent deallocation during async operations
    internal var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    // Keep references to active route calculators to prevent deallocation during async operations
    internal var activeRouteCalculators: [TRPRouteCalculator] = []

    // Use case for step operations (edit, delete, etc.)
    internal lazy var timelineModeUseCases: TRPTimelineModeUseCases = TRPTimelineModeUseCases()

    /// Trip hash to fetch on first load. Set when ViewModel is constructed via `init(tripHash:)`;
    /// consumed once by `loadInitialTimelineIfNeeded()`.
    internal var pendingInitialTripHash: String?

    /// Optional profile merged into the fetched timeline on first load. Used by the create flow
    /// to carry segments/favourites from the original `TRPTimelineProfile`.
    internal var pendingMergeProfile: TRPTimelineProfile?

    // MARK: - Initialization

    /// Initialize with a trip hash only — timeline will be fetched on first VC load,
    /// and the Lottie loader is shown by the VC during the fetch.
    /// - Parameters:
    ///   - tripHash: Trip hash for the GetTimeline request.
    ///   - mergeProfile: Optional profile whose segments/favourites are merged into the fetched timeline
    ///     (used by the create flow to preserve user-supplied data).
    public init(tripHash: String, mergeProfile: TRPTimelineProfile? = nil) {
        print("🟣 [ViewModel Init] init(tripHash:) called")
        self.timeline = nil
        self.pendingInitialTripHash = tripHash
        self.pendingMergeProfile = mergeProfile
    }

    /// Initialize with existing timeline (direct display)
    public init(timeline: TRPTimeline?) {
        print("🟡 [ViewModel Init] init(timeline:) called")
        if var mutableTimeline = timeline {
            // NOTE: Do NOT sync segments - use API response as-is
            // tripProfile.segments is the single source of truth
            // Populate city information in segments BEFORE processing
            populateCitiesInSegments(&mutableTimeline)
            self.timeline = mutableTimeline
        } else {
            self.timeline = timeline
        }

        processTimelineData()

        // Resolve favourite item city IDs asynchronously, then re-filter
        resolveFavouriteItemCities { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.filterFavoriteItems()
                self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
            }
        }
    }

    /// Initialize with existing timeline and itinerary model
    /// Will check for missing booked activities and add them via API
    /// - Parameters:
    ///   - timeline: Existing timeline from server
    ///   - itineraryModel: Itinerary model containing tripItems to check for missing activities
    public init(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) {
        print("🔵 [ViewModel Init] init(timeline:itinerary:) called")
        var mutableTimeline = timeline

        // Store destination items for date-city mapping in AddPlan
        self.destinationItems = itineraryModel.destinationItems

        // Merge favourite items from itinerary model
        mutableTimeline.favouriteItems = itineraryModel.favouriteItems

        // NOTE: Do NOT sync segments - use API response as-is
        // tripProfile.segments is the single source of truth
        // Populate city information in segments BEFORE processing
        populateCitiesInSegments(&mutableTimeline)

        self.timeline = mutableTimeline
        self.itineraryModel = itineraryModel

        processTimelineData()

        print("🔵 [ViewModel Init] About to call syncRemovedCitySegments()")
        // Sync removed city segments (optimistic update)
        syncRemovedCitySegments()

        // Resolve favourite item city IDs asynchronously, then notify UI
        resolveFavouriteItemCities { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.filterFavoriteItems()
                self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                // Check for missing booked activities and add via API if needed
                self.addMissingBookedActivities(from: itineraryModel)
            }
        }
    }

    /// Initialize with itinerary model (will create/fetch timeline)
    /// - Parameters:
    ///   - itineraryModel: Itinerary model containing trip items
    ///   - tripHash: Optional trip hash for fetching existing timeline
    public init(itineraryModel: TRPItineraryWithActivities, tripHash: String? = nil) {
        print("🟢 [ViewModel Init] init(itineraryModel:tripHash:) called with tripHash: \(tripHash ?? "nil")")
        // Store destination items for date-city mapping in AddPlan
        self.destinationItems = itineraryModel.destinationItems

        // Defer timeline creation/fetch to allow delegate to be set up first
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // First GetTimeline on SDK open — show "Getting your itinerary plan" so the
            // splash → timeline transition keeps a single readable message on the loader.
            let initialLoadText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingYourItineraryPlan)
            self.delegate?.timelineItineraryViewModel(showLottieLoading: true, textMode: .single(initialLoadText))

            // First resolve ALL cityIds via API (for both create and fetch paths)
            self.resolveMissingCityIds(in: itineraryModel) { [weak self] resolvedItinerary in
                guard let self = self else { return }

                // Update stored destination items with resolved cityIds
                self.destinationItems = resolvedItinerary.destinationItems

                // Separate valid and invalid destination items
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

                    // Filter out invalid destinations from itinerary
                    var filteredItinerary = resolvedItinerary
                    filteredItinerary.destinationItems = validItems

                    // Update stored destination items with only valid items
                    self.destinationItems = validItems

                    // Show alert (non-blocking, fire and forget)
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

        // NOTE: Do NOT sync segments - use API response as-is
        // tripProfile.segments is the single source of truth
        // Populate city information in segments BEFORE processing
        populateCitiesInSegments(&mutableTimeline)

        self.timeline = mutableTimeline
        processTimelineData()

        // Resolve favourite item city IDs asynchronously, then re-filter
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
        // Reset collapse states when changing day
        sectionCollapseStates.removeAll()

        // Update display items for selected day
        updateDisplayItems()
    }

    /// Whether any displayed item on the currently selected day has a time conflict.
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

    /// Get collapse state for a section (default is expanded = true)
    public func getSectionCollapseState(for section: Int) -> Bool {
        return sectionCollapseStates[section] ?? true // Default to expanded
    }

    /// Set collapse state for a section
    public func setSectionCollapseState(for section: Int, isExpanded: Bool) {
        sectionCollapseStates[section] = isExpanded
    }

    public func getDays() -> [String] {
        // Use central method to get date boundaries
        guard let boundaries = getTimelineDateBoundaries() else { return [] }

        // Calculate number of days
        // Use zero hour dates for accurate day counting
        let startDay = boundaries.startDate.getDateWithZeroHour()
        let endDay = boundaries.endDate.getDateWithZeroHour()
        var numberOfDays = startDay.numberOfDaysBetween(endDay)

        // If activities are on the same day, numberOfDays will be 0
        // We need at least 1 day to show
        if numberOfDays == 0 {
            numberOfDays = 1
        }

        // Generate day items with day of week and date
        var days: [String] = []

        // Use current app language for day names
        let appLanguage = TRPClient.getLanguage()
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: appLanguage)
        dayFormatter.dateFormat = "EEEE" // Full day name

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
    
    /// Get the trip dates as Date objects
    /// Returns all available days based on timeline segments
    /// Calculates from minimum to maximum segment dates (inclusive)
    /// Example: If segments exist on 2025-12-28, 2026-01-04, 2026-01-06
    ///          Returns all days from 2025-12-28 to 2026-01-06
    public func getDayDates() -> [Date] {
        // Use central method to get date boundaries
        guard let boundaries = getTimelineDateBoundaries() else { return [] }

        let numberOfDays = boundaries.startDate.numberOfDaysBetween(boundaries.endDate)

        // Generate all days from start to end (inclusive)
        var dates: [Date] = []
        for dayIndex in 0..<numberOfDays {
            if let currentDate = boundaries.startDate.addDay(dayIndex) {
                dates.append(currentDate)
            }
        }

        return dates
    }
    
    /// Get the trip date range (start and end dates)
    public func getTripDateRange() -> (start: Date, end: Date)? {
        // Use central method to get date boundaries
        guard let boundaries = getTimelineDateBoundaries() else { return nil }
        return (start: boundaries.startDate, end: boundaries.endDate)
    }
    
    /// Get all unique cities from the timeline
    public func getCities() -> [TRPCity] {
        var cities: [TRPCity] = []
        var cityIds = Set<Int>()
        var cityNames = Set<String>() // Track city names to avoid duplicates

        // 1. First priority: Use timeline.city (main city from API)
        if let timelineCity = timeline?.city, timelineCity.id > 0 {
            cities.append(timelineCity)
            cityIds.insert(timelineCity.id)
            cityNames.insert(timelineCity.name.lowercased())
        }

        // 2. Extract cities from plans (API data - most reliable)
        if let plans = timeline?.plans {
            for plan in plans {
                if let city = plan.city, city.id > 0 {
                    let normalizedName = city.name.lowercased()
                    // Skip if same name already exists (prefer earlier sources)
                    if cityNames.contains(normalizedName) {
                        continue
                    }
                    cities.append(city)
                    cityIds.insert(city.id)
                    cityNames.insert(normalizedName)
                }
            }
        }

        // 3. Extract cities from booked segments (might have mock/stale IDs)
        if let segments = timeline?.segments {
            for segment in segments {
                if let city = segment.city, city.id > 0 {
                    let normalizedName = city.name.lowercased()
                    // Skip if same name already exists (prefer plan data)
                    if cityNames.contains(normalizedName) {
                        continue
                    }
                    cities.append(city)
                    cityIds.insert(city.id)
                    cityNames.insert(normalizedName)
                }
            }
        }

        // 4. Extract cities from destinationItems (for date-city mapping)
        for item in destinationItems {
            let coordinate = parseCoordinate(from: item.coordinate)

            // Try to find city by cityId first
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

            // Fallback: Find city by coordinate
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                if cityIds.contains(city.id) { continue }
                if cityNames.contains(city.name.lowercased()) { continue }
                cities.append(city)
                cityIds.insert(city.id)
                cityNames.insert(city.name.lowercased())
            }
        }

        return cities
    }

    /// Parse coordinate string (e.g., "41.3851,2.1734") to TRPLocation
    internal func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
    }

    /// Subscribe to the app-wide `TRPTimelineRefreshState` once. When any flow
    /// (this VM's own `waitForSegmentGeneration`, or a sibling VM such as
    /// `AddPlanTimeSelectionViewModel`'s post-creation polling) reports
    /// `.completed`, apply any pending day navigation and refresh local timeline
    /// data so the screen shows the latest segments the next time it's visible.
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
