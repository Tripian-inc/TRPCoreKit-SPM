//
//  TRPTimelineSectionHeaderView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

protocol TRPTimelineSectionHeaderViewDelegate: AnyObject {
    // No actions needed - FAB handles adding plans
}

class TRPTimelineSectionHeaderView: UITableViewHeaderFooterView {
    
    static let reuseIdentifier = "TRPTimelineSectionHeaderView"
    
    weak var delegate: TRPTimelineSectionHeaderViewDelegate?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(20)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    // MARK: - Initialization
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)

        containerView.addSubview(cityLabel)

        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // City Label
            cityLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            cityLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cityLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            cityLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with data: TRPTimelineSectionHeaderData) {
        cityLabel.text = data.cityName
    }
}

