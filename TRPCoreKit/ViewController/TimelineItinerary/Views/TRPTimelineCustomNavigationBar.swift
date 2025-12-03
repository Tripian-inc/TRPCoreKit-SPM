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
        let backIcon = TRPImageController().getImage(inFramework: "ic_back", inApp: nil)
        button.setImage(backIcon, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .left
        label.text = "Destinos"
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
        backgroundColor = .white
        
        addSubview(backButton)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
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

