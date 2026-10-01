import Foundation
import TRPBookingKit

/// Turns one block `type` into rows.
public protocol BlockRenderer {
    /// The block `type` this renderer handles.
    var type: String { get }
    /// Whether the block answers the step; such a block is never skipped, whatever its `onUnsupported` says.
    var producesAnswer: Bool { get }
    /// The rows for `block`, or nil when it cannot be shown.
    func rows(for block: BookingContract.Block, in registry: BlockRegistry) -> [FormRow]?
}

/// The block renderers and field types the client supports, and how a step is laid out with them.
///
/// A block without a renderer, or whose `requires` asks for a newer feature, follows its `onUnsupported`:
/// `skip` leaves it out, anything else makes the step non-renderable.
public struct BlockRegistry {

    public private(set) var renderers: [String: BlockRenderer]
    public var fields: FieldRegistry

    public init(renderers: [BlockRenderer], fields: FieldRegistry = .standard) {
        self.renderers = Dictionary(renderers.map { ($0.type, $0) }, uniquingKeysWith: { _, last in last })
        self.fields = fields
    }

    /// The nine block types of the contract version this package speaks.
    public static var standard: BlockRegistry {
        BlockRegistry(renderers: BookingContract.BlockType.allCases.filter { $0 != .unknown }.map(StandardBlockRenderer.init))
    }

    public mutating func register(_ renderer: BlockRenderer) {
        renderers[renderer.type] = renderer
    }

    public mutating func remove(_ type: String) {
        renderers[type] = nil
    }

    /// Whether every feature in `requires` is known at the required version or older.
    ///
    /// Versions are contract dates compared with `BookingContract.version`, or integers where 1 is what this
    /// package implements.
    public func supports(_ requires: [String: BookingContract.JSONValue]?) -> Bool {
        guard let requires else { return true }
        return requires.allSatisfy { feature, minimum in
            guard renderers[feature] != nil || fields.supportedTypes.contains(feature) else { return false }
            switch minimum {
            case .string(let version): return version <= BookingContract.version
            case .number(let version): return version <= 1
            default: return false
            }
        }
    }

    /// Lays `step` out; `unsupported` lists what forced the fallback, if anything did.
    public func layout(for step: BookingContract.Step) -> StepLayout {
        var groups: [RowGroup] = []
        var unsupported: [String] = []
        var travelerIndex: Int?
        for block in step.blocks {
            switch resolve(block) {
            case .rows(var rows):
                if case .field(let field) = block, let index = field.travelerIndex, index != travelerIndex {
                    rows.insert(FormRow(id: "traveler.\(index)", kind: .travelerHeader(index)), at: 0)
                    travelerIndex = index
                }
                groups.append(RowGroup(id: block.id, rows: rows))
            case .skip:
                continue
            case .fallback(let type):
                unsupported.append(type)
            }
        }
        return StepLayout(groups: groups, unsupported: unsupported)
    }

    /// The rows of `blocks` in order, or nil when one of them needs the fallback.
    public func rows(for blocks: [BookingContract.Block]) -> [FormRow]? {
        var rows: [FormRow] = []
        for block in blocks {
            switch resolve(block) {
            case .rows(let blockRows): rows += blockRows
            case .skip: continue
            case .fallback: return nil
            }
        }
        return rows
    }

    private enum Resolution {
        case rows([FormRow])
        case skip
        case fallback(String)
    }

    private func resolve(_ block: BookingContract.Block) -> Resolution {
        let type = block.typeRawValue
        let renderer = renderers[type]
        let requires = (try? BookingContract.JSONValue(encoding: block))?.objectValue?["requires"]?.objectValue
        if let renderer, supports(requires), let rows = renderer.rows(for: block, in: self) {
            return .rows(rows)
        }
        let producesAnswer = renderer?.producesAnswer ?? false
        if block.onUnsupported == .skip && !producesAnswer {
            return .skip
        }
        if case .field(let field) = block {
            return .fallback("\(type):\(field.fieldTypeRawValue)")
        }
        return .fallback(type)
    }
}

/// Renders the block types of the contract version this package speaks.
struct StandardBlockRenderer: BlockRenderer {

    let blockType: BookingContract.BlockType

    init(_ blockType: BookingContract.BlockType) {
        self.blockType = blockType
    }

    var type: String { blockType.rawValue }

    var producesAnswer: Bool {
        switch blockType {
        case .date, .choice, .quantity, .field, .consent: return true
        case .summary, .notice, .image, .section, .unknown: return false
        }
    }

    func rows(for block: BookingContract.Block, in registry: BlockRegistry) -> [FormRow]? {
        switch block {
        case .date(let date) where blockType == .date:
            guard date.mode.value != .unknown else { return nil }
            return [FormRow(id: date.id, kind: .date(date))]
        case .choice(let choice) where blockType == .choice:
            return [FormRow(id: choice.id, kind: .choice(choice))]
        case .quantity(let quantity) where blockType == .quantity:
            return [FormRow(id: quantity.id, kind: .quantity(quantity))]
        case .field(let field) where blockType == .field:
            guard let resolved = registry.fields.resolve(field, supports: registry.supports) else { return nil }
            return [FormRow(id: resolved.id, kind: .field(resolved))]
        case .consent(let consent) where blockType == .consent:
            return [FormRow(id: consent.id, kind: .consent(consent))]
        case .summary(let summary) where blockType == .summary:
            return [FormRow(id: summary.id, kind: .summary(summary))]
        case .notice(let notice) where blockType == .notice:
            return [FormRow(id: notice.id, kind: .notice(notice))]
        case .image(let image) where blockType == .image:
            return [FormRow(id: image.id, kind: .image(image))]
        case .section(let section) where blockType == .section:
            guard let nested = registry.rows(for: section.blocks) else { return nil }
            return [FormRow(id: section.id, kind: .sectionHeader(section.title))] + nested
        default:
            return nil
        }
    }
}

/// The `Tripian-Client-Capabilities` header value: the block types, field types and next actions the client handles.
public enum BookingCapabilities {

    public static func header(blocks: BlockRegistry, actions: [String]) -> String {
        let blockTypes = blocks.renderers.keys.sorted().joined(separator: ",")
        let fieldTypes = blocks.fields.supportedTypes.sorted().joined(separator: ",")
        let actionTypes = Set(actions).sorted().joined(separator: ",")
        return "blocks=\(blockTypes); fields=\(fieldTypes); actions=\(actionTypes)"
    }
}
