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

public struct TRPTourSchedule: Codable {
    public let title: String
    public let slots: [TRPTourScheduleSlot]

    public init(title: String, slots: [TRPTourScheduleSlot]) {
        self.title = title
        self.slots = slots
    }
}
