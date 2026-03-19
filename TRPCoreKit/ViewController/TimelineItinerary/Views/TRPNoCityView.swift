//
//  TRPNoCityView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 19.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

protocol TRPNoCityViewDelegate: AnyObject {
    func noCityViewDidTapButton(_ view: TRPNoCityView)
}

class TRPNoCityView: UIView {

    // MARK: - Properties

    weak var delegate: TRPNoCityViewDelegate?

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = TRPImageController().getImage(inFramework: "im_no_city", inApp: nil)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = FontSet.montserratMedium.font(16)
        button.setTitleColor(ColorSet.primary.uiColor, for: .normal)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.primary.uiColor.cgColor
        button.layer.cornerRadius = 24 // height/2 = 48/2
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
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

        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            // Container view - centered in parent
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            // Image - 106x106, centered at top
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 162),
            imageView.heightAnchor.constraint(equalToConstant: 162),

            // Title - 40px below image
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Description - 16px below title
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Button - 40px below description, 48px height, centered
            actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 48),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Configuration

    private func configure() {
        titleLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noCityTitle)
        descriptionLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noCityDescription)
        actionButton.setTitle(TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noCityButton), for: .normal)
    }

    // MARK: - Actions

    @objc private func actionButtonTapped() {
        delegate?.noCityViewDidTapButton(self)
    }
}
