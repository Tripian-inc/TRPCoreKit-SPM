//
//  TRPDateGroupedTimeline.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// City group structure for section display
public struct TRPTimelineCityGroup {
    public let city: TRPCity?
    public let items: [TRPMergedTimelineItem]

    public init(city: TRPCity?, items: [TRPMergedTimelineItem]) {
        self.city = city
        self.items = items
    }
}

/// Date-grouped timeline storage for efficient filtering.
/// Items are indexed by date string (yyyy-MM-dd) for O(1) lookup.
///
/// Usage:
/// 1. Initialize with merged items: `TRPDateGroupedTimeline(items: mergedItems)`
/// 2. Get items for a date: `items(for: selectedDate)`
/// 3. Get items grouped by city: `itemsGroupedByCity(for: selectedDate)`
public class TRPDateGroupedTimeline {

    // MARK: - Storage

    /// All merged items indexed by date string (yyyy-MM-dd)
    private var itemsByDate: [String: [TRPMergedTimelineItem]] = [:]

    /// Ordered list of dates (for day filter)
    public private(set) var availableDates: [Date] = []

    /// All merged items (flat list, preserves API order)
    public private(set) var allItems: [TRPMergedTimelineItem] = []

    // MARK: - Initialization

    public init(items: [TRPMergedTimelineItem]) {
        self.allItems = items
        self.buildDateIndex()
    }

    /// Empty initializer
    public init() {
        self.allItems = []
        self.availableDates = []
    }

    // MARK: - Building Index

    /// Build date index from items
    private func buildDateIndex() {
        itemsByDate.removeAll()
        var dateSet = Set<String>()

        for item in allItems {
            guard let dateStr = item.dateString else { continue }
            dateSet.insert(dateStr)

            if itemsByDate[dateStr] == nil {
                itemsByDate[dateStr] = []
            }
            itemsByDate[dateStr]?.append(item)
        }

        // Sort dates and convert to Date objects
        availableDates = dateSet.sorted().compactMap { dateStr in
            TRPDateHelper.parseDate(dateStr)
        }
    }

    // MARK: - Querying

    /// Get items for a specific date
    /// - Parameter date: Target date
    /// - Returns: Array of merged items for that date (preserves API order)
    public func items(for date: Date) -> [TRPMergedTimelineItem] {
        let dateStr = TRPDateHelper.formatDateString(date)
        return itemsByDate[dateStr] ?? []
    }

    /// Get items for a specific date string
    /// - Parameter dateStr: Date string in yyyy-MM-dd format
    /// - Returns: Array of merged items for that date
    public func items(forDateString dateStr: String) -> [TRPMergedTimelineItem] {
        return itemsByDate[dateStr] ?? []
    }

    /// Get items for a specific day index
    /// - Parameter dayIndex: Day index (0-based)
    /// - Returns: Array of merged items for that day
    public func items(forDayIndex dayIndex: Int) -> [TRPMergedTimelineItem] {
        guard dayIndex >= 0, dayIndex < availableDates.count else {
            return []
        }
        return items(for: availableDates[dayIndex])
    }

    /// Get items grouped by city for a specific date (for section headers)
    /// - Parameter date: Target date
    /// - Returns: Array of city groups, first city from first item appears first
    public func itemsGroupedByCity(for date: Date) -> [TRPTimelineCityGroup] {
        let dayItems = items(for: date)
        guard !dayItems.isEmpty else { return [] }

        // Get first item's city (this will be primary group)
        let firstCityName = dayItems.first?.city?.name ?? "Unknown"

        // Group by city name, preserving order within each group
        var cityGroups: [String: (city: TRPCity?, items: [TRPMergedTimelineItem])] = [:]
        var cityOrder: [String] = []

        for item in dayItems {
            let cityName = item.city?.name ?? "Unknown"

            if cityGroups[cityName] == nil {
                cityGroups[cityName] = (city: item.city, items: [])
                cityOrder.append(cityName)
            }
            cityGroups[cityName]?.items.append(item)
        }

        // Order: first city first, then others in order of appearance
        var result: [TRPTimelineCityGroup] = []

        // Add first city group
        if let firstGroup = cityGroups[firstCityName] {
            result.append(TRPTimelineCityGroup(city: firstGroup.city, items: firstGroup.items))
        }

        // Add other cities in order of appearance
        for cityName in cityOrder where cityName != firstCityName {
            if let group = cityGroups[cityName] {
                result.append(TRPTimelineCityGroup(city: group.city, items: group.items))
            }
        }

        return result
    }

