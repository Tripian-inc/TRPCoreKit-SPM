import Foundation
import TRPBookingKit

/// Why an input row cannot be submitted yet.
public enum FieldProblem: Hashable {
    case required
    case invalid(message: String?)
    case invalidEmail
    case quantityTotal(min: Int, max: Int)
}

/// The values a traveler has entered on one step, the visibility they imply, and the `answers` they submit.
///
/// Values start from each block's and field's default. Hidden rows keep their value but neither submit it
/// nor make other rows visible.
public struct FormState {

    public let layout: StepLayout
    public private(set) var values: [String: BookingContract.JSONValue]
    public private(set) var visibleRowIds: Set<String> = []

    public init(layout: StepLayout) {
        self.layout = layout
        values = Dictionary(layout.rows.compactMap { row in Self.defaultValue(of: row).map { (row.id, $0) } },
                            uniquingKeysWith: { first, _ in first })
        updateVisibility()
    }

    public func value(for id: String) -> BookingContract.JSONValue? {
        values[id]
    }

    public mutating func set(_ value: BookingContract.JSONValue?, for id: String) {
        values[id] = value
        updateVisibility()
    }

    /// Whether the row is shown; rows that are not fields are always shown.
    public func isVisible(_ row: FormRow) -> Bool {
        visibleRowIds.contains(row.id)
    }

    /// The rows currently shown, grouped as in the layout; an emptied group is left out.
    public var visibleGroups: [RowGroup] {
        layout.groups.compactMap { group in
            let rows = group.rows.filter(isVisible)
            return rows.contains(where: { $0.producesAnswer || !isHeader($0) }) ? RowGroup(id: group.id, rows: rows) : nil
        }
    }

    /// The `answers` of a submit: every visible input row with a value, in the contract's shape.
    public var answers: BookingContract.Answers {
        answers(visible: visibleRowIds)
    }

    /// The problems of the visible input rows, keyed by row id; empty when the step can be submitted.
    public func problems() -> [String: FieldProblem] {
        let current = answers
        var problems: [String: FieldProblem] = [:]
        for row in layout.rows where row.producesAnswer && isVisible(row) {
            if let problem = problem(of: row, answers: current) {
                problems[row.id] = problem
            }
        }
        return problems
    }

    private func isHeader(_ row: FormRow) -> Bool {
        switch row.kind {
        case .sectionHeader, .travelerHeader: return true
        default: return false
        }
    }

    private mutating func updateVisibility() {
        var visible = Set(layout.rows.map(\.id))
        for _ in 0...layout.rows.count {
            let current = answers(visible: visible)
            let next = Set(layout.rows.filter { $0.field?.isVisible(answers: current) ?? true }.map(\.id))
            if next == visible { break }
            visible = next
        }
        visibleRowIds = visible
    }

    private func answers(visible: Set<String>) -> BookingContract.Answers {
        var answers = BookingContract.Answers()
        for row in layout.rows where row.producesAnswer && visible.contains(row.id) {
            if let value = Self.submitted(values[row.id], for: row) {
                answers[row.id] = value
            }
        }
        return answers
    }

    private static func submitted(_ value: BookingContract.JSONValue?, for row: FormRow) -> BookingContract.JSONValue? {
        guard let value else { return nil }
        if case .consent = row.kind {
            return value.boolValue == true ? .bool(true) : nil
        }
        switch value {
        case .null: return nil
        case .string(let text): return text.isEmpty ? nil : value
        case .array(let items): return items.isEmpty ? nil : value
        case .object(let members): return members.isEmpty ? nil : value
        default: return value
        }
    }

    private static func defaultValue(of row: FormRow) -> BookingContract.JSONValue? {
        switch row.kind {
        case .date(let date):
            return date.defaultValue.map(BookingContract.JSONValue.string)
        case .choice(let choice):
            switch choice.defaultValue {
            case .single(let value): return .string(value)
            case .multiple(let values): return .array(values.map(BookingContract.JSONValue.string))
            case nil: return nil
            }
        case .quantity(let quantity):
            let units = quantity.items.map { item in
                (item.unitId, BookingContract.JSONValue.number(Double(quantity.defaultValue?[item.unitId] ?? item.min)))
            }
            return .object(Dictionary(units, uniquingKeysWith: { first, _ in first }))
        case .consent(let consent):
            return consent.defaultValue == true ? .bool(true) : nil
        case .field(let field):
            guard let value = (try? BookingContract.JSONValue(encoding: field))?.objectValue?["defaultValue"],
                  value != .null else { return nil }
            return value
        case .sectionHeader, .travelerHeader, .summary, .notice, .image:
            return nil
        }
    }

    private func problem(of row: FormRow, answers: BookingContract.Answers) -> FieldProblem? {
        let value = answers[row.id]
        switch row.kind {
        case .date:
            return value == nil ? .required : nil
        case .choice(let choice):
            return choice.multiple == true || value != nil ? nil : .required
        case .quantity(let quantity):
            let counts = value?.objectValue ?? [:]
            let total = counts.values.compactMap(\.numberValue).reduce(0, +)
            let fits = quantity.items.allSatisfy { item in
                let count = Int(counts[item.unitId]?.numberValue ?? 0)
                return count >= item.min && count <= item.max && (item.allowed.map { $0.contains(count) || count == 0 } ?? true)
            }
            let inTotal = total >= Double(quantity.total.min) && total <= Double(quantity.total.max)
            return fits && inTotal ? nil : .quantityTotal(min: quantity.total.min, max: quantity.total.max)
        case .consent(let consent):
            return consent.required && value == nil ? .required : nil
        case .field(let field):
            guard let value else { return field.isRequired(answers: answers) ? .required : nil }
            return Self.problem(of: value, in: field)
        case .sectionHeader, .travelerHeader, .summary, .notice, .image:
            return nil
        }
    }

    private static func problem(of value: BookingContract.JSONValue, in field: BookingContract.Field) -> FieldProblem? {
        let validation = field.traits?.validation
        if let text = value.stringValue {
            if let minLength = validation?.minLength, text.count < minLength { return .invalid(message: validation?.message) }
            if let maxLength = validation?.maxLength, text.count > maxLength { return .invalid(message: validation?.message) }
            if let pattern = validation?.pattern, text.range(of: "^(?:\(pattern))$", options: .regularExpression) == nil {
                return .invalid(message: validation?.message)
            }
            if case .email = field, text.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) == nil {
                return .invalidEmail
            }
        }
        let number = value.numberValue ?? value.objectValue?["value"]?.numberValue
        if let number {
            if let min = validation?.min, number < min { return .invalid(message: validation?.message) }
            if let max = validation?.max, number > max { return .invalid(message: validation?.message) }
        }
        return nil
    }
}

/// Reads the ISO 8601 instants the contract uses for `holdExpiresAt` and `priceValidUntil`.
public enum CheckoutDeadline {

    public static func date(from text: String?) -> Date? {
        guard let text else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }

    /// The earlier of the hold and price deadlines, the moment the step must be refreshed.
    public static func next(for checkout: BookingContract.Checkout) -> Date? {
        [date(from: checkout.holdExpiresAt), date(from: checkout.priceValidUntil)].compactMap { $0 }.min()
    }
}
