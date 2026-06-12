//
//  TRPDateHelper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

/// Centralized date parsing and formatting utility for Timeline feature.
/// Eliminates duplicated date handling logic across ViewModel and cells.
public struct TRPDateHelper {

    // MARK: - Date Formats

    private static let dateTimeWithSeconds = "yyyy-MM-dd HH:mm:ss"
    private static let dateTimeWithoutSeconds = "yyyy-MM-dd HH:mm"
    private static let dateOnly = "yyyy-MM-dd"
    private static let timeOnly = "HH:mm"
    private static let displayDate = "dd/MM/yyyy"
    private static let displayDateTime = "dd/MM/yyyy HH:mm"
    private static let dayMonth = "EEEE dd/MM"

    // MARK: - Shared Formatter

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Parsing Methods

    /// Parse datetime string (tries both formats: with and without seconds)
    /// - Parameter dateString: Date string in "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd HH:mm" format
    /// - Returns: Parsed Date or nil if parsing fails
    public static func parseDateTime(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }

        // Try with seconds first
        formatter.dateFormat = dateTimeWithSeconds
        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try without seconds
        formatter.dateFormat = dateTimeWithoutSeconds
        return formatter.date(from: dateString)
    }

    /// Parse date-only string
    /// - Parameter dateString: Date string in "yyyy-MM-dd" format
    /// - Returns: Parsed Date (at midnight) or nil if parsing fails
    public static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }

        formatter.dateFormat = dateOnly
        return formatter.date(from: dateString)
    }

    // MARK: - Formatting Methods

    /// Format date to time string (HH:mm)
    /// - Parameter date: Date to format
    /// - Returns: Time string like "10:00"
    public static func formatTime(_ date: Date) -> String {
        formatter.dateFormat = timeOnly
        return formatter.string(from: date)
    }

    /// Format date to date string (yyyy-MM-dd) for grouping/filtering
    /// - Parameter date: Date to format
    /// - Returns: Date string like "2025-01-15"
    public static func formatDateString(_ date: Date) -> String {
        formatter.dateFormat = dateOnly
        return formatter.string(from: date)
    }

    /// Format date to datetime string (yyyy-MM-dd HH:mm). Counterpart to `parseDateTime`.
    /// - Parameter date: Date to format
    /// - Returns: Datetime string like "2025-01-15 10:00"
    public static func formatDateTime(_ date: Date) -> String {
        formatter.dateFormat = dateTimeWithoutSeconds
        return formatter.string(from: date)
    }

    /// Format date to datetime string with seconds (yyyy-MM-dd HH:mm:ss).
    /// - Parameter date: Date to format
    /// - Returns: Datetime string like "2025-01-15 10:00:00"
    public static func formatDateTimeWithSeconds(_ date: Date) -> String {
        formatter.dateFormat = dateTimeWithSeconds
        return formatter.string(from: date)
    }

    /// Format date to display date string (dd/MM/yyyy)
    /// - Parameter date: Date to format
    /// - Returns: Display date string like "15/01/2025"
    public static func formatDisplayDate(_ date: Date) -> String {
        formatter.dateFormat = displayDate
        return formatter.string(from: date)
    }

    /// Format date to display date time string (dd/MM/yyyy HH:mm)
    /// - Parameter date: Date to format
    /// - Returns: Display datetime string like "15/01/2025 10:00"
    public static func formatDisplayDateTime(_ date: Date) -> String {
        formatter.dateFormat = displayDateTime
        return formatter.string(from: date)
    }

    /// Format date to day and month string (EEEE dd/MM)
    /// - Parameter date: Date to format
    /// - Returns: Day month string like "Monday 15/01"
    public static func formatDayMonth(_ date: Date) -> String {
        formatter.dateFormat = dayMonth
        return formatter.string(from: date)
    }

    // MARK: - Extraction Methods

    /// Extract date string (yyyy-MM-dd) from datetime string
    /// - Parameter dateTimeString: Full datetime string
    /// - Returns: Date portion only, or nil if string is too short
    public static func extractDateString(_ dateTimeString: String?) -> String? {
        guard let str = dateTimeString, str.count >= 10 else { return nil }
        return String(str.prefix(10))
    }

    /// Extract time string (HH:mm) from datetime string
    /// - Parameter dateTimeString: Full datetime string
    /// - Returns: Time portion only, or nil if string is too short
    public static func extractTimeString(_ dateTimeString: String?) -> String? {
        guard let str = dateTimeString, str.count >= 16 else { return nil }
        // "yyyy-MM-dd HH:mm" -> extract "HH:mm" (index 11-15)
        let startIndex = str.index(str.startIndex, offsetBy: 11)
        let endIndex = str.index(str.startIndex, offsetBy: 16)
        return String(str[startIndex..<endIndex])
    }

    // MARK: - Comparison Methods

    /// Check if two dates are on the same day
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: true if both dates are on the same calendar day
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Check if datetime string falls on a specific date
    /// - Parameters:
    ///   - dateTimeString: Datetime string to check
    ///   - targetDate: Target date to compare
    /// - Returns: true if the datetime string is on the target date
    public static func isOnDate(_ dateTimeString: String?, targetDate: Date) -> Bool {
        guard let dateStr = extractDateString(dateTimeString) else { return false }
        let targetDateStr = formatDateString(targetDate)
        return dateStr == targetDateStr
    }

    // MARK: - Flexible Extraction

    /// Extract "HH:mm" from either "yyyy-MM-dd HH:mm[:ss]" or a bare "HH:mm[:ss]".
    /// Returns nil for empty/unparseable input. Unlike `extractTimeString`, this does
    /// not assume a fixed character offset — it splits on the date/time separator — so
    /// it also handles time-only inputs (e.g. a step's "HH:mm" start string).
    public static func extractHourMinute(from raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let timePart: String
        if let spaceIndex = raw.firstIndex(of: " ") {
            timePart = String(raw[raw.index(after: spaceIndex)...])
        } else {
            timePart = raw
        }
        let parts = timePart.split(separator: ":")
        guard parts.count >= 2 else { return nil }
        return "\(parts[0]):\(parts[1])"
    }

    /// Extract a validated "yyyy-MM-dd" from "yyyy-MM-dd HH:mm[:ss]" (or pass-through
    /// when the input is already date-only). Returns nil for empty input or a malformed
    /// prefix. Stricter than `extractDateString` — it verifies the 10-char dashed shape
    /// rather than blindly taking `prefix(10)`.
    public static func extractDateOnly(from raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let datePart: String
        if let spaceIndex = raw.firstIndex(of: " ") {
            datePart = String(raw[..<spaceIndex])
        } else {
            datePart = raw
        }
        let chars = Array(datePart)
        guard chars.count == 10, chars[4] == "-", chars[7] == "-" else { return nil }
        return datePart
    }

    // MARK: - Day Matching

    /// Find the `Date` in `days` whose calendar-day matches `ymd` ("yyyy-MM-dd").
    /// Tries UTC first, then the local time zone, because day producers in the timeline
    /// are UTC-anchored while some cell delegates parse segment/step strings in local
    /// time. Trying both sidesteps that inconsistency without changing the producers.
    /// Uses a dedicated formatter so the shared static formatter's time zone is untouched.
    public static func matchDay(ymd: String?, in days: [Date]) -> Date? {
        guard let ymd = ymd else { return nil }
        let matchFormatter = DateFormatter()
        matchFormatter.dateFormat = dateOnly
        for tz in [TimeZone(identifier: "UTC"), TimeZone.current].compactMap({ $0 }) {
            matchFormatter.timeZone = tz
            if let match = days.first(where: { matchFormatter.string(from: $0) == ymd }) {
                return match
            }
        }
        return nil
    }

    // MARK: - Time Arithmetic

    /// Add `minutes` to a "HH:mm[:ss]" time string and return "HH:mm", wrapping at 24h.
    /// Returns nil for unparseable input so the caller can decide its own fallback.
    public static func addMinutes(toTime time: String, minutes: Int) -> String? {
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        let totalMinutes = hour * 60 + minute + minutes
        let endHour = (totalMinutes / 60) % 24
        let endMinute = totalMinutes % 60
        return String(format: "%02d:%02d", endHour, endMinute)
    }

    // MARK: - Range Methods

    /// Format time range string from start and end dates
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Time range string like "10:00 - 12:00"
    public static func formatTimeRange(from startDate: Date?, to endDate: Date?) -> String? {
        guard let start = startDate, let end = endDate else { return nil }
        let startStr = formatTime(start)
        let endStr = formatTime(end)
        return "\(startStr) - \(endStr)"
    }

    /// Format time range string from start and end datetime strings
    /// - Parameters:
    ///   - startDateString: Start datetime string
    ///   - endDateString: End datetime string
    /// - Returns: Time range string like "10:00 - 12:00"
    public static func formatTimeRange(fromString startDateString: String?, toString endDateString: String?) -> String? {
        guard let startTime = extractTimeString(startDateString),
              let endTime = extractTimeString(endDateString) else {
            return nil
        }
        return "\(startTime) - \(endTime)"
    }
}
