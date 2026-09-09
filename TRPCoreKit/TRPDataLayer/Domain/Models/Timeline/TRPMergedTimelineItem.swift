//
//  TRPMergedTimelineItem.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// Unified timeline item that merges segment + plan + original index.
/// This is the SINGLE SOURCE OF TRUTH for timeline display.
///
/// Usage:
/// - `segment`: Contains metadata, additionalData for booked/reserved activities
/// - `plan`: Contains steps for itinerary segments, nil for booked/reserved
/// - `originalSegmentIndex`: Used for DELETE/EDIT API operations
///
/// Data Access by Segment Type:
/// - bookedActivity/reservedActivity: Use `segment.additionalData` for all data
/// - manualPoi: Use `manualPoi` computed property (from plan.steps[0].poi)
/// - itinerary: Use `steps` computed property (from plan.steps)
public class TRPMergedTimelineItem {

    // MARK: - Core Data (Stored)

    /// The segment from tripProfile.segments - SINGLE SOURCE OF TRUTH for metadata
    public let segment: TRPTimelineSegment

    /// The matching plan (nil for booked/reserved activities)
    /// NOTE: Mutable to allow updating step conflict flags
    public var plan: TRPTimelinePlan?

    /// Original index in tripProfile.segments array (for API operations)
    /// This index is captured on FIRST fetch and remains constant
    public let originalSegmentIndex: Int

    // MARK: - Conflict Detection

    /// Whether this item has a time conflict with another item on the same day
    public var hasConflict: Bool = false

    /// Whether to show "Time Overlap" text (false for BookedActivity)
    public var showTimeOverlapText: Bool = false

    // MARK: - Availability

    /// Mirror of `segment.additionalData?.isAvailabilityExpired` for reserved-activity
    /// items, so cells can read it through the merged item without dereferencing the
    /// segment's optional additional data. Always `false` for booked-activity items
    /// and segments without additional data — the post-load sweep doesn't touch those.
    public var isAvailabilityExpired: Bool {
        return segment.additionalData?.isAvailabilityExpired ?? false
    }

    // MARK: - Initialization

    public init(segment: TRPTimelineSegment, plan: TRPTimelinePlan?, originalSegmentIndex: Int) {
        self.segment = segment
        self.plan = plan
        self.originalSegmentIndex = originalSegmentIndex
    }

    // MARK: - Computed Properties (Type)

    /// Segment type for easy switching
    public var segmentType: TRPTimelineSegmentType {
        return segment.segmentType
    }

    /// Check if this is a booked activity
    public var isBookedActivity: Bool {
        return segmentType == .bookedActivity
    }

    /// Check if this is a reserved activity
    public var isReservedActivity: Bool {
        return segmentType == .reservedActivity
    }

    /// Check if this is a manual POI
    public var isManualPoi: Bool {
        return segmentType == .manualPoi
    }

    /// Check if this is an itinerary (recommendations)
    public var isItinerary: Bool {
        return segmentType == .itinerary
    }

    /// Check if this reserved activity was created with a flexible-time slot.
    /// Detection: reservedActivity + additionalData.duration == -1 + start/end time in {00:00, 23:59}.
    public var isFlexibleActivity: Bool {
        guard segmentType == .reservedActivity else { return false }
        guard let duration = segment.additionalData?.duration, duration == -1 else { return false }

        let flexibleTimes: Set<String> = ["00:00", "23:59"]
        let startStr = segment.additionalData?.startDatetime ?? segment.startDate
        let endStr = segment.additionalData?.endDatetime ?? segment.endDate

        guard let startTime = TRPDateHelper.extractTimeString(startStr),
              let endTime = TRPDateHelper.extractTimeString(endStr) else {
            return false
        }
        return flexibleTimes.contains(startTime) && flexibleTimes.contains(endTime)
    }

    // MARK: - Computed Properties (Dates)

    /// Definitive start date (from segment, using additionalData if available)
    public var startDate: Date? {
        let dateStr = segment.additionalData?.startDatetime ?? segment.startDate
        return TRPDateHelper.parseDateTime(dateStr)
    }

    /// Definitive end date (from segment, using additionalData if available)
    public var endDate: Date? {
        let dateStr = segment.additionalData?.endDatetime ?? segment.endDate
        return TRPDateHelper.parseDateTime(dateStr)
    }

    /// Date-only string for grouping/filtering (yyyy-MM-dd)
    public var dateString: String? {
        let dateStr = segment.additionalData?.startDatetime ?? segment.startDate
        return TRPDateHelper.extractDateString(dateStr)
    }

    /// Formatted time range string (e.g., "10:00 - 12:00")
    public var timeRangeString: String? {
        let startStr = segment.additionalData?.startDatetime ?? segment.startDate
        let endStr = segment.additionalData?.endDatetime ?? segment.endDate
        return TRPDateHelper.formatTimeRange(fromString: startStr, toString: endStr)
    }

