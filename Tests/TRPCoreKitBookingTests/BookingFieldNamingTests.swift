import XCTest
@testable import TRPCoreKitBooking

final class BookingFieldNamingTests: XCTestCase {

    func testHumanizedSplitsCamelCaseAndSeparators() {
        XCTAssertEqual(BookingFieldNaming.humanized("passportNumber"), "Passport number")
        XCTAssertEqual(BookingFieldNaming.humanized("date_of_birth"), "Date of birth")
        XCTAssertEqual(BookingFieldNaming.humanized("hotel-name"), "Hotel name")
    }

    func testNormalizedDropsCaseAndPunctuation() {
        XCTAssertEqual(BookingFieldNaming.normalized("First_Name"), "firstname")
    }
}
