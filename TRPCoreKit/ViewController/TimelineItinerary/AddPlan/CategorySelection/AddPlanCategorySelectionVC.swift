//
//  AddPlanCategorySelectionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanCategorySelectionVC)
public class AddPlanCategorySelectionVC: TRPBaseUIViewController, AddPlanChildViewController {

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        return 284
    }

    // MARK: - Properties
    public var viewModel: AddPlanCategorySelectionViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var categoryButtons: [UIButton] = []
    
    // MARK: - UI Components
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectCategories)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let gridContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bottomSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        view.addSubview(descriptionLabel)
        view.addSubview(gridContainer)
        view.addSubview(bottomSeparator)

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            gridContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            gridContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            gridContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            bottomSeparator.topAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: 24),
            bottomSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        setupCategoryButtons()
    }

    // MARK: - Setup
    private func setupCategoryButtons() {
        let itemsPerRow = 3
        let spacing: CGFloat = 8
        let buttonHeight: CGFloat = 96

        let screenWidth = UIScreen.main.bounds.width
        let containerWidth = screenWidth - 48
        let buttonWidth = (containerWidth - (CGFloat(itemsPerRow - 1) * spacing)) / CGFloat(itemsPerRow)

        let totalItems = viewModel.categories.count
        let itemsInLastRow = totalItems % itemsPerRow == 0 ? itemsPerRow : totalItems % itemsPerRow
        let totalRows = Int(ceil(CGFloat(totalItems) / CGFloat(itemsPerRow)))
        
        var previousRowView: UIView? = nil

        for row in 0..<totalRows {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            gridContainer.addSubview(rowView)

            if let previousRow = previousRowView {
                rowView.topAnchor.constraint(equalTo: previousRow.bottomAnchor, constant: spacing).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: gridContainer.topAnchor).isActive = true
            }
            rowView.centerXAnchor.constraint(equalTo: gridContainer.centerXAnchor).isActive = true
            rowView.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

            let startIndex = row * itemsPerRow
            let endIndex = min(startIndex + itemsPerRow, totalItems)
            let itemsInThisRow = endIndex - startIndex
            
            var previousButton: UIButton? = nil
            
            for i in startIndex..<endIndex {
                let category = viewModel.categories[i]
                let button = createCategoryButton(category: category, width: buttonWidth, height: buttonHeight)
                button.tag = i
                rowView.addSubview(button)
                categoryButtons.append(button)

                NSLayoutConstraint.activate([
                    button.topAnchor.constraint(equalTo: rowView.topAnchor),
                    button.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    button.widthAnchor.constraint(equalToConstant: buttonWidth)
                ])
                
                if let previousBtn = previousButton {
                    button.leadingAnchor.constraint(equalTo: previousBtn.trailingAnchor, constant: spacing).isActive = true
                } else {
                    button.leadingAnchor.constraint(equalTo: rowView.leadingAnchor).isActive = true
                }
                
                if i == endIndex - 1 {
                    button.trailingAnchor.constraint(equalTo: rowView.trailingAnchor).isActive = true
                }
                
                previousButton = button
            }
            
            if row == totalRows - 1 {
                rowView.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor).isActive = true
            }
            
            previousRowView = rowView
        }
    }
    
    private func createCategoryButton(category: PlanCategory, width: CGFloat, height: CGFloat) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.isUserInteractionEnabled = false

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = TRPImageController().getImage(inFramework: category.iconName, inApp: nil, withTintColor: true)
        iconImageView.tintColor = ColorSet.fg.uiColor
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = category.name
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping

        contentContainer.addSubview(iconImageView)
        contentContainer.addSubview(label)
        button.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            contentContainer.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            contentContainer.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 8),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -8),

            iconImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            label.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            label.widthAnchor.constraint(lessThanOrEqualToConstant: width - 16),
        ])

        button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)

        updateCategoryButtonStyle(button, isSelected: category.isSelected)

        return button
    }
    
    private func updateCategoryButtonStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = .white
            button.layer.borderColor = ColorSet.fg.uiColor.cgColor
            button.layer.borderWidth = 2
        } else {
            button.backgroundColor = .white
            button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
            button.layer.borderWidth = 1
        }
    }
    
    // MARK: - Actions
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        viewModel.toggleCategory(at: index)
        updateCategoryButtonStyle(sender, isSelected: viewModel.categories[index].isSelected)
        containerVC?.updateContinueButtonState()
    }
    
    // MARK: - Public Methods
    public func clearSelection() {
        viewModel.clearSelection()
        for (index, button) in categoryButtons.enumerated() {
            updateCategoryButtonStyle(button, isSelected: viewModel.categories[index].isSelected)
        }
    }
}
