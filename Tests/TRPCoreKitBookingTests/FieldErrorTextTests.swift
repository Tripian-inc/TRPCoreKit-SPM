import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

/// `TRPBookingText.message(for:)` resolves a coded field error through the host's translations, falling back
/// to the error's own English message when the host has none.
final class FieldErrorTextTests: XCTestCase {

    private func error(code: String?, message: String) -> BookingContract.ErrorData.FieldError {
        BookingContract.ErrorData.FieldError(field: "date", code: code, message: message)
    }

    func testRendersTheHostTranslationWhenOneExists() {
        let text = TRPBookingText(localize: { key, _ in
            key == "booking_error_missing_date" ? "Elige una de las fechas disponibles." : ""
        })
        let message = text.message(for: error(code: "missing_date", message: "Choose one of the available dates."))
        XCTAssertEqual(message, "Elige una de las fechas disponibles.")
    }

    func testFallsBackToTheMessageWhenTheHostEchoesTheKey() {
        let text = TRPBookingText(localize: { key, _ in key })
        let message = text.message(for: error(code: "missing_date", message: "Choose one of the available dates."))
        XCTAssertEqual(message, "Choose one of the available dates.")
    }

    func testFallsBackToTheMessageWhenTheHostReturnsEmpty() {
        let text = TRPBookingText(localize: { _, _ in "" })
        let message = text.message(for: error(code: "missing_date", message: "Choose one of the available dates."))
        XCTAssertEqual(message, "Choose one of the available dates.")
    }

    func testReturnsTheMessageVerbatimWithNoCodeWithoutConsultingLocalize() {
        var consultedKeys: [String] = []
        let text = TRPBookingText(localize: { key, fallback in
            consultedKeys.append(key)
            return fallback
        })
        let message = text.message(for: error(code: nil, message: "Enter a valid email address."))
        XCTAssertEqual(message, "Enter a valid email address.")
        XCTAssertFalse(consultedKeys.contains { $0.hasPrefix("booking_error_") })
    }

    func testAllContainsTheFieldErrorKeyWithNoDuplicates() {
        let keys = TRPBookingTextKey.all.map(\.key)
        XCTAssertTrue(keys.contains("booking_error_missing_date"))
        XCTAssertEqual(keys.count, Set(keys).count, "duplicate TRPBookingTextKey keys")
    }
}
