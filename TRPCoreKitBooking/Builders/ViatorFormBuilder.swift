import Foundation
import TRPBookingKit

/// Builds the Viator booker form from the product's questions and turns its answers into booker details.
struct ViatorFormBuilder {

    let context: ViatorProductContext
    let paxMix: [ViatorPax]
    let optionCode: String
    let text: TRPBookingText

    var travelerCount: Int {
        paxMix.reduce(0) { $0 + $1.numberOfTravelers }
    }

    var languageGuides: [ViatorLanguageGuide] {
        let optionGuides = context.product.option(code: optionCode)?.languageGuides ?? []
        return optionGuides.isEmpty ? context.product.languageGuides : optionGuides
    }

    /// The questions this product asks, pickup left to its own field.
    var questions: [ViatorBookingQuestion] {
        context.questions.filter { context.product.bookingQuestionIds.contains($0.id) && $0.id != ViatorBookingQuestion.pickupPointId }
    }

    var asksPickup: Bool {
        context.product.bookingQuestionIds.contains(ViatorBookingQuestion.pickupPointId)
    }

    var sections: [BookingFormSection] {
        var booker = [
            BookingFormField(id: "booker.firstName", title: text(.firstName), kind: .text, isRequired: true),
            BookingFormField(id: "booker.lastName", title: text(.lastName), kind: .text, isRequired: true),
            BookingFormField(id: "booker.email", title: text(.email), kind: .email, isRequired: true),
            BookingFormField(id: "booker.phone", title: text(.phone), kind: .phone, isRequired: true)
        ]
        if !languageGuides.isEmpty {
            let options = languageGuides.enumerated().map { index, guide in
                BookingFormOption(value: String(index), title: Self.title(of: guide))
            }
            booker.append(BookingFormField(id: "booker.language", title: text(.languageGuide), kind: .choice(options, allowsMultiple: false),
                                           isRequired: true, initialValues: languageGuides.count == 1 ? ["0"] : []))
        }
        var sections = [BookingFormSection(title: text(.contact), fields: booker)]

        let perBooking = questions.filter { $0.group == .perBooking }.flatMap { fields(for: $0, travelerNum: nil) }
        if !perBooking.isEmpty {
            sections.append(BookingFormSection(title: text(.details), fields: perBooking))
        }
        let perTraveler = questions.filter { $0.group == .perTraveler }
        if !perTraveler.isEmpty {
            for (index, band) in travelerBands.enumerated() {
                let number = index + 1
                let title = [text(.traveller, number), Self.bandTitle(band)].compactMap { $0 }.joined(separator: " · ")
                sections.append(BookingFormSection(title: title, fields: perTraveler.flatMap { fields(for: $0, travelerNum: number) }))
            }
        }
        if asksPickup {
            var options = [BookingFormOption(value: ViatorAnswer.meetAtDeparturePoint.answer, title: text(.meetAtDeparture))]
            options += context.pickupLocations.map { location in
                BookingFormOption(value: location.reference, title: [location.name, location.address].compactMap { $0 }.joined(separator: ", "))
            }
            let isRequired = context.questions.first { $0.id == ViatorBookingQuestion.pickupPointId }?.required == .mandatory
            sections.append(BookingFormSection(title: text(.pickup), fields: [
                BookingFormField(id: "pickup", title: text(.pickupPoint), kind: .choice(options, allowsMultiple: false), isRequired: isRequired)
            ]))
        }
        return sections
    }

    func details(from values: BookingFormValues) -> ViatorBookerDetails {
        var answers: [ViatorAnswer] = []
        for question in questions {
            switch question.group {
            case .perBooking:
                answers += answer(question, values: values, travelerNum: nil)
            case .perTraveler:
                for number in 1...max(1, travelerCount) {
                    answers += answer(question, values: values, travelerNum: number)
                }
            }
        }
        if asksPickup, let pickup = values.value("pickup") {
            answers.append(pickup == ViatorAnswer.meetAtDeparturePoint.answer ? .meetAtDeparturePoint : .pickup(at: pickup))
        }
        let language = values.value("booker.language").flatMap(Int.init).flatMap { languageGuides.indices.contains($0) ? languageGuides[$0] : nil }
        return ViatorBookerDetails(firstName: values.value("booker.firstName") ?? "",
                                   lastName: values.value("booker.lastName") ?? "",
                                   email: values.value("booker.email") ?? "",
                                   phone: values.value("booker.phone") ?? "",
                                   answers: answers,
                                   languageGuide: language)
    }

    /// The age band of each traveller, in the order travellers are numbered.
    var travelerBands: [ViatorAgeBand] {
        paxMix.flatMap { Array(repeating: $0.ageBand, count: max(0, $0.numberOfTravelers)) }
    }

    static func fieldId(_ question: ViatorBookingQuestion, travelerNum: Int?) -> String {
        travelerNum.map { "t.\($0).\(question.id)" } ?? "q.\(question.id)"
    }

    static func unitFieldId(_ question: ViatorBookingQuestion, travelerNum: Int?) -> String {
        travelerNum.map { "t.\($0).unit.\(question.id)" } ?? "unit.\(question.id)"
    }

    private func fields(for question: ViatorBookingQuestion, travelerNum: Int?) -> [BookingFormField] {
        let isRequired = question.required == .mandatory
        let kind: BookingFormFieldKind
        if !question.allowedAnswers.isEmpty {
            kind = .choice(question.allowedAnswers.map { BookingFormOption(value: $0, title: BookingFieldNaming.humanized($0)) }, allowsMultiple: false)
        } else {
            switch question.type.uppercased() {
            case "DATE": kind = .date
            case "NUMBER_AND_UNIT", "NUMBER", "INTEGER": kind = .number
            default: kind = .text
            }
        }
        var fields = [BookingFormField(id: Self.fieldId(question, travelerNum: travelerNum), title: question.label, detail: question.hint,
                                       kind: kind, isRequired: isRequired, maxLength: question.maxLength)]
        if question.requiresUnit, !question.units.isEmpty {
            let units = question.units.map { BookingFormOption(value: $0, title: BookingFieldNaming.humanized($0)) }
            fields.append(BookingFormField(id: Self.unitFieldId(question, travelerNum: travelerNum), title: text(.unit),
                                           kind: .choice(units, allowsMultiple: false), isRequired: isRequired,
                                           initialValues: question.units.count == 1 ? question.units : []))
        }
        return fields
    }

    private func answer(_ question: ViatorBookingQuestion, values: BookingFormValues, travelerNum: Int?) -> [ViatorAnswer] {
        guard let value = values.value(Self.fieldId(question, travelerNum: travelerNum)) else { return [] }
        let unit = question.requiresUnit ? values.value(Self.unitFieldId(question, travelerNum: travelerNum)) : nil
        return [ViatorAnswer(question: question.id, answer: value, unit: unit, travelerNum: travelerNum)]
    }

    static func title(of guide: ViatorLanguageGuide) -> String {
        let language = Locale.current.localizedString(forLanguageCode: guide.language) ?? guide.language
        return "\(language) (\(BookingFieldNaming.humanized(guide.type)))"
    }

    static func bandTitle(_ band: ViatorAgeBand) -> String? {
        band == .traveler ? nil : BookingFieldNaming.humanized(band.rawValue)
    }
}
