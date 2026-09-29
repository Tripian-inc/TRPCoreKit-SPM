import UIKit
import TRPBookingKit

/// The last look before paying: what is booked, what it costs and how long the hold lasts.
final class BookingSummaryViewController: BookingBaseViewController {

    var onConfirm: (() -> Void)?
    /// Called once when the hold runs out while the screen is open.
    var onExpired: (() -> Void)?

    private let rows: [BookingSummaryRow]
    private let notes: [(title: String, body: String)]
    private let deadline: BookingDeadline?
    private let actionTitle: String
    private let layout = BookingScrollLayout()
    private let countdownLabel = UILabel()
    private lazy var actionButton = BookingPrimaryButton(theme: theme, title: actionTitle)
    private var timer: Timer?
    private var hasExpired = false

    init(title: String, rows: [BookingSummaryRow], notes: [(title: String, body: String)] = [], deadline: BookingDeadline?,
         actionTitle: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.rows = rows
        self.notes = notes
        self.deadline = deadline
        self.actionTitle = actionTitle
        super.init(theme: theme, text: text)
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout.install(in: view, theme: theme)
        layout.stack.addArrangedSubview(BookingScrollLayout.card([BookingKeyValueView(rows: rows, theme: theme)], theme: theme))
        for note in notes where !note.body.isEmpty {
            let heading = makeLabel(theme.headline, color: theme.text)
            heading.text = note.title
            heading.accessibilityTraits = .header
            let body = makeLabel(theme.caption, color: theme.secondaryText)
            body.text = note.body
            layout.stack.addArrangedSubview(BookingScrollLayout.card([heading, body], theme: theme))
        }
        countdownLabel.font = theme.caption
        countdownLabel.textColor = theme.warning
        countdownLabel.textAlignment = .center
        countdownLabel.adjustsFontForContentSizeCategory = true
        countdownLabel.isHidden = deadline == nil
        layout.footer.addArrangedSubview(countdownLabel)
        layout.footer.addArrangedSubview(actionButton)
        actionButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        tick()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard deadline != nil, timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let deadline else { return }
        let remaining = deadline.remaining()
        countdownLabel.text = text(.holdExpiresIn, BookingFormatting().countdown(remaining))
        guard deadline.isExpired(), !hasExpired else { return }
        hasExpired = true
        timer?.invalidate()
        timer = nil
        countdownLabel.text = text(.holdExpired)
        countdownLabel.textColor = theme.error
        actionButton.isEnabled = false
        onExpired?()
    }

    @objc private func confirm() {
        if let deadline, deadline.isExpired() {
            tick()
            return
        }
        onConfirm?()
    }
}
