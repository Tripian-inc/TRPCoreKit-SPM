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
