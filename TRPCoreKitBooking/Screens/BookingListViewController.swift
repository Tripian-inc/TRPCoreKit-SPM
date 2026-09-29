import UIKit
import TRPBookingKit

/// The bookings made on this device, with a status refresh and, for Viator, a cancellation.
final class BookingListViewController: BookingBaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let booking: TRPBooking
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private var records: [BookingRecord] = []
    private let formatting = BookingFormatting()

    init(booking: TRPBooking, theme: TRPBookingTheme, text: TRPBookingText) {
        self.booking = booking
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
        refreshControl.addTarget(self, action: #selector(pulled), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        tableView.pin(to: view)
        reload(resolving: true)
    }

    @objc private func pulled() {
        reload(resolving: true)
    }

    private func reload(resolving: Bool) {
        Task { @MainActor [weak self, booking] in
            if resolving {
                _ = await booking.resolveUnfinished()
            }
            let records = await booking.records()
            guard let self else { return }
            self.records = records
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
            self.showEmptyStateIfNeeded()
        }
    }

    private func showEmptyStateIfNeeded() {
        guard records.isEmpty else {
            tableView.backgroundView = nil
            return
        }
        let label = makeLabel(theme.body, color: theme.secondaryText)
        label.text = text(.bookingsEmpty)
        label.textAlignment = .center
        tableView.backgroundView = label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let record = records[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "record") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "record")
        cell.backgroundColor = theme.surface
        cell.textLabel?.text = record.title
        cell.textLabel?.font = theme.headline
        cell.textLabel?.textColor = theme.text
        cell.textLabel?.numberOfLines = 0
        let parts = [record.travelDate.map(formatting.day), text(record.status.textKey), formatting.price(record.total, currency: record.currency)]
        cell.detailTextLabel?.text = parts.compactMap { $0 }.joined(separator: "  ·  ")
        cell.detailTextLabel?.font = theme.caption
        cell.detailTextLabel?.textColor = record.status.isLive ? theme.secondaryText : theme.warning
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = records[indexPath.row]
        let sheet = UIAlertController(title: record.title, message: "\(text(.reference)): \(record.reference.primary)", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: text(.refreshStatus), style: .default) { [weak self] _ in self?.refresh(record) })
        if record.reference.provider == .viator, record.status.isLive {
            sheet.addAction(UIAlertAction(title: text(.cancelBooking), style: .destructive) { [weak self] _ in self?.quoteCancellation(record) })
        }
        sheet.addAction(UIAlertAction(title: text(.close), style: .cancel))
        if let popover = sheet.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(sheet, animated: true)
    }

    private func refresh(_ record: BookingRecord) {
        setLoading(true)
        Task { @MainActor [weak self, booking] in
            do {
                switch record.reference.provider {
                case .toristy:
                    _ = try await Self.require(booking.toristy, .toristy).status(of: record.reference)
                case .viator:
                    _ = try await Self.require(booking.viator, .viator).status(of: record.reference)
                case .victory:
                    _ = try await Self.require(booking.victory, .victory).status(of: record.reference)
                }
                self?.setLoading(false)
                self?.reload(resolving: false)
            } catch {
                self?.setLoading(false)
                self?.show(error)
            }
        }
    }

    private func quoteCancellation(_ record: BookingRecord) {
        guard let viator = booking.viator else { return show(BookingError.providerNotConfigured(.viator)) }
        setLoading(true)
        Task { @MainActor [weak self] in
            do {
                let quote = try await viator.cancelQuote(record.reference)
                self?.setLoading(false)
                self?.confirmCancellation(record, quote: quote)
            } catch {
                self?.setLoading(false)
                self?.show(error)
            }
        }
    }

    private func confirmCancellation(_ record: BookingRecord, quote: ViatorCancelQuote) {
        let refund = quote.refundAmount.flatMap { $0 > 0 ? formatting.price($0, currency: quote.currencyCode ?? record.currency) : nil }
        let message = refund.map { text(.cancelQuoteMessage, $0) } ?? text(.cancelQuoteNoRefund)
        let alert = UIAlertController(title: text(.cancelBooking), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: text(.stay), style: .cancel))
        alert.addAction(UIAlertAction(title: text(.cancelConfirm), style: .destructive) { [weak self] _ in self?.cancel(record) })
        present(alert, animated: true)
    }

    private func cancel(_ record: BookingRecord) {
        guard let viator = booking.viator else { return }
        setLoading(true)
        Task { @MainActor [weak self] in
            do {
                let cancellation = try await viator.cancel(record.reference)
                guard let self else { return }
                self.setLoading(false)
                if cancellation.isAccepted {
                    let alert = UIAlertController(title: self.text(.cancelDone), message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: self.text(.close), style: .cancel))
                    self.present(alert, animated: true)
                } else {
                    self.show(message: cancellation.reason ?? cancellation.status)
                }
                self.reload(resolving: false)
            } catch {
                self?.setLoading(false)
                self?.show(error)
            }
        }
    }

    private static func require<T>(_ checkout: T?, _ kind: BookingProviderKind) throws -> T {
        guard let checkout else { throw BookingError.providerNotConfigured(kind) }
        return checkout
    }
}
