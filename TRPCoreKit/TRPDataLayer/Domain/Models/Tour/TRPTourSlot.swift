//
//  TRPTourSlot.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 04.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourSlot: Codable, Hashable {
    public let date: String       // "yyyy-MM-dd"
    /// Specific start time in "HH:mm". When `nil`, the slot is flexible — the activity
    /// is valid at any time on `date` (the booking screen renders an info card instead
    /// of a time grid).
    public let time: String?
    public let price: Double?

    public init(date: String, time: String?, price: Double?) {
        self.date = date
        self.time = time
        self.price = price
    }

    /// Convenience: distinguishes a flexible (any-time) slot from a timed one.
    public var isFlexible: Bool { time == nil }
}
