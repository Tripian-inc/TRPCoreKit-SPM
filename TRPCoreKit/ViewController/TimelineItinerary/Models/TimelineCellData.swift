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

public protocol TimelineCellData {
    /// Segment index for API operations (captured on first fetch)
    var segmentIndex: Int { get }
}

// MARK: - Booked/Reserved Activity Cell Data

public struct BookedActivityCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Order
    public let order: Int

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

    // MARK: - Rating
    public let rating: Float?
    public let ratingCount: Int?

    // MARK: - Location
    /// `true` when the activity has no precise coordinate (segment uses the city fallback). Drives the "No exact location" tag.
    public let isNoLocation: Bool

    // MARK: - Raw Data (for delegate callbacks)
    public let segment: TRPTimelineSegment

    // MARK: - Conflict Detection
    public var hasConflict: Bool = false
    /// Booked-activity cells hard-code this to false; reserved-activity cells honour it.
    public var showTimeOverlapText: Bool = false

    // MARK: - Availability
    /// Set by the post-load availability sweep when the provider no longer offers the scheduled slot.
    public var isAvailabilityExpired: Bool = false

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        order: Int,
        title: String,
        imageUrl: String?,
        timeRange: String,
        isReserved: Bool,
        adultCount: Int,
        childCount: Int,
        duration: Double?,
        price: TRPSegmentActivityPrice?,
        cancellation: String?,
        rating: Float? = nil,
        ratingCount: Int? = nil,
        isNoLocation: Bool = false,
        segment: TRPTimelineSegment,
        hasConflict: Bool = false,
        showTimeOverlapText: Bool = false,
        isAvailabilityExpired: Bool = false
    ) {
        self.segmentIndex = segmentIndex
        self.order = order
        self.title = title
        self.imageUrl = imageUrl
        self.timeRange = timeRange
        self.isReserved = isReserved
        self.adultCount = adultCount
        self.childCount = childCount
        self.duration = duration
        self.price = price
        self.cancellation = cancellation
        self.rating = rating
        self.ratingCount = ratingCount
        self.isNoLocation = isNoLocation
        self.segment = segment
        self.hasConflict = hasConflict
        self.showTimeOverlapText = showTimeOverlapText
        self.isAvailabilityExpired = isAvailabilityExpired
    }

    public init(from item: TRPMergedTimelineItem, order: Int) {
        self.segmentIndex = item.originalSegmentIndex
        self.order = order
        self.title = item.title ?? ""
        self.imageUrl = item.imageUrl
        self.timeRange = item.timeRangeString ?? ""
        self.isReserved = item.isReservedActivity
        self.adultCount = item.adultCount
        self.childCount = item.childCount
        self.duration = item.duration
        self.price = item.price
        self.cancellation = item.cancellation
        self.rating = item.rating
        self.ratingCount = item.ratingCount
        self.isNoLocation = item.isNoLocation
        self.segment = item.segment
        self.hasConflict = item.hasConflict
        self.showTimeOverlapText = item.showTimeOverlapText
        self.isAvailabilityExpired = item.isAvailabilityExpired
    }
}

// MARK: - Flexible Activity Cell Data

/// Reserved activities (duration == -1, times in {00:00, 23:59}). No order number, pinned to top of day.
public struct FlexibleActivityCellData: TimelineCellData {
    public let segmentIndex: Int
    public let title: String
    public let imageUrl: String?
    public let adultCount: Int
    public let childCount: Int
    public let duration: Double?
    public let price: TRPSegmentActivityPrice?
    public let cancellation: String?
    public let rating: Float?
    public let ratingCount: Int?
    public let isNoLocation: Bool
    public let segment: TRPTimelineSegment

