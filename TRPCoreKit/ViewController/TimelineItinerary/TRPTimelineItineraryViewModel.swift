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

public protocol TRPTimelineItineraryViewModelDelegate: ViewModelDelegate {
    func timelineItineraryViewModel(didUpdateTimeline: Bool)
}

public enum TRPTimelineCellType {
    case bookedActivity(TRPTimelineSegment)
    case reservedActivity(TRPTimelineSegment) // Reserved but not purchased
    case activityStep(TRPTimelineStep) // For activity type steps
    case recommendations([TRPTimelineStep]) // For POI type steps
    case emptyState // Empty itinerary day
}

private struct SegmentWithSteps {
    let segment: TRPTimelineSegment
    let steps: [TRPTimelineStep]
}

private enum TimelineItem {
    case bookedActivitySegment(TRPTimelineSegment)
    case reservedActivitySegment(TRPTimelineSegment)
    case activityStep(TRPTimelineStep)
    case poiSteps([TRPTimelineStep])
}

public struct TRPTimelineSectionHeaderData {
    let cityName: String
    let isFirstSection: Bool
    let shouldShowHeader: Bool // Show header for this section
    let hasMultipleDestinations: Bool // Whether timeline has multiple destinations
}

public class TRPTimelineItineraryViewModel {

    // MARK: - Properties
    public weak var delegate: TRPTimelineItineraryViewModelDelegate?

    private var timeline: TRPTimeline?
    private var allSegmentsWithSteps: [[SegmentWithSteps]] = []
    private var segmentsWithSteps: [[SegmentWithSteps]] = []
    private var allTimelineItems: [[TimelineItem]] = []
    private var filteredTimelineItems: [[TimelineItem]] = []
    public var selectedDayIndex: Int = 0
    private var startDate: Date?

    // Keep reference to use case to prevent deallocation during async operations
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    // MARK: - Initialization

