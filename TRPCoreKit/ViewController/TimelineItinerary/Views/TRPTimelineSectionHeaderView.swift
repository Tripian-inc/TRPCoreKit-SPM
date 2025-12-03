//
//  TRPTimelineSectionHeaderView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

protocol TRPTimelineSectionHeaderViewDelegate: AnyObject {
    func sectionHeaderViewDidTapFilter(_ view: TRPTimelineSectionHeaderView)
    func sectionHeaderViewDidTapAddPlans(_ view: TRPTimelineSectionHeaderView)
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(22)
        label.textColor = ColorSet.fg.uiColor
        label.text = "Itinerario"
        return label
    }()
    
    private let moreOptionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_three_dot_menu", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()
    
    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_filter", inApp: nil), for: .normal)
        button.tintColor = .white
        button.backgroundColor = ColorSet.primary.uiColor
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let addPlansButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Plans", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.backgroundColor = ColorSet.primary.uiColor
        button.layer.cornerRadius = 20
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        return button
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
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(moreOptionsButton)
        containerView.addSubview(cityLabel)
        containerView.addSubview(buttonsStackView)
        
        buttonsStackView.addArrangedSubview(filterButton)
        buttonsStackView.addArrangedSubview(addPlansButton)
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // More Options Button
            moreOptionsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreOptionsButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            moreOptionsButton.widthAnchor.constraint(equalToConstant: 30),
            moreOptionsButton.heightAnchor.constraint(equalToConstant: 30),
            
            // City Label
            cityLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            cityLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cityLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            // Buttons Stack View
            buttonsStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Filter Button
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        setupActions()
    }
    
    private func setupActions() {
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        addPlansButton.addTarget(self, action: #selector(addPlansButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func filterButtonTapped() {
        delegate?.sectionHeaderViewDidTapFilter(self)
    }
    
    @objc private func addPlansButtonTapped() {
        delegate?.sectionHeaderViewDidTapAddPlans(self)
    }
    
    // MARK: - Configuration
    func configure(with data: TRPTimelineSectionHeaderData) {
        cityLabel.text = data.cityName
        
        // Show/hide buttons based on whether it's the first section
        filterButton.isHidden = !data.showFilterButton
        addPlansButton.isHidden = !data.showAddPlansButton
        buttonsStackView.isHidden = !data.showFilterButton && !data.showAddPlansButton
        
        // Show "Itinerario" title and city label if:
        // 1. It's the first section (always show for context), OR
        // 2. There are multiple destinations (need to distinguish between cities)
        let shouldShowCityInfo = data.isFirstSection || data.hasMultipleDestinations
        titleLabel.isHidden = !shouldShowCityInfo
        cityLabel.isHidden = !shouldShowCityInfo
        moreOptionsButton.isHidden = !shouldShowCityInfo
    }
}