    /// Get items grouped by city for a specific day index
    /// - Parameter dayIndex: Day index (0-based)
    /// - Returns: Array of city groups
    public func itemsGroupedByCity(forDayIndex dayIndex: Int) -> [TRPTimelineCityGroup] {
        guard dayIndex >= 0, dayIndex < availableDates.count else {
            return []
        }
        return itemsGroupedByCity(for: availableDates[dayIndex])
    }

    // MARK: - Utility Methods

    /// Check if timeline is empty
    public var isEmpty: Bool {
        return allItems.isEmpty
    }

    /// Get total number of items
    public var count: Int {
        return allItems.count
    }

    /// Get number of available days
    public var numberOfDays: Int {
        return availableDates.count
    }

    /// Check if there are multiple destinations in the timeline
    public var hasMultipleDestinations: Bool {
        var cityIds = Set<Int>()
        for item in allItems {
            if let cityId = item.city?.id {
                cityIds.insert(cityId)
                if cityIds.count > 1 {
                    return true
                }
            }
        }
        return false
    }

    /// Get all unique cities in the timeline
    public var allCities: [TRPCity] {
        var seenCityIds = Set<Int>()
        var cities: [TRPCity] = []

        for item in allItems {
            if let city = item.city, !seenCityIds.contains(city.id) {
                seenCityIds.insert(city.id)
                cities.append(city)
            }
        }

        return cities
    }

    /// Get all POIs for a specific date (for map display)
    /// - Parameter date: Target date
    /// - Returns: Array of POIs
    public func allPois(for date: Date) -> [TRPPoi] {
        let dayItems = items(for: date)
        var pois: [TRPPoi] = []

        for item in dayItems {
            pois.append(contentsOf: item.getAllPois())
        }

        return pois
    }

    /// Get all POIs grouped by segment for a specific date (for route calculation)
    /// - Parameter date: Target date
    /// - Returns: Array of POI arrays, each representing a segment
    public func poisGroupedBySegment(for date: Date) -> [[TRPPoi]] {
        let dayItems = items(for: date)
        var result: [[TRPPoi]] = []

        for item in dayItems {
            let itemPois = item.getAllPois()
            if !itemPois.isEmpty {
                result.append(itemPois)
            }
        }

        return result
    }

    /// Get item at a specific index path
    /// - Parameters:
    ///   - section: Section index
    ///   - row: Row index
    ///   - dayIndex: Current day index
    /// - Returns: Merged item or nil
    public func item(at section: Int, row: Int, forDayIndex dayIndex: Int) -> TRPMergedTimelineItem? {
        let groups = itemsGroupedByCity(forDayIndex: dayIndex)
        guard section < groups.count else { return nil }

        let groupItems = groups[section].items
        guard row < groupItems.count else { return nil }

        return groupItems[row]
    }

    /// Get booked/reserved activities for a specific date
    /// - Parameter date: Target date
    /// - Returns: Array of booked and reserved activity segments
    public func bookedActivities(for date: Date) -> [TRPTimelineSegment] {
        return items(for: date)
            .filter { $0.isBookedActivity || $0.isReservedActivity }
            .map { $0.segment }
    }

    /// Get all booked/reserved activities (for POI selection)
    /// - Returns: Array of all booked and reserved activity segments
    public var allBookedActivities: [TRPTimelineSegment] {
        return allItems
            .filter { $0.isBookedActivity || $0.isReservedActivity }
            .map { $0.segment }
    }

    /// Get count of reserved activities
    public var reservedActivitiesCount: Int {
        return allItems.filter { $0.isReservedActivity }.count
    }

    // MARK: - Modification

    /// Update with new items (rebuilds index)
    /// - Parameter items: New merged items
    public func update(with items: [TRPMergedTimelineItem]) {
        self.allItems = items
        self.buildDateIndex()
    }
}
