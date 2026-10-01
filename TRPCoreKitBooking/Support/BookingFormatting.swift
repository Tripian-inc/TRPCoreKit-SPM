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

    /// Formats a `yyyy-MM-dd` day for display; anything unparseable is shown as given.
    func day(_ iso: String) -> String {
        guard let value = Self.isoDate.date(from: String(iso.prefix(10))) else { return iso }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMMyyyy")
        return formatter.string(from: value)
    }

    func price(_ money: BookingContract.Money?) -> String? {
        guard let money else { return nil }
        return price(money.decimalValue, currency: money.currency)
    }

    /// `"09:30:00"` or `"09:30"` becomes `"09:30"`; anything else is left alone.
    func time(_ raw: String) -> String {
        raw.count >= 5 && raw.dropFirst(2).first == ":" ? String(raw.prefix(5)) : raw
    }

    func countdown(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.down)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    static let isoDate = fixedFormatter("yyyy-MM-dd")
    static let isoTime = fixedFormatter("HH:mm")

    private static func fixedFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = format
        return formatter
    }
}
