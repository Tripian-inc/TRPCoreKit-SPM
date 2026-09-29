import UIKit

/// A label and value pair shown on summaries and results.
struct BookingSummaryRow: Hashable {
    let title: String
    let value: String
    var isEmphasized = false
}

/// Stacks summary rows as title on the left, value on the right.
final class BookingKeyValueView: UIStackView {

    init(rows: [BookingSummaryRow], theme: TRPBookingTheme) {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 10
        for row in rows {
            let title = UILabel()
            title.text = row.title
            title.font = row.isEmphasized ? theme.headline : theme.body
            title.textColor = row.isEmphasized ? theme.text : theme.secondaryText
            title.numberOfLines = 0
            title.adjustsFontForContentSizeCategory = true
            let value = UILabel()
            value.text = row.value
            value.font = row.isEmphasized ? theme.headline : theme.body
            value.textColor = theme.text
            value.numberOfLines = 0
            value.textAlignment = .right
            value.adjustsFontForContentSizeCategory = true
            value.setContentCompressionResistancePriority(.required, for: .horizontal)
            let line = UIStackView(arrangedSubviews: [title, value])
            line.spacing = 12
            line.alignment = .firstBaseline
            line.isAccessibilityElement = true
            line.accessibilityLabel = "\(row.title), \(row.value)"
            addArrangedSubview(line)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
