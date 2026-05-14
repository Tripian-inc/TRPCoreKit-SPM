//
//  TRPMapDisplayItem.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Extracted from ViewModel to separate model file
//

import Foundation
import TRPFoundationKit

// MARK: - Map Display Item

/// Item type for map display (collection view and annotations)
/// Used by TRPTimelineItineraryVC+Map for rendering map items
public enum TRPMapDisplayItem {
    case poi(TRPPoi, TRPTimelineSegment, TRPTimelineStep?)
    case activity(TRPTimelineSegment)

    /// Get coordinate for the item
    public var coordinate: TRPLocation? {
        switch self {
        case .poi(let poi, _, _):
            return poi.coordinate
        case .activity(let segment):
            return segment.additionalData?.coordinate
        }
    }

    /// Get unique ID for the item
    public var itemId: String {
        switch self {
        case .poi(let poi, _, _):
            return poi.id
        case .activity(let segment):
            return segment.additionalData?.activityId ?? ""
        }
    }

    /// Get title for the item
    public var title: String {
        switch self {
        case .poi(let poi, _, _):
            return poi.name
        case .activity(let segment):
            return segment.additionalData?.title ?? segment.title ?? ""
        }
    }

    /// Get image URL for the item
    public var imageUrl: String? {
        switch self {
        case .poi(let poi, _, _):
            return poi.image?.url
        case .activity(let segment):
            return segment.additionalData?.imageUrl
        }
    }

    /// Get start time for the item (formatted as "HH:mm")
    public var startTime: String? {
        switch self {
        case .poi(_, let segment, let step):
            // First try to get from step's startDateTimes
            if let stepTime = step?.getStartTime() {
                return stepTime
            }
            // Fallback to segment's startDate (for manual POIs)
            return Self.extractTimeFromSegment(segment)

        case .activity(let segment):
            return Self.extractTimeFromSegment(segment)
        }
    }

    /// Helper to extract time from segment
    private static func extractTimeFromSegment(_ segment: TRPTimelineSegment) -> String? {
        // First try additionalData.startDatetime (format: "yyyy-MM-dd HH:mm:ss")
        if let startDatetime = segment.additionalData?.startDatetime {
            if let date = Date.fromString(startDatetime, format: "yyyy-MM-dd HH:mm:ss") {
                return date.toString(format: "HH:mm")
            }
        }
        // Then try segment.startDate (format: "yyyy-MM-dd HH:mm" or "yyyy-MM-dd HH:mm:ss")
        if let startDate = segment.startDate {
            // Try with seconds first
            if let date = Date.fromString(startDate, format: "yyyy-MM-dd HH:mm:ss") {
                return date.toString(format: "HH:mm")
            }
            // Then try without seconds
            if let date = Date.fromString(startDate, format: "yyyy-MM-dd HH:mm") {
                return date.toString(format: "HH:mm")
            }
        }
        return nil
    }

    /// Check if this is an activity
    public var isActivity: Bool {
        switch self {
        case .poi: return false
        case .activity: return true
        }
    }

    /// `true` when this is an activity whose source had no precise coordinate
    /// (segment uses the city's coordinate as a fallback). Annotations should
    /// skip these; the preview cell surfaces a "No exact location" tag instead.
    public var isNoLocation: Bool {
        switch self {
        case .poi: return false
        case .activity(let segment): return segment.additionalData?.isNoLocation ?? false
        }
    }

    /// Check if this map item is a flexible-time reserved activity.
    /// Detection: activity segment + additionalData.duration == -1 + start/end times in {00:00, 23:59}.
    public var isFlexibleActivity: Bool {
        guard case .activity(let segment) = self else { return false }
        guard let duration = segment.additionalData?.duration, duration == -1 else { return false }

        let flexibleTimes: Set<String> = ["00:00", "23:59"]
        let startStr = segment.additionalData?.startDatetime ?? segment.startDate
        let endStr = segment.additionalData?.endDatetime ?? segment.endDate

        guard let startTime = Self.extractHHmm(startStr),
              let endTime = Self.extractHHmm(endStr) else {
            return false
        }
        return flexibleTimes.contains(startTime) && flexibleTimes.contains(endTime)
    }

    private static func extractHHmm(_ raw: String?) -> String? {
        guard let raw = raw else { return nil }
        if let date = Date.fromString(raw, format: "yyyy-MM-dd HH:mm:ss") {
            return date.toString(format: "HH:mm")
        }
        if let date = Date.fromString(raw, format: "yyyy-MM-dd HH:mm") {
            return date.toString(format: "HH:mm")
        }
        return nil
    }

    /// Get city name for the item
    public var cityName: String? {
        switch self {
        case .poi(_, let segment, _):
            return segment.city?.name
        case .activity(let segment):
            return segment.city?.name
        }
    }
}
