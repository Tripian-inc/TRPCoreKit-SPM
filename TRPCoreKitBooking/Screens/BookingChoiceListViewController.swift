import UIKit

/// One row of a choice list.
struct BookingChoiceItem: Hashable {
    let id: String
    let title: String
    var subtitle: String?
    var detail: String?
    var isEnabled = true
}

/// A list the customer picks from: a day, a departure, a rate, a ticket group or a field's answer.
final class BookingChoiceListViewController: BookingBaseViewController, UITableViewDataSource, UITableViewDelegate {

    var onSelect: ((BookingChoiceItem) -> Void)?
    /// Called with every chosen id when the list allows several; the list then shows a Done button.
    var onSelectMany: (([String]) -> Void)?

    private let items: [BookingChoiceItem]
    private let message: String?
    private let allowsMultiple: Bool
    private var selectedIds: Set<String>
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(title: String, items: [BookingChoiceItem], message: String? = nil, allowsMultiple: Bool = false,
         selectedIds: [String] = [], theme: TRPBookingTheme, text: TRPBookingText) {
        self.items = items
        self.message = message
        self.allowsMultiple = allowsMultiple
        self.selectedIds = Set(selectedIds)
        super.init(theme: theme, text: text)
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = theme.background
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pin(to: view)
        if allowsMultiple {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: text(.done), style: .done, target: self, action: #selector(done))
        }
        if items.isEmpty {
            let label = makeLabel(theme.body, color: theme.secondaryText)
            label.text = message ?? text(.noAvailability)
            label.textAlignment = .center
            tableView.backgroundView = label
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        items.isEmpty ? nil : message
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "choice") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "choice")
        cell.backgroundColor = theme.surface
        cell.textLabel?.text = item.detail.map { "\(item.title)  ·  \($0)" } ?? item.title
        cell.textLabel?.font = theme.headline
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = item.isEnabled ? theme.text : theme.secondaryText
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.font = theme.caption
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = theme.secondaryText
        cell.selectionStyle = item.isEnabled ? .default : .none
        cell.tintColor = theme.primary
        if allowsMultiple || !selectedIds.isEmpty {
            cell.accessoryType = selectedIds.contains(item.id) ? .checkmark : .none
        } else {
            cell.accessoryType = item.isEnabled ? .disclosureIndicator : .none
        }
        cell.accessibilityTraits = item.isEnabled ? .button : [.button, .notEnabled]
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        items[indexPath.row].isEnabled
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        guard item.isEnabled else { return }
        if allowsMultiple {
            if selectedIds.contains(item.id) {
                selectedIds.remove(item.id)
            } else {
                selectedIds.insert(item.id)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            onSelect?(item)
        }
    }

    @objc private func done() {
        onSelectMany?(items.map(\.id).filter(selectedIds.contains))
    }
}
