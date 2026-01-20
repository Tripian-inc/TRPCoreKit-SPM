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
}

// MARK: - Type Aliases for backward compatibility
// Models moved to TRPDataLayer/Domain/Models/Timeline/ (SOLID: SRP)
public typealias MapDisplayItem = TRPMapDisplayItem

public class TRPTimelineItineraryViewModel {

    // MARK: - Properties
    public weak var delegate: TRPTimelineItineraryViewModelDelegate?

    internal var timeline: TRPTimeline?

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

    // Filtered favorite items (excludes items that are already booked or reserved)
    internal var filteredFavoriteItems: [TRPSegmentFavoriteItem] = []

    // Destination items from itinerary (for date-city mapping in AddPlan)
    internal var destinationItems: [TRPSegmentDestinationItem] = []

    // Track if initial data has been loaded (prevents showing empty state during loading)
    internal var hasLoadedData: Bool = false

    // MARK: - Public Methods

    /// Get the trip hash from timeline
    public func getTripHash() -> String? {
        return timeline?.tripHash
    }

    // Track collapse state for each section (section index -> isExpanded)
    internal var sectionCollapseStates: [Int: Bool] = [:]

    // Keep reference to use case to prevent deallocation during async operations
    internal var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    // Use case for step operations (edit, delete, etc.)
    internal lazy var timelineModeUseCases: TRPTimelineModeUseCases = TRPTimelineModeUseCases()

    // MARK: - Initialization

