//
//  TRPTimelineCustomNavigationBar.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

protocol TRPTimelineCustomNavigationBarDelegate: AnyObject {
    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar)
}

class TRPTimelineCustomNavigationBar: UIView {
    
    weak var delegate: TRPTimelineCustomNavigationBarDelegate?
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Create circular white background for better visibility
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .clear
        backgroundView.isUserInteractionEnabled = false
        button.insertSubview(backgroundView, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: 44),
            backgroundView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let backIcon = TRPImageController().getImage(inFramework: "ic_back", inApp: nil)
        button.setImage(backIcon, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.navigationTitle)
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear  // Start with white for list view
        
        addSubview(backButton)
        addSubview(titleLabel)
        
        // Add shadow to title for better readability (will be useful in map mode)
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOpacity = 0
        
        NSLayoutConstraint.activate([
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        delegate?.customNavigationBarDidTapBack(self)
    }
    
    // MARK: - Public Methods
    public func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    public func getTitle() -> String? {
        return titleLabel.text
    }
}

