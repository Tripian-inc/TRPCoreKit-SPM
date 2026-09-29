import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

final class ToristyFormBuilderTests: XCTestCase {

    private let text = TRPBookingText.default

    private func information(
        mainContact: [ToristyContactField] = [],
        mainContactQuestions: [ToristyQuestion] = [],
        passengerContact: [ToristyContactField] = [],
        passengerQuestions: [ToristyQuestion] = [],
        pickupPoints: [ToristyMeetingPoint] = [],
        dropoffPoints: [ToristyMeetingPoint] = []
    ) -> ToristyBookingInformation {
        ToristyBookingInformation(serviceId: 1, currency: "USD", startingPrice: nil, lowestPrice: nil,
                                   fields: ToristyBookingFields(mainContact: mainContact, mainContactQuestions: mainContactQuestions,
                                                                 passengerContact: passengerContact, passengerQuestions: passengerQuestions),
                                   rates: [], cancellationPolicy: nil, cancellationRules: [],
                                   pickupPoints: pickupPoints, dropoffPoints: dropoffPoints)
    }

    private func rate(id: String = "5", prices: [ToristyPricingCategory] = [], pickup: ToristyTransferPricing? = nil, dropoff: ToristyTransferPricing? = nil) -> ToristyRate {
        ToristyRate(id: id, name: "Rate", prices: prices, pickup: pickup, dropoff: dropoff)
    }

    private func startTime(rates: [ToristyStartTimeRate] = [], isPickupSoldOut: Bool = false) -> ToristyStartTime {
        ToristyStartTime(time: "10:00:00", id: 1, availableCount: 10, isPickupSoldOut: isPickupSoldOut, rates: rates)
    }

    private func builder(
        information: ToristyBookingInformation,
        rate: ToristyRate,
        startTime: ToristyStartTime,
        counts: [String: Int] = [:]
    ) -> ToristyFormBuilder {
        ToristyFormBuilder(information: information, rate: rate, date: BookingDate(year: 2026, month: 1, day: 15)!,
                            startTime: startTime, counts: counts, currency: "USD", text: text)
    }

    // MARK: Field ids

    func testMainContactFieldIdsUseMainPrefix() {
        let info = information(mainContact: [ToristyContactField(questionId: "firstName", required: true)])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        let field = sut.sections[0].fields[0]
        XCTAssertEqual(field.id, "main.firstName")
        XCTAssertEqual(field.title, "First name")
        XCTAssertTrue(field.isRequired)
    }

    func testMainContactQuestionFieldIdsUseMainqPrefix() {
        let question = ToristyQuestion(questionId: "specialRequest", question: "", required: false)
        let info = information(mainContactQuestions: [question])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        XCTAssertEqual(sut.sections[0].fields[0].id, "mainq.specialRequest")
    }

    func testPassengerFieldIdsIncludeIndexForDetailAndQuestion() {
        let info = information(passengerContact: [ToristyContactField(questionId: "passportNumber", required: true)],
                                passengerQuestions: [ToristyQuestion(questionId: "seatPreference", question: "", required: false)])
        let category = ToristyPricingCategory(id: "adult", name: "Adult", price: 10)
        let sut = builder(information: info, rate: rate(prices: [category]), startTime: startTime(), counts: ["adult": 2])
        let firstPassengerFields = sut.sections[0].fields
        XCTAssertEqual(firstPassengerFields.map(\.id), ["pax.0.detail.passportNumber", "pax.0.q.seatPreference"])
        let secondPassengerFields = sut.sections[1].fields
        XCTAssertEqual(secondPassengerFields.map(\.id), ["pax.1.detail.passportNumber", "pax.1.q.seatPreference"])
    }

    func testPassengerSectionTitleCombinesTravellerNumberAndCategoryName() {
        let info = information(passengerContact: [ToristyContactField(questionId: "firstName", required: true)])
        let category = ToristyPricingCategory(id: "child", name: "Child", price: 5)
        let sut = builder(information: info, rate: rate(prices: [category]), startTime: startTime(), counts: ["child": 1])
        XCTAssertEqual(sut.sections[0].title, "Traveller 1 · Child")
    }

