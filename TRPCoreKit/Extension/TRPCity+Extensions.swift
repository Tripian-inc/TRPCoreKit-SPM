//
//  TRPCity+Extensions.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

extension TRPCity {
    /// Returns a usable coordinate for this city. When the city instance itself was
    /// built as a placeholder with `(0, 0)` (e.g. via the booked-activity merge path
    /// in `createSegmentProfileFromTripItem`), falls back to `TRPCityCache` by id.
    /// Returns `nil` only when neither the city nor the cache has a real coordinate.
    public func resolvedCoordinate() -> TRPLocation? {
        if !coordinate.isMissingOrZero {
            return coordinate
        }
        if id > 0,
           let cached = TRPCityCache.shared.getCity(byId: id),
           !cached.coordinate.isMissingOrZero {
            return cached.coordinate
        }
        return nil
    }

    /// IANA timezone (e.g. `"Europe/Madrid"`) resolved into a `TimeZone`. Falls
    /// back to the `TRPCityCache` entry when the in-memory city has an empty
    /// timezone (the booked-activity merge can synthesize stub cities). Returns
    /// `nil` if neither source yields a usable identifier — callers should treat
    /// that as "fall back to device timezone".
    public func resolvedTimezone() -> TimeZone? {
        if let tz = timezone, !tz.isEmpty, let zone = TimeZone(identifier: tz) {
            return zone
        }
        if id > 0,
           let cached = TRPCityCache.shared.getCity(byId: id),
           let cachedTz = cached.timezone, !cachedTz.isEmpty,
           let zone = TimeZone(identifier: cachedTz) {
            return zone
        }
        return nil
    }

    /// `true` if `day` falls on the same calendar day as "now" in THIS city's
    /// timezone. Use instead of `Calendar.current.isDateInToday(day)` whenever
    /// "today" must be interpreted from the city's perspective — a device in
    /// Tokyo planning a Barcelona trip can land on a different calendar day
    /// than the city actually sees.
    public func isDateTodayInCityTimezone(_ day: Date) -> Bool {
        var cal = Calendar.current
        cal.timeZone = resolvedTimezone() ?? .current
        return cal.isDate(day, inSameDayAs: Date())
    }

    /// "Now" in this city's timezone as `(hour, minute)` in 24h, with an
    /// optional `offsetSeconds` lead-time (e.g. `5 * 60` for "+5 minutes").
    /// Falls back to device timezone when this city has no usable IANA id.
    public func cityLocalTimeComponents(offsetSeconds: TimeInterval = 0) -> (hour: Int, minute: Int) {
        var cal = Calendar.current
        cal.timeZone = resolvedTimezone() ?? .current
        let target = Date().addingTimeInterval(offsetSeconds)
        let comps = cal.dateComponents([.hour, .minute], from: target)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }

    /// Builds a device-local `Date` whose HH:mm matches the given city-tz
    /// `(hour, minute)`. Use when feeding `TRPSingleTimePickerViewController`'s
    /// `minimumTime` / `initialTime`: that picker extracts HH:mm and reattaches
    /// to the device-local start-of-day, so the (hour, minute) we hand it must
    /// already be the wall-clock value the user expects to see.
    public func deviceLocalProxy(forCityHour hour: Int, minute: Int) -> Date {
        let deviceCal = Calendar.current
        let referenceDay = deviceCal.startOfDay(for: Date())
        return deviceCal.date(bySettingHour: hour, minute: minute, second: 0, of: referenceDay) ?? Date()
    }
}
