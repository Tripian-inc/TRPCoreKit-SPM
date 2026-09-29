import Foundation
import TRPBookingKit

/// Formats prices, dates and countdowns for the booking screens.
struct BookingFormatting {

    var locale: Locale = .current

    func price(_ amount: Decimal?, currency: String?) -> String? {
        guard let amount else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = currency == nil ? .decimal : .currency
        formatter.maximumFractionDigits = 2
        if let currency { formatter.currencyCode = currency.uppercased() }
        return formatter.string(from: amount as NSDecimalNumber)
    }

    func day(_ date: BookingDate) -> String {
        guard let value = Self.calendarDate(date) else { return date.description }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMMyyyy")
        return formatter.string(from: value)
    }

    /// `"09:30:00"` or `"09:30"` becomes `"09:30"`; anything else is left alone.
    func time(_ raw: String) -> String {
        raw.count >= 5 && raw.dropFirst(2).first == ":" ? String(raw.prefix(5)) : raw
    }

    func countdown(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.down)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private static func calendarDate(_ date: BookingDate) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day, hour: 12))
    }
}
