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

        // Get items grouped by city for section display
        // If no items exist for this date, displayItems will be empty (shows empty state)
        displayItems = mergedTimeline.itemsGroupedByCity(for: selectedDate)

        // Calculate unified orders for the current day
        calculateUnifiedOrders()
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
