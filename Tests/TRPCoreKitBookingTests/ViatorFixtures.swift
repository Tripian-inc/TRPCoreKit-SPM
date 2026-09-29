import Foundation
@testable import TRPBookingKit

/// Builds `ViatorProduct`/`ViatorBookingQuestion`/`ViatorLocation` through their JSON `Decodable`
/// initializers, and `ViatorProductContext` through its internal memberwise one.
enum ViatorFixtures {

    static func product(
        bookingQuestionIds: [String] = [],
        languageGuides: [(type: String, language: String)] = [],
        optionCode: String? = nil,
        optionLanguageGuides: [(type: String, language: String)] = [],
        pickupLocationRefs: [String] = []
    ) throws -> ViatorProduct {
        func guideJSON(_ guides: [(type: String, language: String)]) -> String {
            guides.map { "{\"type\":\"\($0.type)\",\"language\":\"\($0.language)\"}" }.joined(separator: ",")
        }
        let optionsJSON: String
        if let optionCode {
            optionsJSON = "[{\"productOptionCode\":\"\(optionCode)\",\"title\":\"Option\",\"languageGuides\":[\(guideJSON(optionLanguageGuides))]}]"
        } else {
            optionsJSON = "[]"
        }
        let bookingQuestionsJSON = bookingQuestionIds.map { "\"\($0)\"" }.joined(separator: ",")
        let pickupLocationsJSON = pickupLocationRefs.map { "{\"location\":{\"ref\":\"\($0)\"}}" }.joined(separator: ",")
        let json = """
        {
          "productCode": "PRODUCT1",
          "title": "Test product",
          "timeZone": "UTC",
          "bookingRequirements": {"minTravelersPerBooking": 1, "maxTravelersPerBooking": 10},
          "bookingQuestions": [\(bookingQuestionsJSON)],
          "languageGuides": [\(guideJSON(languageGuides))],
          "productOptions": \(optionsJSON),
          "logistics": {
            "travelerPickup": {"pickupOptionType": "LOCATIONS", "locations": [\(pickupLocationsJSON)]}
          }
        }
        """
        return try JSONDecoder().decode(ViatorProduct.self, from: Data(json.utf8))
    }

    static func bookingQuestion(
        id: String,
        type: String = "STRING",
        group: String = "PER_BOOKING",
        label: String? = nil,
        required: String = "OPTIONAL",
        units: [String] = [],
        allowedAnswers: [String] = []
    ) throws -> ViatorBookingQuestion {
        func stringArray(_ values: [String]) -> String {
            values.map { "\"\($0)\"" }.joined(separator: ",")
        }
        let json = """
        {
          "id": "\(id)",
          "type": "\(type)",
          "group": "\(group)",
          "label": "\(label ?? id)",
          "required": "\(required)",
          "units": [\(stringArray(units))],
          "allowedAnswers": [\(stringArray(allowedAnswers))]
        }
        """
        return try JSONDecoder().decode(ViatorBookingQuestion.self, from: Data(json.utf8))
    }

    static func location(reference: String, name: String? = nil) throws -> ViatorLocation {
        let json = """
        {"reference": "\(reference)", "name": \(name.map { "\"\($0)\"" } ?? "null")}
        """
        return try JSONDecoder().decode(ViatorLocation.self, from: Data(json.utf8))
    }

    static func emptyCalendar() throws -> ViatorAvailabilityCalendar {
        let json = "{\"productCode\":\"PRODUCT1\",\"bookableItems\":[]}"
        let schedule = try JSONDecoder().decode(ViatorSchedule.self, from: Data(json.utf8))
        return ViatorAvailabilityCalendar(schedule: schedule, timeZone: TimeZone(identifier: "UTC")!)
    }

    static func context(
        bookingQuestionIds: [String] = [],
        languageGuides: [(type: String, language: String)] = [],
        optionCode: String? = nil,
        optionLanguageGuides: [(type: String, language: String)] = [],
        questions: [ViatorBookingQuestion] = [],
        pickupLocationRefs: [String] = [],
        locations: [String: ViatorLocation] = [:]
    ) throws -> ViatorProductContext {
        ViatorProductContext(
            product: try product(bookingQuestionIds: bookingQuestionIds, languageGuides: languageGuides,
                                  optionCode: optionCode, optionLanguageGuides: optionLanguageGuides,
                                  pickupLocationRefs: pickupLocationRefs),
            calendar: try emptyCalendar(),
            questions: questions,
            locations: locations
        )
    }
}
