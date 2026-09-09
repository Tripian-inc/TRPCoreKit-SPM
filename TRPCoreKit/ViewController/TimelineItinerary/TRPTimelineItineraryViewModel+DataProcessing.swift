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

    /// Matches plan.id (String) against segment.dayIds (Int values).
    internal func findMatchingPlan(for segment: TRPTimelineSegment, in plans: [TRPTimelinePlan]) -> TRPTimelinePlan? {
        guard let dayIds = segment.dayIds, !dayIds.isEmpty else {
            return nil
        }

        for plan in plans {
            if let planIdInt = Int(plan.id), dayIds.contains(planIdInt) {
                return plan
            }
        }

        return nil
    }

    // MARK: - Merge Timeline Data

    /// Merges tripProfile.segments + plans into a unified array, preserving API response order.
    /// tripProfile.segments is the SINGLE SOURCE OF TRUTH for all segment types.
    internal func mergeTimelineData() -> [TRPMergedTimelineItem] {
        guard let timeline = timeline else { return [] }

        var mergedItems: [TRPMergedTimelineItem] = []

        if let profileSegments = timeline.tripProfile?.segments {
            for (index, segment) in profileSegments.enumerated() {
                if isDateBoundarySegment(segment) {
                    continue
                }
                let plan: TRPTimelinePlan?

                switch segment.segmentType {
                case .bookedActivity, .reservedActivity:
                    if let additionalData = segment.additionalData {
                        segment.startDate = additionalData.startDatetime
                        segment.endDate = additionalData.endDatetime
                    }
                    plan = nil

                case .manualPoi, .itinerary:
                    if let plans = timeline.plans,
                       let matchingPlan = findMatchingPlan(for: segment, in: plans) {
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

    /// Empty placeholder segments cover the full trip date range and are not displayed.
    internal func isEmptyPlaceholderSegment(_ segment: TRPTimelineSegment) -> Bool {
        return segment.title == "Empty" && segment.available == false
    }

    /// TimelineDate segments (new system) span the full trip duration and mark date boundaries.
    internal func isTimelineDateSegment(_ segment: TRPTimelineSegment) -> Bool {
        return segment.title == "TimelineDate" && segment.available == false
    }

    /// True if segment is Empty (old) or TimelineDate (new).
    internal func isDateBoundarySegment(_ segment: TRPTimelineSegment) -> Bool {
        return isEmptyPlaceholderSegment(segment) || isTimelineDateSegment(segment)
    }

    // MARK: - Display Items

    internal func updateDisplayItems() {
        guard let mergedTimeline = mergedTimeline else {
            displayItems = []
            unifiedOrderMap = [:]
            flatSections = []
            return
        }

        guard selectedDayIndex >= 0, selectedDayIndex < allTripDates.count else {
            displayItems = []
            unifiedOrderMap = [:]
            flatSections = []
            return
        }

        let selectedDate = allTripDates[selectedDayIndex]

        let dayItems = mergedTimeline.items(for: selectedDate)

        // Detect conflicts before grouping so all items on the day are checked against each other.
        detectTimeConflicts(items: dayItems)

        let cityGroups = mergedTimeline.itemsGroupedByCity(for: selectedDate)

        // Pin flexible-time activities to the top of each city section so their 00:00/23:59 times don't misplace them.
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

        calculateUnifiedOrders()

        if usesFlatTimeline {
            buildFlatSections()
            reportPlansGeneratedWithoutPois()
        }
    }

    // MARK: - Time Conflict Detection

    private struct TimeRangeInfo {
        let startTime: Date
        let endTime: Date
        let itemIndex: Int
        let stepIndex: Int?

        func overlaps(with other: TimeRangeInfo) -> Bool {
            // Adjacent times (12:00–13:00 and 13:00–14:00) do NOT overlap.
            return startTime < other.endTime && other.startTime < endTime
        }
    }

    private struct ConflictGroup {
        var segmentIndices: Set<Int>
        var timeRangeIndices: Set<Int>
    }

    /// `bookedActivity` turns its badge red without a label; flexible reserved activities are excluded.
    internal func detectTimeConflicts(items: [TRPMergedTimelineItem]) {
        resetConflictFlags(items: items)

        let timeRanges = collectTimeRanges(from: items)
        let conflictGroups = buildConflictGroups(timeRanges: timeRanges)

        for group in conflictGroups {
            for rangeIndex in group.timeRangeIndices {
                let range = timeRanges[rangeIndex]
                let item = items[range.itemIndex]
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
        var adjacency: [Int: Set<Int>] = [:]
        for i in 0..<timeRanges.count {
            for j in (i + 1)..<timeRanges.count {
                if timeRanges[i].overlaps(with: timeRanges[j]) {
                    adjacency[i, default: []].insert(j)
                    adjacency[j, default: []].insert(i)
                }
            }
        }

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

    /// A 24h/48h ticket's duration is a validity window, not an occupancy block — including it
    /// would flag every other item on the day as overlapping.
    private func spansFullDayOrLonger(start: Date, end: Date) -> Bool {
        return end.timeIntervalSince(start) >= 24 * 60 * 60
    }

    /// Excludes flexible reserved activities and full-day-or-longer spans; `.bookedActivity` participates but with text suppressed.
    private func collectTimeRanges(from items: [TRPMergedTimelineItem]) -> [TimeRangeInfo] {
        var timeRanges: [TimeRangeInfo] = []

        for (itemIndex, item) in items.enumerated() {
            switch item.segmentType {
            case .bookedActivity:
                guard let startDate = item.startDate, let endDate = item.endDate,
                      !spansFullDayOrLonger(start: startDate, end: endDate) else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .reservedActivity:
                // Skip flexible activities — 00:00/23:59 placeholders would falsely overlap everything.
                if item.isFlexibleActivity { break }
                guard let startDate = item.startDate, let endDate = item.endDate,
                      !spansFullDayOrLonger(start: startDate, end: endDate) else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .manualPoi:
                guard let startDate = item.startDate, let endDate = item.endDate,
                      !spansFullDayOrLonger(start: startDate, end: endDate) else { break }
                timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                itemIndex: itemIndex, stepIndex: nil))

            case .itinerary:
                guard let plan = item.plan else { break }
                for (stepIndex, step) in plan.steps.enumerated() {
                    // Use TRPDateHelper (local timezone) so step times match item.startDate/endDate; Date.fromString (UTC) causes timezone-shifted false overlaps.
                    guard let startStr = step.startDateTimes,
                          let endStr = step.endDateTimes,
                          let startDate = TRPDateHelper.parseDateTime(startStr),
                          let endDate = TRPDateHelper.parseDateTime(endStr),
                          !spansFullDayOrLonger(start: startDate, end: endDate) else {
                        continue
                    }
                    timeRanges.append(TimeRangeInfo(startTime: startDate, endTime: endDate,
                                                    itemIndex: itemIndex, stepIndex: stepIndex))
                }
            }
        }

        return timeRanges
    }

    private func resetConflictFlags(items: [TRPMergedTimelineItem]) {
        for item in items {
            item.hasConflict = false
            item.showTimeOverlapText = false
            if item.isItinerary, item.plan != nil {
                for i in 0..<item.plan!.steps.count {
                    item.plan!.steps[i].hasConflict = false
                    item.plan!.steps[i].showTimeOverlapText = false
                }
            }
        }
    }

    /// Day-based numbering continuing across cities; itinerary segments consume one order per step.
    internal func calculateUnifiedOrders() {
        unifiedOrderMap = [:]

        var currentOrder = 1

        for (sectionIndex, cityGroup) in displayItems.enumerated() {
            let sortedItems = cityGroup.items.sorted { item1, item2 in
                let date1 = item1.startDate ?? Date.distantFuture
                let date2 = item2.startDate ?? Date.distantFuture
                return date1 < date2
            }

            for item in sortedItems {
                let key = "\(sectionIndex)_\(item.originalSegmentIndex)"

                // Flexible activities render with "-" and must not consume an order slot.
                if item.isFlexibleActivity {
                    unifiedOrderMap[key] = 0
                    continue
                }

                unifiedOrderMap[key] = currentOrder

                switch item.segmentType {
                case .bookedActivity, .reservedActivity, .manualPoi:
                    currentOrder += 1
                case .itinerary:
                    let stepCount = item.steps.count
                    currentOrder += max(stepCount, 1) // At least 1 even if no steps
                }
            }
        }
    }

    // MARK: - Process Timeline

    internal func processTimelineData() {
        mergedTimeline = nil
        displayItems = []
        filteredFavoriteItems = []
        allTripDates = []

        guard timeline != nil else {
            return
        }

        // Re-apply cached "not available" flags (transient, lost on re-fetch) before building merged items. No-op until the sweep populates expiredAvailabilityKeys.
        reapplyCachedAvailabilityFlags()

        let mergedItems = mergeTimelineData()
        mergedTimeline = TRPDateGroupedTimeline(items: mergedItems)

        allTripDates = calculateAllTripDates()

        if !hasLoadedData {
            selectedDayIndex = computeInitialSelectedDayIndex()
        }

        updateDisplayItems()

        filterFavoriteItems()

        hasLoadedData = true

        // Guarded by hasRunInitialAvailabilityCheck, so later refreshes re-enter as no-ops.
        runInitialAvailabilityCheck()
    }

    // MARK: - Date Calculations

    /// Prioritizes the TimelineDate segment, falling back to scanning all segments for min/max.
    internal func getTimelineDateBoundaries() -> (startDate: Date, endDate: Date)? {
        guard let timeline = timeline else { return nil }

        if let profileSegments = timeline.tripProfile?.segments {
            for segment in profileSegments {
                if isTimelineDateSegment(segment) {
                    if let startDateStr = segment.startDate,
                       let endDateStr = segment.endDate {
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

        // String comparison avoids timezone issues.
        var minDateString: String?
        var maxDateString: String?

        for segment in allSegments {
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

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        guard let startDate = dateFormatter.date(from: minStr),
              let endDate = dateFormatter.date(from: maxStr) else { return nil }

        return (startDate: startDate, endDate: endDate)
    }

    /// First-load index: today if in range, 0 if before the trip, last index if after, 0 if empty.
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

    /// All dates from trip start to end (inclusive), for the day filter.
    internal func calculateAllTripDates() -> [Date] {
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

    // MARK: - Favorite Items

    /// Drops favourites that are already in the plan — as a booked/reserved segment or as an itinerary
    /// activity step — plus the ones the user removed by hand. Compares on the bare product id
    /// (`cleanedAsActivityId()`) so `"12345"` matches `"C_12345_15"`; otherwise a just-added favourite
    /// reappears in Saved Plans.
    internal func filterFavoriteItems() {
        guard let favouriteItems = timeline?.favouriteItems else {
            filteredFavoriteItems = []
            return
        }

        let plannedActivityIds = Set(plannedActivities().map { $0.productId })

        let excludedIds: Set<String>
        if let tripHash = timeline?.tripHash {
            excludedIds = TRPFavouriteExclusionStorage.excludedActivityIds(tripHash: tripHash)
        } else {
            excludedIds = []
        }

        filteredFavoriteItems = favouriteItems.filter { item in
            guard let activityId = item.activityId else { return true }
            let baseId = activityId.cleanedAsActivityId()
            return !plannedActivityIds.contains(baseId) && !excludedIds.contains(baseId)
        }
    }

    // MARK: - Favourite Items City Resolution

    /// Fills in cityIds for favourites that don't have one yet, via `resolveCityIds` (product-lookup first).
    internal func resolveFavouriteItemCities(completion: @escaping () -> Void) {
        guard let initial = timeline?.favouriteItems, !initial.isEmpty else {
            completion()
            return
        }

        let requests = initial.enumerated().compactMap { offset, item -> TRPCityResolutionRequest? in
            guard (item.cityId ?? 0) <= 0 else { return nil }
            return TRPCityResolutionRequest(
                index: offset,
                lookupKeys: item.tourLookupKeys,
                coordinate: item.lacksLocation ? nil : item.coordinate
            )
        }

        guard !requests.isEmpty else {
            completion()
            return
        }

        resolveCityIds(for: requests) { [weak self] resolved in
            guard let self = self else {
                completion()
                return
            }

            var favouriteItems = self.timeline?.favouriteItems ?? initial
            for (index, cityId) in resolved where index < favouriteItems.count {
                favouriteItems[index].cityId = cityId
            }
            self.timeline?.favouriteItems = favouriteItems
            completion()
        }
    }

    // MARK: - Segment Identification

    /// Unique segment id for de-duplication; prefers bookingId, then activityId+startDate, then date-based keys.
    internal func getSegmentUniqueId(_ segment: TRPTimelineSegment) -> String {
        if let bookingId = segment.additionalData?.bookingId {
            return "booking_\(bookingId)"
        }

        // Same activity can recur at different times, so include startDate.
        if let activityId = segment.additionalData?.activityId, let startDate = segment.startDate {
            return "activity_\(activityId)_\(startDate)"
        }

        if let startDate = segment.startDate, let title = segment.title {
            return "segment_\(startDate)_\(title)"
        }

        if let startDate = segment.startDate {
            return "segment_\(startDate)_\(segment.segmentType.rawValue)"
        }

        return "segment_\(ObjectIdentifier(segment))"
    }
}