    func testPassengerSectionsOmittedWhenCategoryCountsAreZero() {
        let info = information(passengerContact: [ToristyContactField(questionId: "firstName", required: true)])
        let category = ToristyPricingCategory(id: "adult", name: "Adult", price: 10)
        let sut = builder(information: info, rate: rate(prices: [category]), startTime: startTime(), counts: [:])
        XCTAssertTrue(sut.sections.isEmpty)
    }

    // MARK: selectionType

    func testPickupUnavailableWhenNoRatePricingAndNoOverride() {
        let sut = builder(information: information(), rate: rate(pickup: nil), startTime: startTime())
        XCTAssertEqual(sut.selectionType(.pickup), .unavailable)
    }

    func testPickupOptionalWhenRateHasPickupPricingAndNoOverride() {
        let pricing = ToristyTransferPricing(prices: [], pricePer: .booking)
        let sut = builder(information: information(), rate: rate(pickup: pricing), startTime: startTime())
        XCTAssertEqual(sut.selectionType(.pickup), .optional)
    }

    func testPickupUsesStartTimeRateOverride() {
        let overrideRate = ToristyStartTimeRate(id: 5, pickupSelection: .preselected)
        let sut = builder(information: information(), rate: rate(id: "5", pickup: nil), startTime: startTime(rates: [overrideRate]))
        XCTAssertEqual(sut.selectionType(.pickup), .preselected)
    }

    func testPickupSoldOutOverridesPreselectedRate() {
        let overrideRate = ToristyStartTimeRate(id: 5, pickupSelection: .preselected)
        let sut = builder(information: information(), rate: rate(id: "5", pickup: nil),
                           startTime: startTime(rates: [overrideRate], isPickupSoldOut: true))
        XCTAssertEqual(sut.selectionType(.pickup), .unavailable)
    }

    func testDropoffHasNoSoldOutOverride() {
        let overrideRate = ToristyStartTimeRate(id: 5, dropoffSelection: .preselected)
        let sut = builder(information: information(), rate: rate(id: "5", dropoff: nil),
                           startTime: startTime(rates: [overrideRate], isPickupSoldOut: true))
        XCTAssertEqual(sut.selectionType(.dropoff), .preselected)
    }

    // MARK: transferSection / transfer, through sections and selection(from:)

    func testPickupSectionOmittedWhenUnavailable() {
        let sut = builder(information: information(), rate: rate(pickup: nil), startTime: startTime())
        XCTAssertFalse(sut.sections.contains { $0.title == "Pickup" })
    }

    func testPickupSectionHasPlaceOptionAndOptionalDescriptionWhenPointsExist() {
        let pricing = ToristyTransferPricing(prices: [], pricePer: .booking)
        let overrideRate = ToristyStartTimeRate(id: 5, pickupSelection: .preselected)
        let info = information(pickupPoints: [ToristyMeetingPoint(id: 1, title: "Hotel lobby")])
        let sut = builder(information: info, rate: rate(id: "5", pickup: pricing), startTime: startTime(rates: [overrideRate]))
        let section = sut.sections.first { $0.title == "Pickup" }!
        XCTAssertEqual(section.fields.map(\.id), ["pickup.place", "pickup.desc"])
        XCTAssertTrue(section.fields[0].isRequired)
        XCTAssertFalse(section.fields[1].isRequired)
    }

    func testPickupSectionDescriptionRequiredWhenPreselectedAndNoPoints() {
        let overrideRate = ToristyStartTimeRate(id: 5, pickupSelection: .preselected)
        let sut = builder(information: information(), rate: rate(id: "5", pickup: nil), startTime: startTime(rates: [overrideRate]))
        let section = sut.sections.first { $0.title == "Pickup" }!
        XCTAssertEqual(section.fields.map(\.id), ["pickup.desc"])
        XCTAssertTrue(section.fields[0].isRequired)
    }

