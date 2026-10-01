import Foundation
import TRPBookingKit

/// The field types the client renders, keyed by `fieldType`; a field of another type is shown as its `degradesTo`.
public struct FieldRegistry {

    public private(set) var supportedTypes: Set<String>

    public init(supportedTypes: Set<String>) {
        self.supportedTypes = supportedTypes
    }

    /// Every field type of the contract version this package speaks.
    public static let standard = FieldRegistry(supportedTypes: Set(
        BookingContract.FieldType.allCases.filter { $0 != .unknown }.map(\.rawValue)))

    public mutating func remove(_ fieldType: String) {
        supportedTypes.remove(fieldType)
    }

    /// The field as the client renders it: itself, its `degradesTo` form, or nil when neither is supported.
    ///
    /// `supports` checks the field's `requires`; a degraded field drops them along with its original type.
    func resolve(_ field: BookingContract.Field, supports: ([String: BookingContract.JSONValue]?) -> Bool) -> BookingContract.Field? {
        var object = (try? BookingContract.JSONValue(encoding: field))?.objectValue ?? [:]
        if !field.isUnknown, supportedTypes.contains(field.fieldTypeRawValue), supports(object["requires"]?.objectValue) {
            return field
        }
        guard let target = field.degradesTo?.rawValue, target != field.fieldTypeRawValue,
              supportedTypes.contains(target) else { return nil }
        object["fieldType"] = .string(target)
        object["degradesTo"] = nil
        object["requires"] = nil
        guard let degraded = try? BookingContract.JSONValue.object(object).decode(as: BookingContract.Field.self),
              !degraded.isUnknown else { return nil }
        return degraded
    }
}

extension BookingContract.Field {

    var isUnknown: Bool {
        if case .unknown = self { return true }
        return false
    }

    /// The answer-independent parts of the field, nil for an unknown type.
    var traits: FieldTraits? {
        switch self {
        case .text(let spec), .multiline(let spec), .email(let spec), .phone(let spec), .date(let spec),
             .time(let spec), .select(let spec), .country(let spec):
            return FieldTraits(spec)
        case .number(let spec): return FieldTraits(spec)
        case .numberWithUnit(let spec): return FieldTraits(spec)
        case .multiSelect(let spec): return FieldTraits(spec)
        case .boolean(let spec): return FieldTraits(spec)
        case .locationOrText(let spec): return FieldTraits(spec)
        case .unknown: return nil
        }
    }

    /// The traveler the field belongs to, when it is traveler-scoped.
    var travelerIndex: Int? {
        guard let traits, traits.scope?.value == .traveler else { return nil }
        return traits.travelerIndex
    }
}

/// The parts of a field spec every field type shares.
struct FieldTraits {
    let scope: BookingContract.OpenEnum<BookingContract.FieldScope>?
    let travelerIndex: Int?
    let validation: BookingContract.Validation?
    let autofill: String?
    let placeholder: String?
    let hint: String?
    let control: String?
    let options: [BookingContract.FieldOption]
    let units: [BookingContract.FieldOption]

    init<Answer>(_ spec: BookingContract.FieldSpec<Answer>) {
        scope = spec.scope
        travelerIndex = spec.travelerIndex
        validation = spec.validation
        autofill = spec.autofill
        placeholder = spec.placeholder
        hint = spec.hint
        control = spec.control
        options = spec.options ?? []
        units = spec.units ?? []
    }
}
