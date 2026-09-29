import Foundation
import TRPBookingKit

/// Builds the Toristy details form from booking information and turns its answers into a selection.
struct ToristyFormBuilder {

    let information: ToristyBookingInformation
    let rate: ToristyRate
    let date: BookingDate
    let startTime: ToristyStartTime
    /// Passengers per pricing category id.
    let counts: [String: Int]
    let currency: String
    let text: TRPBookingText

    private var naming: BookingFieldNaming { BookingFieldNaming(text: text) }

    /// Pricing category ids, one per passenger, in the rate's order.
    var passengerCategories: [String] {
        rate.prices.flatMap { category in Array(repeating: category.id, count: max(0, counts[category.id] ?? 0)) }
    }

    var sections: [BookingFormSection] {
        var sections: [BookingFormSection] = []
        let fields = information.fields
        let contact = fields.mainContact.map { contactField($0, prefix: "main.") }
            + fields.mainContactQuestions.map { questionField($0, id: "mainq.\($0.questionId)") }
        if !contact.isEmpty {
            sections.append(BookingFormSection(title: text(.contact), fields: contact))
        }
        if !fields.passengerContact.isEmpty || !fields.passengerQuestions.isEmpty {
            for (index, categoryId) in passengerCategories.enumerated() {
                let passengerFields = fields.passengerContact.map { contactField($0, prefix: "pax.\(index).detail.") }
                    + fields.passengerQuestions.map { questionField($0, id: "pax.\(index).q.\($0.questionId)") }
                let categoryName = rate.category(id: categoryId)?.name
                let title = [text(.traveller, index + 1), categoryName].compactMap { $0 }.joined(separator: " · ")
                sections.append(BookingFormSection(title: title, fields: passengerFields))
            }
        }
        if let pickup = transferSection(.pickup) {
            sections.append(pickup)
        }
        if let dropoff = transferSection(.dropoff) {
            sections.append(dropoff)
        }
        return sections
    }

    func selection(from values: BookingFormValues) -> ToristySelection {
        let fields = information.fields
        let mainContact = fields.mainContact.compactMap { answer(values, id: "main.\($0.questionId)", questionId: $0.questionId) }
        let bookingAnswers = fields.mainContactQuestions.compactMap { answer(values, id: "mainq.\($0.questionId)", questionId: $0.questionId) }
        let passengers = passengerCategories.enumerated().map { index, categoryId in
            ToristyPassenger(
                pricingCategoryId: categoryId,
                details: fields.passengerContact.compactMap { answer(values, id: "pax.\(index).detail.\($0.questionId)", questionId: $0.questionId) },
                answers: fields.passengerQuestions.compactMap { answer(values, id: "pax.\(index).q.\($0.questionId)", questionId: $0.questionId) }
            )
        }
        return ToristySelection(serviceId: information.serviceId, rateId: rate.id, date: date, startTime: startTime,
                                mainContact: mainContact, passengers: passengers, bookingAnswers: bookingAnswers,
                                pickup: transfer(.pickup, values: values), dropoff: transfer(.dropoff, values: values),
                                currency: currency)
    }

    /// The email the customer typed, for the payment receipt.
    func customerEmail(from values: BookingFormValues) -> String? {
        information.fields.mainContact
            .first { naming.kind(forQuestionId: $0.questionId) == .email }
            .flatMap { values.value("main.\($0.questionId)") }
    }

    enum Transfer: String {
        case pickup
        case dropoff
    }

    func selectionType(_ transfer: Transfer) -> ToristyStartTimeRate.SelectionType? {
        let departureRate = startTime.rate(id: rate.id)
        switch transfer {
        case .pickup:
            if startTime.isPickupSoldOut { return .unavailable }
            return departureRate?.pickupSelection ?? (rate.pickup == nil ? .unavailable : .optional)
        case .dropoff:
            return departureRate?.dropoffSelection ?? (rate.dropoff == nil ? .unavailable : .optional)
        }
    }

    private func points(_ transfer: Transfer) -> [ToristyMeetingPoint] {
        transfer == .pickup ? information.pickupPoints : information.dropoffPoints
    }

    private func transferSection(_ transfer: Transfer) -> BookingFormSection? {
        let type = selectionType(transfer)
        guard let type, type != .unavailable else { return nil }
        let isRequired = type == .preselected
        let points = points(transfer)
        var fields: [BookingFormField] = []
        if !points.isEmpty {
            fields.append(BookingFormField(id: "\(transfer.rawValue).place", title: text(.pickupPoint),
                                           kind: .choice(points.map { BookingFormOption(value: String($0.id), title: $0.title) }, allowsMultiple: false),
                                           isRequired: isRequired))
        }
        fields.append(BookingFormField(id: "\(transfer.rawValue).desc", title: text(.pickupNote), kind: .multiline,
                                       isRequired: isRequired && points.isEmpty))
        return BookingFormSection(title: text(transfer == .pickup ? .pickup : .dropoff), fields: fields)
    }

    private func transfer(_ transfer: Transfer, values: BookingFormValues) -> ToristyTransferSelection? {
        guard let type = selectionType(transfer), type != .unavailable else { return nil }
        let placeId = values.value("\(transfer.rawValue).place").flatMap(Int.init)
        let description = values.value("\(transfer.rawValue).desc")
        guard placeId != nil || description != nil || type == .preselected else { return nil }
        return ToristyTransferSelection(placeId: placeId, description: description)
    }

    private func contactField(_ field: ToristyContactField, prefix: String) -> BookingFormField {
        BookingFormField(id: prefix + field.questionId, title: naming.title(forQuestionId: field.questionId),
                         kind: naming.kind(forQuestionId: field.questionId), isRequired: field.required)
    }

    private func questionField(_ question: ToristyQuestion, id: String) -> BookingFormField {
        let kind: BookingFormFieldKind
        if !question.options.isEmpty {
            kind = .choice(question.options.map { BookingFormOption(value: $0.value, title: $0.name) }, allowsMultiple: question.allowsMultiple)
        } else {
            kind = Self.kind(forDataType: question.dataType)
        }
        let title = question.question.isEmpty ? naming.title(forQuestionId: question.questionId) : question.question
        return BookingFormField(id: id, title: title, kind: kind, isRequired: question.required)
    }

    static func kind(forDataType dataType: String?) -> BookingFormFieldKind {
        let type = dataType?.lowercased() ?? ""
        if type.contains("date") { return .date }
        if type.contains("email") { return .email }
        if type.contains("phone") { return .phone }
        if type.contains("int") || type.contains("number") || type.contains("decimal") { return .number }
        if type.contains("textarea") || type.contains("long") { return .multiline }
        return .text
    }

    private func answer(_ values: BookingFormValues, id: String, questionId: String) -> ToristyAnswer? {
        let answers = values.values(id)
        return answers.isEmpty ? nil : ToristyAnswer(questionId: questionId, values: answers)
    }
}
