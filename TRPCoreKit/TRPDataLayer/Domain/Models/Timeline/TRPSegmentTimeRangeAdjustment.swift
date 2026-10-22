//
//  TRPSegmentTimeRangeAdjustment.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Computes how far a segment's time range must grow so a step's new time range fits inside it.
enum TRPSegmentTimeRangeAdjustment {

    /// Returns the widened segment range, or `nil` when the step already lies within the segment.
    static func widenedRange(segmentStart: Date,
                             segmentEnd: Date,
                             stepStart: Date,
                             stepEnd: Date) -> (start: Date, end: Date)? {
        guard stepStart < segmentStart || stepEnd > segmentEnd else { return nil }
        return (start: min(segmentStart, stepStart), end: max(segmentEnd, stepEnd))
    }

    /// Places the picker's `"HH:mm"` times on the calendar day of `stepDateTime` ("yyyy-MM-dd HH:mm").
    /// Both times stay on that day, since the time picker only accepts an end time after the start time.
    static func stepRange(onDayOf stepDateTime: String?,
                          startTime: String,
                          endTime: String) -> (start: Date, end: Date)? {
        guard let day = TRPDateHelper.extractDateString(stepDateTime),
              let start = TRPDateHelper.parseDateTime("\(day) \(startTime)"),
              let end = TRPDateHelper.parseDateTime("\(day) \(endTime)") else { return nil }
        return (start: start, end: end)
    }
}