    /// Initialize with existing timeline (direct display)
    public init(timeline: TRPTimeline?) {
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

        // Notify that timeline is ready (for VC to reload)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
        }
    }

    /// Initialize with existing timeline and itinerary model
    /// Will check for missing booked activities and add them via API
    /// - Parameters:
    ///   - timeline: Existing timeline from server
    ///   - itineraryModel: Itinerary model containing tripItems to check for missing activities
    public init(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) {
        var mutableTimeline = timeline

        // Store destination items for date-city mapping in AddPlan
        self.destinationItems = itineraryModel.destinationItems

        // NOTE: Do NOT sync segments - use API response as-is
        // tripProfile.segments is the single source of truth
        // Populate city information in segments BEFORE processing
        populateCitiesInSegments(&mutableTimeline)

        self.timeline = mutableTimeline

        processTimelineData()

        // Notify that timeline is ready (for VC to reload)
        // Then check for missing booked activities
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

            // Check for missing booked activities and add via API if needed
            self?.addMissingBookedActivities(from: itineraryModel)
        }
    }

    /// Initialize with itinerary model (will create/fetch timeline)
    /// - Parameters:
    ///   - itineraryModel: Itinerary model containing trip items
    ///   - tripHash: Optional trip hash for fetching existing timeline
    public init(itineraryModel: TRPItineraryWithActivities, tripHash: String? = nil) {
        // Store destination items for date-city mapping in AddPlan
        self.destinationItems = itineraryModel.destinationItems

        // Defer timeline creation/fetch to allow delegate to be set up first
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Start loading
            self.delegate?.viewModel(showPreloader: true)

            // Create/fetch timeline based on tripHash
            if let tripHash = tripHash {
                self.fetchTimeline(tripHash: tripHash, itineraryModel: itineraryModel)
            } else {
                self.createTimeline(from: itineraryModel)
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
    }
    
    public func selectDay(at index: Int) {
        selectedDayIndex = index
        // Reset collapse states when changing day
        sectionCollapseStates.removeAll()

        // Update display items for selected day
        updateDisplayItems()
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
        var startDate: Date?
        var endDate: Date?

        // Try to get dates from plans first
        if let plans = timeline?.plans, !plans.isEmpty {
            startDate = plans.first?.getStartDate()
            endDate = plans.last?.getEndDate()
        } else if let segments = timeline?.segments, !segments.isEmpty {
            // Fall back to segments if no plans exist
            for segment in segments {
                if let segmentStartDateStr = segment.additionalData?.startDatetime {
                    // Try both formats: with and without seconds
                    let segmentDate = Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm:ss")
                    if let date = segmentDate {
                        if startDate == nil || date < startDate! {
                            startDate = date
                        }
                    }
                }

                if let segmentEndDateStr = segment.additionalData?.endDatetime {
                    // Try both formats: with and without seconds
                    let segmentDate = Date.fromString(segmentEndDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(segmentEndDateStr, format: "yyyy-MM-dd HH:mm:ss")
                    if let date = segmentDate {
                        if endDate == nil || date > endDate! {
                            endDate = date
                        }
                    }
                }
            }
        }

        guard let start = startDate, let end = endDate else { return [] }

        // Calculate number of days
        // Use zero hour dates for accurate day counting
        let startDay = start.getDateWithZeroHour()
        let endDay = end.getDateWithZeroHour()
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
            if let currentDate = start.addDay(dayIndex) {
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
        guard let timeline = timeline else { return [] }

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

        guard !allSegments.isEmpty else { return [] }

        // Use string-based comparison to avoid timezone issues
        var minDateString: String?
        var maxDateString: String?

        // Find min and max dates from all segments
        // Check both segment.startDate and segment.additionalData.startDatetime
        for segment in allSegments {
            // First try additionalData.startDatetime (for booked/reserved activities)
            var segmentStartDateStr = segment.additionalData?.startDatetime

            // If not available, try segment.startDate directly (for itinerary segments)
            if segmentStartDateStr == nil {
                segmentStartDateStr = segment.startDate
            }

            guard let dateStr = segmentStartDateStr else { continue }

            // Extract only date portion (yyyy-MM-dd)
            let segmentDateString = String(dateStr.prefix(10))

            // Update min date
            if minDateString == nil || segmentDateString < minDateString! {
                minDateString = segmentDateString
            }

            // Update max date
            if maxDateString == nil || segmentDateString > maxDateString! {
                maxDateString = segmentDateString
            }
        }

        guard let minStr = minDateString, let maxStr = maxDateString else { return [] }

        // Convert date strings to Date objects (at midnight, local timezone)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        guard let startDay = dateFormatter.date(from: minStr),
              let endDay = dateFormatter.date(from: maxStr) else { return [] }

        let numberOfDays = startDay.numberOfDaysBetween(endDay)

        // Generate all days from min to max (inclusive)
        var dates: [Date] = []
        for dayIndex in 0..<numberOfDays {
            if let currentDate = startDay.addDay(dayIndex) {
                dates.append(currentDate)
            }
        }

        return dates
    }
    
    /// Get the trip date range (start and end dates)
    public func getTripDateRange() -> (start: Date, end: Date)? {
        var startDate: Date?
        var endDate: Date?

        // Try to get dates from plans first
        if let plans = timeline?.plans, !plans.isEmpty {
            startDate = plans.first?.getStartDate()
            endDate = plans.last?.getEndDate()
        } else if let segments = timeline?.segments, !segments.isEmpty {
            // Fall back to segments if no plans exist
            for segment in segments {
                if let segmentStartDateStr = segment.additionalData?.startDatetime {
                    // Try both formats: with and without seconds
                    let segmentDate = Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm:ss")
                    if let date = segmentDate {
                        if startDate == nil || date < startDate! {
                            startDate = date
                        }
                    }
                }

                if let segmentEndDateStr = segment.additionalData?.endDatetime {
                    // Try both formats: with and without seconds
                    let segmentDate = Date.fromString(segmentEndDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(segmentEndDateStr, format: "yyyy-MM-dd HH:mm:ss")
                    if let date = segmentDate {
                        if endDate == nil || date > endDate! {
                            endDate = date
                        }
                    }
                }
            }
        }

        guard let start = startDate, let end = endDate else { return nil }

        return (start: start, end: end)
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
}