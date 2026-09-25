import XCTest
import TRPRestKit
@testable import TRPCoreKit

/// Server dates are Gregorian "yyyy-MM-dd" strings in every app language, including languages whose
/// locale defaults to another calendar. `TRPDateHelper` formats with `Locale.current`, which a test
/// process cannot switch, so it is checked only against the app languages it must ignore.
final class TRPFixedFormatDateTests: XCTestCase {

    private let languages = ["th", "fa", "ja-JP-u-ca-japanese"]
    private var originalLanguage: String = "en"
    private var originalZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalLanguage = TRPClient.getLanguage()
        originalZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "Europe/Madrid")!
    }

    override func tearDown() {
        TRPClient.changeLanguage(originalLanguage)
        NSTimeZone.default = originalZone
        super.tearDown()
    }

    private let latinLetters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

    private func utc(_ text: String, format: String = "yyyy-MM-dd") -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = format
        return formatter.date(from: text)!
    }

    // MARK: - String.toDate

    func testToDateReadsAGregorianDayInLanguagesWithAnotherCalendar() {
        for language in languages {
            TRPClient.changeLanguage(language)

            XCTAssertEqual("2026-10-05".toDate(), utc("2026-10-05"), language)
        }
    }

    func testToDateReadsAGregorianDateTimeInLanguagesWithAnotherCalendar() {
        for language in languages {
            TRPClient.changeLanguage(language)

            XCTAssertEqual("2026-10-05 10:30".toDate(format: "yyyy-MM-dd HH:mm"), utc("2026-10-05 10:30", format: "yyyy-MM-dd HH:mm"), language)
        }
    }

    // MARK: - Date.toString

    func testToStringWritesTheGregorianDayInThaiAndJapanese() {
        for language in ["th", "ja-JP-u-ca-japanese"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(utc("2026-10-05").toString(format: "yyyy-MM-dd"), "2026-10-05", language)
        }
    }

    func testToStringAndToDateRoundTripInLanguagesWithAnotherCalendar() {
        let format = "yyyy-MM-dd HH:mm"
        let date = utc("2026-10-05 10:30", format: format)
        for language in languages {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(date.toString(format: format).toDate(format: format), date, language)
        }
    }

    func testToStringWritesLatinDigitsInPersianAndArabic() {
        for language in ["fa", "ar-SA"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(utc("2026-10-05").toString(format: "yyyy-MM-dd"), "2026-10-05", language)
            XCTAssertEqual(utc("2026-10-05 10:30", format: "yyyy-MM-dd HH:mm").toString(format: "yyyy-MM-dd HH:mm"), "2026-10-05 10:30", language)
        }
    }

    func testToDateReadsLatinDigitsInPersianAndArabic() {
        for language in ["fa", "ar-SA"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual("2026-10-05".toDate(format: "yyyy-MM-dd"), utc("2026-10-05"), language)
        }
    }

    func testToStringKeepsDayAndMonthNamesInTheLanguage() {
        let monday = utc("2026-10-05")
        for language in ["fa", "ar-SA"] {
            TRPClient.changeLanguage(language)

            let weekday = monday.toString(format: "EEEE")
            let month = monday.toString(format: "MMMM")

            XCTAssertNotEqual(weekday, "Monday", language)
            XCTAssertNotEqual(month, "October", language)
            XCTAssertNil(weekday.rangeOfCharacter(from: latinLetters), language)
            XCTAssertNil(month.rangeOfCharacter(from: latinLetters), language)
        }
    }

    // MARK: - Calendar year

    func testToStringWritesTheCalendarYearForALateDecemberDay() {
        for language in ["en", "tr", "fa", "ar-SA", "th"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(utc("2026-12-28").toString(format: "yyyy-MM-dd"), "2026-12-28", language)
            XCTAssertEqual(utc("2026-12-31").toString(format: "yyyy-MM-dd"), "2026-12-31", language)
        }
    }

    func testToStringWithoutTimeZoneWritesTheCalendarYearForALateDecemberDay() {
        NSTimeZone.default = TimeZone(identifier: "UTC")!
        for language in ["en", "fa"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(utc("2026-12-28 12:00", format: "yyyy-MM-dd HH:mm").toStringWithoutTimeZone(format: "yyyy-MM-dd"), "2026-12-28", language)
        }
    }

    func testToDateReadsALateDecemberDayInItsCalendarYear() {
        for language in ["en", "fa"] {
            TRPClient.changeLanguage(language)

            XCTAssertEqual("2026-12-28".toDate(format: "yyyy-MM-dd"), utc("2026-12-28"), language)
        }
    }

    // MARK: - TRPDateHelper

    func testDateHelperRoundTripsADayInLanguagesWithAnotherCalendar() {
        for language in languages {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(TRPDateHelper.parseDate("2026-10-05").map(TRPDateHelper.formatDateString), "2026-10-05", language)
        }
    }

    func testDateHelperRoundTripsADateTimeInLanguagesWithAnotherCalendar() {
        for language in languages {
            TRPClient.changeLanguage(language)

            XCTAssertEqual(TRPDateHelper.parseDateTime("2026-10-05 10:30").map(TRPDateHelper.formatDateTime), "2026-10-05 10:30", language)
            XCTAssertEqual(TRPDateHelper.parseDateTime("2026-10-05 10:30:15").map(TRPDateHelper.formatDateTimeWithSeconds), "2026-10-05 10:30:15", language)
        }
    }

    func testDateHelperReadsTheGregorianYear() {
        let date = TRPDateHelper.parseDate("2026-10-05")!

        XCTAssertEqual(Calendar(identifier: .gregorian).component(.year, from: date), 2026)
    }
}
