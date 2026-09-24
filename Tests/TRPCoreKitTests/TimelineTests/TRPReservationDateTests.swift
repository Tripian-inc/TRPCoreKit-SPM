import XCTest
import TRPRestKit
@testable import TRPCoreKit

/// The date handed to the host for a reservation is wall-clock UTC: the server's `HH:mm` must reach
/// the host unchanged wherever the traveller's device is.
final class TRPReservationDateTests: XCTestCase {

    private let zones = ["America/Mexico_City", "Europe/Istanbul", "Pacific/Kiritimati", "Pacific/Pago_Pago"]
    private var originalZone: TimeZone!
    private var originalLanguage: String = "en"

    override func setUp() {
        super.setUp()
        originalZone = NSTimeZone.default
        originalLanguage = TRPClient.getLanguage()
        TRPClient.changeLanguage("en")
    }

    override func tearDown() {
        NSTimeZone.default = originalZone
        TRPClient.changeLanguage(originalLanguage)
        super.tearDown()
    }

    private func utc(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    private func makeScreen() -> TRPTimelineItineraryVC {
        return TRPTimelineItineraryVC(viewModel: TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline()))
    }

    private func select(_ ymd: String, on screen: TRPTimelineItineraryVC) {
        guard let index = screen.viewModel.getDayDates().firstIndex(where: { TRPDateHelper.formatDateString($0) == ymd }) else {
            return XCTFail("\(ymd) is not a day of the mock trip")
        }
        screen.viewModel.selectDay(at: index)
    }

    func testTimedSourceKeepsItsWallClockInUTC() {
        for id in zones {
            NSTimeZone.default = TimeZone(identifier: id)!
            let screen = makeScreen()

            XCTAssertEqual(screen.resolveReservationDate(preferred: "2026-10-05 10:30"), utc("2026-10-05 10:30"), id)
            XCTAssertEqual(screen.resolveReservationDate(preferred: "2026-10-05 23:45:00"), utc("2026-10-05 23:45"), id)
        }
    }

    func testFlexibleSourceIsPinnedToMidnightUTCOfItsDay() {
        for id in zones {
            NSTimeZone.default = TimeZone(identifier: id)!
            let screen = makeScreen()

            XCTAssertEqual(screen.resolveReservationDate(preferred: "2026-10-05 23:59", isFlexible: true), utc("2026-10-05 00:00"), id)
        }
    }

    func testMissingSourceFallsBackToTheSelectedDayAtMidnightUTC() {
        for id in zones {
            NSTimeZone.default = TimeZone(identifier: id)!
            let screen = makeScreen()
            select("2025-12-09", on: screen)

            XCTAssertEqual(screen.resolveReservationDate(preferred: nil), utc("2025-12-09 00:00"), id)
        }
    }

    func testUnreadableSourceFallsBackToTheSelectedDay() {
        let screen = makeScreen()
        select("2025-12-09", on: screen)

        XCTAssertEqual(screen.resolveReservationDate(preferred: "10/05/2026 10:30"), utc("2025-12-09 00:00"))
    }

    func testTimedSourceKeepsItsWallClockInOtherLanguages() {
        for language in ["es", "de", "fr", "tr", "it", "pt"] {
            TRPClient.changeLanguage(language)
            let screen = makeScreen()

            XCTAssertEqual(screen.resolveReservationDate(preferred: "2026-10-05 10:30"), utc("2026-10-05 10:30"), language)
        }
    }

    /// Server strings are Gregorian even when the app language defaults to a Buddhist or Solar Hijri calendar.
    func testTimedSourceKeepsItsYearInLanguagesWithAnotherCalendar() {
        for language in ["th", "fa", "ja-JP-u-ca-japanese"] {
            TRPClient.changeLanguage(language)
            let screen = makeScreen()

            XCTAssertEqual(screen.resolveReservationDate(preferred: "2026-10-05 10:30"), utc("2026-10-05 10:30"), language)
        }
    }
}
