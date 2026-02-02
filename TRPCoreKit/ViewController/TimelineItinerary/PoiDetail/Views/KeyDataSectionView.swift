//
//  KeyDataSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Key data section view extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class KeyDataSectionView: UIView {

    private let headerLabel: UILabel
    private let phoneStack: UIStackView
    private let hoursStack: UIStackView
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    init(headerLabel: UILabel, phoneStack: UIStackView, hoursStack: UIStackView) {
        self.headerLabel = headerLabel
        self.phoneStack = phoneStack
        self.hoursStack = hoursStack

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

        contentStackView.addArrangedSubview(phoneStack)
        contentStackView.addArrangedSubview(hoursStack)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Content Stack (automatically handles hidden subviews)
            contentStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }
}
