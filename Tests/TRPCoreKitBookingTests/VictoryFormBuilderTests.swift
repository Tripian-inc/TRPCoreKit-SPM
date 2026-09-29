import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

final class VictoryFormBuilderTests: XCTestCase {

    private let text = TRPBookingText.default
    private let locale = Locale(identifier: "en_US")

    private func builder() -> VictoryFormBuilder {
        VictoryFormBuilder(text: text, locale: locale)
    }

    func testContactSectionFieldIdsAndRequiredFlags() {
        let fields = builder().sections[0].fields
        XCTAssertEqual(fields.map(\.id), ["name", "email", "phone"])
        XCTAssertEqual(fields.map(\.isRequired), [true, true, false])
        XCTAssertEqual(fields.map(\.kind), [.text, .email, .phone])
    }

    func testAddressSectionFieldIdsAndRequiredFlags() {
        let fields = builder().sections[1].fields
        XCTAssertEqual(fields.map(\.id), ["street", "extended", "city", "region", "postalCode", "country"])
        XCTAssertEqual(fields.map(\.isRequired), [true, false, true, false, true, true])
    }

    func testCountryFieldPreselectsTheLocaleRegion() {
        let field = builder().sections[1].fields.last!
        XCTAssertEqual(field.id, "country")
        XCTAssertEqual(field.initialValues, ["US"])
    }

    func testCountryFieldOffersEveryIsoRegionSortedByLocalizedName() {
        guard case let .choice(options, allowsMultiple) = builder().sections[1].fields.last!.kind else {
            return XCTFail("expected a choice field")
        }
        XCTAssertFalse(allowsMultiple)
        XCTAssertTrue(options.contains { $0.value == "US" && $0.title == "United States" })
        let titles = options.map(\.title)
        XCTAssertEqual(titles, titles.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
    }

    func testBuyerMapsRequiredAndOptionalFields() {
        var values = BookingFormValues()
        values.set("Ada Lovelace", for: "name")
        values.set("ada@example.com", for: "email")
        values.set("+1 555 0100", for: "phone")
        values.set("123 Main St", for: "street")
        values.set("Apt 4", for: "extended")
        values.set("Springfield", for: "city")
        values.set("IL", for: "region")
        values.set("62704", for: "postalCode")
        values.set("US", for: "country")
        let buyer = builder().buyer(from: values)
        XCTAssertEqual(buyer.name, "Ada Lovelace")
        XCTAssertEqual(buyer.email, "ada@example.com")
        XCTAssertEqual(buyer.phoneNumber, "+1 555 0100")
        XCTAssertEqual(buyer.billingAddress.streetAddress, "123 Main St")
        XCTAssertEqual(buyer.billingAddress.extendedAddress, "Apt 4")
        XCTAssertEqual(buyer.billingAddress.locality, "Springfield")
        XCTAssertEqual(buyer.billingAddress.region, "IL")
        XCTAssertEqual(buyer.billingAddress.postalCode, "62704")
        XCTAssertEqual(buyer.billingAddress.countryCode, "US")
    }

    func testBuyerLeavesOptionalFieldsNilWhenMissing() {
        var values = BookingFormValues()
        values.set("Ada", for: "name")
        values.set("ada@example.com", for: "email")
        values.set("123 Main St", for: "street")
        values.set("Springfield", for: "city")
        values.set("62704", for: "postalCode")
        values.set("US", for: "country")
        let buyer = builder().buyer(from: values)
        XCTAssertNil(buyer.phoneNumber)
        XCTAssertNil(buyer.billingAddress.extendedAddress)
        XCTAssertNil(buyer.billingAddress.region)
        XCTAssertNil(buyer.phoneCountryCode)
    }
}
