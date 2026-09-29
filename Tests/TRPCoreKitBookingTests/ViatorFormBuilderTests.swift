import XCTest
import TRPBookingKit
@testable import TRPCoreKitBooking

final class ViatorFormBuilderTests: XCTestCase {

    private let text = TRPBookingText.default

    private func builder(context: ViatorProductContext, paxMix: [ViatorPax] = [ViatorPax(ageBand: .adult, numberOfTravelers: 1)],
                          optionCode: String = "") -> ViatorFormBuilder {
        ViatorFormBuilder(context: context, paxMix: paxMix, optionCode: optionCode, text: text)
    }

    // MARK: Booker fields

    func testBookerSectionFieldsAreRequiredWithExpectedKinds() throws {
        let context = try ViatorFixtures.context()
        let sut = builder(context: context)
        let fields = sut.sections[0].fields
        XCTAssertEqual(fields.map(\.id), ["booker.firstName", "booker.lastName", "booker.email", "booker.phone"])
        XCTAssertTrue(fields.allSatisfy(\.isRequired))
        XCTAssertEqual(fields.map(\.kind), [.text, .text, .email, .phone])
    }

    func testLanguageFieldAbsentWhenProductHasNoLanguageGuides() throws {
        let context = try ViatorFixtures.context()
        let sut = builder(context: context)
        XCTAssertFalse(sut.sections[0].fields.contains { $0.id == "booker.language" })
    }

