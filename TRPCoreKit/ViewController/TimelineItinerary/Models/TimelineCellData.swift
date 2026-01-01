//
//  TimelineCellData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

// MARK: - Protocol

/// Base protocol for all cell data types.
/// Provides segment index for API operations (DELETE/EDIT).
public protocol TimelineCellData {
    /// Original segment index for API operations (captured on first fetch)
    var segmentIndex: Int { get }
}

// MARK: - Booked/Reserved Activity Cell Data

/// Cell data for booked and reserved activity cells.
/// Contains all pre-computed display data from TRPMergedTimelineItem.
public struct BookedActivityCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Display Data
    public let title: String
    public let imageUrl: String?
    public let timeRange: String

    // MARK: - Activity State
    public let isReserved: Bool  // true = reserved (pending payment), false = booked (paid)

    // MARK: - Booking Info
    public let adultCount: Int
    public let childCount: Int
    public let duration: Double?  // Duration in minutes
    public let price: TRPSegmentActivityPrice?
    public let cancellation: String?

    // MARK: - Raw Data (for delegate callbacks)
    public let segment: TRPTimelineSegment

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        title: String,
        imageUrl: String?,
        timeRange: String,
        isReserved: Bool,
        adultCount: Int,
        childCount: Int,
        duration: Double?,
        price: TRPSegmentActivityPrice?,
        cancellation: String?,
        segment: TRPTimelineSegment
    ) {
        self.segmentIndex = segmentIndex
        self.title = title
        self.imageUrl = imageUrl
        self.timeRange = timeRange
        self.isReserved = isReserved
        self.adultCount = adultCount
        self.childCount = childCount
        self.duration = duration
        self.price = price
        self.cancellation = cancellation
        self.segment = segment
    }

    /// Create from TRPMergedTimelineItem
    public init(from item: TRPMergedTimelineItem) {
        self.segmentIndex = item.originalSegmentIndex
        self.title = item.title ?? ""
        self.imageUrl = item.imageUrl
        self.timeRange = item.timeRangeString ?? ""
        self.isReserved = item.isReservedActivity
        self.adultCount = item.adultCount
        self.childCount = item.childCount
        self.duration = item.duration
        self.price = item.price
        self.cancellation = item.cancellation
        self.segment = item.segment
    }
}

// MARK: - Manual POI Cell Data

/// Cell data for manual POI cells.
/// Contains all pre-computed display data from TRPMergedTimelineItem.
public struct ManualPoiCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Display Data
    public let title: String
    public let imageUrl: String?
    public let timeRange: String

    // MARK: - POI Info
    public let rating: Float?
    public let ratingCount: Int?
    public let categoryName: String?

    // MARK: - Raw Data (for delegate callbacks and navigation)
    public let segment: TRPTimelineSegment
    public let poi: TRPPoi?

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        title: String,
        imageUrl: String?,
        timeRange: String,
        rating: Float?,
        ratingCount: Int?,
        categoryName: String?,
        segment: TRPTimelineSegment,
        poi: TRPPoi?
    ) {
        self.segmentIndex = segmentIndex
        self.title = title
        self.imageUrl = imageUrl
        self.timeRange = timeRange
        self.rating = rating
        self.ratingCount = ratingCount
        self.categoryName = categoryName
        self.segment = segment
        self.poi = poi
    }

    /// Create from TRPMergedTimelineItem
    public init(from item: TRPMergedTimelineItem) {
        self.segmentIndex = item.originalSegmentIndex
        self.title = item.manualPoi?.name ?? item.title ?? ""
        self.imageUrl = item.manualPoi?.image?.url ?? item.imageUrl
        self.timeRange = item.timeRangeString ?? ""
        self.rating = item.manualPoi?.rating
        self.ratingCount = item.manualPoi?.ratingCount
        self.categoryName = item.manualPoi?.categories.first?.name
        self.segment = item.segment
        self.poi = item.manualPoi
    }
}

// MARK: - Recommendations Cell Data

