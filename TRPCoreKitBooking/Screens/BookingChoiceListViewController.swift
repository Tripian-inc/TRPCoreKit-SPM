import UIKit

/// One row of a choice list.
struct BookingChoiceItem: Hashable {
    let id: String
    let title: String
    var subtitle: String?
    var detail: String?
    var isEnabled = true
    /// Shown right-aligned, already formatted.
    var price: String?
    /// Shown as a chip under the title.
    var badge: String?
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
            label.text = message ?? text(.noOptions)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: BookingChoiceCell.reuseIdentifier) as? BookingChoiceCell
            ?? BookingChoiceCell(reuseIdentifier: BookingChoiceCell.reuseIdentifier)
        cell.configure(with: item, theme: theme)
        cell.selectionStyle = item.isEnabled ? .default : .none
        cell.tintColor = theme.primary
        if allowsMultiple || !selectedIds.isEmpty {
            cell.accessoryType = selectedIds.contains(item.id) ? .checkmark : .none
        } else {
            cell.accessoryType = item.isEnabled ? .disclosureIndicator : .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        items[indexPath.row].isEnabled
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        items[indexPath.row].isEnabled ? indexPath : nil
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

/// A choice row: title, an optional badge chip and subtitle under it, and the price right-aligned.
final class BookingChoiceCell: UITableViewCell {

    static let reuseIdentifier = "choice"

    let titleLabel = UILabel()
    let badgeLabel = BookingChipLabel()
    let subtitleLabel = UILabel()
    let priceLabel = UILabel()
    private let textStack: UIStackView
    private let rowStack: UIStackView

    init(reuseIdentifier: String?) {
        textStack = UIStackView(arrangedSubviews: [titleLabel, badgeLabel, subtitleLabel])
        rowStack = UIStackView(arrangedSubviews: [textStack, priceLabel])
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        for label in [titleLabel, subtitleLabel, priceLabel, badgeLabel] {
            label.adjustsFontForContentSizeCategory = true
        }
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Fills the row from `item`; a disabled item is dimmed.
    func configure(with item: BookingChoiceItem, theme: TRPBookingTheme) {
        backgroundColor = theme.surface
        titleLabel.text = item.detail.flatMap { $0.isEmpty ? nil : "\(item.title)  ·  \($0)" } ?? item.title
        titleLabel.font = theme.headline
        titleLabel.textColor = item.isEnabled ? theme.text : theme.secondaryText
        badgeLabel.text = item.badge
        badgeLabel.font = theme.caption
        badgeLabel.textColor = theme.onPrimary
        badgeLabel.backgroundColor = theme.primary
        badgeLabel.isHidden = item.badge?.isEmpty != false
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = theme.caption
        subtitleLabel.textColor = theme.secondaryText
        subtitleLabel.isHidden = item.subtitle?.isEmpty != false
        priceLabel.text = item.price
        priceLabel.font = theme.headline
        priceLabel.textColor = item.isEnabled ? theme.text : theme.secondaryText
        priceLabel.isHidden = item.price?.isEmpty != false
        rowStack.alpha = item.isEnabled ? 1 : 0.5
        tintColor = theme.primary
        isAccessibilityElement = true
        accessibilityLabel = [item.title, item.badge, item.subtitle, item.price].compactMap { $0 }.joined(separator: ", ")
        accessibilityTraits = item.isEnabled ? .button : [.button, .notEnabled]
    }
}

/// A small rounded label used as a chip.
final class BookingChipLabel: UILabel {

    private let insets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 6
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