    public init(from item: TRPMergedTimelineItem) {
        self.segmentIndex = item.originalSegmentIndex
        self.title = item.title ?? ""
        self.imageUrl = item.imageUrl
        self.adultCount = item.adultCount
        self.childCount = item.childCount
        self.duration = item.duration
        self.price = item.price
        self.cancellation = item.cancellation
        self.rating = item.rating
        self.ratingCount = item.ratingCount
        self.isNoLocation = item.isNoLocation
        self.segment = item.segment
    }
}

// MARK: - Manual POI Cell Data

public struct ManualPoiCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Order
    public let order: Int

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

    // MARK: - Conflict Detection
    public var hasConflict: Bool = false
    public var showTimeOverlapText: Bool = false

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        order: Int,
        title: String,
        imageUrl: String?,
        timeRange: String,
        rating: Float?,
        ratingCount: Int?,
        categoryName: String?,
        segment: TRPTimelineSegment,
        poi: TRPPoi?,
        hasConflict: Bool = false,
        showTimeOverlapText: Bool = false
    ) {
        self.segmentIndex = segmentIndex
        self.order = order
        self.title = title
        self.imageUrl = imageUrl
        self.timeRange = timeRange
        self.rating = rating
        self.ratingCount = ratingCount
        self.categoryName = categoryName
        self.segment = segment
        self.poi = poi
        self.hasConflict = hasConflict
        self.showTimeOverlapText = showTimeOverlapText
    }

    public init(from item: TRPMergedTimelineItem, order: Int) {
        self.segmentIndex = item.originalSegmentIndex
        self.order = order
        self.title = item.manualPoi?.name ?? item.title ?? ""
        self.imageUrl = item.manualPoi?.image?.url ?? item.imageUrl
        self.timeRange = item.timeRangeString ?? ""
        self.rating = item.manualPoi?.rating
        self.ratingCount = item.manualPoi?.ratingCount
        self.categoryName = item.manualPoi?.categories.first?.name
        self.segment = item.segment
        self.poi = item.manualPoi
        self.hasConflict = item.hasConflict
        self.showTimeOverlapText = item.showTimeOverlapText
    }
}

// MARK: - Recommendations Cell Data

public struct RecommendationsCellData: TimelineCellData {
    // MARK: - Core
    public let segmentIndex: Int

    // MARK: - Order
    /// Starting order for first step; each subsequent step uses startingOrder + stepIndex.
    public let startingOrder: Int

    // MARK: - Display Data
    public let title: String
    public let steps: [TRPTimelineStep]
    public var isExpanded: Bool

    // MARK: - Location Data
    /// City for this segment; used for city-center fallback when accommodation is nil.
    public let city: TRPCity?

    // MARK: - Raw Data (for delegate callbacks)
    public let segment: TRPTimelineSegment

    // MARK: - Initialization

    public init(
        segmentIndex: Int,
        startingOrder: Int,
        title: String,
        steps: [TRPTimelineStep],
        isExpanded: Bool,
        segment: TRPTimelineSegment,
        city: TRPCity? = nil
    ) {
        self.segmentIndex = segmentIndex
        self.startingOrder = startingOrder
        self.title = title
        self.steps = steps
        self.isExpanded = isExpanded
        self.segment = segment
        self.city = city ?? segment.city
    }

    /// For itinerary segments, use the customTitle init for dynamic numbering.
    public init(from item: TRPMergedTimelineItem, startingOrder: Int, isExpanded: Bool = true) {
        self.segmentIndex = item.originalSegmentIndex
        self.startingOrder = startingOrder
        self.title = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.recommendations)
        self.steps = item.steps
        self.isExpanded = isExpanded
        self.segment = item.segment
        self.city = item.city
    }

    public init(from item: TRPMergedTimelineItem, startingOrder: Int, isExpanded: Bool = true, customTitle: String) {
        self.segmentIndex = item.originalSegmentIndex
        self.startingOrder = startingOrder
        self.title = customTitle
        self.steps = item.steps
        self.isExpanded = isExpanded
        self.segment = item.segment
        self.city = item.city
    }
}

// MARK: - Activity Step Cell Data

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

