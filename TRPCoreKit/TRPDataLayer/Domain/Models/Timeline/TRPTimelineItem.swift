//
//  TRPTimelineItem.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Extracted from ViewController to separate model file
//

import Foundation

// MARK: - Timeline Item

/// Enum to represent items in timeline (POIs and Booked Activities)
/// Used by TRPTimelineItineraryVC for handling different item types
public enum TRPTimelineItem {
    case poi(TRPPoi)
    case bookedActivity(TRPTimelineSegment)

    /// Get the coordinate for this item
    public var coordinate: TRPLocation? {
        switch self {
        case .poi(let poi):
            return poi.coordinate
        case .bookedActivity(let segment):
            return segment.additionalData?.coordinate ?? segment.coordinate
        }
    }

    /// Get the title for this item
    public var title: String {
        switch self {
        case .poi(let poi):
            return poi.name
        case .bookedActivity(let segment):
            return segment.additionalData?.title ?? segment.title ?? ""
        }
    }

    /// Check if this is a booked activity
    public var isBookedActivity: Bool {
        switch self {
        case .poi: return false
        case .bookedActivity: return true
        }
    }
}
