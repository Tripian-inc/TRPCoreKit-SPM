//
//  TRPTimelineItineraryViewModel+DataProcessing.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Data processing methods extracted from main ViewModel
//

import Foundation
import TRPFoundationKit

// MARK: - Data Processing

extension TRPTimelineItineraryViewModel {

    // MARK: - Plan Matching

    /// Find the matching plan for a segment using plan.id and segment.dayIds
    /// Returns the plan if found, nil otherwise
    internal func findMatchingPlan(for segment: TRPTimelineSegment, in plans: [TRPTimelinePlan]) -> TRPTimelinePlan? {
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

    // MARK: - Merge Timeline Data

    /// Merges tripProfile.segments + plans into unified TRPMergedTimelineItem array.
    /// tripProfile.segments is the SINGLE SOURCE OF TRUTH for all segment types.
    /// - Returns: Array of TRPMergedTimelineItem preserving API response order
    internal func mergeTimelineData() -> [TRPMergedTimelineItem] {
        guard let timeline = timeline else { return [] }

        var mergedItems: [TRPMergedTimelineItem] = []

        // Process tripProfile.segments in API response order (SINGLE SOURCE OF TRUTH)
        // Each segment has a segmentType that determines which cell to display:
        // - bookedActivity → TRPTimelineBookedActivityCell
        // - reservedActivity → TRPTimelineBookedActivityCell (with isReserved=true)
        // - manualPoi → TRPTimelineManualPoiCell
        // - itinerary → TRPTimelineRecommendationsCell
        if let profileSegments = timeline.tripProfile?.segments {
            for (index, segment) in profileSegments.enumerated() {
                // Skip empty placeholder segments (title = "Empty" and available = false)
                if isEmptyPlaceholderSegment(segment) {
                    continue
                }
                let plan: TRPTimelinePlan?

                switch segment.segmentType {
                case .bookedActivity, .reservedActivity:
                    // Booked/reserved activities don't have plans
                    // Update segment dates from additionalData if available
                    if let additionalData = segment.additionalData {
                        segment.startDate = additionalData.startDatetime
                        segment.endDate = additionalData.endDatetime
                    }
                    plan = nil

                case .manualPoi, .itinerary:
                    // Find matching plan using plan.id and segment.dayIds
                    if let plans = timeline.plans,
                       let matchingPlan = findMatchingPlan(for: segment, in: plans) {
                        // Update segment dates from plan if not set
                        if segment.startDate == nil || segment.startDate?.isEmpty == true {
                            segment.startDate = matchingPlan.startDate
                        }
                        if segment.endDate == nil || segment.endDate?.isEmpty == true {
                            segment.endDate = matchingPlan.endDate
                        }
                        plan = matchingPlan
                    } else {
                        plan = nil
                    }
                }

                let mergedItem = TRPMergedTimelineItem(
                    segment: segment,
                    plan: plan,
                    originalSegmentIndex: index
                )
                mergedItems.append(mergedItem)
            }
        }

        return mergedItems
    }

    /// Checks if a segment is an empty placeholder segment
    /// Empty placeholder segments are created to ensure timeline covers the full trip date range
    /// They should not be displayed in the UI
    /// - Parameter segment: The segment to check
    /// - Returns: true if the segment is an empty placeholder (title = "Empty" and available = false)
    internal func isEmptyPlaceholderSegment(_ segment: TRPTimelineSegment) -> Bool {
        return segment.title == "Empty" && segment.available == false
    }

    // MARK: - Display Items

    /// Updates displayItems for current day using new architecture
    internal func updateDisplayItems() {
        guard let mergedTimeline = mergedTimeline else {
            displayItems = []
            unifiedOrderMap = [:]
            return
        }

        // Get the selected date from all trip dates (continuous range)
        guard selectedDayIndex >= 0, selectedDayIndex < allTripDates.count else {
            displayItems = []
            unifiedOrderMap = [:]
            return
        }

        let selectedDate = allTripDates[selectedDayIndex]

        // Get items for the selected date (flat list, not grouped yet)
        let dayItems = mergedTimeline.items(for: selectedDate)

        // Detect time conflicts BEFORE grouping by city
        // This ensures all items on the same day are checked against each other
        detectTimeConflicts(items: dayItems)

        // Get items grouped by city for section display
        // If no items exist for this date, displayItems will be empty (shows empty state)
        displayItems = mergedTimeline.itemsGroupedByCity(for: selectedDate)

        // Calculate unified orders for the current day
        calculateUnifiedOrders()
    }

    // MARK: - Time Conflict Detection

    /// Helper struct for time range comparison
    private struct TimeRangeInfo {
        let startTime: Date
        let endTime: Date
        let itemIndex: Int       // Index in the items array
        let stepIndex: Int?      // For itinerary items, the step index
        let isBookedActivity: Bool

        func overlaps(with other: TimeRangeInfo) -> Bool {
            // Two ranges overlap if R1.start < R2.end AND R2.start < R1.end
            // Adjacent times (12:00-13:00 and 13:00-14:00) do NOT overlap
            return startTime < other.endTime && other.startTime < endTime
        }
    }

    /// Detects time conflicts among items for a single day
    /// - Parameter items: All merged timeline items for the selected day
    internal func detectTimeConflicts(items: [TRPMergedTimelineItem]) {
        // Reset conflict flags for all items and steps
        for item in items {
            item.hasConflict = false
            item.showTimeOverlapText = false
            // Reset step conflicts for itinerary items
            if item.isItinerary, item.plan != nil {
                for i in 0..<item.plan!.steps.count {
                    item.plan!.steps[i].hasConflict = false
                    item.plan!.steps[i].showTimeOverlapText = false
                }
            }
        }

        // Collect all time ranges
        var timeRanges: [TimeRangeInfo] = []

        for (itemIndex, item) in items.enumerated() {
            let isBooked = item.isBookedActivity

            switch item.segmentType {
            case .bookedActivity, .reservedActivity, .manualPoi:
                // Single time range for non-itinerary items
                guard let startDate = item.startDate,
                      let endDate = item.endDate else { continue }

                timeRanges.append(TimeRangeInfo(
                    startTime: startDate,
                    endTime: endDate,
                    itemIndex: itemIndex,
                    stepIndex: nil,
                    isBookedActivity: isBooked
                ))

            case .itinerary:
                // Collect time range for each step
                guard let plan = item.plan else { continue }

                for (stepIndex, step) in plan.steps.enumerated() {
                    guard let startStr = step.startDateTimes,
                          let endStr = step.endDateTimes,
                          let startDate = Date.fromString(startStr, format: "yyyy-MM-dd HH:mm:ss"),
                          let endDate = Date.fromString(endStr, format: "yyyy-MM-dd HH:mm:ss") else {
                        continue
                    }

                    timeRanges.append(TimeRangeInfo(
                        startTime: startDate,
                        endTime: endDate,
                        itemIndex: itemIndex,
                        stepIndex: stepIndex,
                        isBookedActivity: false
                    ))
                }
            }
        }

        // Check for conflicts (O(n²) but n is small - typically < 20 items per day)
        for i in 0..<timeRanges.count {
            for j in (i + 1)..<timeRanges.count {
                let range1 = timeRanges[i]
                let range2 = timeRanges[j]

                if range1.overlaps(with: range2) {
                    // Mark both ranges as having conflicts
                    markAsConflict(items: items, range: range1)
                    markAsConflict(items: items, range: range2)
                }
            }
        }
    }

    /// Marks an item or step as having a conflict
    private func markAsConflict(items: [TRPMergedTimelineItem], range: TimeRangeInfo) {
        let item = items[range.itemIndex]

        if let stepIndex = range.stepIndex {
            // Itinerary step conflict
            if item.plan != nil, stepIndex < item.plan!.steps.count {
                item.plan!.steps[stepIndex].hasConflict = true
                item.plan!.steps[stepIndex].showTimeOverlapText = true
            }
            // Also mark the parent item as having conflict (for potential container styling)
            item.hasConflict = true
        } else {
            // Non-itinerary item conflict
            item.hasConflict = true
            // BookedActivity does NOT show "Time Overlap" text
            item.showTimeOverlapText = !range.isBookedActivity
        }
    }

    /// Calculates unified order for all items in the current day
    /// Order resets to 1 for each city (section) - city-based numbering
    /// - BookedActivity/ReservedActivity/ManualPoi: 1 order each
    /// - Itinerary (Recommendations): consumes N orders (where N = number of steps)
    internal func calculateUnifiedOrders() {
        unifiedOrderMap = [:]

        // Calculate order per city group (section)
        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            // Sort items within this city by start time
            let sortedItems = cityGroup.items.sorted { item1, item2 in
                let date1 = item1.startDate ?? Date.distantFuture
                let date2 = item2.startDate ?? Date.distantFuture
                return date1 < date2
            }

            // Reset order to 1 for each city
            var currentOrder = 1
            for item in sortedItems {
                // Key format: "sectionIndex_segmentIndex"
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"
                unifiedOrderMap[key] = currentOrder

                switch item.segmentType {
                case .bookedActivity, .reservedActivity, .manualPoi:
                    // Single item, consumes 1 order
                    currentOrder += 1
                case .itinerary:
                    // Recommendations segment, consumes N orders (one per step)
                    let stepCount = item.steps.count
                    currentOrder += max(stepCount, 1) // At least 1 even if no steps
                }
            }
        }
    }