// MARK: - Flat Timeline Cell Data

/// Starting point row of the flat timeline (accommodation or city centre).
public struct StartingPointCellData: TimelineCellData {
    public let segmentIndex: Int
    public let name: String
    public let segment: TRPTimelineSegment

    public init(segmentIndex: Int, name: String, segment: TRPTimelineSegment) {
        self.segmentIndex = segmentIndex
        self.name = name
        self.segment = segment
    }
}

/// Route leg between two consecutive located rows of the flat timeline.
public struct RouteSeparatorCellData {
    /// Kilometers, one decimal.
    public let distance: Float
    public let minutes: Int
    public let isWalking: Bool

    public init(distance: Float, minutes: Int, isWalking: Bool) {
        self.distance = distance
        self.minutes = minutes
        self.isWalking = isWalking
    }
}

/// One itinerary plan step listed at the top level of the flat timeline.
public struct PlanStepCellData: TimelineCellData {
    public let segmentIndex: Int
    public let order: Int
    public let step: TRPTimelineStep
    public let segment: TRPTimelineSegment

    public init(segmentIndex: Int, order: Int, step: TRPTimelineStep, segment: TRPTimelineSegment) {
        self.segmentIndex = segmentIndex
        self.order = order
        self.step = step
        self.segment = segment
    }
}

// MARK: - Unified Cell Type Enum

public enum TimelineCellType {
    case bookedActivity(BookedActivityCellData)
    case reservedActivity(BookedActivityCellData)
    /// Reserved activity with a flexible-time slot (no specific start time, pinned to top).
    case flexibleActivity(FlexibleActivityCellData)
    case manualPoi(ManualPoiCellData)
    case activityStep(ActivityStepCellData)
    case recommendations(RecommendationsCellData)
    case startingPoint(StartingPointCellData)
    case routeSeparator(RouteSeparatorCellData)
    case planStep(PlanStepCellData)
    case emptyState

    // MARK: - Convenience Properties

    public var segmentIndex: Int? {
        switch self {
        case .bookedActivity(let data): return data.segmentIndex
        case .reservedActivity(let data): return data.segmentIndex
        case .flexibleActivity(let data): return data.segmentIndex
        case .manualPoi(let data): return data.segmentIndex
        case .activityStep(let data): return data.segmentIndex
        case .recommendations(let data): return data.segmentIndex
        case .startingPoint(let data): return data.segmentIndex
        case .planStep(let data): return data.segmentIndex
        case .routeSeparator, .emptyState: return nil
        }
    }

    public var segment: TRPTimelineSegment? {
        switch self {
        case .bookedActivity(let data): return data.segment
        case .reservedActivity(let data): return data.segment
        case .flexibleActivity(let data): return data.segment
        case .manualPoi(let data): return data.segment
        case .activityStep(let data): return data.segment
        case .recommendations(let data): return data.segment
        case .startingPoint(let data): return data.segment
        case .planStep(let data): return data.segment
        case .routeSeparator, .emptyState: return nil
        }
    }
}

// MARK: - Factory Method

extension TimelineCellType {

    /// `order` is the unified day order for booked/reserved/manualPoi, or starting order for recommendations.
    public static func from(_ item: TRPMergedTimelineItem, order: Int, isExpanded: Bool = true) -> TimelineCellType {
        switch item.segmentType {
        case .bookedActivity:
            return .bookedActivity(BookedActivityCellData(from: item, order: order))

        case .reservedActivity:
            if item.isFlexibleActivity {
                return .flexibleActivity(FlexibleActivityCellData(from: item))
            }
            return .reservedActivity(BookedActivityCellData(from: item, order: order))

        case .manualPoi:
            return .manualPoi(ManualPoiCellData(from: item, order: order))

        case .itinerary:
            return .recommendations(RecommendationsCellData(from: item, startingOrder: order, isExpanded: isExpanded))
        }
    }
}
