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

    public func numberOfSections() -> Int {
        guard hasLoadedData else { return 0 }
        if usesFlatTimeline {
            return flatSections.isEmpty ? 1 : flatSections.count
        }
        return displayItems.isEmpty ? 1 : displayItems.count
    }

    public func numberOfRows(in section: Int) -> Int {
        if usesFlatTimeline {
            if flatSections.isEmpty { return 1 }
            guard section < flatSections.count else { return 0 }
            return flatSections[section].rows.count
        }
        if displayItems.isEmpty { return 1 }
        guard section < displayItems.count else { return 0 }
        return displayItems[section].items.count
    }

    public func cellType(at indexPath: IndexPath) -> TimelineCellType? {
        if usesFlatTimeline {
            return flatCellType(at: indexPath)
        }

        if displayItems.isEmpty {
            return .emptyState
        }

        guard indexPath.section < displayItems.count else { return nil }

        let cityGroup = displayItems[indexPath.section]
        guard indexPath.row < cityGroup.items.count else { return nil }

        let mergedItem = cityGroup.items[indexPath.row]
        let isExpanded = getSectionCollapseState(for: indexPath.section)

        // Key format: "sectionIndex_segmentIndex"
        let key = "\(indexPath.section)_\(mergedItem.originalSegmentIndex)"
        let order = unifiedOrderMap[key] ?? 1

        if mergedItem.segmentType == .itinerary {
            let recommendationNumber = getRecommendationNumber(for: indexPath)
            let dynamicTitle = generateRecommendationTitle(number: recommendationNumber)
            return .recommendations(RecommendationsCellData(
                from: mergedItem,
                startingOrder: order,
                isExpanded: isExpanded,
                customTitle: dynamicTitle
            ))
        }

        return TimelineCellType.from(mergedItem, order: order, isExpanded: isExpanded)
    }

    private func flatCellType(at indexPath: IndexPath) -> TimelineCellType? {
        if flatSections.isEmpty {
            return .emptyState
        }
        guard let row = flatRow(at: indexPath) else { return nil }

        switch row {
        case .flexibleActivity(let item):
            return .flexibleActivity(FlexibleActivityCellData(from: item))

        case .startingPoint(let name, _, let item):
            return .startingPoint(StartingPointCellData(segmentIndex: item.originalSegmentIndex, name: name, segment: item.segment))

        case .routeSeparator(let routeInfo, _):
            return .routeSeparator(RouteSeparatorCellData(distance: routeInfo.distance, minutes: routeInfo.time, isWalking: routeInfo.isWalking))

        case .bookedActivity(let item, let order):
            let cellData = BookedActivityCellData(from: item, order: order)
            return item.isReservedActivity ? .reservedActivity(cellData) : .bookedActivity(cellData)

        case .manualPoi(let item, let order):
            return .manualPoi(ManualPoiCellData(from: item, order: order))

        case .planStep(let item, _, let order):
            guard let step = row.step else { return nil }
            return .planStep(PlanStepCellData(segmentIndex: item.originalSegmentIndex, order: order, step: step, segment: item.segment))
        }
    }

    public func getMergedItem(at indexPath: IndexPath) -> TRPMergedTimelineItem? {
        if usesFlatTimeline {
            return flatRow(at: indexPath)?.item
        }

        guard indexPath.section < displayItems.count else { return nil }

        let cityGroup = displayItems[indexPath.section]
        guard indexPath.row < cityGroup.items.count else { return nil }

        return cityGroup.items[indexPath.row]
    }

    public func headerData(for section: Int) -> TRPTimelineSectionHeaderData {
        let sectionCities: [TRPCity?] = usesFlatTimeline ? flatSections.map { $0.city } : displayItems.map { $0.city }

        if sectionCities.isEmpty {
            return TRPTimelineSectionHeaderData(
                cityName: "",
                isFirstSection: false,
                shouldShowHeader: false,
                hasMultipleDestinations: false
            )
        }

        let isFirstSection = section == 0
        let hasMultipleDests = mergedTimeline?.hasMultipleDestinations ?? false

        guard section < sectionCities.count else {
            return TRPTimelineSectionHeaderData(
                cityName: "",
                isFirstSection: isFirstSection,
                shouldShowHeader: false,
                hasMultipleDestinations: hasMultipleDests
            )
        }

        let unknownText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.unknown)
        let cityName = sectionCities[section]?.name ?? unknownText

        // Show a header only when the city changes.
        var shouldShowHeader = isFirstSection
        if hasMultipleDests && !isFirstSection && section > 0 {
            let previousCityName = sectionCities[section - 1]?.name ?? unknownText
            shouldShowHeader = (cityName != previousCityName)
        }

        return TRPTimelineSectionHeaderData(
            cityName: cityName,
            isFirstSection: isFirstSection,
            shouldShowHeader: shouldShowHeader,
            hasMultipleDestinations: hasMultipleDests
        )
    }

    public func getSegmentIndex(at indexPath: IndexPath) -> Int? {
        guard let item = getMergedItem(at: indexPath) else { return nil }
        return item.originalSegmentIndex >= 0 ? item.originalSegmentIndex : nil
    }

    public func getAvailableDates() -> [Date] {
        return allTripDates
    }

    // MARK: - Dynamic Recommendation Title

    /// Counts itinerary items up to and including this one across the day's sections.
    private func getRecommendationNumber(for indexPath: IndexPath) -> Int {
        var count = 0

        for sectionIndex in 0...indexPath.section {
            guard sectionIndex < displayItems.count else { break }
            let cityGroup = displayItems[sectionIndex]
            let maxRow = (sectionIndex == indexPath.section) ? indexPath.row : cityGroup.items.count - 1

            for rowIndex in 0...maxRow {
                guard rowIndex < cityGroup.items.count else { break }
                if cityGroup.items[rowIndex].segmentType == .itinerary {
                    count += 1
                }
            }
        }

        return count
    }

    /// 1 → "Recommendations", 2 → "Recommendations 2", etc.
    private func generateRecommendationTitle(number: Int) -> String {
        let localizedBase = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.recommendations)

        if number <= 1 {
            return localizedBase
        }

        return localizedBase + " " + String(number)
    }
}
