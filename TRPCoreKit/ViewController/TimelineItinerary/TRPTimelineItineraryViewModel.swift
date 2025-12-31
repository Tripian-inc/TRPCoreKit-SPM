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
    case manualPoi(TRPTimelineSegment, TRPPoi?) // Manual POI segment with POI data from plans.steps
    case activityStep(TRPTimelineStep) // For activity type steps
    case recommendations([TRPTimelineStep], TRPTimelineSegment?) // For POI type steps with their segment
    case emptyState // Empty itinerary day
}

private struct SegmentWithSteps {
    let segment: TRPTimelineSegment
    let steps: [TRPTimelineStep]
}

private enum TimelineItem {
    case bookedActivitySegment(TRPTimelineSegment)
    case reservedActivitySegment(TRPTimelineSegment)
    case manualPoiSegment(TRPTimelineSegment, TRPPoi?) // Manual POI segment with POI data
    case activityStep(TRPTimelineStep)
    case poiSteps([TRPTimelineStep], TRPCity?, TRPTimelineSegment?) // Steps with their plan's city and parent segment
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

    // Filtered favorite items (excludes items that are already booked or reserved)
    private var filteredFavoriteItems: [TRPSegmentFavoriteItem] = []

    // Track if initial data has been loaded (prevents showing empty state during loading)
    private var hasLoadedData: Bool = false

    // MARK: - Public Methods

    /// Get the trip hash from timeline
    public func getTripHash() -> String? {
        return timeline?.tripHash
    }

    // Track collapse state for each section (section index -> isExpanded)
    private var sectionCollapseStates: [Int: Bool] = [:]

    // Keep reference to use case to prevent deallocation during async operations
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    // Use case for step operations (edit, delete, etc.)
    private lazy var timelineModeUseCases: TRPTimelineModeUseCases = TRPTimelineModeUseCases()

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

    /// Find the matching plan for a segment using plan.id and segment.dayIds
    /// Returns the plan if found, nil otherwise
    private func findMatchingPlan(for segment: TRPTimelineSegment, in plans: [TRPTimelinePlan]) -> TRPTimelinePlan? {
        guard let dayIds = segment.dayIds, !dayIds.isEmpty else {
            return nil
        }

        // Match plan.id (String) with segment.dayIds (contains Int values)
        for plan in plans {
            if let planIdInt = Int(plan.id), dayIds.contains(planIdInt) {
                return plan
            }
        }

        return nil
    }

