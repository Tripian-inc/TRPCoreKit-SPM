import UIKit

/// A form row: shows one field and reports its answers.
protocol BookingFormRow: UIView {
    var field: BookingFormField { get }
    var onChange: (([String]) -> Void)? { get set }
}

/// Title and optional detail above a control.
private func header(for field: BookingFormField, theme: TRPBookingTheme, text: TRPBookingText) -> UIStackView {
    let title = UILabel()
    title.font = theme.headline
    title.textColor = theme.text
    title.numberOfLines = 0
    title.adjustsFontForContentSizeCategory = true
    title.text = field.isRequired || { if case .stepper = field.kind { return true }; return false }()
        ? field.title
        : "\(field.title) \(text(.optionalSuffix))"
    let column = UIStackView(arrangedSubviews: [title])
    column.axis = .vertical
    column.spacing = 2
    if let detail = field.detail, !detail.isEmpty {
        let label = UILabel()
        label.font = theme.caption
        label.textColor = theme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = detail
        column.addArrangedSubview(label)
    }
    return column
}

final class BookingTextRow: UIView, BookingFormRow, UITextFieldDelegate, UITextViewDelegate {

    let field: BookingFormField
    var onChange: (([String]) -> Void)?
    private var textField: UITextField?
    private var textView: UITextView?

    init(field: BookingFormField, value: String?, theme: TRPBookingTheme, text: TRPBookingText) {
        self.field = field
        super.init(frame: .zero)
        let column = header(for: field, theme: theme, text: text)
        column.spacing = 6
        let input: UIView
        if field.kind == .multiline {
            let view = UITextView()
            view.font = theme.body
            view.textColor = theme.text
            view.backgroundColor = theme.background
            view.layer.cornerRadius = 8
            view.isScrollEnabled = false
            view.text = value
            view.delegate = self
            view.accessibilityLabel = field.title
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
            textView = view
            input = view
        } else {
            let view = UITextField()
            view.font = theme.body
            view.textColor = theme.text
            view.borderStyle = .roundedRect
            view.text = value
            view.delegate = self
            view.accessibilityLabel = field.title
            view.clearButtonMode = .whileEditing
            view.returnKeyType = .next
            view.addTarget(self, action: #selector(textChanged), for: .editingChanged)
            switch field.kind {
            case .email:
                view.keyboardType = .emailAddress
                view.textContentType = .emailAddress
                view.autocapitalizationType = .none
                view.autocorrectionType = .no
            case .phone:
                view.keyboardType = .phonePad
                view.textContentType = .telephoneNumber
            case .number:
                view.keyboardType = .decimalPad
            default:
                view.autocapitalizationType = .words
            }
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            textField = view
            input = view
        }
        column.addArrangedSubview(input)
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        column.pin(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func textChanged() {
        onChange?([textField?.text ?? ""])
    }

    func textViewDidChange(_ textView: UITextView) {
        onChange?([textView.text ?? ""])
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let maxLength = field.maxLength, let current = textField.text, let range = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: range, with: string).count <= maxLength
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let maxLength = field.maxLength, let current = textView.text, let range = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: range, with: text).count <= maxLength
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

final class BookingStepperRow: UIView, BookingFormRow {

    let field: BookingFormField
    var onChange: (([String]) -> Void)?
    private let stepper = UIStepper()
    private let valueLabel = UILabel()

    init(field: BookingFormField, value: Int, theme: TRPBookingTheme, text: TRPBookingText) {
        self.field = field
        super.init(frame: .zero)
        guard case .stepper(let minimum, let maximum) = field.kind else { preconditionFailure("not a stepper field") }
        stepper.minimumValue = Double(minimum)
        stepper.maximumValue = Double(max(minimum, maximum))
        stepper.value = Double(min(max(value, minimum), max(minimum, maximum)))
        stepper.tintColor = theme.primary
        stepper.accessibilityLabel = field.title
        stepper.addTarget(self, action: #selector(stepped), for: .valueChanged)
        valueLabel.font = theme.headline
        valueLabel.textColor = theme.text
        valueLabel.textAlignment = .center
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        valueLabel.text = String(Int(stepper.value))

        let labels = header(for: field, theme: theme, text: text)
        let row = UIStackView(arrangedSubviews: [labels, valueLabel, stepper])
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(row)
        row.pin(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func stepped() {
        let value = Int(stepper.value)
        valueLabel.text = String(value)
        onChange?([String(value)])
    }
}

final class BookingChoiceRow: UIView, BookingFormRow {

    let field: BookingFormField
    var onChange: (([String]) -> Void)?
    /// Asked to present the options; the row updates itself from what comes back.
    var onPick: ((BookingChoiceRow) -> Void)?
    private(set) var selected: [String]
    private let button = UIButton(type: .system)
    private let text: TRPBookingText
    private let theme: TRPBookingTheme

    init(field: BookingFormField, values: [String], theme: TRPBookingTheme, text: TRPBookingText) {
        self.field = field
        self.selected = values
        self.text = text
        self.theme = theme
        super.init(frame: .zero)
        let column = header(for: field, theme: theme, text: text)
        column.spacing = 6
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = theme.body
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.backgroundColor = theme.background
        button.layer.cornerRadius = 8
        button.accessibilityLabel = field.title
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        column.addArrangedSubview(button)
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        column.pin(to: self)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var options: [BookingFormOption] {
        if case .choice(let options, _) = field.kind { return options }
        return []
    }

    var allowsMultiple: Bool {
        if case .choice(_, let multiple) = field.kind { return multiple }
        return false
    }

    func select(_ values: [String]) {
        selected = values
        refresh()
        onChange?(values)
    }

    @objc private func tapped() {
        onPick?(self)
    }

    private func refresh() {
        let titles = options.filter { selected.contains($0.value) }.map(\.title)
        let title = titles.isEmpty ? text(.selectValue) : titles.joined(separator: ", ")
        button.setTitle(title, for: .normal)
        button.setTitleColor(titles.isEmpty ? theme.secondaryText : theme.text, for: .normal)
    }
}

final class BookingDateRow: UIView, BookingFormRow {

    let field: BookingFormField
    var onChange: (([String]) -> Void)?
    private let picker = UIDatePicker()
    private static let format: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(field: BookingFormField, value: String?, theme: TRPBookingTheme, text: TRPBookingText) {
        self.field = field
        super.init(frame: .zero)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.timeZone = TimeZone(identifier: "UTC")
        picker.tintColor = theme.primary
        picker.accessibilityLabel = field.title
        if let value, let date = Self.format.date(from: value) { picker.date = date }
        picker.addTarget(self, action: #selector(picked), for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [header(for: field, theme: theme, text: text), picker])
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        row.pin(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func picked() {
        onChange?([Self.format.string(from: picker.date)])
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