    func testLanguageFieldPreselectsWhenExactlyOneGuideExists() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en")])
        let sut = builder(context: context)
        let field = sut.sections[0].fields.first { $0.id == "booker.language" }!
        XCTAssertTrue(field.isRequired)
        XCTAssertEqual(field.initialValues, ["0"])
    }

    func testLanguageFieldHasNoPreselectionWhenSeveralGuidesExist() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en"), (type: "GUIDE", language: "es")])
        let sut = builder(context: context)
        let field = sut.sections[0].fields.first { $0.id == "booker.language" }!
        XCTAssertEqual(field.initialValues, [])
    }

    func testLanguageGuidesPreferTheSelectedOptionOverTheProduct() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en")],
                                                   optionCode: "OPT1", optionLanguageGuides: [(type: "AUDIO", language: "fr")])
        let sut = builder(context: context, optionCode: "OPT1")
        XCTAssertEqual(sut.languageGuides.map(\.type), ["AUDIO"])
    }

    func testLanguageGuidesFallBackToProductWhenOptionHasNone() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en")], optionCode: "OPT1")
        let sut = builder(context: context, optionCode: "OPT1")
        XCTAssertEqual(sut.languageGuides.map(\.type), ["GUIDE"])
    }

    // MARK: questions / PICKUP_POINT exclusion

    func testQuestionsExcludePickupPoint() throws {
        let pickupQuestion = try ViatorFixtures.bookingQuestion(id: "PICKUP_POINT")
        let dietQuestion = try ViatorFixtures.bookingQuestion(id: "DIET")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["PICKUP_POINT", "DIET"], questions: [pickupQuestion, dietQuestion])
        let sut = builder(context: context)
        XCTAssertEqual(sut.questions.map(\.id), ["DIET"])
    }

    func testQuestionsExcludeIdsNotInProductBookingQuestionIds() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "DIET")
        let context = try ViatorFixtures.context(bookingQuestionIds: [], questions: [question])
        let sut = builder(context: context)
        XCTAssertTrue(sut.questions.isEmpty)
    }

    func testPerBookingQuestionFieldIdUsesQPrefix() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "DIET", group: "PER_BOOKING", required: "MANDATORY")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["DIET"], questions: [question])
        let sut = builder(context: context)
        let section = sut.sections.first { $0.title == "Your details" }!
        XCTAssertEqual(section.fields.map(\.id), ["q.DIET"])
        XCTAssertTrue(section.fields[0].isRequired)
    }

    func testPerTravelerQuestionFieldIdsRepeatPerTravelerNumber() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "WEIGHT", group: "PER_TRAVELER")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["WEIGHT"], questions: [question])
        let sut = builder(context: context, paxMix: [ViatorPax(ageBand: .adult, numberOfTravelers: 2)])
        let travelerSections = sut.sections.filter { $0.title?.hasPrefix("Traveller") == true }
        XCTAssertEqual(travelerSections.count, 2)
        XCTAssertEqual(travelerSections[0].fields.map(\.id), ["t.1.WEIGHT"])
        XCTAssertEqual(travelerSections[1].fields.map(\.id), ["t.2.WEIGHT"])
    }

    func testTravelerSectionTitleIncludesBandExceptForPlainTraveler() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "WEIGHT", group: "PER_TRAVELER")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["WEIGHT"], questions: [question])
        let sut = builder(context: context, paxMix: [ViatorPax(ageBand: .child, numberOfTravelers: 1), ViatorPax(ageBand: .traveler, numberOfTravelers: 1)])
        let travelerSections = sut.sections.filter { $0.title?.hasPrefix("Traveller") == true }
        XCTAssertEqual(travelerSections[0].title, "Traveller 1 · Child")
        XCTAssertEqual(travelerSections[1].title, "Traveller 2")
    }

    func testUnitFieldAppearsOnlyWhenQuestionRequiresUnitAndHasUnits() throws {
        let withUnits = try ViatorFixtures.bookingQuestion(id: "HEIGHT", type: "NUMBER_AND_UNIT", units: ["CM", "IN"])
        let withoutUnits = try ViatorFixtures.bookingQuestion(id: "WEIGHT", type: "NUMBER_AND_UNIT", units: [])
        let context = try ViatorFixtures.context(bookingQuestionIds: ["HEIGHT", "WEIGHT"], questions: [withUnits, withoutUnits])
        let sut = builder(context: context)
        let section = sut.sections.first { $0.title == "Your details" }!
        XCTAssertEqual(section.fields.map(\.id), ["q.HEIGHT", "unit.HEIGHT", "q.WEIGHT"])
    }

    func testUnitFieldPreselectsWhenExactlyOneUnitExists() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "HEIGHT", type: "NUMBER_AND_UNIT", units: ["CM"])
        let context = try ViatorFixtures.context(bookingQuestionIds: ["HEIGHT"], questions: [question])
        let sut = builder(context: context)
        let unitField = sut.sections.first { $0.title == "Your details" }!.fields.first { $0.id == "unit.HEIGHT" }!
        XCTAssertEqual(unitField.initialValues, ["CM"])
    }

    func testAllowedAnswersBecomeAHumanizedChoiceField() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "SEAT", allowedAnswers: ["FRONT_ROW", "BACK_ROW"])
        let context = try ViatorFixtures.context(bookingQuestionIds: ["SEAT"], questions: [question])
        let sut = builder(context: context)
        let field = sut.sections.first { $0.title == "Your details" }!.fields[0]
        XCTAssertEqual(field.kind, .choice([BookingFormOption(value: "FRONT_ROW", title: "Front row"),
                                             BookingFormOption(value: "BACK_ROW", title: "Back row")], allowsMultiple: false))
    }

    // MARK: Pickup section

    func testPickupSectionOmittedWhenProductDoesNotAskForIt() throws {
        let context = try ViatorFixtures.context(bookingQuestionIds: [])
        let sut = builder(context: context)
        XCTAssertFalse(sut.sections.contains { $0.title == "Pickup" })
    }

    func testPickupSectionOffersMeetAtDepartureAndResolvedLocations() throws {
        let pickupQuestion = try ViatorFixtures.bookingQuestion(id: "PICKUP_POINT", required: "OPTIONAL")
        let hotel = try ViatorFixtures.location(reference: "LOC1", name: "Hotel lobby")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["PICKUP_POINT"], questions: [pickupQuestion],
                                                   pickupLocationRefs: ["LOC1"], locations: ["LOC1": hotel])
        let sut = builder(context: context)
        let section = sut.sections.first { $0.title == "Pickup" }!
        XCTAssertEqual(section.fields[0].id, "pickup")
        guard case let .choice(options, _) = section.fields[0].kind else { return XCTFail("expected a choice field") }
        XCTAssertEqual(options.map(\.value), ["MEET_AT_DEPARTURE_POINT", "LOC1"])
        XCTAssertEqual(options[1].title, "Hotel lobby")
        XCTAssertFalse(section.fields[0].isRequired)
    }

    func testPickupSectionIsRequiredWhenQuestionIsMandatory() throws {
        let pickupQuestion = try ViatorFixtures.bookingQuestion(id: "PICKUP_POINT", required: "MANDATORY")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["PICKUP_POINT"], questions: [pickupQuestion])
        let sut = builder(context: context)
        let section = sut.sections.first { $0.title == "Pickup" }!
        XCTAssertTrue(section.fields[0].isRequired)
    }

    // MARK: details(from:)

    func testDetailsMapsBookerFieldsFromValues() throws {
        let context = try ViatorFixtures.context()
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("Ada", for: "booker.firstName")
        values.set("Lovelace", for: "booker.lastName")
        values.set("ada@example.com", for: "booker.email")
        values.set("+1 555", for: "booker.phone")
        let details = sut.details(from: values)
        XCTAssertEqual(details.firstName, "Ada")
        XCTAssertEqual(details.lastName, "Lovelace")
        XCTAssertEqual(details.email, "ada@example.com")
        XCTAssertEqual(details.phone, "+1 555")
    }

    func testDetailsMapsMeetAtDeparturePointSelection() throws {
        let pickupQuestion = try ViatorFixtures.bookingQuestion(id: "PICKUP_POINT")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["PICKUP_POINT"], questions: [pickupQuestion])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("MEET_AT_DEPARTURE_POINT", for: "pickup")
        XCTAssertEqual(sut.details(from: values).answers, [.meetAtDeparturePoint])
    }

    func testDetailsMapsLocationPickupSelection() throws {
        let pickupQuestion = try ViatorFixtures.bookingQuestion(id: "PICKUP_POINT")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["PICKUP_POINT"], questions: [pickupQuestion])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("LOC1", for: "pickup")
        XCTAssertEqual(sut.details(from: values).answers, [.pickup(at: "LOC1")])
    }

    func testDetailsOmitsPickupAnswerWhenProductDoesNotAskForIt() throws {
        let context = try ViatorFixtures.context(bookingQuestionIds: [])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("LOC1", for: "pickup")
        XCTAssertTrue(sut.details(from: values).answers.isEmpty)
    }

    func testDetailsResolvesLanguageGuideByIndex() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en"), (type: "AUDIO", language: "es")])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("1", for: "booker.language")
        XCTAssertEqual(sut.details(from: values).languageGuide?.type, "AUDIO")
    }

    func testDetailsIgnoresOutOfRangeLanguageIndex() throws {
        let context = try ViatorFixtures.context(languageGuides: [(type: "GUIDE", language: "en")])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("5", for: "booker.language")
        XCTAssertNil(sut.details(from: values).languageGuide)
    }

    func testDetailsMapsPerBookingAnswerByQuestionId() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "DIET", group: "PER_BOOKING")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["DIET"], questions: [question])
        let sut = builder(context: context)
        var values = BookingFormValues()
        values.set("Vegetarian", for: "q.DIET")
        let answers = sut.details(from: values).answers
        XCTAssertEqual(answers, [ViatorAnswer(question: "DIET", answer: "Vegetarian")])
    }

    func testDetailsMapsPerTravelerAnswersWithUnit() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "HEIGHT", type: "NUMBER_AND_UNIT", group: "PER_TRAVELER", units: ["CM", "IN"])
        let context = try ViatorFixtures.context(bookingQuestionIds: ["HEIGHT"], questions: [question])
        let sut = builder(context: context, paxMix: [ViatorPax(ageBand: .adult, numberOfTravelers: 2)])
        var values = BookingFormValues()
        values.set("180", for: "t.1.HEIGHT")
        values.set("CM", for: "t.1.unit.HEIGHT")
        values.set("70", for: "t.2.HEIGHT")
        values.set("IN", for: "t.2.unit.HEIGHT")
        let answers = sut.details(from: values).answers
        XCTAssertEqual(answers, [
            ViatorAnswer(question: "HEIGHT", answer: "180", unit: "CM", travelerNum: 1),
            ViatorAnswer(question: "HEIGHT", answer: "70", unit: "IN", travelerNum: 2)
        ])
    }

    func testDetailsSkipsPerTravelerAnswerWhenTravelerCountIsZeroAndNoValueGiven() throws {
        let question = try ViatorFixtures.bookingQuestion(id: "HEIGHT", group: "PER_TRAVELER")
        let context = try ViatorFixtures.context(bookingQuestionIds: ["HEIGHT"], questions: [question])
        let sut = builder(context: context, paxMix: [])
        let answers = sut.details(from: BookingFormValues()).answers
        XCTAssertTrue(answers.isEmpty)
    }

    // MARK: title(of:) / bandTitle

    func testTitleOfGuideAppendsHumanizedType() {
        let title = ViatorFormBuilder.title(of: ViatorLanguageGuide(type: "AUDIO_HEADSET", language: "en"))
        XCTAssertTrue(title.hasSuffix("(Audio headset)"))
    }

    func testBandTitleIsNilForPlainTravelerBand() {
        XCTAssertNil(ViatorFormBuilder.bandTitle(.traveler))
    }

    func testBandTitleIsHumanizedForOtherBands() {
        XCTAssertEqual(ViatorFormBuilder.bandTitle(.senior), "Senior")
    }

    // MARK: travelerCount / travelerBands

    func testTravelerCountSumsAcrossPaxMix() {
        let sut = builder(context: try! ViatorFixtures.context(),
                           paxMix: [ViatorPax(ageBand: .adult, numberOfTravelers: 2), ViatorPax(ageBand: .child, numberOfTravelers: 1)])
        XCTAssertEqual(sut.travelerCount, 3)
    }

    func testTravelerBandsRepeatsEachBandByItsCount() {
        let sut = builder(context: try! ViatorFixtures.context(),
                           paxMix: [ViatorPax(ageBand: .adult, numberOfTravelers: 2), ViatorPax(ageBand: .child, numberOfTravelers: 1)])
        XCTAssertEqual(sut.travelerBands, [.adult, .adult, .child])
    }
}