/// Cell data for recommendations/itinerary cells.
/// Contains all pre-computed display data from TRPMergedTimelineItem.
public struct RecommendationsCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Display Data
    public let title: String
    public let steps: [TRPTimelineStep]
    public var isExpanded: Bool

    // MARK: - Raw Data (for delegate callbacks)
    public let segment: TRPTimelineSegment

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        title: String,
        steps: [TRPTimelineStep],
        isExpanded: Bool,
        segment: TRPTimelineSegment
    ) {
        self.segmentIndex = segmentIndex
        self.title = title
        self.steps = steps
        self.isExpanded = isExpanded
        self.segment = segment
    }

    /// Create from TRPMergedTimelineItem
    public init(from item: TRPMergedTimelineItem, isExpanded: Bool = true) {
        self.segmentIndex = item.originalSegmentIndex
        self.title = item.title ?? "Recommendations"
        self.steps = item.steps
        self.isExpanded = isExpanded
        self.segment = item.segment
    }
}

// MARK: - Activity Step Cell Data

/// Cell data for individual activity step cells.
/// Used when activity steps are displayed separately from recommendations.
public struct ActivityStepCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Display Data
    public let title: String
    public let imageUrl: String?
    public let timeRange: String

    // MARK: - Activity Info
    public let duration: String?
    public let price: String?
    public let cancellation: String?

    // MARK: - Raw Data (for delegate callbacks)
    public let step: TRPTimelineStep
    public let segment: TRPTimelineSegment

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        title: String,
        imageUrl: String?,
        timeRange: String,
        duration: String?,
        price: String?,
        cancellation: String?,
        step: TRPTimelineStep,
        segment: TRPTimelineSegment
    ) {
        self.segmentIndex = segmentIndex
        self.title = title
        self.imageUrl = imageUrl
        self.timeRange = timeRange
        self.duration = duration
        self.price = price
        self.cancellation = cancellation
        self.step = step
        self.segment = segment
    }
}

// MARK: - Unified Cell Type Enum

/// Unified cell type for timeline display.
/// Each case contains pre-computed cell data ready for display.
public enum TimelineCellType {
    /// Booked activity (paid, confirmed)
    case bookedActivity(BookedActivityCellData)

    /// Reserved activity (pending payment)
    case reservedActivity(BookedActivityCellData)

    /// Manual POI added by user
    case manualPoi(ManualPoiCellData)

    /// Individual activity step (from recommendations)
    case activityStep(ActivityStepCellData)

    /// AI recommendations (grouped POI steps)
    case recommendations(RecommendationsCellData)

    /// Empty state (no items for selected day)
    case emptyState

    // MARK: - Convenience Properties

    /// Get the segment index for API operations
    public var segmentIndex: Int? {
        switch self {
        case .bookedActivity(let data): return data.segmentIndex
        case .reservedActivity(let data): return data.segmentIndex
        case .manualPoi(let data): return data.segmentIndex
        case .activityStep(let data): return data.segmentIndex
        case .recommendations(let data): return data.segmentIndex
        case .emptyState: return nil
        }
    }

    /// Get the raw segment for delegate callbacks
    public var segment: TRPTimelineSegment? {
        switch self {
        case .bookedActivity(let data): return data.segment
        case .reservedActivity(let data): return data.segment
        case .manualPoi(let data): return data.segment
        case .activityStep(let data): return data.segment
        case .recommendations(let data): return data.segment
        case .emptyState: return nil
        }
    }
}

// MARK: - Factory Method

extension TimelineCellType {

    /// Create TimelineCellType from TRPMergedTimelineItem
    /// - Parameters:
    ///   - item: The merged timeline item
    ///   - isExpanded: Whether recommendations cell should be expanded (default: true)
    /// - Returns: Appropriate TimelineCellType for the item's segment type
    public static func from(_ item: TRPMergedTimelineItem, isExpanded: Bool = true) -> TimelineCellType {
        switch item.segmentType {
        case .bookedActivity:
            return .bookedActivity(BookedActivityCellData(from: item))

        case .reservedActivity:
            return .reservedActivity(BookedActivityCellData(from: item))

        case .manualPoi:
            return .manualPoi(ManualPoiCellData(from: item))

        case .itinerary:
            return .recommendations(RecommendationsCellData(from: item, isExpanded: isExpanded))
        }
    }
}
