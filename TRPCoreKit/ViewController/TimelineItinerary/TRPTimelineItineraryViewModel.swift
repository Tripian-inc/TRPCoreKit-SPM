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

public enum TRPTimelineCellType {
    case bookedActivity(TRPTimelineSegment)
    case activityStep(TRPTimelineStep) // For activity type steps
    case recommendations([TRPTimelineStep]) // For POI type steps
}

private struct SegmentWithSteps {
    let segment: TRPTimelineSegment
    let steps: [TRPTimelineStep]
}

private enum TimelineItem {
    case bookedActivitySegment(TRPTimelineSegment)
    case activityStep(TRPTimelineStep)
    case poiSteps([TRPTimelineStep])
}

public struct TRPTimelineSectionHeaderData {
    let cityName: String
    let showFilterButton: Bool
    let showAddPlansButton: Bool
    let isFirstSection: Bool
    let shouldShowHeader: Bool // Show header for this section
    let hasMultipleDestinations: Bool // Whether timeline has multiple destinations
}

public class TRPTimelineItineraryViewModel {
    
    // MARK: - Properties
    private var timeline: TRPTimeline?
    private var allSegmentsWithSteps: [[SegmentWithSteps]] = []
    private var segmentsWithSteps: [[SegmentWithSteps]] = []
    private var allTimelineItems: [[TimelineItem]] = []
    private var filteredTimelineItems: [[TimelineItem]] = []
    public var selectedDayIndex: Int = 0
    private var startDate: Date?
    
    // MARK: - Initialization
    public init(timeline: TRPTimeline?) {
        self.timeline = timeline
        processTimelineData()
    }
    
