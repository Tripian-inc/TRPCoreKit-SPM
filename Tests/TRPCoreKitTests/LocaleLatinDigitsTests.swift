import XCTest
@testable import TRPCoreKit

final class LocaleLatinDigitsTests: XCTestCase {

    func testAddsTheNumbersKeywordToAnIdentifierWithoutKeywords() {
        XCTAssertEqual(Locale(identifier: "fa").withLatinDigits.identifier, "fa@numbers=latn")
    }

    func testAppendsTheNumbersKeywordAfterExistingKeywords() {
        XCTAssertEqual(Locale(identifier: "ja_JP@calendar=japanese").withLatinDigits.identifier, "ja_JP@calendar=japanese;numbers=latn")
    }

    func testKeepsTheExistingCalendarKeyword() {
        XCTAssertEqual(Locale(identifier: "ja_JP@calendar=japanese").withLatinDigits.calendar.identifier, .japanese)
    }

    func testKeepsTheLanguage() {
        XCTAssertEqual(Locale(identifier: "ar_SA").withLatinDigits.languageCode, "ar")
    }

    func testFormatsNumbersWithLatinDigits() {
        for identifier in ["fa", "ar_SA", "ar-SA"] {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: identifier).withLatinDigits

            XCTAssertEqual(formatter.string(from: 2026), "2026", identifier)
        }
    }
}
