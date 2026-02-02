//
//  AddressSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Address section view extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class AddressSectionView: UIView {

    private let headerLabel: UILabel
    private let mapContainer: UIView
    private let locationStack: UIStackView
    private let viewMapButton: UIButton
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()

    init(headerLabel: UILabel, mapContainer: UIView, locationStack: UIStackView, viewMapButton: UIButton) {
        self.headerLabel = headerLabel
        self.mapContainer = mapContainer
        self.locationStack = locationStack
        self.viewMapButton = viewMapButton

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerLabel)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(mapContainer)
        contentStackView.addArrangedSubview(locationStack)
        contentStackView.addArrangedSubview(viewMapButton)

        // Set custom spacing of 36px between locationStack and viewMapButton
        contentStackView.setCustomSpacing(36, after: locationStack)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Content Stack (automatically handles hidden subviews)
            contentStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),

            // Map Container height (when visible)
            mapContainer.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
}