    /// Initialize with existing timeline (direct display)
    public init(timeline: TRPTimeline?) {
        self.timeline = timeline
        processTimelineData()

        // Notify that timeline is ready (for VC to reload)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
        }
    }

    /// Initialize with itinerary model (will create/fetch timeline)
    /// - Parameters:
    ///   - itineraryModel: Itinerary model containing trip items
    ///   - tripHash: Optional trip hash for fetching existing timeline
    public init(itineraryModel: TRPItineraryWithActivities, tripHash: String? = nil) {
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
    
    // MARK: - Data Processing
    private func processTimelineData() {
        // Always reset to empty state first
        segmentsWithSteps = []
        allSegmentsWithSteps = []
        allTimelineItems = []
        filteredTimelineItems = []
        startDate = nil

        guard let timeline = timeline else {
            return
        }

        // Store start date for filtering
        // Try to get from plans first, then fall back to segments
        if let planStartDate = timeline.plans?.first?.getStartDate() {
            startDate = planStartDate
        } else if let segments = timeline.segments, !segments.isEmpty {
            // Get earliest date from segments
            var earliestDate: Date?
            for segment in segments {
                if let segmentStartDateStr = segment.additionalData?.startDatetime {
                    // Try both formats: with and without seconds
                    let segmentDate = Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(segmentStartDateStr, format: "yyyy-MM-dd HH:mm:ss")
                    if let date = segmentDate {
                        if earliestDate == nil || date < earliestDate! {
                            earliestDate = date
                        }
                    }
                }
            }
            startDate = earliestDate
        } else {
            startDate = nil
        }

        var items: [TimelineItem] = []

        // 1. Process activity segments (booked and reserved - those with additionalData)
        if let segments = timeline.segments {
            for segment in segments {
                if let additionalData = segment.additionalData {
                    // Copy dates from additionalData to segment for sorting/filtering
                    segment.startDate = additionalData.startDatetime
                    segment.endDate = additionalData.endDatetime

                    // Check segment type to distinguish between booked and reserved
                    if segment.segmentType == .reservedActivity {
                        items.append(.reservedActivitySegment(segment))
                    } else {
                        // Default to booked activity (bookedActivity or if type not set)
                        segment.segmentType = .bookedActivity
                        items.append(.bookedActivitySegment(segment))
                    }
                }
            }
        }
        
        // 2. Process plan steps (group all steps together including activities)
        if let plans = timeline.plans {
            for plan in plans {
                // Group all steps together (both POI and activity types)
                if !plan.steps.isEmpty {
                    items.append(.poiSteps(plan.steps))
                }
            }
        }
        
        // 3. Sort all items by start time
        items.sort { item1, item2 in
            let date1 = getItemStartDate(item1)
            let date2 = getItemStartDate(item2)
            return date1 < date2
        }
        
        // 4. Each item becomes its own section
        allTimelineItems = items.map { [$0] }

        filterItemsByDay(selectedDayIndex)
    }
    
    // Helper to get start date for timeline items
    private func getItemStartDate(_ item: TimelineItem) -> Date {
        switch item {
        case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
            if let startDatetime = segment.additionalData?.startDatetime {
                // Try both formats: with and without seconds
                return Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()

        case .activityStep(let step):
            if let stepStart = step.startDateTimes {
                // Try both formats: with and without seconds
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()

        case .poiSteps(let steps):
            if let firstStep = steps.first, let stepStart = firstStep.startDateTimes {
                // Try both formats: with and without seconds
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()
        }
    }
    
    private func filterItemsByDay(_ dayIndex: Int) {
        guard let startDate = startDate else {
            filteredTimelineItems = allTimelineItems
            return
        }

        // Calculate the selected date
        guard let selectedDate = startDate.addDay(dayIndex) else {
            filteredTimelineItems = allTimelineItems
            return
        }

        // Filter items that fall on the selected day
        var filtered: [[TimelineItem]] = []
        let selectedDayStart = selectedDate.getDateWithZeroHour()
        let selectedDayEnd = selectedDate.addDay(1)?.getDateWithZeroHour() ?? selectedDate

        for itemGroup in allTimelineItems {
            var filteredGroup: [TimelineItem] = []

            for item in itemGroup {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
                    // Check if activity (booked or reserved) falls on selected day
                    if let segmentStartDate = segment.startDate {
                        // Try both formats: with and without seconds
                        let activityDate = Date.fromString(segmentStartDate, format: "yyyy-MM-dd HH:mm") ??
                                          Date.fromString(segmentStartDate, format: "yyyy-MM-dd HH:mm:ss")

                        if let date = activityDate, date >= selectedDayStart && date < selectedDayEnd {
                            filteredGroup.append(item)
                        }
                    }

                case .activityStep(let step):
                    // Check if activity step falls on selected day
                    if let stepStartDate = step.startDateTimes {
                        // Try both formats: with and without seconds
                        let stepDate = Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm") ??
                                      Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm:ss")
                        if let date = stepDate, date >= selectedDayStart && date < selectedDayEnd {
                            filteredGroup.append(item)
                        }
                    }

                case .poiSteps(let steps):
                    // Filter POI steps that match the selected day
                    let filteredSteps = steps.filter { step in
                        guard let stepStartDate = step.startDateTimes else {
                            return false
                        }
                        // Try both formats: with and without seconds
                        let stepDate = Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm") ??
                                      Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm:ss")
                        guard let date = stepDate else {
                            return false
                        }
                        return date >= selectedDayStart && date < selectedDayEnd
                    }

                    if !filteredSteps.isEmpty {
                        filteredGroup.append(.poiSteps(filteredSteps))
                    }
                }
            }
            
            if !filteredGroup.isEmpty {
                filtered.append(filteredGroup)
            }
        }
        
        // Sort each filtered group by start time
        var sorted: [[TimelineItem]] = []
        for var group in filtered {
            group.sort { item1, item2 in
                let date1 = getItemStartDate(item1)
                let date2 = getItemStartDate(item2)
                return date1 < date2
            }
            sorted.append(group)
        }

        filteredTimelineItems = sorted
    }
    
    // MARK: - Public Methods
    public func updateTimeline(_ timeline: TRPTimeline) {
        self.timeline = timeline
        processTimelineData()
    }
    
    public func selectDay(at index: Int) {
        selectedDayIndex = index
        filterItemsByDay(index)
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
    public func getDayDates() -> [Date] {
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

        // Use zero hour dates for accurate day counting
        let startDay = start.getDateWithZeroHour()
        let endDay = end.getDateWithZeroHour()
        var numberOfDays = startDay.numberOfDaysBetween(endDay)

        // If activities are on the same day, numberOfDays will be 0
        // We need at least 1 day to show
        if numberOfDays == 0 {
            numberOfDays = 1
        }

        var dates: [Date] = []
        for dayIndex in 0..<numberOfDays {
            if let currentDate = start.addDay(dayIndex) {
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
        
        // Extract cities from booked segments
        if let segments = timeline?.segments {
            for segment in segments {
                if let city = segment.city, !cityIds.contains(city.id) {
                    cities.append(city)
                    cityIds.insert(city.id)
                }
            }
        }
        
        // Extract cities from plans
        if let plans = timeline?.plans {
            for plan in plans {
                if let city = plan.city, !cityIds.contains(city.id) {
                    cities.append(city)
                    cityIds.insert(city.id)
                }
            }
        }
        
        return cities
    }
    
    // MARK: - TableView Data Methods
    public func numberOfSections() -> Int {
        // If no items, return 1 section for empty state
        return filteredTimelineItems.isEmpty ? 1 : filteredTimelineItems.count
    }
    
    public func numberOfRows(in section: Int) -> Int {
        // If no items, show empty state (1 row)
        if filteredTimelineItems.isEmpty {
            return 1
        }
        
        guard section < filteredTimelineItems.count else { return 0 }
        
        let sectionItems = filteredTimelineItems[section]
        
        // Each item (bookedActivity, activityStep, or poiSteps) is one row
        return sectionItems.count
    }
    
    public func cellType(at indexPath: IndexPath) -> TRPTimelineCellType? {
        // If no items, return empty state
        if filteredTimelineItems.isEmpty {
            return .emptyState
        }
        
        guard indexPath.section < filteredTimelineItems.count else {
            return nil
        }
        
        let sectionItems = filteredTimelineItems[indexPath.section]
        
        // Each row corresponds to one timeline item
        guard indexPath.row < sectionItems.count else {
            return nil
        }
        
        let item = sectionItems[indexPath.row]
        
        switch item {
        case .bookedActivitySegment(let segment):
            return .bookedActivity(segment)

        case .reservedActivitySegment(let segment):
            return .reservedActivity(segment)

        case .activityStep(let step):
            return .activityStep(step)

        case .poiSteps(let steps):
            return .recommendations(steps)
        }
    }
    
    public func headerData(for section: Int) -> TRPTimelineSectionHeaderData {
        // If empty state, don't show header
        if filteredTimelineItems.isEmpty {
            return TRPTimelineSectionHeaderData(
                cityName: "",
                isFirstSection: false,
                shouldShowHeader: false,
                hasMultipleDestinations: false
            )
        }
        
        let isFirstSection = section == 0
        let cityName = getCityName(for: section)
        let hasMultipleDests = hasMultipleDestinations()
        
        // Determine if we should show the header:
        // 1. Always show for first section (for context)
        // 2. If multiple destinations exist, show header only when city CHANGES from previous section
        var shouldShowHeader = isFirstSection

        if hasMultipleDests && !isFirstSection {
            // Check if this section's city is different from the previous section's city
            let previousCityName = getCityName(for: section - 1)
            shouldShowHeader = (cityName != previousCityName)
        }

        return TRPTimelineSectionHeaderData(
            cityName: cityName,
            isFirstSection: isFirstSection,
            shouldShowHeader: shouldShowHeader,
            hasMultipleDestinations: hasMultipleDests
        )
    }
    
    private func getCityName(for section: Int) -> String {
        guard section < filteredTimelineItems.count,
              let firstItem = filteredTimelineItems[section].first else {
            return "Unknown"
        }
        
        // Extract city from the timeline item
        switch firstItem {
        case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
            return segment.city?.name ?? "Unknown"

        case .activityStep(let step):
            // Activity steps might not have city info directly, try to get from POI
            return step.poi?.locations.first?.name ?? "Unknown"
            
        case .poiSteps(let steps):
            if let firstStep = steps.first, let location = firstStep.poi?.locations.first {
                return location.name
            }
            return "Unknown"
        }
    }
    
    /// Check if there are multiple different destinations in the timeline
    private func hasMultipleDestinations() -> Bool {
        var cityIds = Set<Int>()
        var cityNames = Set<String>()
        
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
                    if let city = segment.city {
                        cityIds.insert(city.id)
                        cityNames.insert(city.name)
                    }

                case .activityStep(let step):
                    if let location = step.poi?.locations.first {
                        cityIds.insert(location.id)
                        cityNames.insert(location.name)
                    }
                    
                case .poiSteps(let steps):
                    if let firstStep = steps.first, let location = firstStep.poi?.locations.first {
                        cityIds.insert(location.id)
                        cityNames.insert(location.name)
                    }
                }
                
                // If we found more than one city, we have multiple destinations
                if cityIds.count > 1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Map Helper Methods
    
    /// Get all POIs for the currently selected day
    public func getPoisForSelectedDay() -> [TRPPoi] {
        var pois: [TRPPoi] = []
        
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .activityStep(let step):
                    if let poi = step.poi {
                        pois.append(poi)
                    }
                    
                case .poiSteps(let steps):
                    for step in steps {
                        if let poi = step.poi {
                            pois.append(poi)
                        }
                    }

                case .bookedActivitySegment, .reservedActivitySegment:
                    // Booked/reserved activities don't have POIs to show on map
                    break
                }
            }
        }
        
        return pois
    }
    
    /// Get POIs grouped by segments for the selected day
    /// Each inner array represents a separate segment that should have its own route
    public func getSegmentsWithPoisForSelectedDay() -> [[TRPPoi]] {
        var segmentGroups: [[TRPPoi]] = []
        
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .activityStep(let step):
                    // Activity steps are individual
                    if let poi = step.poi {
                        segmentGroups.append([poi])
                    }
                    
                case .poiSteps(let steps):
                    // POI steps are grouped together
                    var poisInGroup: [TRPPoi] = []
                    for step in steps {
                        if let poi = step.poi {
                            poisInGroup.append(poi)
                        }
                    }
                    if !poisInGroup.isEmpty {
                        segmentGroups.append(poisInGroup)
                    }

                case .bookedActivitySegment, .reservedActivitySegment:
                    // Booked/reserved activities don't have POIs
                    break
                }
            }
        }
        
        return segmentGroups
    }
    
    /// Get booked and reserved activities for the selected day
    public func getBookedActivitiesForSelectedDay() -> [TRPTimelineSegment] {
        var bookedActivities: [TRPTimelineSegment] = []

        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
                    bookedActivities.append(segment)
                default:
                    break
                }
            }
        }

        return bookedActivities
    }
    
    /// Get POI by ID
    public func getPoi(byId id: String) -> TRPPoi? {
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .activityStep(let step):
                    if let poi = step.poi, poi.id == id {
                        return poi
                    }
                    
                case .poiSteps(let steps):
                    for step in steps {
                        if let poi = step.poi, poi.id == id {
                            return poi
                        }
                    }

                case .bookedActivitySegment, .reservedActivitySegment:
                    break
                }
            }
        }
        return nil
    }

    /// Get booked or reserved activity by activity ID
    public func getBookedActivity(byId activityId: String) -> TRPTimelineSegment? {
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment):
                    if let additionalData = segment.additionalData,
                       additionalData.activityId == activityId {
                        return segment
                    }
                default:
                    break
                }
            }
        }
        return nil
    }
    
    /// Get step for a specific POI ID
    public func getStep(forPoiId id: String) -> TRPTimelineStep? {
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .activityStep(let step):
                    if let poi = step.poi, poi.id == id {
                        return step
                    }
                    
                case .poiSteps(let steps):
                    for step in steps {
                        if let poi = step.poi, poi.id == id {
                            return step
                        }
                    }

                case .bookedActivitySegment, .reservedActivitySegment:
                    break
                }
            }
        }
        return nil
    }

    /// Get first plan from timeline
    public func getFirstPlan() -> TRPTimelinePlan? {
        return timeline?.plans?.first
    }
    
    /// Calculate route for given locations
    public func calculateRoute(for locations: [TRPLocation], completion: @escaping (Route?, Error?) -> Void) {
        guard locations.count > 1 else {
            completion(nil, nil)
            return
        }

        guard let accessToken = TRPApiKeyController.getKey(TRPApiKeys.mglMapboxAccessToken) else {
            completion(nil, NSError(domain: "MapBox", code: -1, userInfo: [NSLocalizedDescriptionKey: "MapBox access token not found"]))
            return
        }

        let calculator = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: locations, dailyPlanId: 0)
        calculator.calculateRoute { route, error, _, _ in
            DispatchQueue.main.async {
                completion(route, error)
            }
        }
    }

    // MARK: - Timeline Creation/Fetch Methods

    /// Creates a new timeline from itinerary model
    private func createTimeline(from itineraryModel: TRPItineraryWithActivities) {
        // Create timeline profile from itinerary
        let profile = itineraryModel.createTimelineProfileFromBookings()

        // Also add favourite items to profile
        profile.favouriteItems = itineraryModel.favouriteItems

        // Create timeline using repository
        let repository = TRPTimelineRepository()
        let createUseCase = TRPCreateTimelineUseCase(repository: repository)

        createUseCase.executeCreateTimeline(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let createdTimeline):
                // Wait for timeline generation to complete
                self.waitForTimelineGeneration(tripHash: createdTimeline.tripHash, itineraryModel: itineraryModel)

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Waits for timeline generation to complete
    private func waitForTimelineGeneration(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
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

            // Fetch the complete timeline
            self.fetchTimeline(tripHash: tripHash, itineraryModel: itineraryModel)

            // Clear use case reference after completion
            self.checkAllPlanUseCase = nil
        }

        // Start checking generation status
        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
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

    /// Fetches existing timeline by tripHash
    private func fetchTimeline(tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(var timeline):
                    // Merge itinerary model data (segments from tripItems)
                    timeline = self.mergeItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                    // Update timeline and process data
                    self.timeline = timeline
                    self.processTimelineData()

                    // Notify delegate
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Merges itinerary model data into timeline
    private func mergeItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) -> TRPTimeline {
        var updatedTimeline = timeline

        // Add favourite items
        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        // Convert tripItems to segments
        if let tripItems = itineraryModel.tripItems, !tripItems.isEmpty {
            let profileFromBookings = itineraryModel.createTimelineProfileFromBookings()

            if !profileFromBookings.segments.isEmpty {
                updatedTimeline.segments = profileFromBookings.segments
            }
        }

        return updatedTimeline
    }
}


