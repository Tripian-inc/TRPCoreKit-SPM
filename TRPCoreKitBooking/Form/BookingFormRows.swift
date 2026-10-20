import UIKit
import TRPBookingKit

typealias JSONValue = BookingContract.JSONValue

/// The frame of an input row: a title, an optional hint, the control and a line for its problem.
class BookingInputRowView: UIView {

    let rowId: String
    let theme: TRPBookingTheme
    let text: TRPBookingText
    var onChange: ((JSONValue?) -> Void)?
    /// Asked to show a picker; the row updates itself from the picker's callbacks.
    var onPick: ((UIViewController) -> Void)?
    var onOpenURL: ((URL) -> Void)?
    let column = UIStackView()
    private let problemLabel = UILabel()

    init(rowId: String, title: String?, hint: String?, isOptional: Bool, theme: TRPBookingTheme, text: TRPBookingText) {
        self.rowId = rowId
        self.theme = theme
        self.text = text
        super.init(frame: .zero)
        column.axis = .vertical
        column.spacing = 6
        if let title, !title.isEmpty {
            column.addArrangedSubview(Self.label(isOptional ? "\(title) \(text(.optionalSuffix))" : title, font: theme.headline, color: theme.text))
        }
        if let hint, !hint.isEmpty {
            column.addArrangedSubview(Self.label(hint, font: theme.caption, color: theme.secondaryText))
        }
        problemLabel.font = theme.caption
        problemLabel.textColor = theme.error
        problemLabel.numberOfLines = 0
        problemLabel.isHidden = true
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        column.pin(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func addControl(_ control: UIView) {
        column.addArrangedSubview(control)
        column.addArrangedSubview(problemLabel)
    }

    var hasProblem: Bool { !problemLabel.isHidden }

    func show(problem: String?) {
        problemLabel.text = problem
        problemLabel.isHidden = problem == nil
        if let problem { UIAccessibility.post(notification: .announcement, argument: problem) }
    }

    static func label(_ value: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = value
        return label
    }

    static func fieldButton(theme: TRPBookingTheme) -> UIButton {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = theme.body
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.backgroundColor = theme.background
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }

    static func textField(theme: TRPBookingTheme) -> UITextField {
        let field = UITextField()
        field.font = theme.body
        field.textColor = theme.text
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return field
    }
}

/// A one-line or multiline text field for text, email, phone, number and free-form country answers.
final class BookingTextInputRow: BookingInputRowView, UITextFieldDelegate, UITextViewDelegate {

    private let isNumber: Bool
    private let maxLength: Int?

    init(row: FormRow, field: BookingContract.Field, value: JSONValue?, isOptional: Bool, theme: TRPBookingTheme, text: TRPBookingText) {
        let traits = field.traits
        isNumber = field.fieldTypeRawValue == BookingContract.FieldType.number.rawValue
        maxLength = traits?.validation?.maxLength
        super.init(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, theme: theme, text: text)
        let current = value?.stringValue ?? value?.numberValue.map(BookingTextInputRow.format)
        if case .multiline = field {
            let view = UITextView()
            view.font = theme.body
            view.textColor = theme.text
            view.backgroundColor = theme.background
            view.layer.cornerRadius = 8
            view.isScrollEnabled = false
            view.text = current
            view.delegate = self
            view.accessibilityLabel = field.label
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
            addControl(view)
            return
        }
        let view = Self.textField(theme: theme)
        view.text = current
        view.placeholder = traits?.placeholder
        view.delegate = self
        view.accessibilityLabel = field.label
        view.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        Self.configure(view, for: field, autofill: traits?.autofill)
        addControl(view)
    }

    static func format(_ number: Double) -> String {
        number.rounded() == number ? String(Int(number)) : String(number)
    }

    static func number(from text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }

    private static func configure(_ view: UITextField, for field: BookingContract.Field, autofill: String?) {
        switch field {
        case .email:
            view.keyboardType = .emailAddress
            view.autocapitalizationType = .none
            view.autocorrectionType = .no
        case .phone:
            view.keyboardType = .phonePad
        case .number:
            view.keyboardType = .decimalPad
        case .country:
            view.autocapitalizationType = .allCharacters
            view.autocorrectionType = .no
        default:
            view.autocapitalizationType = .words
        }
        view.textContentType = BookingAutofill.contentType(for: autofill, field: field)
    }

    @objc private func textChanged(_ sender: UITextField) {
        report(sender.text ?? "")
    }

    func textViewDidChange(_ textView: UITextView) {
        report(textView.text ?? "")
    }

    private func report(_ value: String) {
        if isNumber {
            onChange?(Self.number(from: value).map(JSONValue.number) ?? (value.isEmpty ? nil : .string(value)))
        } else {
            onChange?(.string(value))
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        fits(textField.text, range, string)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        fits(textView.text, range, text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func fits(_ current: String?, _ range: NSRange, _ replacement: String) -> Bool {
        guard let maxLength, let current, let range = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: range, with: replacement).count <= maxLength
    }
}

/// Maps the contract's `autofill` hints onto iOS text content types.
enum BookingAutofill {

    static func contentType(for autofill: String?, field: BookingContract.Field) -> UITextContentType? {
        switch autofill {
        case "email"?: return .emailAddress
        case "tel"?: return .telephoneNumber
        case "passport"?: return nil
        case let hint?:
            let known: [UITextContentType] = [.givenName, .familyName, .name, .middleName, .namePrefix, .nameSuffix,
                                              .nickname, .addressCity, .addressState, .addressCityAndState,
                                              .postalCode, .countryName, .streetAddressLine1, .streetAddressLine2,
                                              .fullStreetAddress, .organizationName, .location]
            return known.first { $0.rawValue == hint }
        case nil:
            switch field {
            case .email: return .emailAddress
            case .phone: return .telephoneNumber
            default: return nil
            }
        }
    }
}

/// A date or time picker. A date block with a list of dates picks from that list instead.
final class BookingDateInputRow: BookingInputRowView {

    private let picker = UIDatePicker()
    private let listButton: UIButton
    private let isTime: Bool
    private var dates: [String] = []
    private let formatting = BookingFormatting()

    init(rowId: String, title: String?, hint: String?, isOptional: Bool, isTime: Bool, value: String?,
         dates: [String]?, minimum: String?, maximum: String?, theme: TRPBookingTheme, text: TRPBookingText) {
        self.isTime = isTime
        listButton = Self.fieldButton(theme: theme)
        super.init(rowId: rowId, title: title, hint: hint, isOptional: isOptional, theme: theme, text: text)
        if let dates, !dates.isEmpty {
            self.dates = dates
            listButton.accessibilityLabel = title
            listButton.addTarget(self, action: #selector(pickFromList), for: .touchUpInside)
            addControl(listButton)
            showListValue(value)
            return
        }
        picker.datePickerMode = isTime ? .time : .date
        if #available(iOS 14.0, *) { picker.preferredDatePickerStyle = .compact }
        picker.timeZone = TimeZone(identifier: "UTC")
        picker.locale = isTime ? Locale(identifier: "en_GB") : .current
        picker.tintColor = theme.primary
        picker.accessibilityLabel = title
        picker.minimumDate = minimum.flatMap(formatter.date(from:))
        picker.maximumDate = maximum.flatMap(formatter.date(from:))
        if let value, let date = formatter.date(from: value) { picker.date = date }
        picker.addTarget(self, action: #selector(picked), for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [UIView(), picker])
        row.alignment = .center
        addControl(row)
    }

    private var formatter: DateFormatter {
        isTime ? BookingFormatting.isoTime : BookingFormatting.isoDate
    }

    @objc private func picked() {
        onChange?(.string(formatter.string(from: picker.date)))
    }

    @objc private func pickFromList() {
        let items = dates.map { BookingChoiceItem(id: $0, title: formatting.day($0)) }
        let list = BookingChoiceListViewController(title: text(.chooseDate), items: items, theme: theme, text: text)
        list.onSelect = { [weak self, weak list] item in
            self?.showListValue(item.id)
            self?.onChange?(.string(item.id))
            list?.navigationController?.popViewController(animated: true)
        }
        onPick?(list)
    }

    private func showListValue(_ value: String?) {
        listButton.setTitle(value.map(formatting.day) ?? text(.selectValue), for: .normal)
        listButton.setTitleColor(value == nil ? theme.secondaryText : theme.text, for: .normal)
    }
}

/// One option a pick row offers.
struct BookingPickOption: Hashable {
    let value: String
    let title: String
    var subtitle: String?
    var detail: String?
    var isEnabled = true
    var price: String?
    var badge: String?
}

extension BookingPickOption {

    /// An option of a contract `.choice` block, with its price formatted and its badge kept apart.
    init(_ option: BookingContract.ChoiceBlock.Option) {
        self.init(value: option.value, title: option.title, subtitle: option.subtitle, isEnabled: option.disabled != true,
                  price: BookingFormatting().price(option.price), badge: option.badge)
    }
}

/// Picks one or several options: a segmented control for a few options, otherwise a list on its own screen.
final class BookingPickRow: BookingInputRowView {

    private let options: [BookingPickOption]
    private let allowsMultiple: Bool
    private let listTitle: String
    private var selected: [String]
    private let button: UIButton
    private var segments: UISegmentedControl?

    init(rowId: String, title: String?, hint: String?, isOptional: Bool, options: [BookingPickOption], allowsMultiple: Bool,
         segmented: Bool, value: JSONValue?, theme: TRPBookingTheme, text: TRPBookingText) {
        self.options = options
        self.allowsMultiple = allowsMultiple
        self.listTitle = title ?? text(.chooseOption)
        selected = value?.arrayValue?.compactMap(\.stringValue) ?? value?.stringValue.map { [$0] } ?? []
        button = Self.fieldButton(theme: theme)
        super.init(rowId: rowId, title: title, hint: hint, isOptional: isOptional, theme: theme, text: text)
        if segmented, !allowsMultiple, (2...4).contains(options.count) {
            let control = UISegmentedControl(items: options.map(\.title))
            control.selectedSegmentIndex = options.firstIndex { selected.contains($0.value) } ?? UISegmentedControl.noSegment
            control.accessibilityLabel = title
            control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
            segments = control
            addControl(control)
        } else {
            button.accessibilityLabel = title
            button.addTarget(self, action: #selector(pick), for: .touchUpInside)
            addControl(button)
            refresh()
        }
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        guard options.indices.contains(sender.selectedSegmentIndex) else { return }
        select([options[sender.selectedSegmentIndex].value])
    }

    @objc private func pick() {
        let items = options.map { BookingChoiceItem(id: $0.value, title: $0.title, subtitle: $0.subtitle, detail: $0.detail, isEnabled: $0.isEnabled,
                                                  price: $0.price, badge: $0.badge) }
        let list = BookingChoiceListViewController(title: listTitle, items: items, allowsMultiple: allowsMultiple,
                                                   selectedIds: selected, theme: theme, text: text)
        list.onSelect = { [weak self, weak list] item in
            self?.select([item.id])
            list?.navigationController?.popViewController(animated: true)
        }
        list.onSelectMany = { [weak self, weak list] values in
            self?.select(values)
            list?.navigationController?.popViewController(animated: true)
        }
        onPick?(list)
    }

    private func select(_ values: [String]) {
        selected = values
        refresh()
        onChange?(allowsMultiple ? .array(values.map(JSONValue.string)) : values.first.map(JSONValue.string))
    }

    private func refresh() {
        guard segments == nil else { return }
        let titles = options.filter { selected.contains($0.value) }.map(\.title)
        button.setTitle(titles.isEmpty ? text(.selectValue) : titles.joined(separator: ", "), for: .normal)
        button.setTitleColor(titles.isEmpty ? theme.secondaryText : theme.text, for: .normal)
    }
}

/// A stepper per unit of a quantity block; the answer holds every unit, zeros included.
final class BookingQuantityRow: BookingInputRowView {

    private var counts: [String: Int]
    private var labels: [String: UILabel] = [:]

    init(block: BookingContract.QuantityBlock, value: JSONValue?, theme: TRPBookingTheme, text: TRPBookingText) {
        var counts: [String: Int] = [:]
        for item in block.items {
            counts[item.unitId] = Int(value?.objectValue?[item.unitId]?.numberValue ?? Double(item.min))
        }
        self.counts = counts
        super.init(rowId: block.id, title: text(.travellers), hint: nil, isOptional: false, theme: theme, text: text)
        let column = UIStackView(arrangedSubviews: block.items.map(makeLine))
        column.axis = .vertical
        column.spacing = 12
        addControl(column)
    }

    private func makeLine(for item: BookingContract.QuantityBlock.Item) -> UIView {
        let titles = UIStackView(arrangedSubviews: [Self.label(item.title, font: theme.headline, color: theme.text)])
        titles.axis = .vertical
        titles.spacing = 2
        let detail = [item.subtitle, BookingFormatting().price(item.price)].compactMap { $0 }.joined(separator: " · ")
        if !detail.isEmpty { titles.addArrangedSubview(Self.label(detail, font: theme.caption, color: theme.secondaryText)) }
        let count = Self.label(String(counts[item.unitId] ?? 0), font: theme.headline, color: theme.text)
        count.textAlignment = .center
        count.setContentHuggingPriority(.required, for: .horizontal)
        count.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        labels[item.unitId] = count
        let stepper = BookingUnitStepper(unitId: item.unitId, allowed: item.allowed)
        stepper.minimumValue = Double(item.allowed?.min() ?? item.min)
        stepper.maximumValue = Double(max(item.min, item.allowed?.max() ?? item.max))
        stepper.value = Double(counts[item.unitId] ?? 0)
        stepper.tintColor = theme.primary
        stepper.accessibilityLabel = item.title
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        stepper.addTarget(self, action: #selector(stepped(_:)), for: .valueChanged)
        let line = UIStackView(arrangedSubviews: [titles, count, stepper])
        line.spacing = 12
        line.alignment = .center
        return line
    }

    @objc private func stepped(_ stepper: BookingUnitStepper) {
        var value = Int(stepper.value)
        if let allowed = stepper.allowed?.sorted(), !allowed.contains(value) {
            let previous = counts[stepper.unitId] ?? 0
            value = value > previous ? (allowed.first { $0 > previous } ?? previous) : (allowed.last { $0 < previous } ?? previous)
            stepper.value = Double(value)
        }
        counts[stepper.unitId] = value
        labels[stepper.unitId]?.text = String(value)
        onChange?(.object(counts.mapValues { .number(Double($0)) }))
    }
}

/// A stepper that remembers which unit it counts and which counts are allowed.
final class BookingUnitStepper: UIStepper {
    let unitId: String
    let allowed: [Int]?

    init(unitId: String, allowed: [Int]?) {
        self.unitId = unitId
        self.allowed = allowed
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

/// A switch with its text: a boolean field, or a consent with its links.
final class BookingToggleRow: BookingInputRowView {

    private let toggle = UISwitch()
    private let links: [URL]

    init(rowId: String, title: String, hint: String?, links: [(title: String, url: URL)], isOn: Bool,
         theme: TRPBookingTheme, text: TRPBookingText) {
        self.links = links.map(\.url)
        super.init(rowId: rowId, title: nil, hint: nil, isOptional: false, theme: theme, text: text)
        toggle.isOn = isOn
        toggle.onTintColor = theme.primary
        toggle.accessibilityLabel = title
        toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)
        let titles = UIStackView(arrangedSubviews: [Self.label(title, font: theme.body, color: theme.text)])
        titles.axis = .vertical
        titles.spacing = 4
        if let hint, !hint.isEmpty { titles.addArrangedSubview(Self.label(hint, font: theme.caption, color: theme.secondaryText)) }
        for (index, link) in links.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(link.title, for: .normal)
            button.titleLabel?.font = theme.caption
            button.tintColor = theme.primary
            button.contentHorizontalAlignment = .leading
            button.tag = index
            button.addTarget(self, action: #selector(openLink(_:)), for: .touchUpInside)
            titles.addArrangedSubview(button)
        }
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        let line = UIStackView(arrangedSubviews: [titles, toggle])
        line.spacing = 12
        line.alignment = .center
        addControl(line)
    }

    @objc private func toggled() {
        onChange?(.bool(toggle.isOn))
    }

    @objc private func openLink(_ sender: UIButton) {
        guard links.indices.contains(sender.tag) else { return }
        onOpenURL?(links[sender.tag])
    }
}

/// A number with its unit, answered as `{"value": 72, "unit": "kg"}`.
final class BookingNumberWithUnitRow: BookingInputRowView, UITextFieldDelegate {

    private let units: [BookingContract.FieldOption]
    private let field: UITextField
    private let unitControl: UISegmentedControl

    init(row: FormRow, spec field: BookingContract.Field, value: JSONValue?, isOptional: Bool, theme: TRPBookingTheme, text: TRPBookingText) {
        let traits = field.traits
        units = traits?.units ?? []
        unitControl = UISegmentedControl(items: units.map(\.title))
        self.field = Self.textField(theme: theme)
        super.init(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, theme: theme, text: text)
        let object = value?.objectValue
        self.field.keyboardType = .decimalPad
        self.field.delegate = self
        self.field.accessibilityLabel = field.label
        self.field.text = object?["value"]?.numberValue.map(BookingTextInputRow.format)
        self.field.addTarget(self, action: #selector(changed), for: .editingChanged)
        let unit = object?["unit"]?.stringValue
        unitControl.selectedSegmentIndex = units.firstIndex { $0.value == unit } ?? (units.isEmpty ? UISegmentedControl.noSegment : 0)
        unitControl.addTarget(self, action: #selector(changed), for: .valueChanged)
        unitControl.setContentHuggingPriority(.required, for: .horizontal)
        let line = UIStackView(arrangedSubviews: [self.field, unitControl])
        line.spacing = 12
        line.alignment = .center
        addControl(line)
    }

    @objc private func changed() {
        guard let number = BookingTextInputRow.number(from: field.text ?? ""), units.indices.contains(unitControl.selectedSegmentIndex) else {
            onChange?(nil)
            return
        }
        onChange?(.object(["value": .number(number), "unit": .string(units[unitControl.selectedSegmentIndex].value)]))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

/// A known place from the options, or free text: answered as `{"ref": …}` or `{"text": …}`.
final class BookingLocationOrTextRow: BookingInputRowView, UITextFieldDelegate {

    private let options: [BookingContract.FieldOption]
    private let button: UIButton
    private let field: UITextField
    private var ref: String?
    private let listTitle: String

    init(row: FormRow, spec field: BookingContract.Field, value: JSONValue?, isOptional: Bool, theme: TRPBookingTheme, text: TRPBookingText) {
        let traits = field.traits
        options = traits?.options ?? []
        listTitle = field.label
        button = Self.fieldButton(theme: theme)
        self.field = Self.textField(theme: theme)
        super.init(rowId: row.id, title: field.label, hint: traits?.hint, isOptional: isOptional, theme: theme, text: text)
        ref = value?.objectValue?["ref"]?.stringValue
        button.accessibilityLabel = field.label
        button.addTarget(self, action: #selector(pick), for: .touchUpInside)
        self.field.placeholder = traits?.placeholder ?? text(.orTypeIt)
        self.field.text = value?.objectValue?["text"]?.stringValue
        self.field.delegate = self
        self.field.addTarget(self, action: #selector(typed), for: .editingChanged)
        let column = UIStackView(arrangedSubviews: options.isEmpty ? [self.field] : [button, self.field])
        column.axis = .vertical
        column.spacing = 8
        addControl(column)
        refresh()
    }

    @objc private func pick() {
        let items = options.map { BookingChoiceItem(id: $0.value, title: $0.title) }
        let list = BookingChoiceListViewController(title: listTitle, items: items, selectedIds: [ref].compactMap { $0 },
                                                   theme: theme, text: text)
        list.onSelect = { [weak self, weak list] item in
            self?.ref = item.id
            self?.field.text = nil
            self?.refresh()
            self?.onChange?(.object(["ref": .string(item.id)]))
            list?.navigationController?.popViewController(animated: true)
        }
        onPick?(list)
    }

    @objc private func typed() {
        ref = nil
        refresh()
        let value = field.text ?? ""
        onChange?(value.isEmpty ? nil : .object(["text": .string(value)]))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func refresh() {
        let title = options.first { $0.value == ref }?.title
        button.setTitle(title ?? text(.selectValue), for: .normal)
        button.setTitleColor(title == nil ? theme.secondaryText : theme.text, for: .normal)
    }
}

extension UIView {

    func pin(to container: UIView, inset: CGFloat = 0) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset),
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset)
        ])
    }
}
