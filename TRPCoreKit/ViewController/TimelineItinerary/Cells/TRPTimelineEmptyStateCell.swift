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
        view.backgroundColor = .clear
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.fgWeak.uiColor
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let addPlanButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.primary.uiColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = FontSet.montserratSemiBold.font(14)
        button.layer.cornerRadius = 24
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
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
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(addPlanButton)
        
        addPlanButton.addTarget(self, action: #selector(addPlanButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            // Icon Image View
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Add Plan Button
            addPlanButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            addPlanButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            addPlanButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(title: String? = nil, description: String? = nil, buttonTitle: String? = nil) {
        // Set icon
        if let icon = TRPImageController().getImage(inFramework: "ic_empty_state", inApp: nil) {
            iconImageView.image = icon
        } else {
            // Fallback to system image if custom icon not found
            iconImageView.image = UIImage(systemName: "calendar.badge.plus")
        }
        
        // Set title (default if not provided)
        titleLabel.text = title ?? "No plans for this day"
        
        // Set description (default if not provided)
        descriptionLabel.text = description ?? "Add activities and places to make the most of your day"
        
        // Set button title (default if not provided)
        addPlanButton.setTitle(buttonTitle ?? "Add Plan", for: .normal)
    }
    
    // MARK: - Actions
    @objc private func addPlanButtonTapped() {
        delegate?.emptyStateCellDidTapAddPlan(self)
    }
}
