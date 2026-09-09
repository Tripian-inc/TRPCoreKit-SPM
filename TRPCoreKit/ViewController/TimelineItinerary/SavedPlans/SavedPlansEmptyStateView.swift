//
//  SavedPlansEmptyStateView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 11.06.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

/// "All done" placeholder shown on Saved Plans once every saved activity has been added and the list is empty.
final class SavedPlansEmptyStateView: UIView {

    var onViewItineraryTapped: (() -> Void)?

    // MARK: - UI Components

    private lazy var checkBadgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.bgPink.uiColor
        view.layer.cornerRadius = 28
        return view
    }()

    private lazy var checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        let image = TRPImageController().getImage(inFramework: "ic_check", inApp: nil, withTintColor: true)
        imageView.image = image
        imageView.tintColor = ColorSet.primary.uiColor
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewItineraryButton: TRPButton = {
        let button = TRPButton(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.viewItinerary),
            style: .primary,
            height: 40
        )
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        button.addTarget(self, action: #selector(viewItineraryButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white

        addSubview(checkBadgeView)
        checkBadgeView.addSubview(checkImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(viewItineraryButton)

        NSLayoutConstraint.activate([
            checkBadgeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkBadgeView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            checkBadgeView.widthAnchor.constraint(equalToConstant: 56),
            checkBadgeView.heightAnchor.constraint(equalToConstant: 56),

            checkImageView.centerXAnchor.constraint(equalTo: checkBadgeView.centerXAnchor),
            checkImageView.centerYAnchor.constraint(equalTo: checkBadgeView.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: 28),
            checkImageView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: checkBadgeView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            viewItineraryButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            viewItineraryButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    // MARK: - Configuration
    private func configure() {
        titleLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedPlansAllAddedTitle)

        let descriptionText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedPlansAllAddedDescription)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center

        descriptionLabel.attributedText = NSAttributedString(
            string: descriptionText,
            attributes: [
                .font: FontSet.montserratMedium.font(16),
                .foregroundColor: ColorSet.fgWeak.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    // MARK: - Actions
    @objc private func viewItineraryButtonTapped() {
        onViewItineraryTapped?()
    }
}
