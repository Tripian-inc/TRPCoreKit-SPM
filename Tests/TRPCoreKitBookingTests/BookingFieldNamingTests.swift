import XCTest
@testable import TRPCoreKitBooking

final class BookingFieldNamingTests: XCTestCase {

    private let naming = BookingFieldNaming(text: .default)

    func testHumanizedSplitsCamelCaseAndSeparators() {
        XCTAssertEqual(BookingFieldNaming.humanized("passportNumber"), "Passport number")
        XCTAssertEqual(BookingFieldNaming.humanized("date_of_birth"), "Date of birth")
        XCTAssertEqual(BookingFieldNaming.humanized("hotel-name"), "Hotel name")
    }

    func testNormalizedDropsCaseAndPunctuation() {
        XCTAssertEqual(BookingFieldNaming.normalized("First_Name"), "firstname")
    }

    func testTitleRecognizesFirstNameVariants() {
        XCTAssertEqual(naming.title(forQuestionId: "firstName"), "First name")
        XCTAssertEqual(naming.title(forQuestionId: "first_name"), "First name")
    }

    func testTitleRecognizesLastNameAndSurnameVariants() {
        XCTAssertEqual(naming.title(forQuestionId: "lastName"), "Last name")
        XCTAssertEqual(naming.title(forQuestionId: "surname"), "Last name")
    }

    func testTitleRecognizesEmailVariants() {
        XCTAssertEqual(naming.title(forQuestionId: "email"), "Email")
        XCTAssertEqual(naming.title(forQuestionId: "email_address"), "Email")
    }

    func testTitleRecognizesPhoneVariants() {
        for id in ["phone", "phoneNumber", "mobile", "mobilePhone"] {
            XCTAssertEqual(naming.title(forQuestionId: id), "Phone")
        }
    }

    func testTitleRecognizesFullNameVariants() {
        XCTAssertEqual(naming.title(forQuestionId: "fullName"), "Full name")
        XCTAssertEqual(naming.title(forQuestionId: "name"), "Full name")
    }

    func testTitleFallsBackToHumanizedIdForUnrecognizedIds() {
        XCTAssertEqual(naming.title(forQuestionId: "passport_number"), "Passport number")
    }

    func testTitleHumanizesDateOfBirthAsFallback() {
        XCTAssertEqual(naming.title(forQuestionId: "dob"), "Date of birth")
    }

    func testKindRecognizesEmailVariants() {
        XCTAssertEqual(naming.kind(forQuestionId: "email"), .email)
        XCTAssertEqual(naming.kind(forQuestionId: "emailAddress"), .email)
    }

    func testKindRecognizesPhoneVariants() {
        for id in ["phone", "phoneNumber", "mobile", "mobilePhone"] {
            XCTAssertEqual(naming.kind(forQuestionId: id), .phone)
        }
    }

    func testKindRecognizesDateOfBirthVariants() {
        for id in ["dob", "dateOfBirth", "birthDate", "birthday"] {
            XCTAssertEqual(naming.kind(forQuestionId: id), .date)
        }
    }

    func testKindDefaultsToTextForUnrecognizedIds() {
        XCTAssertEqual(naming.kind(forQuestionId: "passport_number"), .text)
    }

    func testKindDefaultsToTextForNameFields() {
        XCTAssertEqual(naming.kind(forQuestionId: "firstName"), .text)
    }
}
