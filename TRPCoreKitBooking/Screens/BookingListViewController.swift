import UIKit
import TRPBookingKit

/// The customer's bookings from the server, a page at a time; a booking opens its details.
final class BookingListViewController: BookingBaseViewController, UITableViewDataSource, UITableViewDelegate {

    static let pageSize = 20

    private let client: BookingClient
    private let lang: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private var bookings: [BookingContract.Booking] = []
    private var nextPage: Int? = 1
    private var isLoading = false
    private let formatting = BookingFormatting()

    init(client: BookingClient, lang: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.client = client
        self.lang = lang
        super.init(theme: theme, text: text)
        title = text(.myBookingsTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = theme.background
        tableView.translatesAutoresizingMaskIntoConstraints = false
        refreshControl.tintColor = theme.primary
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        tableView.pin(to: view)
        setLoading(true)
        reload()
    }

    @objc private func reload() {
        load(page: 1, replacing: true)
    }

    private func load(page: Int, replacing: Bool) {
        guard !isLoading || replacing else { return }
        isLoading = true
        Task { @MainActor [weak self, client, lang] in
            do {
                let result = try await client.list(status: [], page: page, limit: Self.pageSize, lang: lang)
                guard let self else { return }
                self.bookings = replacing ? result.bookings : self.bookings + result.bookings
                self.nextPage = Self.page(after: page, of: result)
                self.finishLoading()
            } catch {
                guard let self else { return }
                self.finishLoading()
                self.show(error) { [weak self] in self?.load(page: page, replacing: replacing) }
            }
        }
    }

    /// The page to load next, or nil when the last page has arrived.
    static func page(after page: Int, of result: BookingContract.BookingPage) -> Int? {
        guard let pagination = result.pagination else { return nil }
        return pagination.currentPage < pagination.totalPages ? pagination.currentPage + 1 : nil
    }

    private func finishLoading() {
        isLoading = false
        setLoading(false)
        refreshControl.endRefreshing()
        tableView.reloadData()
        tableView.tableFooterView = nextPage == nil ? nil : makeLoadMoreButton()
        showEmptyStateIfNeeded()
    }

    private func makeLoadMoreButton() -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(text(.loadMore), for: .normal)
        button.titleLabel?.font = theme.body
        button.tintColor = theme.primary
        button.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52)
        button.addTarget(self, action: #selector(loadMore), for: .touchUpInside)
        return button
    }

    @objc private func loadMore() {
        guard let nextPage else { return }
        load(page: nextPage, replacing: false)
    }

    private func showEmptyStateIfNeeded() {
        guard bookings.isEmpty else {
            tableView.backgroundView = nil
            return
        }
        let label = makeLabel(theme.body, color: theme.secondaryText)
        label.text = text(.bookingsEmpty)
        label.textAlignment = .center
        tableView.backgroundView = label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bookings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let booking = bookings[indexPath.row]
        cell.backgroundColor = theme.surface
        cell.textLabel?.text = booking.product.title
        cell.textLabel?.font = theme.headline
        cell.textLabel?.textColor = theme.text
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = [formatting.day(booking.start.date), booking.status.statusText(text)].joined(separator: " · ")
        cell.detailTextLabel?.font = theme.caption
        cell.detailTextLabel?.textColor = theme.secondaryText
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = BookingDetailViewController(booking: bookings[indexPath.row], client: client, lang: lang, theme: theme, text: text)
        detail.onChange = { [weak self] updated in
            guard let self, let index = self.bookings.firstIndex(where: { $0.uuid == updated.uuid }) else { return }
            self.bookings[index] = updated
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(detail, animated: true)
    }
}

/// One booking: when and where, the amount, its vouchers and, while allowed, a cancellation.
final class BookingDetailViewController: BookingBaseViewController {

    var onChange: ((BookingContract.Booking) -> Void)?

    private var booking: BookingContract.Booking
    private let client: BookingClient
    private let lang: String
    private let layout = BookingScrollLayout()
    private let formatting = BookingFormatting()
    private lazy var cancelPrompt = BookingCancelPrompt(text: text, formatting: formatting)

    init(booking: BookingContract.Booking, client: BookingClient, lang: String, theme: TRPBookingTheme, text: TRPBookingText) {
        self.booking = booking
        self.client = client
        self.lang = lang
        super.init(theme: theme, text: text)
        title = booking.product.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout.install(in: view, theme: theme)
        render()
        refresh()
    }

    private func refresh() {
        Task { @MainActor [weak self, client, lang, uuid = booking.uuid] in
            guard let updated = try? await client.get(uuid: uuid, lang: lang), let self else { return }
            self.update(updated)
        }
    }

    private func update(_ updated: BookingContract.Booking) {
        booking = updated
        onChange?(updated)
        render()
    }

