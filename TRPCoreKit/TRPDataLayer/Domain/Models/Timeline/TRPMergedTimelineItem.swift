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

    /// Check if this activity has a flexible-time slot: additionalData.duration == -1 + start time, and end time
    /// when present, in {00:00, 23:59}. A booked activity without a start time is flexible as well.
    public var isFlexibleActivity: Bool {
        switch segmentType {
        case .reservedActivity:
            return hasFlexibleSlotTimes
        case .bookedActivity:
            return hasFlexibleSlotTimes || timeRangeString == nil
        default:
            return false
        }
    }

    private var hasFlexibleSlotTimes: Bool {
        guard let duration = segment.additionalData?.duration, duration == -1 else { return false }

        let flexibleTimes: Set<String> = ["00:00", "23:59"]
        let startStr = segment.additionalData?.startDatetime ?? segment.startDate
        let endStr = segment.additionalData?.endDatetime ?? segment.endDate

        guard let startTime = TRPDateHelper.extractTimeString(startStr), flexibleTimes.contains(startTime) else {
            return false
        }
        guard let endTime = TRPDateHelper.extractTimeString(endStr) else { return true }
        return flexibleTimes.contains(endTime)
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

    /// End used for overlap checks: the end time, or the start plus a positive `additionalData.duration` when no end time was sent.
    public var occupiedEndDate: Date? {
        if let endDate = endDate { return endDate }
        guard let startDate = startDate, let minutes = segment.additionalData?.duration, minutes > 0 else { return nil }
        return startDate.addingTimeInterval(minutes * 60)
    }

    /// Date-only string for grouping/filtering (yyyy-MM-dd)
    public var dateString: String? {
        let dateStr = segment.additionalData?.startDatetime ?? segment.startDate
        return TRPDateHelper.extractDateString(dateStr)
    }

    /// Formatted time range string (e.g., "10:00 - 12:00"). Without an end time the end is the start plus
    /// `duration`, and without a duration only the start time is returned.
    public var timeRangeString: String? {
        guard let startTime = TRPDateHelper.extractTimeString(segment.additionalData?.startDatetime)
                ?? TRPDateHelper.extractTimeString(segment.startDate) else {
            return nil
        }
        let endTime = TRPDateHelper.extractTimeString(segment.additionalData?.endDatetime)
            ?? TRPDateHelper.extractTimeString(segment.endDate)
            ?? duration.flatMap { TRPDateHelper.addMinutes(toTime: startTime, minutes: Int($0)) }
        guard let endTime = endTime else { return startTime }
        return "\(startTime) - \(endTime)"
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

    /// Adult count. The segment is the source of truth: the API's `additionalData` carries no
    /// traveller counts, so the mapper fills it with a placeholder `1`.
    public var adultCount: Int {
        return segment.adults
    }

    /// Child count. Read from the segment for the same reason as `adultCount`.
    public var childCount: Int {
        return segment.children
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
        guard isBookedActivity || isReservedActivity else {
            return segment.additionalData?.isNoLocation ?? false
        }
        return segment.hasNoLocation
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
