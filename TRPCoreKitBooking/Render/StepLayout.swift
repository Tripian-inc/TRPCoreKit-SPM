import Foundation
import TRPBookingKit

/// What one row of a step shows; the input kinds carry the contract block or field they answer.
public enum RowKind: Hashable {
    case sectionHeader(String)
    case travelerHeader(Int)
    case date(BookingContract.DateBlock)
    case choice(BookingContract.ChoiceBlock)
    case quantity(BookingContract.QuantityBlock)
    /// A field already resolved to a type the client renders, after `degradesTo` when needed.
    case field(BookingContract.Field)
    case consent(BookingContract.ConsentBlock)
    case summary(BookingContract.SummaryBlock)
    case notice(BookingContract.NoticeBlock)
    case image(BookingContract.ImageBlock)
}

/// One row of a rendered step. `id` is the answer key for input rows.
public struct FormRow: Hashable {
    public let id: String
    public let kind: RowKind

    public init(id: String, kind: RowKind) {
        self.id = id
        self.kind = kind
    }

    /// Whether the row contributes to the step's answers.
    public var producesAnswer: Bool {
        switch kind {
        case .date, .choice, .quantity, .field, .consent: return true
        case .sectionHeader, .travelerHeader, .summary, .notice, .image: return false
        }
    }

    /// The field the row shows, if it is a field row.
    public var field: BookingContract.Field? {
        if case .field(let field) = kind { return field }
        return nil
    }
}

/// The rows of one top-level block of a step; a section is one group holding its nested rows.
public struct RowGroup: Hashable {
    public let id: String
    public let rows: [FormRow]

    public init(id: String, rows: [FormRow]) {
        self.id = id
        self.rows = rows
    }
}

/// A step turned into rows, UI-free. A step with `unsupported` entries is not renderable and goes to the fallback.
public struct StepLayout: Hashable {
    public let groups: [RowGroup]
    /// The block or field types that forced the fallback.
    public let unsupported: [String]

    public init(groups: [RowGroup], unsupported: [String]) {
        self.groups = groups
        self.unsupported = unsupported
    }

    public var isRenderable: Bool { unsupported.isEmpty }

    public var rows: [FormRow] { groups.flatMap(\.rows) }

    /// The total of the step's summary, the amount on screen that a submit sends as `expectedAmount`.
    public var displayedAmount: BookingContract.Money? {
        for row in rows {
            if case .summary(let summary) = row.kind { return summary.total }
        }
        return nil
    }
}
