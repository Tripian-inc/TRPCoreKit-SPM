//
//  TRPTourScheduleAvailability.swift
//  TRPDataLayer
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// One entry of the `tour-api/schedule-availability` batch response — pairs the
/// requested `activityId` with its resolved `TRPTourSchedule` for the queried date.
/// `schedule == nil` means the backend returned an empty/null schedule for that id
/// (typically: sold out or no slots on the requested day).
public struct TRPTourScheduleAvailability: Codable {
    public let activityId: String
    public let schedule: TRPTourSchedule?

    public init(activityId: String, schedule: TRPTourSchedule?) {
        self.activityId = activityId
        self.schedule = schedule
    }

    /// Convenience: true when the schedule has at least one slot across all days.
    public var hasAvailability: Bool {
        guard let schedule = schedule else { return false }
        return !schedule.allSlots.isEmpty
    }
}
