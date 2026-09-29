import Foundation

/// Titles and keyboards for provider field ids that come without a label.
struct BookingFieldNaming {

    let text: TRPBookingText

    func title(forQuestionId questionId: String) -> String {
        switch Self.normalized(questionId) {
        case "firstname": return text(.firstName)
        case "lastname", "surname": return text(.lastName)
        case "email", "emailaddress": return text(.email)
        case "phone", "phonenumber", "mobile", "mobilephone": return text(.phone)
        case "fullname", "name": return text(.fullName)
        default: return Self.humanized(questionId)
        }
    }

    func kind(forQuestionId questionId: String) -> BookingFormFieldKind {
        switch Self.normalized(questionId) {
        case "email", "emailaddress": return .email
        case "phone", "phonenumber", "mobile", "mobilephone": return .phone
        case "dob", "dateofbirth", "birthdate", "birthday": return .date
        default: return .text
        }
    }

    /// `"passport_number"` and `"passportNumber"` both become `"Passport number"`.
    static func humanized(_ id: String) -> String {
        var words: [String] = []
        var current = ""
        for character in id {
            if character == "_" || character == "-" || character == " " {
                if !current.isEmpty { words.append(current) }
                current = ""
            } else if character.isUppercase, let last = current.last, last.isLowercase {
                words.append(current)
                current = String(character)
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { words.append(current) }
        let sentence = words.map { $0.lowercased() }.joined(separator: " ")
        if sentence == "dob" { return "Date of birth" }
        return sentence.prefix(1).uppercased() + sentence.dropFirst()
    }

    static func normalized(_ id: String) -> String {
        id.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