    func testSelectionOmitsPickupWhenOptionalAndNoAnswerGiven() {
        let pricing = ToristyTransferPricing(prices: [], pricePer: .booking)
        let sut = builder(information: information(), rate: rate(pickup: pricing), startTime: startTime())
        let values = BookingFormValues()
        XCTAssertNil(sut.selection(from: values).pickup)
    }

    func testSelectionIncludesPickupWhenPreselectedEvenWithoutAnAnswer() {
        let overrideRate = ToristyStartTimeRate(id: 5, pickupSelection: .preselected)
        let sut = builder(information: information(), rate: rate(id: "5", pickup: nil), startTime: startTime(rates: [overrideRate]))
        let values = BookingFormValues()
        let pickup = sut.selection(from: values).pickup
        XCTAssertNotNil(pickup)
        XCTAssertNil(pickup?.placeId)
        XCTAssertNil(pickup?.description)
    }

    func testSelectionMapsPickupPlaceAndDescriptionAnswers() {
        let pricing = ToristyTransferPricing(prices: [], pricePer: .booking)
        let sut = builder(information: information(), rate: rate(pickup: pricing), startTime: startTime())
        var values = BookingFormValues()
        values.set("42", for: "pickup.place")
        values.set("Front desk", for: "pickup.desc")
        let pickup = sut.selection(from: values).pickup
        XCTAssertEqual(pickup?.placeId, 42)
        XCTAssertEqual(pickup?.description, "Front desk")
    }

    // MARK: selection(from:)

    func testSelectionMapsAnswersBackByQuestionIdWithoutBlankValues() {
        let info = information(mainContact: [ToristyContactField(questionId: "firstName", required: true),
                                              ToristyContactField(questionId: "lastName", required: false)])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        var values = BookingFormValues()
        values.set("Ada", for: "main.firstName")
        values.set("   ", for: "main.lastName")
        let selection = sut.selection(from: values)
        XCTAssertEqual(selection.mainContact.count, 1)
        XCTAssertEqual(selection.mainContact.first?.questionId, "firstName")
        XCTAssertEqual(selection.mainContact.first?.values, ["Ada"])
    }

    func testSelectionExpandsPassengersByCategoryCount() {
        let category = ToristyPricingCategory(id: "adult", name: "Adult", price: 10)
        let sut = builder(information: information(), rate: rate(prices: [category]), startTime: startTime(), counts: ["adult": 3])
        let selection = sut.selection(from: BookingFormValues())
        XCTAssertEqual(selection.passengers.map(\.pricingCategoryId), ["adult", "adult", "adult"])
    }

    // MARK: customerEmail(from:)

    func testCustomerEmailReadsMainContactFieldNamedEmail() {
        let info = information(mainContact: [ToristyContactField(questionId: "email", required: true)])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        var values = BookingFormValues()
        values.set("ada@example.com", for: "main.email")
        XCTAssertEqual(sut.customerEmail(from: values), "ada@example.com")
    }

    func testCustomerEmailNilWhenNoContactFieldIsAnEmailKind() {
        let info = information(mainContact: [ToristyContactField(questionId: "firstName", required: true)])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        var values = BookingFormValues()
        values.set("Ada", for: "main.firstName")
        XCTAssertNil(sut.customerEmail(from: values))
    }

    // MARK: BookingFieldNaming.kind(forDataType:) via question fields

    func testQuestionKindFallsBackToProviderDataType() {
        let question = ToristyQuestion(questionId: "birthCity", question: "", required: false, dataType: "TEXTAREA")
        let info = information(mainContactQuestions: [question])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        XCTAssertEqual(sut.sections[0].fields[0].kind, .multiline)
    }

    func testQuestionWithOptionsBecomesAChoiceField() {
        let option = ToristyQuestion.Option(name: "Vegetarian", value: "veg")
        let question = ToristyQuestion(questionId: "diet", question: "Diet", required: true, options: [option])
        let info = information(mainContactQuestions: [question])
        let sut = builder(information: info, rate: rate(), startTime: startTime())
        XCTAssertEqual(sut.sections[0].fields[0].kind, .choice([BookingFormOption(value: "veg", title: "Vegetarian")], allowsMultiple: false))
    }
}
