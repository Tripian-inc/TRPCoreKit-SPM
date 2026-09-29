import UIKit

/// Renders booking form sections, keeps the answers and checks them before handing them over.
final class BookingFormViewController: BookingBaseViewController {

    var onChange: ((BookingFormValues) -> Void)?
    /// Receives the answers once every required field is filled.
    var onSubmit: ((BookingFormValues) -> Void)?

    private let sections: [BookingFormSection]
    private let submitTitle: String
    private(set) var values: BookingFormValues
    private let layout = BookingScrollLayout()
    private let summaryLabel = UILabel()
    private let issuesLabel = UILabel()
    private lazy var submitButton = BookingPrimaryButton(theme: theme, title: submitTitle)

    init(title: String, sections: [BookingFormSection], submitTitle: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.sections = sections
        self.submitTitle = submitTitle
        self.values = BookingFormValues(sections: sections)
        super.init(theme: theme, text: text)
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout.install(in: view, theme: theme)
        for section in sections where !section.fields.isEmpty {
            layout.stack.addArrangedSubview(makeSection(section))
        }
        issuesLabel.font = theme.caption
        issuesLabel.textColor = theme.error
        issuesLabel.numberOfLines = 0
        issuesLabel.isHidden = true
        summaryLabel.font = theme.headline
        summaryLabel.textColor = theme.text
        summaryLabel.numberOfLines = 0
        summaryLabel.isHidden = true
        layout.footer.addArrangedSubview(issuesLabel)
        layout.footer.addArrangedSubview(summaryLabel)
        layout.footer.addArrangedSubview(submitButton)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        onChange?(values)
    }

    /// A line above the button, such as the running total.
    func setSummary(_ summary: String?) {
        loadViewIfNeeded()
        summaryLabel.text = summary
        summaryLabel.isHidden = summary == nil
    }

    /// Problems to show above the button; an empty list hides them.
    func setIssues(_ issues: [String]) {
        loadViewIfNeeded()
        issuesLabel.text = issues.joined(separator: "\n")
        issuesLabel.isHidden = issues.isEmpty
        if !issues.isEmpty {
            UIAccessibility.post(notification: .announcement, argument: issuesLabel.text)
        }
    }

    func setSubmitEnabled(_ isEnabled: Bool) {
        loadViewIfNeeded()
        submitButton.isEnabled = isEnabled
    }

    private func makeSection(_ section: BookingFormSection) -> UIView {
        var views: [UIView] = []
        if let title = section.title {
            let label = makeLabel(theme.title, color: theme.text)
            label.text = title
            label.accessibilityTraits = .header
            views.append(label)
        }
        for field in section.fields {
            views.append(makeRow(field))
        }
        if let footer = section.footer {
            let label = makeLabel(theme.caption, color: theme.secondaryText)
            label.text = footer
            views.append(label)
        }
        return BookingScrollLayout.card(views, theme: theme)
    }

    private func makeRow(_ field: BookingFormField) -> UIView {
        let row: BookingFormRow
        switch field.kind {
        case .text, .multiline, .email, .phone, .number:
            row = BookingTextRow(field: field, value: values.value(field.id), theme: theme, text: text)
        case .date:
            row = BookingDateRow(field: field, value: values.value(field.id), theme: theme, text: text)
        case .stepper(let minimum, _):
            let current = values.value(field.id).flatMap(Int.init) ?? minimum
            values.set(String(current), for: field.id)
            row = BookingStepperRow(field: field, value: current, theme: theme, text: text)
        case .choice:
            let choice = BookingChoiceRow(field: field, values: values.values(field.id), theme: theme, text: text)
            choice.onPick = { [weak self] row in self?.pick(for: row) }
            row = choice
        }
        row.onChange = { [weak self] answers in
            guard let self else { return }
            self.values.set(answers, for: field.id)
            self.onChange?(self.values)
        }
        return row
    }

    private func pick(for row: BookingChoiceRow) {
        view.endEditing(true)
        var items = row.options.map { BookingChoiceItem(id: $0.value, title: $0.title) }
        if !row.field.isRequired, !row.allowsMultiple {
            items.insert(BookingChoiceItem(id: "", title: text(.noChoice)), at: 0)
        }
        let list = BookingChoiceListViewController(title: row.field.title, items: items, message: row.field.detail,
                                                   allowsMultiple: row.allowsMultiple, selectedIds: row.selected,
                                                   theme: theme, text: text)
        list.onSelect = { [weak self, weak row] item in
            row?.select(item.id.isEmpty ? [] : [item.id])
            self?.navigationController?.popViewController(animated: true)
        }
        list.onSelectMany = { [weak self, weak row] ids in
            row?.select(ids)
            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(list, animated: true)
    }

    @objc private func submit() {
        view.endEditing(true)
        let issues = BookingFormChecker(text: text).issues(values, sections: sections)
        setIssues(issues)
        guard issues.isEmpty else { return }
        onSubmit?(values)
    }
}