    private func render() {
        layout.stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        layout.footer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        layout.stack.addArrangedSubview(BookingScrollLayout.card([BookingKeyValueView(rows: rows, theme: theme)], theme: theme))
        if let policy = policyText {
            let label = makeLabel(theme.body, color: theme.text)
            label.text = policy
            let heading = makeLabel(theme.headline, color: theme.text)
            heading.text = text(.cancellationPolicy)
            layout.stack.addArrangedSubview(BookingScrollLayout.card([heading, label], theme: theme))
        }
        for (index, voucher) in booking.vouchers.enumerated() where URL(string: voucher.url) != nil {
            let button = BookingPrimaryButton(theme: theme, title: text(.voucher))
            button.tag = index
            button.addTarget(self, action: #selector(openVoucher(_:)), for: .touchUpInside)
            layout.footer.addArrangedSubview(button)
        }
        if booking.cancellation.allowed {
            let cancel = UIButton(type: .system)
            cancel.setTitle(text(.cancelBooking), for: .normal)
            cancel.titleLabel?.font = theme.body
            cancel.tintColor = theme.error
            cancel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            cancel.addTarget(self, action: #selector(confirmCancel), for: .touchUpInside)
            layout.footer.addArrangedSubview(cancel)
        }
    }

    private var rows: [BookingSummaryRow] {
        let reference = BookingReference.preferred(providerReference: booking.providerReference, uuid: booking.uuid) ?? booking.uuid
        var rows = [BookingSummaryRow(title: text(.reference), value: reference),
                    BookingSummaryRow(title: text(.date), value: formatting.day(booking.start.date))]
        if let time = booking.start.time { rows.append(BookingSummaryRow(title: text(.time), value: formatting.time(time))) }
        if let point = booking.meetingPoint {
            rows.append(BookingSummaryRow(title: text(.meetingPoint), value: [point.name, point.address].compactMap { $0 }.joined(separator: "\n")))
        }
        rows.append(BookingSummaryRow(title: text(.total), value: formatting.price(booking.amount) ?? booking.amount.amount, isEmphasized: true))
        if let refund = booking.refund, let amount = formatting.price(refund.amount) {
            rows.append(BookingSummaryRow(title: text(.refund), value: amount))
        }
        rows.append(BookingSummaryRow(title: "", value: booking.status.statusText(text), isEmphasized: true))
        return rows
    }

    private var policyText: String? {
        cancelPrompt.policy(for: booking, cancellation: booking.cancellation)
    }

    private func showCancelled() {
        let alert = UIAlertController(title: text(.cancelDone), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: text(.done), style: .default))
        present(alert, animated: true)
    }

    @objc private func openVoucher(_ sender: UIButton) {
        guard booking.vouchers.indices.contains(sender.tag), let url = URL(string: booking.vouchers[sender.tag].url) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func confirmCancel() {
        guard client is BookingCancellationQuoting else {
            presentCancelPrompt()
            return
        }
        setLoading(true)
        Task { @MainActor [weak self, client, booking] in
            let quoted = await BookingCancelPrompt.cancellation(for: booking, client: client)
            guard let self else { return }
            self.setLoading(false)
            self.update(BookingCancelPrompt.booking(self.booking, with: quoted))
            self.presentCancelPrompt()
        }
    }

    private func presentCancelPrompt() {
        switch cancelPrompt.outcome(for: booking, cancellation: booking.cancellation) {
        case .notCancellable(let message):
            show(message: message)
        case .confirm(let message):
            let alert = UIAlertController(title: text(.cancelBooking), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: text(.stay), style: .cancel))
            alert.addAction(UIAlertAction(title: text(.cancelConfirm), style: .destructive) { [weak self] _ in self?.cancelBooking() })
            present(alert, animated: true)
        }
    }

    private func cancelBooking() {
        setLoading(true)
        Task { @MainActor [weak self, client, lang, uuid = booking.uuid] in
            do {
                let updated = try await client.cancel(uuid: uuid, lang: lang)
                guard let self else { return }
                self.setLoading(false)
                self.update(updated)
                self.showCancelled()
            } catch {
                guard let self else { return }
                self.setLoading(false)
                self.show(error)
            }
        }
    }
}

extension BookingContract.OpenEnum where Value == BookingContract.BookingStatus {

    /// The status as the customer reads it.
    func statusText(_ text: TRPBookingText) -> String {
        switch value {
        case .onHold: return text(.statusOnHold)
        case .confirmed: return text(.statusConfirmed)
        case .pending: return text(.statusPending)
        case .expired: return text(.statusExpired)
        case .cancelled: return text(.statusCancelled)
        case .rejected: return text(.statusRejected)
        case .unknown: return rawValue
        }
    }
}
