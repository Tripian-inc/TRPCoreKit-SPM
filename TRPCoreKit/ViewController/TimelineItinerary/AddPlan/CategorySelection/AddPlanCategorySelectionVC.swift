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
public class AddPlanCategorySelectionVC: TRPBaseUIViewController {
    
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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        return scrollView
    }()
    
    private let categoriesContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(categoriesContainer)
        categoriesContainer.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            categoriesContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            categoriesContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            categoriesContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            categoriesContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            categoriesContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: categoriesContainer.topAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: categoriesContainer.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: categoriesContainer.trailingAnchor, constant: -24),
        ])
        
        setupCategoryButtons()
    }
    
    // MARK: - Setup
    private func setupCategoryButtons() {
        // Create grid container
        let gridContainer = UIView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        categoriesContainer.addSubview(gridContainer)
        
        NSLayoutConstraint.activate([
            gridContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            gridContainer.leadingAnchor.constraint(equalTo: categoriesContainer.leadingAnchor, constant: 24),
            gridContainer.trailingAnchor.constraint(equalTo: categoriesContainer.trailingAnchor, constant: -24),
            gridContainer.bottomAnchor.constraint(equalTo: categoriesContainer.bottomAnchor)
        ])
        
        let itemsPerRow = 3
        let spacing: CGFloat = 8
        let buttonHeight: CGFloat = 96
        
        // Calculate button width based on screen width
        let screenWidth = UIScreen.main.bounds.width
        let containerWidth = screenWidth - 48 // 24pt padding on each side
        let buttonWidth = (containerWidth - (CGFloat(itemsPerRow - 1) * spacing)) / CGFloat(itemsPerRow)
        
        // Calculate total rows
        let totalItems = viewModel.categories.count
        let itemsInLastRow = totalItems % itemsPerRow == 0 ? itemsPerRow : totalItems % itemsPerRow
        let totalRows = Int(ceil(CGFloat(totalItems) / CGFloat(itemsPerRow)))
        
        var previousRowView: UIView? = nil
        
        // Create rows
        for row in 0..<totalRows {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            gridContainer.addSubview(rowView)
            
            // Row constraints
            if let previousRow = previousRowView {
                rowView.topAnchor.constraint(equalTo: previousRow.bottomAnchor, constant: spacing).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: gridContainer.topAnchor).isActive = true
            }
            rowView.centerXAnchor.constraint(equalTo: gridContainer.centerXAnchor).isActive = true
            rowView.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            
            // Add buttons to row
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
                
                // Button constraints
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
        
        // Icon container
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = TRPImageController().getImage(inFramework: category.iconName, inApp: nil)
        iconImageView.tintColor = ColorSet.fgWeak.uiColor
        iconImageView.contentMode = .scaleAspectFit
        
        // Label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = category.name
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        
        button.addSubview(iconImageView)
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -10),
        ])
        
        button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        
        // Set initial state
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
