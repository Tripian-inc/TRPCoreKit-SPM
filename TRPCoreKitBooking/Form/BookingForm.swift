import Foundation

/// One selectable answer of a choice field.
struct BookingFormOption: Hashable {
    let value: String
    let title: String
}

enum BookingFormFieldKind: Hashable {
    case text
    case multiline
    case email
    case phone
    case number
    /// Answered as `yyyy-MM-dd`.
    case date
    case choice([BookingFormOption], allowsMultiple: Bool)
    case stepper(minimum: Int, maximum: Int)
}

/// A field of a booking form. `id` is how a builder finds the answer again.
struct BookingFormField: Hashable {
    let id: String
    let title: String
    var detail: String?
    let kind: BookingFormFieldKind
    let isRequired: Bool
    var maxLength: Int?
    var initialValues: [String] = []
}

struct BookingFormSection: Hashable {
    var title: String?
    var footer: String?
    var fields: [BookingFormField]
}

/// The answers of a form, by field id.
struct BookingFormValues: Hashable {

    private(set) var storage: [String: [String]]

    init(_ storage: [String: [String]] = [:]) {
        self.storage = storage
    }

    init(sections: [BookingFormSection]) {
        var storage: [String: [String]] = [:]
        for field in sections.flatMap(\.fields) where !field.initialValues.isEmpty {
            storage[field.id] = field.initialValues
        }
        self.storage = storage
    }

    /// The answers with blank ones dropped.
    func values(_ id: String) -> [String] {
        (storage[id] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    func value(_ id: String) -> String? {
        values(id).first
    }

    func int(_ id: String) -> Int {
        value(id).flatMap(Int.init) ?? 0
    }

    mutating func set(_ values: [String], for id: String) {
        storage[id] = values
    }

    mutating func set(_ value: String?, for id: String) {
        storage[id] = value.map { [$0] } ?? []
    }
}

/// The checks every form gets before its builder sees the answers.
struct BookingFormChecker {

    let text: TRPBookingText

    func issues(_ values: BookingFormValues, sections: [BookingFormSection]) -> [String] {
        var issues: [String] = []
        for field in sections.flatMap(\.fields) {
            let answers = values.values(field.id)
            if field.isRequired, answers.isEmpty, !Self.isStepper(field) {
                issues.append(text(.requiredField, field.title))
                continue
            }
            if field.kind == .email, let email = answers.first, !Self.isEmail(email) {
                issues.append(text(.invalidEmail))
            }
        }
        return issues
    }

    static func isEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."), !parts[1].hasPrefix("."), !parts[1].hasSuffix(".") else {
            return false
        }
        return !value.contains(" ")
    }

    private static func isStepper(_ field: BookingFormField) -> Bool {
        if case .stepper = field.kind { return true }
        return false
    }
}