    // MARK: - Process Timeline

    internal func processTimelineData() {
        // Reset to empty state
        mergedTimeline = nil
        displayItems = []
        filteredFavoriteItems = []
        allTripDates = []

        guard timeline != nil else {
            return
        }

        // Build merged timeline (SINGLE SOURCE OF TRUTH)
        let mergedItems = mergeTimelineData()
        mergedTimeline = TRPDateGroupedTimeline(items: mergedItems)

        // Calculate all trip dates (continuous from start to end)
        allTripDates = calculateAllTripDates()

        updateDisplayItems()

        // Filter favorite items to exclude already booked/reserved activities
        filterFavoriteItems()

        // Mark data as loaded
        hasLoadedData = true
    }

    // MARK: - Date Calculations

    /// Calculates all dates from trip start to end (continuous range for day filter)
    internal func calculateAllTripDates() -> [Date] {
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
        for segment in allSegments {
            var segmentStartDateStr = segment.additionalData?.startDatetime
            if segmentStartDateStr == nil {
                segmentStartDateStr = segment.startDate
            }

            guard let dateStr = segmentStartDateStr else { continue }

            // Extract only date portion (yyyy-MM-dd)
            let segmentDateString = String(dateStr.prefix(10))

            if minDateString == nil || segmentDateString < minDateString! {
                minDateString = segmentDateString
            }
            if maxDateString == nil || segmentDateString > maxDateString! {
                maxDateString = segmentDateString
            }
        }

        guard let minStr = minDateString, let maxStr = maxDateString else { return [] }

        // Convert date strings to Date objects
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

    // MARK: - Favorite Items

    /// Filters favorite items to exclude those that are already booked or reserved
    internal func filterFavoriteItems() {
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

    // MARK: - Favourite Items City Resolution

    /// Resolves cityIds for favourite items that don't have a valid one using the resolveCities API.
    /// Items with cityId nil or <= 0 will be resolved. Results are written back to item.cityId.
    /// - Parameter completion: Called when resolution is complete (regardless of success/failure)
    internal func resolveFavouriteItemCities(completion: @escaping () -> Void) {
        guard var favouriteItems = timeline?.favouriteItems,
              !favouriteItems.isEmpty else {
            completion()
            return
        }

        // Collect items that need city resolution (cityId is nil or invalid <= 0)
        let itemsNeedingResolution = favouriteItems.enumerated().filter { ($0.element.cityId ?? 0) <= 0 }

        guard !itemsNeedingResolution.isEmpty else {
            completion()
            return
        }

        let coordinates = itemsNeedingResolution.map { $0.element.coordinate }

        let cityRemoteApi = TRPCityRemoteApi()
        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else {
                completion()
                return
            }

            switch result {
            case .success(let cityIds):
                // cityIds order matches coordinates order
                let originalIndices = itemsNeedingResolution.map { $0.offset }
                for (arrayIndex, originalIndex) in originalIndices.enumerated() {
                    if arrayIndex < cityIds.count {
                        favouriteItems[originalIndex].cityId = cityIds[arrayIndex]
                    }
                }
                self.timeline?.favouriteItems = favouriteItems
                Log.i("resolveFavouriteItemCities: Resolved \(cityIds.count) city IDs for favourite items")

            case .failure(let error):
                Log.e("resolveFavouriteItemCities: Failed - \(error.localizedDescription)")
            }

            completion()
        }
    }

    // MARK: - Segment Identification

    /// Generates a unique identifier for a segment to avoid duplicates
    /// Uses activityId or bookingId if available, otherwise creates from startDate + title
    internal func getSegmentUniqueId(_ segment: TRPTimelineSegment) -> String {
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
}
