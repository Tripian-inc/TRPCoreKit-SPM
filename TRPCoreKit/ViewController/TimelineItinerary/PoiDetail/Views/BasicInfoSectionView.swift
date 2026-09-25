//
//  BasicInfoSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Basic info section view extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class BasicInfoSectionView: UIView {

    private let cityLabel: UILabel
    private let poiNameLabel: UILabel
    private let ratingContainerView: UIView
    private let descriptionLabel: UILabel
    private let readMoreButton: UIButton
    private let onReadMoreTapped: () -> Void

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let descriptionStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private var bottomConstraint: NSLayoutConstraint!

    init(cityLabel: UILabel, poiNameLabel: UILabel, ratingContainerView: UIView, descriptionLabel: UILabel, readMoreButton: UIButton, onReadMoreTapped: @escaping () -> Void) {
        self.cityLabel = cityLabel
        self.poiNameLabel = poiNameLabel
        self.ratingContainerView = ratingContainerView
        self.descriptionLabel = descriptionLabel
        self.readMoreButton = readMoreButton
        self.onReadMoreTapped = onReadMoreTapped

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStackView)

        mainStackView.addArrangedSubview(cityLabel)
        mainStackView.addArrangedSubview(poiNameLabel)
        mainStackView.addArrangedSubview(ratingContainerView)
        mainStackView.addArrangedSubview(descriptionStackView)

        descriptionStackView.addArrangedSubview(descriptionLabel)
        descriptionStackView.addArrangedSubview(readMoreButton)

        bottomConstraint = mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bottomConstraint,

            ratingContainerView.heightAnchor.constraint(equalToConstant: 24),

            cityLabel.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            poiNameLabel.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            descriptionStackView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            descriptionLabel.widthAnchor.constraint(equalTo: descriptionStackView.widthAnchor)
        ])
    }

    func setDescriptionSectionHidden(_ hidden: Bool) {
        descriptionStackView.isHidden = hidden
        bottomConstraint.constant = hidden ? -16 : -40
    }
}
