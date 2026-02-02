//
//  TRPTimelineSavedPlansButton.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

protocol TRPTimelineSavedPlansButtonDelegate: AnyObject {
    func savedPlansButtonDidTap(_ button: TRPTimelineSavedPlansButton)
}

class TRPTimelineSavedPlansButton: UIView {
    
    weak var delegate: TRPTimelineSavedPlansButtonDelegate?
    
    // MARK: - UI Components
    private let button: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor // #F7F7F7 (very close to #F6F6F6)
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let heartIconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.bgPink.uiColor // Light pink background
        view.layer.cornerRadius = 20 // 40x40 circular
        return view
    }()

    private let heartIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.primary.uiColor // Primary color fill
        return imageView
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.primary.uiColor // Primary badge background
        view.layer.cornerRadius = 8.5 // 17x17 circular (17/2 = 8.5)
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(12)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let savedPlansTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 2
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.primary.uiColor // Primary tint color
        return imageView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(button)
        
        // Add subviews to button
        button.addSubview(heartIconContainer)
        heartIconContainer.addSubview(heartIconImageView)
        heartIconContainer.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        button.addSubview(savedPlansTextLabel)
        button.addSubview(arrowImageView)
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Set heart icon (filled with primary color)
        if let heartIcon = TRPImageController().getImage(inFramework: "ic_heart", inApp: nil) {
            heartIconImageView.image = heartIcon.withRenderingMode(.alwaysTemplate)
        } else {
            heartIconImageView.image = UIImage(systemName: "heart.fill")
        }

        // Set arrow icon (ic_next with primary tint)
        if let arrowIcon = TRPImageController().getImage(inFramework: "ic_next", inApp: nil) {
            arrowImageView.image = arrowIcon.withRenderingMode(.alwaysTemplate)
        } else {
            arrowImageView.image = UIImage(systemName: "chevron.right")
        }

        NSLayoutConstraint.activate([
            // Button fills the view
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 72),

            // Heart Icon Container (40x40 circle) - 16px from left
            heartIconContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            heartIconContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            heartIconContainer.widthAnchor.constraint(equalToConstant: 40),
            heartIconContainer.heightAnchor.constraint(equalToConstant: 40),

            // Heart Icon (20x20, centered in container)
            heartIconImageView.centerXAnchor.constraint(equalTo: heartIconContainer.centerXAnchor),
            heartIconImageView.centerYAnchor.constraint(equalTo: heartIconContainer.centerYAnchor),
            heartIconImageView.widthAnchor.constraint(equalToConstant: 20),
            heartIconImageView.heightAnchor.constraint(equalToConstant: 20),

            // Badge View (17x17, positioned to overflow container by 3px from right and bottom)
            badgeView.trailingAnchor.constraint(equalTo: heartIconContainer.trailingAnchor, constant: 3),
            badgeView.bottomAnchor.constraint(equalTo: heartIconContainer.bottomAnchor, constant: 3),
            badgeView.widthAnchor.constraint(equalToConstant: 17),
            badgeView.heightAnchor.constraint(equalToConstant: 17),

            // Badge Label (centered in badge)
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            // Saved Plans Text Label
            savedPlansTextLabel.leadingAnchor.constraint(equalTo: heartIconContainer.trailingAnchor, constant: 16),
            savedPlansTextLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            savedPlansTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -12),

            // Arrow Icon - 16px from right
            arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 24),
            arrowImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    func configure(savedPlansCount: Int) {
        // Set badge count
        if savedPlansCount > 0 {
            badgeLabel.text = "\(savedPlansCount)"
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }

        // Set text - "Añade tus planes guardados al itinerario"
        savedPlansTextLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addSavedPlansToItinerary)
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        delegate?.savedPlansButtonDidTap(self)
    }
}
