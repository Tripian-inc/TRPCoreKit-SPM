//
//  AddPlanDaySelection.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Initial-day rule shared by every Add Plan entry point: a past day is never preselected.
enum AddPlanDaySelection {

    /// Earliest non-past day (today when the trip includes it), or nil when every day is past.
    static func firstSelectableDay(in days: [Date]) -> Date? {
        return days.filter { !$0.isPastDay() }.min()
    }

    /// `days[preferredIndex]` when it exists and is not past, else `firstSelectableDay(in:)`.
    static func initialDay(in days: [Date], preferredIndex: Int?) -> Date? {
        if let preferredIndex = preferredIndex, days.indices.contains(preferredIndex), !days[preferredIndex].isPastDay() {
            return days[preferredIndex]
        }
        return firstSelectableDay(in: days)
    }
}
