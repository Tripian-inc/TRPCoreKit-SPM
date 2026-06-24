//
//  AddPlanShowMoreSlotCell.swift
//  TRPCoreKit
//
//  "Show more" link rendered as the 8th cell in the time-slot grid when the day has more slots than fit collapsed.
//

import UIKit

class AddPlanShowMoreSlotCell: UICollectionViewCell {

    static let reuseIdentifier = "AddPlanShowMoreSlotCell"

    // MARK: - UI Components
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupCell() {
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Configuration
    func configure(title: String) {
        label.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .font: FontSet.montserratMedium.font(14),
                .foregroundColor: ColorSet.primaryText.uiColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
    }
}