    // MARK: - Computed Properties (Location)

    /// City for this item (from plan or segment)
    public var city: TRPCity? {
        return plan?.city ?? segment.city
    }

    /// Coordinate for this item
    public var coordinate: TRPLocation? {
        if let additionalData = segment.additionalData {
            return additionalData.coordinate
        }
        return segment.coordinate ?? plan?.steps.first?.poi?.coordinate
    }

    // MARK: - Computed Properties (Display)

    /// Title (from additionalData, segment, or plan)
    public var title: String? {
        return segment.additionalData?.title ?? segment.title ?? plan?.name
    }

    /// Image URL (from additionalData or first POI)
    public var imageUrl: String? {
        if let additionalData = segment.additionalData {
            return additionalData.imageUrl
        }
        return plan?.steps.first?.poi?.image?.url
    }

    // MARK: - Computed Properties (Content)

    /// Steps (only for itinerary segments)
    public var steps: [TRPTimelineStep] {
        return plan?.steps ?? []
    }

    /// POI for manual POI segments (from plan's first step)
    public var manualPoi: TRPPoi? {
        guard segmentType == .manualPoi else { return nil }
        return plan?.steps.first?.poi
    }

    /// Additional data for booked/reserved activities
    public var activityData: TRPSegmentActivityItem? {
        return segment.additionalData
    }

    // MARK: - Computed Properties (Booking Info)

    /// Adult count (from additionalData or segment)
    public var adultCount: Int {
        return segment.additionalData?.adultCount ?? segment.adults
    }

    /// Child count (from additionalData or segment)
    public var childCount: Int {
        return segment.additionalData?.childCount ?? segment.children
    }

    /// Duration in minutes (from additionalData or calculated from start/end times)
    public var duration: Double? {
        // 1. First check additionalData.duration
        if let existingDuration = segment.additionalData?.duration, existingDuration > 0 {
            return existingDuration
        }

        // 2. Calculate from startDatetime and endDatetime
        guard let startDate = startDate,
              let endDate = endDate else {
            return nil
        }

        // Calculate difference in minutes
        let minutes = endDate.timeIntervalSince(startDate) / 60.0
        return minutes > 0 ? minutes : nil
    }

    /// Price information (from additionalData)
    public var price: TRPSegmentActivityPrice? {
        return segment.additionalData?.price
    }

    /// Average rating (from additionalData)
    public var rating: Float? {
        return segment.additionalData?.rating
    }

    /// Number of ratings backing `rating` (from additionalData)
    public var ratingCount: Int? {
        return segment.additionalData?.ratingCount
    }

    /// `true` when the activity was created without a precise coordinate and
    /// uses the city's coordinate as a fallback. Drives the "no exact location"
    /// tag in the cell and excludes the item from map annotations.
    public var isNoLocation: Bool {
        return segment.additionalData?.isNoLocation ?? false
    }

    /// Cancellation policy text (from additionalData)
    public var cancellation: String? {
        return segment.additionalData?.cancellation
    }

    /// Activity ID (from additionalData)
    public var activityId: String? {
        return segment.additionalData?.activityId
    }

    /// Booking ID (from additionalData)
    public var bookingId: String? {
        return segment.additionalData?.bookingId
    }

    // MARK: - Computed Properties (Identification)

    /// Unique identifier for deduplication
    public var uniqueId: String {
        if let bookingId = segment.additionalData?.bookingId {
            return "booking_\(bookingId)"
        }
        if let activityId = segment.additionalData?.activityId,
           let dateStr = dateString {
            return "activity_\(activityId)_\(dateStr)"
        }
        if let startDate = segment.startDate, let title = segment.title {
            return "segment_\(startDate)_\(title)"
        }
        return "segment_\(originalSegmentIndex)"
    }

    // MARK: - Helper Methods

    /// Check if this item falls on a specific date
    /// - Parameter date: Target date to check
    /// - Returns: true if item is on the target date
    public func isOnDate(_ date: Date) -> Bool {
        guard let itemDateStr = dateString else { return false }
        let targetDateStr = TRPDateHelper.formatDateString(date)
        return itemDateStr == targetDateStr
    }

    /// Get all POIs from this item (for map display)
    /// - Returns: Array of POIs
    public func getAllPois() -> [TRPPoi] {
        switch segmentType {
        case .bookedActivity, .reservedActivity:
            // Booked/reserved activities don't have POIs for map
            return []

        case .manualPoi:
            if let poi = manualPoi {
                return [poi]
            }
            return []

        case .itinerary:
            return steps.compactMap { $0.poi }
        }
    }
}

// MARK: - Equatable
extension TRPMergedTimelineItem: Equatable {
    public static func == (lhs: TRPMergedTimelineItem, rhs: TRPMergedTimelineItem) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }
}

// MARK: - Hashable
extension TRPMergedTimelineItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }
}
