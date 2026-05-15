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
                // Skip date boundary segments (Empty or TimelineDate)
                // These segments mark trip date boundaries and should not be displayed in UI
                if isDateBoundarySegment(segment) {
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

    /// Checks if a segment is a TimelineDate segment (new system)
    /// TimelineDate segments span the full trip duration and mark date boundaries
    /// - Parameter segment: The segment to check
    /// - Returns: true if the segment is a TimelineDate segment
    internal func isTimelineDateSegment(_ segment: TRPTimelineSegment) -> Bool {
        return segment.title == "TimelineDate" && segment.available == false
    }

    /// Unified check for date boundary segments (supports both old and new systems)
    /// Returns true if segment is either Empty (old) or TimelineDate (new)
    /// - Parameter segment: The segment to check
    /// - Returns: true if the segment is a date boundary segment
    internal func isDateBoundarySegment(_ segment: TRPTimelineSegment) -> Bool {
        return isEmptyPlaceholderSegment(segment) || isTimelineDateSegment(segment)
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
        let cityGroups = mergedTimeline.itemsGroupedByCity(for: selectedDate)

        // Within each city, pin flexible-time activities to the top of the section.
        // Flex items keep their city; only the in-section order is overridden so that
        // their `00:00` / `23:59` timestamps don't push them out of place.
        displayItems = cityGroups.map { group in
            let reordered = group.items.sorted { lhs, rhs in
                if lhs.isFlexibleActivity != rhs.isFlexibleActivity {
                    return lhs.isFlexibleActivity
                }
                let d1 = lhs.startDate ?? Date.distantFuture
                let d2 = rhs.startDate ?? Date.distantFuture
                return d1 < d2
            }
            return TRPTimelineCityGroup(city: group.city, items: reordered)
        }

        // Calculate unified orders for the current day
        calculateUnifiedOrders()
    }

    // MARK: - Time Conflict Detection

    /// Helper struct for time range comparison
    private struct TimeRangeInfo {
        let startTime: Date
        let endTime: Date
        let itemIndex: Int   // Index in the items array
        let stepIndex: Int?  // For itinerary items, the step index

        func overlaps(with other: TimeRangeInfo) -> Bool {
            // Two ranges overlap if R1.start < R2.end AND R2.start < R1.end.
            // Adjacent times (12:00–13:00 and 13:00–14:00) do NOT overlap.
            return startTime < other.endTime && other.startTime < endTime
        }
    }

    /// Helper struct for grouping conflicting time ranges
    private struct ConflictGroup {
        var segmentIndices: Set<Int>    // Unique item indices
        var timeRangeIndices: Set<Int>  // All conflicting range indices
    }

    /// Detects time conflicts among display items for the current day.
    /// Rules:
    ///   - `bookedActivity`: included — time badge turns red, no "Time Overlap" label.
    ///   - Flexible-time reserved activities: excluded (00:00–23:59 placeholder times).
    ///   - All other conflicting items/steps: `hasConflict = true`, `showTimeOverlapText = true`.
    ///   - Only items passed in `items` (current day's list) are considered.
    internal func detectTimeConflicts(items: [TRPMergedTimelineItem]) {
        resetConflictFlags(items: items)

        let timeRanges = collectTimeRanges(from: items)
        let conflictGroups = buildConflictGroups(timeRanges: timeRanges)

        for group in conflictGroups {
            for rangeIndex in group.timeRangeIndices {
                let range = timeRanges[rangeIndex]
                let item = items[range.itemIndex]
                // bookedActivity: time badge turns red but no "Time Overlap" label.
                let showText = !item.isBookedActivity

                if let stepIndex = range.stepIndex {
                    if let plan = item.plan, stepIndex < plan.steps.count {
                        item.plan!.steps[stepIndex].hasConflict = true
                        item.plan!.steps[stepIndex].showTimeOverlapText = showText
                    }
                    item.hasConflict = true
                } else {
                    item.hasConflict = true
                    item.showTimeOverlapText = showText
                }
            }
        }
    }

    // MARK: - Conflict Detection Helpers

    /// Builds conflict groups using BFS on the overlap adjacency graph.
    private func buildConflictGroups(timeRanges: [TimeRangeInfo]) -> [ConflictGroup] {
        // Build adjacency list — O(n²)
        var adjacency: [Int: Set<Int>] = [:]
        for i in 0..<timeRanges.count {
            for j in (i + 1)..<timeRanges.count {
                if timeRanges[i].overlaps(with: timeRanges[j]) {
                    adjacency[i, default: []].insert(j)
                    adjacency[j, default: []].insert(i)
                }
            }
        }

        // BFS to collect connected components
        var groups: [ConflictGroup] = []
        var visited = Set<Int>()

        for start in 0..<timeRanges.count {
            guard !visited.contains(start), adjacency[start] != nil else { continue }

            var group = ConflictGroup(segmentIndices: [], timeRangeIndices: [])
            var queue = [start]

            while !queue.isEmpty {
                let current = queue.removeFirst()
                guard !visited.contains(current) else { continue }
                visited.insert(current)
                group.timeRangeIndices.insert(current)
                group.segmentIndices.insert(timeRanges[current].itemIndex)
                if let neighbours = adjacency[current] {
                    queue.append(contentsOf: neighbours)
                }
            }

            groups.append(group)
        }

        return groups
    }

    /// Collects time ranges for conflict checking.
    /// Excluded from the check:
    ///   - Flexible-time reserved activities (00:00–23:59 placeholder times)
    /// Included but text-suppressed:
    ///   - `.bookedActivity` — participates in overlap detection so its time badge
    ///     turns red, but `showTimeOverlapText` is kept false (no label).
    private func collectTimeRanges(from items: [TRPMergedTimelineItem]) -> [TimeRangeInfo] {
        var timeRanges: [TimeRangeInfo] = []

        for (itemIndex, item) in items.enumerated() {
            switch item.segmentType {
            case .bookedActivity:
                guard let startDate = item.startDate, let endDate = item.endDate else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .reservedActivity:
                // Skip flexible-time activities — their 00:00/23:59 placeholder
                // times would falsely overlap with every other item on the day.
                if item.isFlexibleActivity { break }
                guard let startDate = item.startDate, let endDate = item.endDate else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .manualPoi:
                guard let startDate = item.startDate, let endDate = item.endDate else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .itinerary:
                guard let plan = item.plan else { break }
                for (stepIndex, step) in plan.steps.enumerated() {
                    // Use TRPDateHelper (local timezone) — same as item.startDate/endDate —
                    // so step times and reserved-activity times are compared on the same
                    // clock. Date.fromString uses UTC and causes a timezone-shifted
                    // overlap between unrelated items (e.g. a UTC+2 device makes the
                    // Istanbul tour appear 2 h earlier, falsely conflicting with steps
                    // that are actually clear).
                    guard let startStr = step.startDateTimes,
                          let endStr = step.endDateTimes,
                          let startDate = TRPDateHelper.parseDateTime(startStr),
                          let endDate = TRPDateHelper.parseDateTime(endStr) else {
                        continue
                    }
                    timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                    itemIndex: itemIndex, stepIndex: stepIndex))
                }
            }
        }

        return timeRanges
    }

    /// Resets all conflict flags
    /// - Parameter items: All merged timeline items
    private func resetConflictFlags(items: [TRPMergedTimelineItem]) {
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
    }

    /// Calculates unified order for all items in the current day
    /// Order continues across cities - day-based numbering
    /// - BookedActivity/ReservedActivity/ManualPoi: 1 order each
    /// - Itinerary (Recommendations): consumes N orders (where N = number of steps)
    internal func calculateUnifiedOrders() {
        unifiedOrderMap = [:]

        // Start order at 1 for the entire day (continues across cities)
        var currentOrder = 1

        // Calculate order per city group (section)
        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            // Sort items within this city by start time
            let sortedItems = cityGroup.items.sorted { item1, item2 in
                let date1 = item1.startDate ?? Date.distantFuture
                let date2 = item2.startDate ?? Date.distantFuture
                return date1 < date2
            }

            for item in sortedItems {
                // Key format: "sectionIndex_segmentIndex"
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"

                // Flexible activities render with "-" instead of an order number;
                // they must not consume a slot in the day's unified ordering.
                if item.isFlexibleActivity {
                    unifiedOrderMap[key] = 0
                    continue
                }

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

        // First load: default selectedDayIndex to today (or nearest in-range fallback)
        if !hasLoadedData {
            selectedDayIndex = computeInitialSelectedDayIndex()
        }

        updateDisplayItems()

        // Filter favorite items to exclude already booked/reserved activities
        filterFavoriteItems()

        // Mark data as loaded
        hasLoadedData = true
    }

    // MARK: - Date Calculations

    /// Gets the timeline date boundaries (start and end dates)
    /// Prioritizes TimelineDate segment for accuracy, falls back to scanning all segments
    /// - Returns: Tuple of (startDate, endDate) or nil if no valid dates found
    internal func getTimelineDateBoundaries() -> (startDate: Date, endDate: Date)? {
        guard let timeline = timeline else { return nil }

        // STEP 1: Check for TimelineDate segment first (most accurate source)
        // TimelineDate segment spans the full trip duration
        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                if isTimelineDateSegment(segment) {
                    // Found TimelineDate segment - use its dates directly
                    if let startDateStr = segment.startDate,
                       let endDateStr = segment.endDate {
                        // Parse dates
                        let startDate = Date.fromString(startDateStr, format: "yyyy-MM-dd HH:mm") ??
                                       Date.fromString(startDateStr, format: "yyyy-MM-dd HH:mm:ss")
                        let endDate = Date.fromString(endDateStr, format: "yyyy-MM-dd HH:mm") ??
                                     Date.fromString(endDateStr, format: "yyyy-MM-dd HH:mm:ss")

                        if let start = startDate, let end = endDate {
                            return (startDate: start, endDate: end)
                        }
                    }
                }
            }
        }

        // STEP 2: Fallback - scan all segments for min/max (backward compatibility for Empty segments)
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

        guard !allSegments.isEmpty else { return nil }

        // Use string-based comparison to avoid timezone issues
        var minDateString: String?
        var maxDateString: String?

        // Find min and max dates from all segments
        for segment in allSegments {
            // Check startDate
            var segmentStartDateStr = segment.additionalData?.startDatetime
            if segmentStartDateStr == nil {
                segmentStartDateStr = segment.startDate
            }

            if let dateStr = segmentStartDateStr {
                let segmentDateString = String(dateStr.prefix(10))
                if minDateString == nil || segmentDateString < minDateString! {
                    minDateString = segmentDateString
                }
                if maxDateString == nil || segmentDateString > maxDateString! {
                    maxDateString = segmentDateString
                }
            }

            // Check endDate
            var segmentEndDateStr = segment.additionalData?.endDatetime
            if segmentEndDateStr == nil {
                segmentEndDateStr = segment.endDate
            }

            if let dateStr = segmentEndDateStr {
                let segmentDateString = String(dateStr.prefix(10))
                if minDateString == nil || segmentDateString < minDateString! {
                    minDateString = segmentDateString
                }
                if maxDateString == nil || segmentDateString > maxDateString! {
                    maxDateString = segmentDateString
                }
            }
        }

        guard let minStr = minDateString, let maxStr = maxDateString else { return nil }

        // Convert date strings to Date objects
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        guard let startDate = dateFormatter.date(from: minStr),
              let endDate = dateFormatter.date(from: maxStr) else { return nil }

        return (startDate: startDate, endDate: endDate)
    }

    /// Computes the initial selectedDayIndex on first load.
    /// - Returns today's index if today falls within `allTripDates`.
    /// - Returns 0 if today is before the trip range.
    /// - Returns last index if today is after the trip range.
    /// - Returns 0 for empty range.
    internal func computeInitialSelectedDayIndex() -> Int {
        guard !allTripDates.isEmpty else { return 0 }
        let today = Date()
        let calendar = Calendar.current
        if let idx = allTripDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) {
            return idx
        }
        if let first = allTripDates.first, today < first {
            return 0
        }
        return allTripDates.count - 1
    }

    /// Calculates all dates from trip start to end (continuous range for day filter)
    internal func calculateAllTripDates() -> [Date] {
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

    /// Resolves cityIds for favourite items that don't have a valid one.
    /// Items with a coordinate go through cities/resolve; items without (coordinate
    /// `(0, 0)`) fall through to tour-api/product-lookup using their `activityId`.
    /// Results are written back to `item.cityId`.
    /// - Parameter completion: Called when resolution is complete (regardless of success/failure)
    internal func resolveFavouriteItemCities(completion: @escaping () -> Void) {
        guard let initial = timeline?.favouriteItems, !initial.isEmpty else {
            completion()
            return
        }

        // Collect items that need city resolution (cityId is nil or invalid <= 0)
        let itemsNeedingResolution = initial.enumerated().filter { ($0.element.cityId ?? 0) <= 0 }

        guard !itemsNeedingResolution.isEmpty else {
            completion()
            return
        }

        let withLocation = itemsNeedingResolution.filter { !$0.element.lacksLocation }
        let noLocation = itemsNeedingResolution.filter { $0.element.lacksLocation }

        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.tripian.timeline.favourites.cityResolve")
        var resolved: [Int: Int] = [:]  // index -> cityId

        // With-location branch: cities/resolve (no cache fallback historically).
        if !withLocation.isEmpty {
            group.enter()
            let coordinates = withLocation.map { $0.element.coordinate }
            TRPCityRemoteApi().resolveCities(coordinates: coordinates) { result in
                switch result {
                case .success(let cityIds):
                    resultsQueue.async {
                        for (i, entry) in withLocation.enumerated() where i < cityIds.count {
                            resolved[entry.offset] = cityIds[i]
                        }
                        Log.i("resolveFavouriteItemCities: Resolved \(cityIds.count) city IDs via cities/resolve")
                        group.leave()
                    }
                case .failure(let error):
                    resultsQueue.async {
                        Log.e("resolveFavouriteItemCities: cities/resolve failed - \(error.localizedDescription)")
                        group.leave()
                    }
                }
            }
        }

        // No-location branch: lookup by product id.
        let lookupTriples: [(index: Int, productId: String, providerId: Int)] = noLocation.compactMap { entry in
            guard let keys = entry.element.tourLookupKeys else { return nil }
            return (index: entry.offset, productId: keys.productId, providerId: keys.providerId)
        }

        if !lookupTriples.isEmpty {
            group.enter()
            lookupCityIds(for: lookupTriples) { lookupResults in
                resultsQueue.async {
                    for (idx, cityId) in lookupResults {
                        resolved[idx] = cityId
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            var favouriteItems = self.timeline?.favouriteItems ?? initial
            resultsQueue.sync {
                for (index, cityId) in resolved where index < favouriteItems.count {
                    favouriteItems[index].cityId = cityId
                }
            }
            self.timeline?.favouriteItems = favouriteItems
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
