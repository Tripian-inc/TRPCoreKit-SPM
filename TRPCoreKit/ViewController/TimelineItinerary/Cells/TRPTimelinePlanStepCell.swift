//
//  TRPTimelinePlanStepCell.swift
//  TRPCoreKit
//

import UIKit

protocol TRPTimelinePlanStepCellDelegate: AnyObject {
    func planStepCellDidSelect(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep)
    func planStepCellDidTapChangeTime(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep)
    func planStepCellDidTapRemove(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep)
    func planStepCellDidTapReservation(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep)
}

/// Top-level itinerary step row of the flat timeline, rendered by `TRPTimelineStepRowView`.
final class TRPTimelinePlanStepCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelinePlanStepCell"

    weak var delegate: TRPTimelinePlanStepCellDelegate?

    private var rowView: TRPTimelineStepRowView?
    private var isPastDayMode: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isPastDayMode = false
    }

    func configure(with cellData: PlanStepCellData) {
        rowView?.removeFromSuperview()

        let row = TRPTimelineStepRowView(step: cellData.step, order: cellData.order)
        row.onTap = { [weak self] step in
            guard let self = self else { return }
            self.delegate?.planStepCellDidSelect(self, step: step)
        }
        row.onChangeTime = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.planStepCellDidTapChangeTime(self, step: step)
        }
        row.onRemove = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.planStepCellDidTapRemove(self, step: step)
        }
        row.onReservation = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.planStepCellDidTapReservation(self, step: step)
        }

        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        rowView = row
    }

    /// Past-day rendering: hide the reservation CTA, grey out the action buttons. Call after `configure`.
    func applyPastDayStyle() {
        isPastDayMode = true
        rowView?.applyPastDayStyle()
    }
}
