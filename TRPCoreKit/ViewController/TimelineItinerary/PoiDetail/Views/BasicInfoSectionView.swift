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

    private let descriptionStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        return stack
    }()

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

        addSubview(cityLabel)
        addSubview(poiNameLabel)
        addSubview(ratingContainerView)
        addSubview(descriptionStackView)

        // Add description and button to stack (button will auto-hide when isHidden = true)
        descriptionStackView.addArrangedSubview(descriptionLabel)
        descriptionStackView.addArrangedSubview(readMoreButton)

        NSLayoutConstraint.activate([
            // City Label
            cityLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            cityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cityLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // POI Name
            poiNameLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 16),
            poiNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            poiNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Rating Container
            ratingContainerView.topAnchor.constraint(equalTo: poiNameLabel.bottomAnchor, constant: 12),
            ratingContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ratingContainerView.heightAnchor.constraint(equalToConstant: 24),

            // Description Stack (automatically handles hidden readMoreButton)
            descriptionStackView.topAnchor.constraint(equalTo: ratingContainerView.bottomAnchor, constant: 20),
            descriptionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            descriptionStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            descriptionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),

            // Ensure description label takes full width within stack
            descriptionLabel.widthAnchor.constraint(equalTo: descriptionStackView.widthAnchor)
        ])
    }
}
