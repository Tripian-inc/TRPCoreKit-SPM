import UIKit
import TRPBookingKit

/// Renders one contract step from its layout: every row once, hidden or shown as the answers change.
final class CheckoutStepViewController: BookingBaseViewController {

    var onSubmit: ((BookingContract.Answers) -> Void)?
    var onBack: (() -> Void)?
    var onExtend: (() -> Void)?
    /// Called when the hold or the price runs out while the step is on screen.
    var onDeadline: (() -> Void)?
    var onOpenURL: ((URL) -> Void)?

    let step: BookingContract.Step
    private(set) var form: FormState
    private let deadline: Date?
    private let canGoBack: Bool
    private let canExtend: Bool
    private let now: () -> Date
    private let layout = BookingScrollLayout()
    private var rowViews: [String: UIView] = [:]
    private var groupViews: [String: UIView] = [:]
    private var countdownLabel: UILabel?
    private var timer: Timer?

    init(step: BookingContract.Step, layout stepLayout: StepLayout, checkout: BookingContract.Checkout,
         canGoBack: Bool, canExtend: Bool, now: @escaping () -> Date, theme: TRPBookingTheme, text: TRPBookingText) {
        self.step = step
        form = FormState(layout: stepLayout)
        deadline = CheckoutDeadline.next(for: checkout)
        self.canGoBack = canGoBack
        self.canExtend = canExtend
        self.now = now
        super.init(theme: theme, text: text)
        title = step.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout.install(in: view, theme: theme)
        buildHeader()
        buildRows()
        buildFooter()
        applyVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCountdown()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    /// Shows the server's field errors under their rows; errors for rows not on screen are joined into one alert.
    func show(fieldErrors: [BookingContract.ErrorData.FieldError]) {
        clearProblems()
        var unplaced: [String] = []
        for error in fieldErrors {
            if let row = rowViews[error.field] as? BookingInputRowView {
                row.show(problem: error.message)
            } else {
                unplaced.append(error.message)
            }
        }
        if !unplaced.isEmpty { show(message: unplaced.joined(separator: "\n")) }
        scrollToFirstProblem()
    }

    private func buildHeader() {
        if let subtitle = step.subtitle, !subtitle.isEmpty {
            layout.stack.addArrangedSubview(BookingInputRowView.label(subtitle, font: theme.body, color: theme.secondaryText))
        }
    }

    private func buildRows() {
        let factory = BookingRowFactory(theme: theme, text: text)
        for group in form.layout.groups {
            let column = UIStackView()
            column.axis = .vertical
            column.spacing = 12
            for row in group.rows {
                let rowView = factory.view(for: row, value: form.value(for: row.id))
                if let input = rowView as? BookingInputRowView {
                    input.onChange = { [weak self] value in self?.update(value, for: row.id) }
                    input.onPick = { [weak self] picker in self?.navigationController?.pushViewController(picker, animated: true) }
                    input.onOpenURL = { [weak self] url in self?.onOpenURL?(url) }
                }
                rowViews[row.id] = rowView
                column.addArrangedSubview(rowView)
            }
            let card = BookingScrollLayout.card([column], theme: theme)
            groupViews[group.id] = card
            layout.stack.addArrangedSubview(card)
        }
    }

    private func buildFooter() {
        let progressLabel = BookingInputRowView.label(progressText, font: theme.caption, color: theme.secondaryText)
        progressLabel.textAlignment = .center
        layout.footer.addArrangedSubview(progressLabel)
        if deadline != nil {
            let label = BookingInputRowView.label("", font: theme.caption, color: theme.warning)
            label.textAlignment = .center
            countdownLabel = label
            layout.footer.addArrangedSubview(label)
        }
        let submit = BookingPrimaryButton(theme: theme, title: step.primaryAction.title)
        submit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        layout.footer.addArrangedSubview(submit)
        var secondary: [UIButton] = []
        if canGoBack { secondary.append(secondaryButton(text(.back), action: #selector(backTapped))) }
        if canExtend { secondary.append(secondaryButton(text(.extendHold), action: #selector(extendTapped))) }
        if !secondary.isEmpty {
            let line = UIStackView(arrangedSubviews: secondary)
            line.distribution = .fillEqually
            line.spacing = 8
            layout.footer.addArrangedSubview(line)
        }
    }

    private var progressText: String {
        let progress = step.progress
        if let count = progress.count { return text(.stepProgress, progress.index, count) }
        return text(.stepIndex, progress.index)
    }

    private func secondaryButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = theme.body
        button.tintColor = theme.primary
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func update(_ value: JSONValue?, for id: String) {
        form.set(value, for: id)
        (rowViews[id] as? BookingInputRowView)?.show(problem: nil)
        UIView.animate(withDuration: 0.2) { self.applyVisibility() }
    }

    private func applyVisibility() {
        for group in form.layout.groups {
            var anyVisible = false
            for row in group.rows {
                let visible = form.isVisible(row)
                anyVisible = anyVisible || visible
                if rowViews[row.id]?.isHidden != !visible { rowViews[row.id]?.isHidden = !visible }
            }
            groupViews[group.id]?.isHidden = !anyVisible
        }
    }

    private func clearProblems() {
        rowViews.values.compactMap { $0 as? BookingInputRowView }.forEach { $0.show(problem: nil) }
    }

    private func scrollToFirstProblem() {
        let first = form.layout.rows.lazy.compactMap { self.rowViews[$0.id] as? BookingInputRowView }.first { !$0.isHidden && $0.hasProblem }
        guard let first else { return }
        layout.scrollView.scrollRectToVisible(first.convert(first.bounds, to: layout.scrollView), animated: true)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        clearProblems()
        let problems = form.problems()
        guard problems.isEmpty else {
            for (id, problem) in problems {
                (rowViews[id] as? BookingInputRowView)?.show(problem: message(for: problem))
            }
            scrollToFirstProblem()
            return
        }
        onSubmit?(form.answers)
    }

    @objc private func backTapped() {
        onBack?()
    }

    @objc private func extendTapped() {
        onExtend?()
    }

    private func message(for problem: FieldProblem) -> String {
        switch problem {
        case .required: return text(.required)
        case .invalid(let message): return message ?? text(.invalidValue)
        case .invalidEmail: return text(.invalidEmail)
        case .quantityTotal(let min, let max): return text(.quantityTotal, min, max)
        }
    }

    private func startCountdown() {
        guard let deadline, timer == nil else { return }
        tick(deadline)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick(deadline) }
        }
    }

    private func tick(_ deadline: Date) {
        let remaining = deadline.timeIntervalSince(now())
        guard remaining > 0 else {
            timer?.invalidate()
            timer = nil
            countdownLabel?.text = text(.holdExpired)
            onDeadline?()
            return
        }
        countdownLabel?.text = text(.holdExpiresIn, BookingFormatting().countdown(remaining))
    }
}