    private func processTimelineData() {
        // Always reset to empty state first
        segmentsWithSteps = []
        allSegmentsWithSteps = []
        allTimelineItems = []
        filteredTimelineItems = []
        filteredFavoriteItems = []
        startDate = nil

        guard let timeline = timeline else {
            return
        }

        // IMPORTANT: Process segments in the order they appear in tripProfile.segments
        // This preserves the API response order
        // Match segments with plans using plan.id and segment.dayIds

        var items: [TimelineItem] = []
        var processedSegmentIds = Set<String>()
        var processedPlanIds = Set<String>()
        var earliestDateString: String?

        // Process tripProfile.segments in order (API response order)
        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                let segmentId = getSegmentUniqueId(segment)

                // Skip duplicates
                guard !processedSegmentIds.contains(segmentId) else { continue }
                processedSegmentIds.insert(segmentId)

                // Update earliest date for filtering
                let segmentStartDateStr = segment.additionalData?.startDatetime ?? segment.startDate
                if let dateStr = segmentStartDateStr {
                    let segmentDateString = String(dateStr.prefix(10))
                    if earliestDateString == nil || segmentDateString < earliestDateString! {
                        earliestDateString = segmentDateString
                    }
                }

                // Determine segment type and create appropriate TimelineItem
                // IMPORTANT: Check segmentType FIRST to preserve API response order
                // Do NOT check additionalData first as it would misclassify segment types
                switch segment.segmentType {
                case .bookedActivity:
                    // Booked activity segment (already purchased)
                    if let additionalData = segment.additionalData {
                        segment.startDate = additionalData.startDatetime
                        segment.endDate = additionalData.endDatetime
                    }
                    items.append(.bookedActivitySegment(segment))

                case .reservedActivity:
                    // Reserved activity segment (not yet purchased)
                    if let additionalData = segment.additionalData {
                        segment.startDate = additionalData.startDatetime
                        segment.endDate = additionalData.endDatetime
                    }
                    items.append(.reservedActivitySegment(segment))

                case .manualPoi:
                    // Manual POI segment - get POI data from matching plan's steps
                    // Match using plan.id and segment.dayIds
                    if let plans = timeline.plans,
                       let matchingPlan = findMatchingPlan(for: segment, in: plans) {
                        processedPlanIds.insert(matchingPlan.id)

                        // Update earliest date from plan
                        let planStartDate = matchingPlan.startDate
                        if !planStartDate.isEmpty {
                            let planDateString = String(planStartDate.prefix(10))
                            if earliestDateString == nil || planDateString < earliestDateString! {
                                earliestDateString = planDateString
                            }
                        }

                        // Update segment dates from plan
                        if segment.startDate == nil || segment.startDate?.isEmpty == true {
                            segment.startDate = matchingPlan.startDate
                        }
                        if segment.endDate == nil || segment.endDate?.isEmpty == true {
                            segment.endDate = matchingPlan.endDate
                        }

                        // Get POI from first step
                        let poi = matchingPlan.steps.first?.poi
                        items.append(.manualPoiSegment(segment, poi))
                    }

                case .itinerary:
                    // Itinerary segment - get matching plan using plan.id and segment.dayIds
                    if let plans = timeline.plans,
                       let matchingPlan = findMatchingPlan(for: segment, in: plans) {
                        processedPlanIds.insert(matchingPlan.id)

                        // Update earliest date from plan
                        let planStartDate = matchingPlan.startDate
                        if !planStartDate.isEmpty {
                            let planDateString = String(planStartDate.prefix(10))
                            if earliestDateString == nil || planDateString < earliestDateString! {
                                earliestDateString = planDateString
                            }
                        }

                        if !matchingPlan.steps.isEmpty {
                            items.append(.poiSteps(matchingPlan.steps, matchingPlan.city, segment))
                        }
                    }
                }
            }
        }

        // NOTE: Do NOT process timeline.segments separately
        // tripProfile.segments is the single source of truth from the API
        // Processing both would cause duplicates

        // Process any remaining plans that weren't matched to segments
        if let plans = timeline.plans {
            for plan in plans {
                // Skip plans that were already processed via segment matching
                guard !processedPlanIds.contains(plan.id) else { continue }

                // Update earliest date
                let planStartDate = plan.startDate
                if !planStartDate.isEmpty {
                    let planDateString = String(planStartDate.prefix(10))
                    if earliestDateString == nil || planDateString < earliestDateString! {
                        earliestDateString = planDateString
                    }
                }

                if !plan.steps.isEmpty {
                    items.append(.poiSteps(plan.steps, plan.city, nil))
                }
            }
        }

        // Convert earliest date string to Date (at midnight, local timezone)
        if let dateString = earliestDateString {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            startDate = dateFormatter.date(from: dateString)
        } else {
            startDate = nil
        }

        // NOTE: Do NOT sort items - preserve API response order
        // API returns segments in the correct order, we only need to filter by day and group by city for headers

        // Each item becomes its own section
        allTimelineItems = items.map { [$0] }

        filterItemsByDay(selectedDayIndex)

        // Filter favorite items to exclude already booked/reserved activities
        filterFavoriteItems()

        // Mark data as loaded
        hasLoadedData = true
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

        case .manualPoiSegment(let segment, _):
            if let startDate = segment.startDate {
                // Try both formats: with and without seconds
                return Date.fromString(startDate, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(startDate, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()

        case .activityStep(let step):
            if let stepStart = step.startDateTimes {
                // Try both formats: with and without seconds
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()

        case .poiSteps(let steps, _, _):
            if let firstStep = steps.first, let stepStart = firstStep.startDateTimes {
                // Try both formats: with and without seconds
                return Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm") ??
                       Date.fromString(stepStart, format: "yyyy-MM-dd HH:mm:ss") ?? Date()
            }
            return Date()
        }
    }

    // Helper to get city name for timeline items
    private func getItemCityName(_ item: TimelineItem) -> String {
        switch item {
        case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment), .manualPoiSegment(let segment, _):
            return segment.city?.name ?? "Unknown"

        case .activityStep(let step):
            return step.poi?.locations.first?.name ?? "Unknown"

        case .poiSteps(_, let city, _):
            // Use the plan's city, not the POI's location
            return city?.name ?? "Unknown"
        }
    }

    // Groups items by city, with first segment's city appearing first
    // Within each city group, items remain sorted by start time
    private func groupItemsByCity(_ items: [TimelineItem]) -> [TimelineItem] {
        guard !items.isEmpty else { return items }

        // Get the first item's city (this will be the primary city group)
        let firstCityName = getItemCityName(items[0])

        // Group items by city
        var cityGroups: [String: [TimelineItem]] = [:]
        for item in items {
            let cityName = getItemCityName(item)
            if cityGroups[cityName] == nil {
                cityGroups[cityName] = []
            }
            cityGroups[cityName]?.append(item)
        }

        // Build result: first city group first, then others
        var result: [TimelineItem] = []

        // Add first city group
        if let firstCityItems = cityGroups[firstCityName] {
            result.append(contentsOf: firstCityItems)
        }

        // Add other city groups (sorted by city name for consistency)
        let otherCities = cityGroups.keys.filter { $0 != firstCityName }.sorted()
        for cityName in otherCities {
            if let cityItems = cityGroups[cityName] {
                result.append(contentsOf: cityItems)
            }
        }

        return result
    }

    /// Filters favorite items to exclude those that are already booked or reserved
    private func filterFavoriteItems() {
        guard let favouriteItems = timeline?.favouriteItems else {
            filteredFavoriteItems = []
            return
        }

        // Collect all activityIds from booked and reserved segments
        var bookedOrReservedActivityIds = Set<String>()

        // Check timeline.segments
        if let segments = timeline?.segments {
            for segment in segments {
                if segment.segmentType == .bookedActivity || segment.segmentType == .reservedActivity {
                    if let activityId = segment.additionalData?.activityId {
                        bookedOrReservedActivityIds.insert(activityId)
                    }
                }
            }
        }

        // Check timeline.tripProfile.segments
        if let profileSegments = timeline?.tripProfile?.segments {
            for segment in profileSegments {
                if segment.segmentType == .bookedActivity || segment.segmentType == .reservedActivity {
                    if let activityId = segment.additionalData?.activityId {
                        bookedOrReservedActivityIds.insert(activityId)
                    }
                }
            }
        }

        // Filter out favorite items whose activityId exists in booked/reserved segments
        filteredFavoriteItems = favouriteItems.filter { item in
            guard let activityId = item.activityId else { return true }
            return !bookedOrReservedActivityIds.contains(activityId)
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

        // Use string-based date comparison to avoid timezone issues
        // Format: "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let selectedDateString = dateFormatter.string(from: selectedDate)

        // Filter items that fall on the selected day
        var filtered: [[TimelineItem]] = []

        for itemGroup in allTimelineItems {
            var filteredGroup: [TimelineItem] = []

            for item in itemGroup {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment), .manualPoiSegment(let segment, _):
                    // Check if activity (booked, reserved, or manual POI) falls on selected day
                    // Use string comparison: extract "yyyy-MM-dd" from segment date
                    // Priority: additionalData.startDatetime > segment.startDate
                    var segmentStartDateStr = segment.additionalData?.startDatetime
                    if segmentStartDateStr == nil {
                        segmentStartDateStr = segment.startDate
                    }

                    if let dateStr = segmentStartDateStr {
                        // Extract date portion (first 10 characters: "yyyy-MM-dd")
                        let segmentDateString = String(dateStr.prefix(10))

                        if segmentDateString == selectedDateString {
                            filteredGroup.append(item)
                        }
                    }

                case .activityStep(let step):
                    // Check if activity step falls on selected day
                    if let stepStartDate = step.startDateTimes {
                        let stepDateString = String(stepStartDate.prefix(10))
                        if stepDateString == selectedDateString {
                            filteredGroup.append(item)
                        }
                    }

                case .poiSteps(let steps, let city, let segment):
                    // Filter steps that match the selected day
                    let filteredSteps = steps.filter { step in
                        guard let stepStartDate = step.startDateTimes else {
                            return false
                        }
                        let stepDateString = String(stepStartDate.prefix(10))
                        return stepDateString == selectedDateString
                    }

                    if !filteredSteps.isEmpty {
                        filteredGroup.append(.poiSteps(filteredSteps, city, segment))
                    }
                }
            }

            if !filteredGroup.isEmpty {
                filtered.append(filteredGroup)
            }
        }

        // NOTE: Do NOT sort - preserve API response order
        filteredTimelineItems = filtered
    }

    /// Generates a unique identifier for a segment to avoid duplicates
    /// Uses activityId or bookingId if available, otherwise creates from startDate + title
    private func getSegmentUniqueId(_ segment: TRPTimelineSegment) -> String {
        // Priority 1: Use bookingId from additionalData (unique per booking)
        if let bookingId = segment.additionalData?.bookingId {
            return "booking_\(bookingId)"
        }

        // Priority 2: Use activityId + startDate for reserved/booked activities
        // Same activity can be at different times, so include startDate
        if let activityId = segment.additionalData?.activityId, let startDate = segment.startDate {
            return "activity_\(activityId)_\(startDate)"
        }

        // Priority 3: For itinerary segments, use startDate + title
        if let startDate = segment.startDate, let title = segment.title {
            return "segment_\(startDate)_\(title)"
        }

        // Priority 4: Use startDate + segmentType
        if let startDate = segment.startDate {
            return "segment_\(startDate)_\(segment.segmentType.rawValue)"
        }

        // Last resort: Use object pointer as string
        return "segment_\(ObjectIdentifier(segment))"
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
        filterItemsByDay(index)
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

        return cities
    }
    
    // MARK: - TableView Data Methods
    public func numberOfSections() -> Int {
        // Don't show anything (including empty state) until data has loaded
        guard hasLoadedData else { return 0 }

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

        case .manualPoiSegment(let segment, let poi):
            return .manualPoi(segment, poi)

        case .activityStep(let step):
            return .activityStep(step)

        case .poiSteps(let steps, _, let segment):
            return .recommendations(steps, segment)
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
        case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment), .manualPoiSegment(let segment, _):
            let cityName = segment.city?.name ?? "Unknown"
            return cityName

        case .activityStep(let step):
            // Activity steps might not have city info directly, try to get from POI
            return step.poi?.locations.first?.name ?? "Unknown"

        case .poiSteps(_, let city, _):
            // Use the plan's city, not the POI's location
            return city?.name ?? "Unknown"
        }
    }

    /// Check if there are multiple different destinations in the timeline
    private func hasMultipleDestinations() -> Bool {
        var cityIds = Set<Int>()
        var cityNames = Set<String>()

        for sectionItems in filteredTimelineItems {
            for item in sectionItems {
                switch item {
                case .bookedActivitySegment(let segment), .reservedActivitySegment(let segment), .manualPoiSegment(let segment, _):
                    if let city = segment.city {
                        cityIds.insert(city.id)
                        cityNames.insert(city.name)
                    }

                case .activityStep(let step):
                    if let location = step.poi?.locations.first {
                        cityIds.insert(location.id)
                        cityNames.insert(location.name)
                    }

                case .poiSteps(_, let city, _):
                    // Use the plan's city, not POI locations
                    if let city = city {
                        cityIds.insert(city.id)
                        cityNames.insert(city.name)
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

                case .poiSteps(let steps, _, _):
                    for step in steps {
                        if let poi = step.poi {
                            pois.append(poi)
                        }
                    }

                case .manualPoiSegment(_, let poi):
                    // Manual POI segment has POI to show on map
                    if let poi = poi {
                        pois.append(poi)
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

                case .poiSteps(let steps, _, _):
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

                case .manualPoiSegment(_, let poi):
                    // Manual POI is individual
                    if let poi = poi {
                        segmentGroups.append([poi])
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

    /// Get all booked and reserved activities (for all days, used in POI selection)
    public func getAllBookedActivities() -> [TRPTimelineSegment] {
        var bookedActivities: [TRPTimelineSegment] = []

        for sectionItems in allTimelineItems {
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

    /// Get count of reserved activities (saved plans that haven't been purchased)
    public func getReservedActivitiesCount() -> Int {
        var count = 0
        
        // Check all timeline items (not just filtered for selected day)
        for sectionItems in allTimelineItems {
            for item in sectionItems {
                if case .reservedActivitySegment = item {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    /// Get count of favorite items from timeline (filtered, excludes booked/reserved)
    public func getFavoriteItemsCount() -> Int {
        return filteredFavoriteItems.count
    }

    /// Check if timeline has favorite items (filtered, excludes booked/reserved)
    public func hasFavoriteItems() -> Bool {
        return !filteredFavoriteItems.isEmpty
    }

    /// Get favourite items from timeline (filtered, excludes booked/reserved)
    public func getFavoriteItems() -> [TRPSegmentFavoriteItem] {
        return filteredFavoriteItems
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

                case .poiSteps(let steps, _, _):
                    for step in steps {
                        if let poi = step.poi, poi.id == id {
                            return poi
                        }
                    }

                case .manualPoiSegment(_, let poi):
                    if let poi = poi, poi.id == id {
                        return poi
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

                case .poiSteps(let steps, _, _):
                    for step in steps {
                        if let poi = step.poi, poi.id == id {
                            return step
                        }
                    }

                case .manualPoiSegment, .bookedActivitySegment, .reservedActivitySegment:
                    // Manual POI, booked and reserved activities don't have steps
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
        TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)

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
                    // Merge itinerary model data (only favouriteItems - segments handled via API)
                    timeline = self.mergeItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                    // NOTE: Do NOT sync segments - use API response as-is
                    // tripProfile.segments is the single source of truth
                    // Populate city information in segments BEFORE processing
                    self.populateCitiesInSegments(&timeline)

                    // Update timeline and process data
                    self.timeline = timeline
                    self.processTimelineData()

                    // Notify delegate - UI is ready
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                    // Check for missing booked activities and add via API if needed
                    // This runs in background after UI is shown
                    self.addMissingBookedActivities(from: itineraryModel)

                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Merges itinerary model data into timeline
    /// IMPORTANT: Does NOT modify segments - only adds favouriteItems
    /// Missing booked activities should be added via addMissingBookedActivities() which calls API
    private func mergeItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) -> TRPTimeline {
        var updatedTimeline = timeline

        // Add favourite items only - segments are handled separately via API
        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        return updatedTimeline
    }

    // MARK: - Add Missing Booked Activities

    /// Adds missing booked activities from itineraryModel to timeline via API
    /// Compares itineraryModel.tripItems with timeline segments and adds only missing ones
    /// - Parameter itineraryModel: Itinerary model containing tripItems to check
    public func addMissingBookedActivities(from itineraryModel: TRPItineraryWithActivities) {
        guard let timeline = timeline,
              let tripItems = itineraryModel.tripItems,
              !tripItems.isEmpty else {
            return
        }

        let tripHash = timeline.tripHash

        // Collect existing activity IDs from timeline (both segments and tripProfile.segments)
        var existingActivityIds = Set<String>()

        if let segments = timeline.segments {
            for segment in segments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId)
                }
            }
        }

        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                if let activityId = segment.additionalData?.activityId {
                    existingActivityIds.insert(activityId)
                }
            }
        }

        // Find tripItems that are NOT in timeline
        let missingTripItems = tripItems.filter { tripItem in
            guard let activityId = tripItem.activityId else { return false }
            return !existingActivityIds.contains(activityId)
        }

        // If no missing items, nothing to do
        guard !missingTripItems.isEmpty else {
            return
        }

        Log.i("TRPTimelineItineraryViewModel: Found \(missingTripItems.count) missing booked activities to add via API")

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Add each missing tripItem via API (sequentially)
        addMissingTripItemsSequentially(tripItems: missingTripItems, tripHash: tripHash, index: 0)
    }

    /// Recursively adds missing tripItems one by one via API
    private func addMissingTripItemsSequentially(tripItems: [TRPSegmentActivityItem], tripHash: String, index: Int) {
        // Base case: all items added
        guard index < tripItems.count else {
            Log.i("TRPTimelineItineraryViewModel: All missing booked activities added successfully")
            // Wait for generation and refresh timeline
            waitForSegmentGeneration(tripHash: tripHash)
            return
        }

        let tripItem = tripItems[index]

        // Create segment profile from tripItem
        let profile = createSegmentProfileFromTripItem(tripItem, tripHash: tripHash)

        // Call API to add segment
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let success):
                if success {
                    Log.i("TRPTimelineItineraryViewModel: Added booked activity \(tripItem.activityId ?? "unknown") via API")
                    // Continue with next item
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                } else {
                    Log.e("TRPTimelineItineraryViewModel: Failed to add booked activity \(tripItem.activityId ?? "unknown")")
                    // Continue anyway to try remaining items
                    self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
                }

            case .failure(let error):
                Log.e("TRPTimelineItineraryViewModel: Error adding booked activity: \(error.localizedDescription)")
                // Continue anyway to try remaining items
                self.addMissingTripItemsSequentially(tripItems: tripItems, tripHash: tripHash, index: index + 1)
            }
        }
    }

    /// Creates a TRPCreateEditTimelineSegmentProfile from a TRPSegmentActivityItem
    private func createSegmentProfileFromTripItem(_ tripItem: TRPSegmentActivityItem, tripHash: String) -> TRPCreateEditTimelineSegmentProfile {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        // Set segment type
        profile.segmentType = .bookedActivity

        // Set basic properties
        profile.title = tripItem.title
        profile.description = tripItem.description
        profile.available = false // Booking products are fixed activities
        profile.distinctPlan = true

        // Set dates
        profile.startDate = tripItem.startDatetime
        profile.endDate = tripItem.endDatetime

        // Set coordinate
        profile.coordinate = tripItem.coordinate

        // Set traveler counts
        profile.adults = tripItem.adultCount
        profile.children = tripItem.childCount
        profile.pets = 0

        // Set additional data (this is CRITICAL for booked activities)
        profile.additionalData = tripItem

        // Don't generate recommendations for booked activities
        profile.doNotGenerate = 1

        return profile
    }

    /// Populates city information in segments using index-based mapping with plans
    /// CRITICAL: ONLY tripProfile.segments[i] and plans[i] represent the SAME segment (same order)
    /// timeline.segments has DIFFERENT order/content, so we DON'T use index mapping for it
    private func populateCitiesInSegments(_ timeline: inout TRPTimeline, destinationItems: [TRPSegmentDestinationItem] = []) {
        guard let plans = timeline.plans, !plans.isEmpty else {
            return
        }

        // ONLY populate city info for tripProfile.segments using index-based mapping
        // timeline.segments has different order/content than plans, so we skip it
        if let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for (index, segment) in profileSegments.enumerated() {
                // Skip if segment already has complete city info
                if let existingCity = segment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                // Get corresponding plan city (same index)
                if index < plans.count, let planCity = plans[index].city, planCity.id > 0 {
                    segment.city = planCity
                }
            }
        }

        // For timeline.segments: Copy city from corresponding tripProfile.segments by matching unique ID
        if let segments = timeline.segments, !segments.isEmpty,
           let profileSegments = timeline.tripProfile?.segments, !profileSegments.isEmpty {
            for timelineSegment in segments {
                // Skip if already has city
                if let existingCity = timelineSegment.city, existingCity.id > 0, !existingCity.name.isEmpty {
                    continue
                }

                // Find matching segment in tripProfile.segments by unique ID
                let timelineSegmentId = getSegmentUniqueId(timelineSegment)

                for profileSegment in profileSegments {
                    let profileSegmentId = getSegmentUniqueId(profileSegment)

                    if timelineSegmentId == profileSegmentId {
                        // Found matching segment, copy city
                        if let profileCity = profileSegment.city, profileCity.id > 0 {
                            timelineSegment.city = profileCity
                        }
                        break
                    }
                }
            }
        }
    }

    // MARK: - Smart Recommendations Segment Creation

    /// Checks if a given location is the city center
    /// Returns true if the coordinates match the city's center coordinates (with small tolerance)
    private func isCityCenterLocation(_ location: TRPLocation, city: TRPCity) -> Bool {
        let cityCenter = city.coordinate
        let tolerance = 0.0001 // Small tolerance for floating point comparison

        let latMatch = abs(location.lat - cityCenter.lat) < tolerance
        let lonMatch = abs(location.lon - cityCenter.lon) < tolerance

        return latMatch && lonMatch
    }

    /// Generates a unique segment title based on existing segments
    /// Returns "Recommendations" or "Recommendations 2", "Recommendations 3", etc.
    /// Only applies to segments with segmentType = .itinerary
    private func generateSegmentTitle(for city: TRPCity, on startDate: String) -> String {
        guard let timeline = timeline else {
            return "Recommendations"
        }

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

        // Extract date portion (ignore time) for comparison
        let targetDate = String(startDate.prefix(10)) // "yyyy-MM-dd"

        // Find all segments with "Recommendations" title on same date and city
        var existingNumbers: [Int] = []

        for segment in allSegments {
            // Only check itinerary type segments
            guard segment.segmentType == .itinerary else { continue }

            // Check if same city
            guard segment.city?.id == city.id else { continue }

            // Check if same date (compare only date portion)
            guard let segmentStartDate = segment.startDate,
                  String(segmentStartDate.prefix(10)) == targetDate else { continue }

            // Check if title matches "Recommendations" pattern
            guard let title = segment.title else { continue }

            if title == "Recommendations" {
                existingNumbers.append(1) // "Recommendations" = 1
            } else if title.hasPrefix("Recommendations ") {
                // Extract number from "Recommendations 2", "Recommendations 3", etc.
                let numberPart = title.replacingOccurrences(of: "Recommendations ", with: "")
                if let number = Int(numberPart) {
                    existingNumbers.append(number)
                }
            }
        }

        // If no existing segments, use "Recommendations"
        if existingNumbers.isEmpty {
            return "Recommendations"
        }

        // Find highest number and increment
        let maxNumber = existingNumbers.max() ?? 0
        let nextNumber = maxNumber + 1

        return "Recommendations \(nextNumber)"
    }

    /// Creates a smart recommendation segment from AddPlanData
    public func createSmartRecommendationSegment(from data: AddPlanData) {
        // 1. Validate required data
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

        // 2. Show loading
        delegate?.viewModel(showPreloader: true)

        // 3. Build segment profile
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)

        // Basic properties
        profile.segmentType = .itinerary
        profile.distinctPlan = true
        profile.smartRecommendation = true
        profile.city = city
        profile.adults = data.travelers
        profile.children = 0
        profile.pets = 0

        // Check if starting point is city center
        let isCityCenter = isCityCenterLocation(startingPointLocation, city: city)

        // Only set coordinate and accommodation if NOT city center
        if !isCityCenter {
            profile.coordinate = startingPointLocation

            // Accommodation from starting point
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
        // If city center: only cityId is sent (via profile.city), no coordinate or accommodation

        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        profile.startDate = dateFormatter.string(from: startTime)
        profile.endDate = dateFormatter.string(from: endTime)

        // Generate unique title for segment
        profile.title = generateSegmentTitle(for: city, on: profile.startDate ?? "")

        // Categories → activityFreeText (comma-separated)
        if !data.selectedCategories.isEmpty {
            profile.activityFreeText = data.selectedCategories.joined(separator: ",")
        }

        // FavouriteItems → activityIds
        if let favouriteItems = timeline.favouriteItems, !favouriteItems.isEmpty {
            profile.activityIds = favouriteItems.compactMap { item in
                guard let activityId = item.activityId else { return nil }
                // Validate format: must start with "C_" and contain underscore
                if activityId.hasPrefix("C_") && activityId.contains("_") {
                    return activityId
                }
                return nil
            }
        }

        // Booked Activities → excludedActivityIds
        if let segments = timeline.tripProfile?.segments {
            profile.excludedActivityIds = segments.compactMap { segment in
                // Only collect from booked_activity segments
                guard segment.segmentType == .bookedActivity else { return nil }
                guard let activityId = segment.additionalData?.activityId else { return nil }
                // Validate format: must start with "C_" and contain underscore
                if activityId.hasPrefix("C_") && activityId.contains("_") {
                    return activityId
                }
                return nil
            }
        }

        // 4. Create segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Segment created successfully
                        // Keep loading visible while waiting for generation
                        // Wait for segment generation to complete before refreshing
                        self.waitForSegmentGeneration(tripHash: tripHash)
                    } else {
                        // API returned success=false
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.viewModel(error: NSError(
                            domain: "TRPTimelineItinerary",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create smart recommendation"]
                        ))
                    }

                case .failure(let error):
                    // API error
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Waits for segment generation to complete (polls timeline until generatedStatus != 0)
    public func waitForSegmentGeneration(tripHash: String) {
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

            DispatchQueue.main.async {
                // Refresh timeline now that generation is complete
                self.refreshTimeline()

                // Clear use case reference after completion
                self.checkAllPlanUseCase = nil
            }
        }

        // Start checking generation status
        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                // Polling started successfully
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

    /// Refreshes the timeline after segment generation completes
    public func refreshTimeline() {
        guard let timeline = timeline else { return }

        let tripHash = timeline.tripHash

        // Fetch updated timeline
        let repository = TRPTimelineRepository()
        repository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Hide loading after timeline refresh completes (or fails)
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(var updatedTimeline):
                    // NOTE: Do NOT sync segments - use the API response as-is
                    // tripProfile.segments is the single source of truth
                    // Populate city information in segments BEFORE processing
                    self.populateCitiesInSegments(&updatedTimeline)

                    // Update timeline data with fresh response (replaces old data completely)
                    self.timeline = updatedTimeline
                    self.processTimelineData()

                    // Notify delegate
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                case .failure(let error):
                    // Don't show error - segment was created and generated, just couldn't refresh
                    // User can manually refresh or restart
                    break
                }
            }
        }
    }

    // MARK: - Remove Segment

    /// Removes a segment from the timeline
    /// - Parameter segment: The segment to remove
    public func removeSegment(_ segment: TRPTimelineSegment) {
        guard let timeline = timeline,
              let segments = timeline.tripProfile?.segments else { return }

        // Find segment index
        guard let segmentIndex = segments.firstIndex(where: { $0 === segment }) else {
            delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Segment not found"]))
            return
        }

        let tripHash = timeline.tripHash

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Delete segment via repository
        let repository = TRPTimelineRepository()
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Refresh timeline to get updated data
                        self.refreshTimeline()
                    } else {
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.viewModel(error: NSError(domain: "Timeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove segment"]))
                    }
                case .failure(let error):
                    self.delegate?.viewModel(showPreloader: false)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    // MARK: - Step Time Update

    /// Updates a step's start and end times
    /// - Parameters:
    ///   - step: The step to update
    ///   - startTime: New start time in "yyyy-MM-dd HH:mm" format
    ///   - endTime: New end time in "yyyy-MM-dd HH:mm" format
    ///   - completion: Completion handler with success/failure result
    public func updateStepTime(step: TRPTimelineStep, startTime: String, endTime: String, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Use the UseCase for step editing
        timelineModeUseCases.executeEditStepHour(id: step.id, startTime: startTime, endTime: endTime) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(let updatedStep):
                    // Update the step in timeline locally
                    self.updateStepInTimeline(updatedStep)

                    // Notify delegate to reload UI
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)

                    completion(.success(updatedStep))

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Updates a step within the timeline data structure
    private func updateStepInTimeline(_ updatedStep: TRPTimelineStep) {
        guard var timeline = timeline, var plans = timeline.plans else { return }

        // Find and update the step in plans
        for (planIndex, plan) in plans.enumerated() {
            if let stepIndex = plan.steps.firstIndex(where: { $0.id == updatedStep.id }) {
                plans[planIndex].steps[stepIndex] = updatedStep
                break
            }
        }

        // Update timeline with modified plans
        timeline.plans = plans
        self.timeline = timeline

        // Reprocess timeline data to update UI
        processTimelineData()
    }
}


