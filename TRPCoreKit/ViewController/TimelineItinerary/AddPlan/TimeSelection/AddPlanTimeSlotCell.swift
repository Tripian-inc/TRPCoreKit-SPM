//
//  AddPlanTimeSlotCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

class AddPlanTimeSlotCell: UICollectionViewCell {

    static let reuseIdentifier = "AddPlanTimeSlotCell"

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        view.backgroundColor = .white
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
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
        contentView.addSubview(containerView)
        containerView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
        ])
    }

    // MARK: - Configuration
    func configure(with timeSlot: TimeSlot, isSelected: Bool) {
        timeLabel.text = timeSlot.time

        if isSelected {
            containerView.backgroundColor = ColorSet.bgPink.uiColor
            containerView.layer.borderColor = ColorSet.primary.uiColor.cgColor
            timeLabel.textColor = ColorSet.primary.uiColor
        } else {
            containerView.backgroundColor = .white
            containerView.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
            timeLabel.textColor = ColorSet.fg.uiColor
        }
    }
}
