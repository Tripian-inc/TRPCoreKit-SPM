//
//  TRPTimelineEmptyStateCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

protocol TRPTimelineEmptyStateCellDelegate: AnyObject {
    func emptyStateCellDidTapAddPlan(_ cell: TRPTimelineEmptyStateCell)
}

class TRPTimelineEmptyStateCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineEmptyStateCell"

    weak var delegate: TRPTimelineEmptyStateCellDelegate?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral100.uiColor
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(17)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var addPlansButton: TRPButton = {
        let button = TRPButton(
            title: "",
            style: .primary,
            height: 40
        )
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 29, bottom: 0, right: 29)
        button.addTarget(self, action: #selector(addPlansButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(addPlansButton)

        NSLayoutConstraint.activate([
            // Container View - 32px margin from dayFilters
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Title Label - top gap 32px
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Description Label - top gap 12px
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Add Plans Button - top gap 16px, bottom gap 32px, horizontally centered
            addPlansButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            addPlansButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            addPlansButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32)
        ])
    }

    // MARK: - Configuration
    func configure() {
        titleLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noPlansYet)
        addPlansButton.updateTitle(TimelineLocalizationKeys.localized(TimelineLocalizationKeys.addPlansButton))

        // Set description with line height 23px
        let descriptionText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noPlansDescription)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 23 - (FontSet.montserratLight.font(14).lineHeight)
        paragraphStyle.alignment = .center

        let attributedString = NSAttributedString(
            string: descriptionText,
            attributes: [
                .font: FontSet.montserratLight.font(14),
                .foregroundColor: ColorSet.fgWeak.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        descriptionLabel.attributedText = attributedString
    }

    // MARK: - Actions
    @objc private func addPlansButtonTapped() {
        delegate?.emptyStateCellDidTapAddPlan(self)
    }
}
