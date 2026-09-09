//
//  TimePickerBounds.swift
//  TRPCoreKit
//

import Foundation

/// Pure, city-timezone-aware computations for what a `TRPSingleTimePickerViewController`
/// should consider valid (`minimumTime`) and what it should sit on by default
/// (`initialTime`) when the user hasn't picked anything yet.
///
/// Lives outside the picker and its host VCs so that:
/// - the same rules drive smart-recommendation (`AddPlanTimeAndTravelersViewModel`)
///   and manual-POI (`TRPTimeRangeSelectionViewController`) without duplication,
/// - the VCs stay focused on view wiring (no business logic),
/// - the helpers are trivially unit-testable (only `Date()` / `Calendar.current`
///   touch the system clock; everything else is plain arithmetic).
///
/// Contract with the picker — `TRPSingleTimePickerViewController.applyTimeRestrictions`
/// extracts HH:mm from the Date we hand it and reattaches them to the
/// **device-local** start-of-day. So the Date we return is a proxy: only its
/// HH:mm matters. All conversions use `TRPCity.deviceLocalProxy(forCityHour:minute:)`
/// to make sure the wall-clock the user sees in the picker reads the same as the
/// city-local wall clock.
public enum TimePickerBounds {

    /// Minimum selectable start time. When `selectedDay` is "today" in the
    /// city's timezone, the user must pick at least `now + 5 minutes` in that
    /// timezone. On future days there is no restriction.
    /// Falls back to device timezone when `city` is nil or carries no usable
    /// IANA id — so existing single-city / unknown-tz flows behave unchanged.
    public static func minimumStartTime(selectedDay: Date?, city: TRPCity?) -> Date? {
        guard let selectedDay = selectedDay else { return nil }

        let isToday = city?.isDateTodayInCityTimezone(selectedDay)
            ?? Calendar.current.isDateInToday(selectedDay)
        guard isToday else { return nil }

        if let city = city {
            let (h, m) = city.cityLocalTimeComponents(offsetSeconds: 5 * 60)
            return city.deviceLocalProxy(forCityHour: h, minute: m)
        }
        return Date().addingTimeInterval(5 * 60)
    }

    /// Minimum selectable end time. The end-time picker is opened in
    /// strict-minimum mode when a start time exists (`endTimeButtonTapped` flips
    /// the picker into "minimum is the wheel start but not confirmable"); when
    /// no start time has been picked yet the same "earliest sensible moment"
    /// applies as `minimumStartTime`.
    public static func minimumEndTime(selectedDay: Date?, city: TRPCity?, currentStartTime: Date?) -> Date? {
        if let startTime = currentStartTime {
            return startTime
        }
        return minimumStartTime(selectedDay: selectedDay, city: city)
    }

    /// Default `initialTime` for the end-time picker when the user hasn't
    /// selected one yet. When a start time exists, returns `startTime + 1h`
    /// preserving the minute (13:30 → 14:30, 13:00 → 14:00) so the end picker
    /// opens one hour past start by default. When no start time exists, falls
    /// back to `defaultInitialTime` (next top of the hour in the city's tz).
    ///
    /// Wrap-around guard: when start is 23:xx, `+1h` would land in the next
    /// calendar day, which the picker's HH:mm-only comparison treats as
    /// *before* start — that disables the confirm button on open. We return
    /// `nil` for that edge so the picker keeps its own default (which the
    /// strict-minimum gate then clamps).
    public static func defaultInitialEndTime(selectedDay: Date?, city: TRPCity?, currentStartTime: Date?) -> Date? {
        if let startTime = currentStartTime {
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: startTime)
            let startHour = comps.hour ?? 0
            guard startHour < 23 else { return nil }
            let minute = comps.minute ?? 0
            let today = cal.startOfDay(for: Date())
            return cal.date(bySettingHour: startHour + 1, minute: minute, second: 0, of: today)
        }
        return defaultInitialTime(selectedDay: selectedDay, city: city)
    }

    /// Default `initialTime` for the picker when the user hasn't selected one
    /// yet. For "today" (in the city's timezone), returns the next top of the
    /// hour in that timezone — e.g. city-local 13:36 → 14:00, 13:00 stays
    /// 13:00. For future days or the 23:xx edge case, returns `nil` so the
    /// picker keeps its own default (`getDefaultTime`).
    public static func defaultInitialTime(selectedDay: Date?, city: TRPCity?) -> Date? {
        guard let selectedDay = selectedDay else { return nil }

        let isToday = city?.isDateTodayInCityTimezone(selectedDay)
            ?? Calendar.current.isDateInToday(selectedDay)
        guard isToday else { return nil }

        let (h, m): (Int, Int)
        if let city = city {
            (h, m) = city.cityLocalTimeComponents()
        } else {
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: Date())
            (h, m) = (comps.hour ?? 0, comps.minute ?? 0)
        }
        // Round up to the next hour. Already on the hour stays on the hour —
        // that IS the next "tam saat" from the user's perspective.
        let nextHour = (m > 0) ? h + 1 : h
        guard nextHour < 24 else { return nil }   // 23:xx → let picker default

        if let city = city {
            return city.deviceLocalProxy(forCityHour: nextHour, minute: 0)
        }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return cal.date(bySettingHour: nextHour, minute: 0, second: 0, of: today)
    }
}
