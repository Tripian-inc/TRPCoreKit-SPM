//
//  TRPTimelineItineraryViewModel+TableViewData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - TableView data source methods extracted from main ViewModel
//

import Foundation
import TRPFoundationKit

// MARK: - TableView Data Methods

extension TRPTimelineItineraryViewModel {

    /// Get number of sections
    public func numberOfSections() -> Int {
        guard hasLoadedData else { return 0 }
        return displayItems.isEmpty ? 1 : displayItems.count
    }

    /// Get number of rows in section
    public func numberOfRows(in section: Int) -> Int {
        if displayItems.isEmpty { return 1 }
        guard section < displayItems.count else { return 0 }
        return displayItems[section].items.count
    }

    /// Get cell type at index path (returns TimelineCellType with pre-computed CellData)
    public func cellType(at indexPath: IndexPath) -> TimelineCellType? {
        // Empty state
        if displayItems.isEmpty {
            return .emptyState
        }

        guard indexPath.section < displayItems.count else { return nil }

        let cityGroup = displayItems[indexPath.section]
        guard indexPath.row < cityGroup.items.count else { return nil }

        let mergedItem = cityGroup.items[indexPath.row]
        let isExpanded = getSectionCollapseState(for: indexPath.section)

        // Get unified order from map (default to 1 if not found)
        // Key format: "sectionIndex_segmentIndex"
        let key = "\(indexPath.section)_\(mergedItem.originalSegmentIndex)"
        let order = unifiedOrderMap[key] ?? 1

        return TimelineCellType.from(mergedItem, order: order, isExpanded: isExpanded)
    }

    /// Get merged item at index path (for delegate callbacks and navigation)
    public func getMergedItem(at indexPath: IndexPath) -> TRPMergedTimelineItem? {
        guard indexPath.section < displayItems.count else { return nil }

        let cityGroup = displayItems[indexPath.section]
        guard indexPath.row < cityGroup.items.count else { return nil }

        return cityGroup.items[indexPath.row]
    }

    /// Get section header data
    public func headerData(for section: Int) -> TRPTimelineSectionHeaderData {
        if displayItems.isEmpty {
            return TRPTimelineSectionHeaderData(
                cityName: "",
                isFirstSection: false,
                shouldShowHeader: false,
                hasMultipleDestinations: false
            )
        }

        let isFirstSection = section == 0
        let hasMultipleDests = mergedTimeline?.hasMultipleDestinations ?? false

        guard section < displayItems.count else {
            return TRPTimelineSectionHeaderData(
                cityName: "",
                isFirstSection: isFirstSection,
                shouldShowHeader: false,
                hasMultipleDestinations: hasMultipleDests
            )
        }

        let unknownText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.unknown)
        let cityName = displayItems[section].city?.name ?? unknownText

        // Show header when city changes
        var shouldShowHeader = isFirstSection
        if hasMultipleDests && !isFirstSection && section > 0 {
            let previousCityName = displayItems[section - 1].city?.name ?? unknownText
            shouldShowHeader = (cityName != previousCityName)
        }

        return TRPTimelineSectionHeaderData(
            cityName: cityName,
            isFirstSection: isFirstSection,
            shouldShowHeader: shouldShowHeader,
            hasMultipleDestinations: hasMultipleDests
        )
    }

    /// Get segment index for API operations (DELETE/EDIT)
    public func getSegmentIndex(at indexPath: IndexPath) -> Int? {
        guard let item = getMergedItem(at: indexPath) else { return nil }
        return item.originalSegmentIndex >= 0 ? item.originalSegmentIndex : nil
    }

    /// Get all trip dates (for day filter - continuous from start to end)
    public func getAvailableDates() -> [Date] {
        return allTripDates
    }
}
