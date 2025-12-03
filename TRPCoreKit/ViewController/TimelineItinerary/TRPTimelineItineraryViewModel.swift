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
    case recommendations([TRPTimelineStep])
}

private struct SegmentWithSteps {
    let segment: TRPTimelineSegment
    let steps: [TRPTimelineStep]
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
            startDate = nil
            return
        }
        
        // Store start date for filtering
        startDate = timeline.plans?.first?.getStartDate()
        
        // Process all segments (both booked activities and itineraries)
        var allSegments: [SegmentWithSteps] = []
        
        // 1. Process booked activity segments (those with additionalData)
        if let segments = timeline.segments {
            for segment in segments {
                if let additionalData = segment.additionalData {
                    // Copy dates from additionalData to segment for sorting/filtering
                    segment.startDate = additionalData.startDatetime
                    segment.endDate = additionalData.endDatetime
                    segment.segmentType = .bookedActivity
                    
                    // Booked activities don't have steps, create empty array
                    let segmentWithSteps = SegmentWithSteps(segment: segment, steps: [])
                    allSegments.append(segmentWithSteps)
                }
            }
        }
        
        // 2. Process plan segments (itineraries with recommendations)
        if let plans = timeline.plans {
            for plan in plans {
                // Create an itinerary segment for the plan with all its steps
                if !plan.steps.isEmpty {
                    let segment = TRPTimelineSegment()
                    segment.segmentType = .itinerary
                    segment.city = plan.city
                    segment.startDate = plan.startDate
                    segment.endDate = plan.endDate
                    
                    let segmentWithSteps = SegmentWithSteps(segment: segment, steps: plan.steps)
                    allSegments.append(segmentWithSteps)
                }
            }
        }
        
        // 3. Sort all segments by start time
        allSegments.sort { segment1, segment2 in
            // For booked activities, prioritize additionalData startDatetime
            let date1: Date
            if segment1.segment.segmentType == .bookedActivity, 
               let startDatetime = segment1.segment.additionalData?.startDatetime {
                date1 = Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else if let firstStep = segment1.steps.first, let stepStart = firstStep.startDateTimes {
                date1 = Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else if let segmentStart = segment1.segment.startDate {
                date1 = Date.fromString(segmentStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else {
                date1 = Date()
            }
            
            let date2: Date
            if segment2.segment.segmentType == .bookedActivity,
               let startDatetime = segment2.segment.additionalData?.startDatetime {
                date2 = Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else if let firstStep = segment2.steps.first, let stepStart = firstStep.startDateTimes {
                date2 = Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else if let segmentStart = segment2.segment.startDate {
                date2 = Date.fromString(segmentStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            } else {
                date2 = Date()
            }
            
            return date1 < date2
        }
        
        // 4. Each segment becomes its own section
        allSegmentsWithSteps = allSegments.map { [$0] }
        filterSegmentsByDay(selectedDayIndex)
    }
    
    private func filterSegmentsByDay(_ dayIndex: Int) {
        guard let startDate = startDate else {
            segmentsWithSteps = allSegmentsWithSteps
            return
        }
        
        // Calculate the selected date
        guard let selectedDate = startDate.addDay(dayIndex) else {
            segmentsWithSteps = allSegmentsWithSteps
            return
        }
        
        // Filter segments that fall on the selected day
        var filteredSegments: [[SegmentWithSteps]] = []
        let selectedDayStart = selectedDate.getDateWithZeroHour()
        let selectedDayEnd = selectedDate.addDay(1)?.getDateWithZeroHour() ?? selectedDate
        
        for (_, segmentGroup) in allSegmentsWithSteps.enumerated() {
            var filteredGroup: [SegmentWithSteps] = []
            
            for segmentWithSteps in segmentGroup {
                let segment = segmentWithSteps.segment
                
                // Check if this is a booked activity (has additionalData)
                if segment.segmentType == .bookedActivity {
                    // For booked activities, check the segment's start date (already copied from additionalData)
                    if let segmentStartDate = segment.startDate,
                       let activityDate = Date.fromString(segmentStartDate, format: "yyyy-MM-dd HH:mm:ss") {
                        
                        if activityDate >= selectedDayStart && activityDate < selectedDayEnd {
                            filteredGroup.append(segmentWithSteps)
                        }
                    }
                } else {
                    // For itineraries, filter steps that match the selected day
                    let filteredSteps = segmentWithSteps.steps.filter { step in
                        guard let stepStartDate = step.startDateTimes,
                              let stepDate = Date.fromString(stepStartDate, format: "yyyy-MM-dd HH:mm:ss") else {
                            return true
                        }
                        return stepDate >= selectedDayStart && stepDate < selectedDayEnd
                    }
                    
                    if !filteredSteps.isEmpty {
                        let newSegmentWithSteps = SegmentWithSteps(
                            segment: segmentWithSteps.segment,
                            steps: filteredSteps
                        )
                        filteredGroup.append(newSegmentWithSteps)
                    }
                }
            }
            
            if !filteredGroup.isEmpty {
                filteredSegments.append(filteredGroup)
            }
        }
        
        // Sort each filtered group by start time
        var sortedFilteredSegments: [[SegmentWithSteps]] = []
        for (_, var group) in filteredSegments.enumerated() {
            group.sort { seg1, seg2 in
                let date1 = getSegmentStartDate(seg1)
                let date2 = getSegmentStartDate(seg2)
                return date1 < date2
            }
            sortedFilteredSegments.append(group)
        }
        
        segmentsWithSteps = sortedFilteredSegments.isEmpty ? allSegmentsWithSteps : sortedFilteredSegments
    }
    
    // Helper to get segment start date for sorting
    private func getSegmentStartDate(_ segmentWithSteps: SegmentWithSteps) -> Date {
        let segment = segmentWithSteps.segment
        
        // For booked activities, use additionalData startDatetime
        if segment.segmentType == .bookedActivity, let startDatetime = segment.additionalData?.startDatetime {
            return Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
        }
        
        // For itineraries, use first step's start time or segment's start date
        if let firstStep = segmentWithSteps.steps.first, let stepStart = firstStep.startDateTimes {
            return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
        }
        
        // Fallback to segment start date
        if let segmentStart = segment.startDate {
            return Date.fromString(segmentStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
        }
        
        return Date()
    }
    
    // MARK: - Public Methods
    public func updateTimeline(_ timeline: TRPTimeline) {
        self.timeline = timeline
        processTimelineData()
    }
    
    public func selectDay(at index: Int) {
        selectedDayIndex = index
        filterSegmentsByDay(index)
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
    
    // MARK: - TableView Data Methods
    public func numberOfSections() -> Int {
        return segmentsWithSteps.count
    }
    
    public func numberOfRows(in section: Int) -> Int {
        guard section < segmentsWithSteps.count else { return 0 }
        
        let sectionSegments = segmentsWithSteps[section]
        
        // Each segment (bookedActivity or itinerary) is one row
        // No add buttons between sections
        return sectionSegments.count
    }
    
    public func cellType(at indexPath: IndexPath) -> TRPTimelineCellType? {
        guard indexPath.section < segmentsWithSteps.count else {
            return nil
        }
        
        let sectionSegments = segmentsWithSteps[indexPath.section]
        
        // Each row corresponds to one segment
        guard indexPath.row < sectionSegments.count else {
            return nil
        }
        
        let segmentWithSteps = sectionSegments[indexPath.row]
        
        if segmentWithSteps.segment.segmentType == .bookedActivity {
            return .bookedActivity(segmentWithSteps.segment)
        } else {
            // itinerary type - return all steps as recommendations
            return .recommendations(segmentWithSteps.steps)
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
        guard section < segmentsWithSteps.count,
              let firstSegment = segmentsWithSteps[section].first,
              let city = firstSegment.segment.city else {
            return "Unknown"
        }
        return city.name
    }
    
    /// Check if there are multiple different destinations in the timeline
    private func hasMultipleDestinations() -> Bool {
        var cityIds = Set<Int>()
        var cityNames = Set<String>()
        
        for sectionSegments in segmentsWithSteps {
            for segmentWithSteps in sectionSegments {
                if let city = segmentWithSteps.segment.city {
                    cityIds.insert(city.id)
                    cityNames.insert(city.name)
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
        
        for sectionSegments in segmentsWithSteps {
            for segmentWithSteps in sectionSegments {
                for step in segmentWithSteps.steps {
                    if let poi = step.poi {
                        pois.append(poi)
                    }
                }
            }
        }
        
        return pois
    }
    
    /// Get POIs grouped by segments for the selected day
    /// Each inner array represents a separate segment that should have its own route
    public func getSegmentsWithPoisForSelectedDay() -> [[TRPPoi]] {
        var segmentGroups: [[TRPPoi]] = []
        
        for sectionSegments in segmentsWithSteps {
            for segmentWithSteps in sectionSegments {
                var poisInSegment: [TRPPoi] = []
                
                for step in segmentWithSteps.steps {
                    if let poi = step.poi {
                        poisInSegment.append(poi)
                    }
                }
                
                if !poisInSegment.isEmpty {
                    segmentGroups.append(poisInSegment)
                }
            }
        }
        
        return segmentGroups
    }
    
    /// Get POI by ID
    public func getPoi(byId id: String) -> TRPPoi? {
        for sectionSegments in segmentsWithSteps {
            for segmentWithSteps in sectionSegments {
                for step in segmentWithSteps.steps {
                    if let poi = step.poi, poi.id == id {
                        return poi
                    }
                }
            }
        }
        return nil
    }
    
    /// Get step for a specific POI ID
    public func getStep(forPoiId id: String) -> TRPTimelineStep? {
        for sectionSegments in segmentsWithSteps {
            for segmentWithSteps in sectionSegments {
                for step in segmentWithSteps.steps {
                    if let poi = step.poi, poi.id == id {
                        return step
                    }
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


