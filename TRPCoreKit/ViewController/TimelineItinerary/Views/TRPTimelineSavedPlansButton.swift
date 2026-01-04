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
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let heartIconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.bgPink.uiColor // Light pink background
        view.layer.cornerRadius = 24 // Circular
        return view
    }()
    
    private let heartIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.primary.uiColor // Pink color
        return imageView
    }()
    
    private let badgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.primary.uiColor // Pink badge background
        view.layer.cornerRadius = 10 // Circular badge
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
        label.textColor = ColorSet.primaryText.uiColor // #333333
        label.numberOfLines = 2
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.primary.uiColor // Pink arrow
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
        
        // Set heart icon
        if let heartIcon = TRPImageController().getImage(inFramework: "ic_favorite", inApp: nil) {
            heartIconImageView.image = heartIcon
        } else {
            heartIconImageView.image = UIImage(systemName: "heart.fill")
        }
        
        // Set arrow icon
        if let arrowIcon = TRPImageController().getImage(inFramework: "ic_chevron_right", inApp: nil) {
            arrowImageView.image = arrowIcon
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
            
            // Heart Icon Container (48x48 circle)
            heartIconContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            heartIconContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            heartIconContainer.widthAnchor.constraint(equalToConstant: 48),
            heartIconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            // Heart Icon (centered in container)
            heartIconImageView.centerXAnchor.constraint(equalTo: heartIconContainer.centerXAnchor),
            heartIconImageView.centerYAnchor.constraint(equalTo: heartIconContainer.centerYAnchor),
            heartIconImageView.widthAnchor.constraint(equalToConstant: 24),
            heartIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Badge View (positioned bottom-right of heart icon)
            badgeView.trailingAnchor.constraint(equalTo: heartIconContainer.trailingAnchor, constant: -2),
            badgeView.bottomAnchor.constraint(equalTo: heartIconContainer.bottomAnchor, constant: -2),
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            
            // Badge Label (centered in badge with padding, determines badge width)
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -6),
            
            // Ensure badge has minimum width for single digit (circular)
            badgeView.widthAnchor.constraint(greaterThanOrEqualTo: badgeView.heightAnchor),
            
            // Saved Plans Text Label
            savedPlansTextLabel.leadingAnchor.constraint(equalTo: heartIconContainer.trailingAnchor, constant: 16),
            savedPlansTextLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            savedPlansTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -12),
            
            // Arrow Icon
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
            
            // Adjust corner radius based on digit count (pill shape for 2+ digits, circle for 1 digit)
            badgeView.layer.cornerRadius = savedPlansCount > 9 ? 12 : 10
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
