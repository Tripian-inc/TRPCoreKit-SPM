//
//  TRPTourSchedule.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourScheduleSlot: Codable {
    /// Specific start time in "HH:mm". When `nil`, the slot is flexible — the activity
    /// is valid at any time on the parent schedule's date (the booking screen renders
    /// an info card instead of a time grid).
    public let time: String?
    public let price: Double?

    public init(time: String?, price: Double? = nil) {
        self.time = time
        self.price = price
    }

    /// Convenience: distinguishes a flexible (any-time) slot from a timed one.
    public var isFlexible: Bool { time == nil }
}

/// One day's worth of slots inside a tour schedule. Always present in the domain
/// `TRPTourSchedule.dates` array — single-day responses become a 1-entry list, range
/// responses produce N entries, one per requested day.
public struct TRPTourScheduleDay: Codable {
    public let date: String          // "yyyy-MM-dd"
    public let slots: [TRPTourScheduleSlot]

    public init(date: String, slots: [TRPTourScheduleSlot]) {
        self.date = date
        self.slots = slots
    }
}

public struct TRPTourSchedule: Codable {
    public let title: String
    /// Per-day slot buckets. Always populated (at least one entry); range queries
    /// fan out across multiple days.
    public let dates: [TRPTourScheduleDay]

    public init(title: String, dates: [TRPTourScheduleDay]) {
        self.title = title
        self.dates = dates
    }

    /// Convenience: flat list of every slot across every day. Useful for callers
    /// that don't care about per-day grouping.
    public var allSlots: [TRPTourScheduleSlot] {
        return dates.flatMap { $0.slots }
    }
}
