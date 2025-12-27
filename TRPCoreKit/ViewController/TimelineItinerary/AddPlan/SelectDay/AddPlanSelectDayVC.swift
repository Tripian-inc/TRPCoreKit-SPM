//
//  AddPlanSelectDayVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanSelectDayVC)
public class AddPlanSelectDayVC: TRPBaseUIViewController {
    
    // MARK: - Properties
    public var viewModel: AddPlanSelectDayViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0
    
    // MARK: - UI Components
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addToDay)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.city)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var cityButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratRegular.font(16)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 40)
        button.addTarget(self, action: #selector(cityButtonTapped), for: .touchUpInside)
        
        // Add chevron down icon
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.tintColor = ColorSet.primaryText.uiColor
        chevronImageView.contentMode = .scaleAspectFit
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        return button
    }()
    
    // Selection section
    private lazy var selectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.howToAddPlans)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var smartRecommendationsCard: UIView = {
        return createModeSelectionCard(
            iconImageName: "ic_smart_recommendations",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendations),
            description: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendationsDescription),
            action: #selector(smartRecommendationsTapped)
        )
    }()
    
    private lazy var manualAddCard: UIView = {
        return createModeSelectionCard(
            iconImageName: "ic_add_manual",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addManually),
            description: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addManuallyDescription),
            action: #selector(manualAddTapped)
        )
    }()
    
    private func createModeSelectionCard(iconImageName: String, title: String, description: String, action: Selector) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = ColorSet.primary.uiColor
        iconView.contentMode = .scaleAspectFit
        if let image = TRPImageController().getImage(inFramework: iconImageName, inApp: nil) {
            iconView.image = image
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = FontSet.montserratSemiBold.font(14)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = description
        descLabel.font = FontSet.montserratMedium.font(12)
        descLabel.textColor = ColorSet.fgWeak.uiColor
        descLabel.numberOfLines = 0
        
        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    // Category selection section (shown when manual mode is selected)
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectCategories)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.isHidden = true
        return label
    }()
    
    private lazy var categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.isHidden = true
        return stackView
    }()
    
    private lazy var activitiesCategoryButton: UIButton = {
        return createCategoryButton(
            id: "activities",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryActivities),
            imageName: "ic_activities"
        )
    }()
    
    private lazy var placesOfInterestCategoryButton: UIButton = {
        return createCategoryButton(
            id: "places_of_interest",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryPlacesOfInterest),
            imageName: "ic_see_do"
        )
    }()
    
    private lazy var eatAndDrinkCategoryButton: UIButton = {
        return createCategoryButton(
            id: "eat_and_drink",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryEatAndDrink),
            imageName: "ic_eat_drink"
        )
    }()
    
    private var categoryButtons: [UIButton] {
        return [activitiesCategoryButton, placesOfInterestCategoryButton, eatAndDrinkCategoryButton]
    }
    
    private func createCategoryButton(id: String, title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        button.tag = id.hashValue // Use hash for tag
        
        // Store category ID in button's accessibility identifier
        button.accessibilityIdentifier = id
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = TRPImageController().getImage(inFramework: imageName, inApp: nil)
        iconImageView.tintColor = ColorSet.fg.uiColor
        iconImageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        
        button.addSubview(iconImageView)
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            label.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
        ])
        
        button.heightAnchor.constraint(equalToConstant: 100).isActive = true
        button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private var selectedMode: AddPlanMode {
        get {
            return viewModel.getSelectedMode()
        }
        set {
            viewModel.setSelectedMode(newValue)
        }
    }
    
    private var manualCardBottomConstraint: NSLayoutConstraint?
    private var categoryLabelTopConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        
        // Create scroll view for flexible height
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 24, right: 0)
        
        // Create a content container
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews to container
        contentContainer.addSubview(dayLabel)
        contentContainer.addSubview(dayFilterView)
        contentContainer.addSubview(cityLabel)
        contentContainer.addSubview(cityButton)
        contentContainer.addSubview(selectionLabel)
        contentContainer.addSubview(smartRecommendationsCard)
        contentContainer.addSubview(manualAddCard)
        contentContainer.addSubview(categoryLabel)
        contentContainer.addSubview(categoryStackView)
        
        // Add category buttons to stack view
        categoryStackView.addArrangedSubview(activitiesCategoryButton)
        categoryStackView.addArrangedSubview(placesOfInterestCategoryButton)
        categoryStackView.addArrangedSubview(eatAndDrinkCategoryButton)
        
        scrollView.addSubview(contentContainer)
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            // Scroll View - fills entire view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content Container - with padding inside scroll view
            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Day Label
            dayLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            
            // Day Filter View
            dayFilterView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 8),
            dayFilterView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 56),
            
            // City Label
            cityLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 16),
            cityLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            
            // City Button
            cityButton.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 8),
            cityButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            cityButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            cityButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Selection Label
            selectionLabel.topAnchor.constraint(equalTo: cityButton.bottomAnchor, constant: 24),
            selectionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            selectionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // Smart Recommendations Card
            smartRecommendationsCard.topAnchor.constraint(equalTo: selectionLabel.bottomAnchor, constant: 12),
            smartRecommendationsCard.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            smartRecommendationsCard.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // Manual Add Card
            manualAddCard.topAnchor.constraint(equalTo: smartRecommendationsCard.bottomAnchor, constant: 12),
            manualAddCard.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            manualAddCard.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // Category Label (initially hidden, shown when manual mode selected)
            categoryLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            categoryLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // Category Stack View (initially hidden, shown when manual mode selected)
            categoryStackView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 12),
            categoryStackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            categoryStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            categoryStackView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
        
        // Store constraints that need to be toggled
        manualCardBottomConstraint = manualAddCard.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        categoryLabelTopConstraint = categoryLabel.topAnchor.constraint(equalTo: manualAddCard.bottomAnchor, constant: 24)
        
        // Initially, manual card is at bottom (categories hidden)
        manualCardBottomConstraint?.isActive = true
        
        configureDayFilterView()
        updateCityButton()
        updateSelectionStyles()
        updateCategorySelectionUI()
        
        // Restore continue button state if mode was already selected
        updateContinueButtonState()
    }
    
    // MARK: - Setup
    private func configureDayFilterView() {
        let days = viewModel.getAvailableDays()
        let dayStrings = formatDays(days)
        
        // Determine selected day index
        if let selectedDay = viewModel.getSelectedDay(),
           let index = days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            selectedDayIndex = index
        }
        
        dayFilterView.configure(with: dayStrings, selectedDay: selectedDayIndex)
    }
    
    private func formatDays(_ days: [Date]) -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        
        return days.map { date in
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: date).capitalized
            dateFormatter.dateFormat = "dd/MM"
            let dayDate = dateFormatter.string(from: date)
            return "\(dayName) \(dayDate)"
        }
    }
    
    private func updateCityButton() {
        cityButton.setTitle(viewModel.getSelectedCity()?.name ?? "Select City", for: .normal)
    }
    
    // MARK: - Actions
    @objc private func cityButtonTapped() {
        showCityPicker()
    }
    
    @objc private func smartRecommendationsTapped() {
        selectedMode = .smartRecommendations
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
        // This will proceed to the next screens (time/travelers, then categories)
    }
    
    @objc private func manualAddTapped() {
        selectedMode = .manual
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
        // Show category selection on this screen
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        guard let categoryId = sender.accessibilityIdentifier else { return }
        
        // Single-select: deselect all others first
        for button in categoryButtons {
            let isSelected = (button.accessibilityIdentifier == categoryId)
            updateCategoryButtonStyle(button, isSelected: isSelected)
        }
        
        // Store selected category
        viewModel.setSelectedManualCategory(categoryId)
        updateContinueButtonState()
    }
    
    private func showCityPicker() {
        let cities = viewModel.getAvailableCities()

        guard !cities.isEmpty else { return }

        let citySelectionVC = AddPlanCitySelectionVC()
        citySelectionVC.cities = cities
        citySelectionVC.selectedCity = viewModel.getSelectedCity()
        citySelectionVC.onCitySelected = { [weak self] city in
            self?.viewModel.selectCity(city)
            self?.updateCityButton()
        }

        presentVCWithModal(citySelectionVC)
    }
    
    private func updateSelectionStyles() {
        // Update smart recommendations card - only change border color
        if selectedMode == .smartRecommendations {
            smartRecommendationsCard.layer.borderColor = ColorSet.fg.uiColor.cgColor
        } else {
            smartRecommendationsCard.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        }
        
        // Update manual add card - only change border color
        if selectedMode == .manual {
            manualAddCard.layer.borderColor = ColorSet.fg.uiColor.cgColor
        } else {
            manualAddCard.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        }
    }
    
    private func updateCategorySelectionUI() {
        let showCategories = (selectedMode == .manual)
        categoryLabel.isHidden = !showCategories
        categoryStackView.isHidden = !showCategories
        
        // Update constraints based on visibility
        if showCategories {
            // Show categories: manual card connects to category label, categories at bottom
            manualCardBottomConstraint?.isActive = false
            categoryLabelTopConstraint?.isActive = true
        } else {
            // Hide categories: manual card at bottom
            categoryLabelTopConstraint?.isActive = false
            manualCardBottomConstraint?.isActive = true
        }
        
        // Update category button styles based on selected category
        if showCategories {
            let selectedCategoryId = viewModel.getSelectedManualCategory()
            for button in categoryButtons {
                let isSelected = (button.accessibilityIdentifier == selectedCategoryId)
                updateCategoryButtonStyle(button, isSelected: isSelected)
            }
        }
    }
    
    private func updateCategoryButtonStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.layer.borderColor = ColorSet.fg.uiColor.cgColor
            button.layer.borderWidth = 2
        } else {
            button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
            button.layer.borderWidth = 1
        }
    }
    
    private func updateContinueButtonState() {
        let canContinue: Bool
        if selectedMode == .manual {
            // For manual mode, require category selection
            canContinue = viewModel.getSelectedManualCategory() != nil
        } else if selectedMode == .smartRecommendations {
            // For smart recommendations, just need mode selection
            canContinue = true
        } else {
            canContinue = false
        }
        containerVC?.setContinueButtonEnabled(canContinue)
    }
    
    // MARK: - Public Methods
    public func clearSelection() {
        viewModel.clearSelection()
        viewModel.setSelectedManualCategory(nil)
        selectedDayIndex = 0
        configureDayFilterView()
        updateCityButton()
        
        // Clear selection mode
        selectedMode = .none
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanSelectDayVC: TRPTimelineDayFilterViewDelegate {
    
    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        selectedDayIndex = dayIndex
        let days = viewModel.getAvailableDays()
        if dayIndex < days.count {
            viewModel.selectDay(days[dayIndex])
        }
    }
    
    public func dayFilterViewDidTapFilter(_ view: TRPTimelineDayFilterView) {
        // Optional: Handle filter button tap if needed
        // Could be used to show a calendar picker or additional filters
    }
}
