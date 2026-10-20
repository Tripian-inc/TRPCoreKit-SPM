import UIKit
import TRPBookingKit

/// Builds the view for a row of a step layout.
struct BookingRowFactory {

    let theme: TRPBookingTheme
    let text: TRPBookingText

    func view(for row: FormRow, value: JSONValue?) -> UIView {
        switch row.kind {
        case .sectionHeader(let title):
            return BookingInputRowView.label(title, font: theme.title, color: theme.text)
        case .travelerHeader(let index):
            return BookingInputRowView.label(text(.traveller, index + 1), font: theme.headline, color: theme.text)
        case .date(let block):
            return BookingDateInputRow(rowId: row.id, title: text(.date), hint: nil, isOptional: false, isTime: false,
                                       value: value?.stringValue, dates: block.mode == .available ? block.dates : nil,
                                       minimum: block.range?.from ?? block.min, maximum: block.range?.to ?? block.max,
                                       theme: theme, text: text)
        case .choice(let block):
            let options = block.options.map(BookingPickOption.init)
            return BookingPickRow(rowId: row.id, title: text(.chooseOption), hint: nil, isOptional: false, options: options,
                                  allowsMultiple: block.multiple == true, segmented: false, value: value, theme: theme, text: text)
        case .quantity(let block):
            return BookingQuantityRow(block: block, value: value, theme: theme, text: text)
        case .consent(let block):
            let links = (block.links ?? []).compactMap { link in URL(string: link.url).map { (title: link.title, url: $0) } }
            return BookingToggleRow(rowId: row.id, title: block.text, hint: nil, links: links,
                                    isOn: value?.boolValue ?? false, theme: theme, text: text)
        case .field(let field):
            return fieldView(row: row, field: field, value: value)
        case .summary(let block):
            return summaryView(block)
        case .notice(let block):
            return noticeView(block)
        case .image(let block):
            return BookingImageView(block: block, theme: theme)
        }
    }

    private func fieldView(row: FormRow, field: BookingContract.Field, value: JSONValue?) -> UIView {
        let traits = field.traits
        let isOptional = !field.required && field.requiredWhen == nil
        let options = (traits?.options ?? []).map { BookingPickOption(value: $0.value, title: $0.title) }
        switch field {
        case .date, .time:
            let isTime: Bool
            if case .time = field { isTime = true } else { isTime = false }
            return BookingDateInputRow(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, isTime: isTime,
                                       value: value?.stringValue, dates: nil, minimum: nil, maximum: nil, theme: theme, text: text)
        case .select, .multiSelect:
            let multiple: Bool
            if case .multiSelect = field { multiple = true } else { multiple = false }
            return BookingPickRow(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, options: options,
                                  allowsMultiple: multiple, segmented: traits?.control == "segmented", value: value, theme: theme, text: text)
        case .country where !options.isEmpty:
            return BookingPickRow(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, options: options,
                                  allowsMultiple: false, segmented: false, value: value, theme: theme, text: text)
        case .boolean:
            return BookingToggleRow(rowId: row.id, title: field.label, hint: traits?.hint, links: [],
                                    isOn: value?.boolValue ?? false, theme: theme, text: text)
        case .numberWithUnit:
            return BookingNumberWithUnitRow(row: row, spec: field, value: value, isOptional: isOptional, theme: theme, text: text)
        case .locationOrText:
            return BookingLocationOrTextRow(row: row, spec: field, value: value, isOptional: isOptional, theme: theme, text: text)
        case .text, .multiline, .email, .phone, .number, .country, .unknown:
            return BookingTextInputRow(row: row, field: field, value: value, isOptional: isOptional, theme: theme, text: text)
        }
    }

    private func summaryView(_ block: BookingContract.SummaryBlock) -> UIView {
        let formatting = BookingFormatting()
        var rows = block.lines.map {
            BookingSummaryRow(title: [$0.title, $0.detail].compactMap { $0 }.joined(separator: "\n"),
                              value: formatting.price($0.amount) ?? "")
        }
        rows.append(BookingSummaryRow(title: text(.total), value: formatting.price(block.total) ?? block.total.amount, isEmphasized: true))
        let column = UIStackView(arrangedSubviews: [BookingKeyValueView(rows: rows, theme: theme)])
        column.axis = .vertical
        column.spacing = 8
        if let note = block.note, !note.isEmpty {
            column.addArrangedSubview(BookingInputRowView.label(note, font: theme.caption, color: theme.secondaryText))
        }
        return column
    }

    private func noticeView(_ block: BookingContract.NoticeBlock) -> UIView {
        let color: UIColor
        switch block.tone.value {
        case .warning: color = theme.warning
        case .critical: color = theme.error
        case .info, .unknown: color = theme.primary
        }
        let label = BookingInputRowView.label(block.text, font: theme.body, color: theme.text)
        label.translatesAutoresizingMaskIntoConstraints = false
        let box = UIView()
        box.backgroundColor = color.withAlphaComponent(0.12)
        box.layer.cornerRadius = 8
        box.layer.borderWidth = 1
        box.layer.borderColor = color.cgColor
        box.addSubview(label)
        label.pin(to: box, inset: 12)
        return box
    }
}

/// An image block, loaded from its url without caching.
final class BookingImageView: UIImageView {

    private var task: URLSessionDataTask?

    init(block: BookingContract.ImageBlock, theme: TRPBookingTheme) {
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = 8
        backgroundColor = theme.surface
        isAccessibilityElement = true
        accessibilityLabel = block.alt
        accessibilityTraits = .image
        let ratio = block.aspectRatio.flatMap { $0 > 0 ? $0 : nil } ?? 16.0 / 9.0
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(1 / ratio)).isActive = true
        guard let url = URL(string: block.url) else { return }
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.image = image }
        }
        task?.resume()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        task?.cancel()
    }
}