    // MARK: - Data Processing
    private func processTimelineData() {
        guard let timeline = timeline else {
            segmentsWithSteps = []
            allSegmentsWithSteps = []
            allTimelineItems = []
            filteredTimelineItems = []
            startDate = nil
            return
        }
        
        // Store start date for filtering
        startDate = timeline.plans?.first?.getStartDate()
        
        var items: [TimelineItem] = []
        
        // 1. Process booked activity segments (those with additionalData)
        if let segments = timeline.segments {
            for segment in segments {
                if let additionalData = segment.additionalData {
                    // Copy dates from additionalData to segment for sorting/filtering
                    segment.startDate = additionalData.startDatetime
                    segment.endDate = additionalData.endDatetime
                    segment.segmentType = .bookedActivity
                    
                    items.append(.bookedActivitySegment(segment))
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
        case .bookedActivitySegment(let segment):
            if let startDatetime = segment.additionalData?.startDatetime {
                return Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()
            
        case .activityStep(let step):
            if let stepStart = step.startDateTimes {
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()
            
        case .poiSteps(let steps):
            if let firstStep = steps.first, let stepStart = firstStep.startDateTimes {
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
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
                case .bookedActivitySegment(let segment):
                    // Check if booked activity falls on selected day
                    if let segmentStartDate = segment.startDate,
                       let activityDate = Date.fromString(segmentStartDate, format: "yyyy-MM-dd HH:mm:ss") {
                        if activityDate >= selectedDayStart && activityDate < selectedDayEnd {
                            filteredGroup.append(item)
                        }
                    }
                    
                case .activityStep(let step):
                    // Check if activity step falls on selected day
                    if let stepStartDate = step.startDateTimes,
                       let stepDate = Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm:ss") {
                        if stepDate >= selectedDayStart && stepDate < selectedDayEnd {
                            filteredGroup.append(item)
                        }
                    }
                    
                case .poiSteps(let steps):
                    // Filter POI steps that match the selected day
                    let filteredSteps = steps.filter { step in
                        guard let stepStartDate = step.startDateTimes,
                              let stepDate = Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm:ss") else {
                            return true
                        }
                        return stepDate >= selectedDayStart && stepDate < selectedDayEnd
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
        
        filteredTimelineItems = sorted.isEmpty ? allTimelineItems : sorted
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
        guard let plans = timeline?.plans, !plans.isEmpty else { return [] }
        
        // Get the overall start and end dates from all plans
        let startDate = plans.first?.getStartDate() ?? Date()
        let endDate = plans.last?.getEndDate() ?? Date()
        
        // Calculate number of days
        let numberOfDays = startDate.numberOfDaysBetween(endDate)
        
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
            if let currentDate = startDate.addDay(dayIndex) {
                let dayName = dayFormatter.string(from: currentDate).capitalized
                let dateString = dateFormatter.string(from: currentDate)
                days.append("\(dayName) \(dateString)")
            }
        }
        
        return days
    }
    
    /// Get the trip dates as Date objects
    public func getDayDates() -> [Date] {
        guard let plans = timeline?.plans, !plans.isEmpty else { return [] }
        
        let startDate = plans.first?.getStartDate() ?? Date()
        let endDate = plans.last?.getEndDate() ?? Date()
        let numberOfDays = startDate.numberOfDaysBetween(endDate)
        
        var dates: [Date] = []
        for dayIndex in 0..<numberOfDays {
            if let currentDate = startDate.addDay(dayIndex) {
                dates.append(currentDate)
            }
        }
        
        return dates
    }
    
    /// Get the trip date range (start and end dates)
    public func getTripDateRange() -> (start: Date, end: Date)? {
        guard let plans = timeline?.plans, !plans.isEmpty else { return nil }
        
        let startDate = plans.first?.getStartDate() ?? Date()
        let endDate = plans.last?.getEndDate() ?? Date()
        
        return (start: startDate, end: endDate)
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
        return filteredTimelineItems.count
    }
    
    public func numberOfRows(in section: Int) -> Int {
        guard section < filteredTimelineItems.count else { return 0 }
        
        let sectionItems = filteredTimelineItems[section]
        
        // Each item (bookedActivity, activityStep, or poiSteps) is one row
        return sectionItems.count
    }
    
    public func cellType(at indexPath: IndexPath) -> TRPTimelineCellType? {
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
            
        case .activityStep(let step):
            return .activityStep(step)
            
        case .poiSteps(let steps):
            return .recommendations(steps)
        }
    }
    
    public func headerData(for section: Int) -> TRPTimelineSectionHeaderData {
        let isFirstSection = section == 0
        let cityName = getCityName(for: section)
        let hasMultipleDests = hasMultipleDestinations()
        
        // Determine if we should show the header:
        // 1. Always show for first section (needs filter and add plans buttons)
        // 2. If multiple destinations exist, show header only when city CHANGES from previous section
        var shouldShowHeader = isFirstSection
        
        if hasMultipleDests && !isFirstSection {
            // Check if this section's city is different from the previous section's city
            let previousCityName = getCityName(for: section - 1)
            shouldShowHeader = (cityName != previousCityName)
        }
        
        return TRPTimelineSectionHeaderData(
            cityName: cityName,
            showFilterButton: isFirstSection,
            showAddPlansButton: isFirstSection,
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
        case .bookedActivitySegment(let segment):
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
                case .bookedActivitySegment(let segment):
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
                    
                case .bookedActivitySegment:
                    // Booked activities don't have POIs to show on map
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
                    
                case .bookedActivitySegment:
                    // Booked activities don't have POIs
                    break
                }
            }
        }
        
        return segmentGroups
    }
    
    /// Get booked activities for the selected day
    public func getBookedActivitiesForSelectedDay() -> [TRPTimelineSegment] {
        var bookedActivities: [TRPTimelineSegment] = []
        
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                if case .bookedActivitySegment(let segment) = item {
                    bookedActivities.append(segment)
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
                    
                case .bookedActivitySegment:
                    break
                }
            }
        }
        return nil
    }
    
    /// Get booked activity by activity ID
    public func getBookedActivity(byId activityId: String) -> TRPTimelineSegment? {
        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                if case .bookedActivitySegment(let segment) = item,
                   let additionalData = segment.additionalData,
                   additionalData.activityId == activityId {
                    return segment
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
                    
                case .bookedActivitySegment:
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
}


