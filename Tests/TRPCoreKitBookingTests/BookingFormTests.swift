import XCTest
@testable import TRPCoreKitBooking

final class BookingFormValuesTests: XCTestCase {

    func testValuesTrimsWhitespaceAndDropsBlankAnswers() {
        var values = BookingFormValues()
        values.set(["  Ada  ", "   ", ""], for: "name")
        XCTAssertEqual(values.values("name"), ["Ada"])
    }

    func testValueReturnsFirstNonBlankAnswer() {
        var values = BookingFormValues()
        values.set(["", "Ada", "Lovelace"], for: "name")
        XCTAssertEqual(values.value("name"), "Ada")
    }

    func testValueIsNilWhenNothingWasSet() {
        XCTAssertNil(BookingFormValues().value("missing"))
    }

    func testSetSingleValueReplacesStoredAnswers() {
        var values = BookingFormValues()
        values.set(["1", "2"], for: "count")
        values.set("3", for: "count")
        XCTAssertEqual(values.values("count"), ["3"])
    }

    func testSetNilValueClearsStoredAnswers() {
        var values = BookingFormValues()
        values.set("Ada", for: "name")
        values.set(nil, for: "name")
        XCTAssertEqual(values.values("name"), [])
    }

    func testIntParsesTheFirstValue() {
        var values = BookingFormValues()
        values.set("42", for: "age")
        XCTAssertEqual(values.int("age"), 42)
    }

    func testIntDefaultsToZeroWhenNotAnInteger() {
        var values = BookingFormValues()
        values.set("not a number", for: "age")
        XCTAssertEqual(values.int("age"), 0)
    }

    func testInitFromSectionsSeedsInitialValues() {
        let field = BookingFormField(id: "country", title: "Country", kind: .text, isRequired: true, initialValues: ["US"])
        let section = BookingFormSection(fields: [field])
        let values = BookingFormValues(sections: [section])
        XCTAssertEqual(values.value("country"), "US")
    }

    func testInitFromSectionsSkipsFieldsWithoutInitialValues() {
        let field = BookingFormField(id: "name", title: "Name", kind: .text, isRequired: true)
        let section = BookingFormSection(fields: [field])
        let values = BookingFormValues(sections: [section])
        XCTAssertNil(values.value("name"))
    }
}

final class BookingFormCheckerTests: XCTestCase {

    private let checker = BookingFormChecker(text: .default)

    private func section(_ fields: [BookingFormField]) -> [BookingFormSection] {
        [BookingFormSection(fields: fields)]
    }

    func testRequiredFieldWithNoAnswerProducesAnIssueNamingTheField() {
        let field = BookingFormField(id: "name", title: "Full name", kind: .text, isRequired: true)
        let issues = checker.issues(BookingFormValues(), sections: section([field]))
        XCTAssertEqual(issues, ["Full name is required."])
    }

    func testRequiredFieldWithAnAnswerProducesNoIssue() {
        let field = BookingFormField(id: "name", title: "Full name", kind: .text, isRequired: true)
        var values = BookingFormValues()
        values.set("Ada", for: "name")
        XCTAssertTrue(checker.issues(values, sections: section([field])).isEmpty)
    }

    func testStepperFieldIsExemptFromTheRequiredCheckEvenWhenMarkedRequired() {
        let field = BookingFormField(id: "count", title: "Tickets", kind: .stepper(minimum: 0, maximum: 10), isRequired: true)
        XCTAssertTrue(checker.issues(BookingFormValues(), sections: section([field])).isEmpty)
    }

    func testInvalidEmailProducesAnInvalidEmailIssue() {
        let field = BookingFormField(id: "email", title: "Email", kind: .email, isRequired: false)
        var values = BookingFormValues()
        values.set("not-an-email", for: "email")
        XCTAssertEqual(checker.issues(values, sections: section([field])), ["Enter a valid email address."])
    }

    func testValidEmailProducesNoIssue() {
        let field = BookingFormField(id: "email", title: "Email", kind: .email, isRequired: false)
        var values = BookingFormValues()
        values.set("ada@example.com", for: "email")
        XCTAssertTrue(checker.issues(values, sections: section([field])).isEmpty)
    }

    func testMissingRequiredEmailOnlyProducesTheRequiredIssue() {
        let field = BookingFormField(id: "email", title: "Email", kind: .email, isRequired: true)
        let issues = checker.issues(BookingFormValues(), sections: section([field]))
        XCTAssertEqual(issues, ["Email is required."])
    }

    func testIsEmailRejectsMissingAtSign() {
        XCTAssertFalse(BookingFormChecker.isEmail("ada.example.com"))
    }

    func testIsEmailRejectsDomainWithoutADot() {
        XCTAssertFalse(BookingFormChecker.isEmail("ada@example"))
    }

    func testIsEmailRejectsDomainStartingWithADot() {
        XCTAssertFalse(BookingFormChecker.isEmail("ada@.com"))
    }

    func testIsEmailRejectsSpaces() {
        XCTAssertFalse(BookingFormChecker.isEmail("ada @example.com"))
    }

    func testIsEmailAcceptsAWellFormedAddress() {
        XCTAssertTrue(BookingFormChecker.isEmail("ada@example.com"))
    }
}
