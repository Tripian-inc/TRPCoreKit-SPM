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
public class AddPlanSelectDayVC: TRPBaseUIViewController, AddPlanChildViewController {

    // MARK: - Height Constants (Static heights from design)
    private let baseContentHeight: CGFloat = 464 // Base height without categories
    private let manualModeContentHeight: CGFloat = 632 // Height when manual mode is selected (shows categories)

    // MARK: - Properties
    public var viewModel: AddPlanSelectDayViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        let showCategories = (viewModel?.getSelectedMode() == .manual)
        return showCategories ? manualModeContentHeight : baseContentHeight
    }
    
    // MARK: - UI Components
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addToDay)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var citySelectionButton: AddPlanCitySelectionButton = {
        let view = AddPlanCitySelectionButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
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
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        
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
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
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
        stackView.spacing = 8
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
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        button.tag = id.hashValue // Use hash for tag

        // Store category ID in button's accessibility identifier
        button.accessibilityIdentifier = id

        // Container view to hold icon and label (centered in button)
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.isUserInteractionEnabled = false

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = TRPImageController().getImage(inFramework: imageName, inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = ColorSet.fg.uiColor
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping

        contentContainer.addSubview(iconImageView)
        contentContainer.addSubview(label)
        button.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            // Center container in button
            contentContainer.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            contentContainer.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 10),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -10),

            // Icon at top of container
            iconImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            // Label below icon
            label.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])

        button.heightAnchor.constraint(equalToConstant: 96).isActive = true
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
    private var categoryStackViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh day filter and city to show current selections (in case changed in another screen)
        configureDayFilterView()
        updateCityButton()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        // Add all subviews directly to view (scroll is handled by container)
        view.addSubview(dayLabel)
        view.addSubview(dayFilterView)
        view.addSubview(citySelectionButton)
        view.addSubview(selectionLabel)
        view.addSubview(smartRecommendationsCard)
        view.addSubview(manualAddCard)
        view.addSubview(categoryLabel)
        view.addSubview(categoryStackView)

        // Add category buttons to stack view
        categoryStackView.addArrangedSubview(activitiesCategoryButton)
        categoryStackView.addArrangedSubview(placesOfInterestCategoryButton)
        categoryStackView.addArrangedSubview(eatAndDrinkCategoryButton)

        NSLayoutConstraint.activate([
            // Day Label - top 12, height 16
            dayLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            dayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dayLabel.heightAnchor.constraint(equalToConstant: 16),

            // Day Filter View - top 12, height 44
            dayFilterView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 12),
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 44),

            // City Selection Button - top 24, height 68 (16 label + 4 gap + 48 button)
            citySelectionButton.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
            citySelectionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            citySelectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Selection Label (How do you add plans) - top 32, height 24
            selectionLabel.topAnchor.constraint(equalTo: citySelectionButton.bottomAnchor, constant: 32),
            selectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectionLabel.heightAnchor.constraint(equalToConstant: 24),

            // Smart Recommendations Card - top 16, height 88
            smartRecommendationsCard.topAnchor.constraint(equalTo: selectionLabel.bottomAnchor, constant: 16),
            smartRecommendationsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            smartRecommendationsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            smartRecommendationsCard.heightAnchor.constraint(equalToConstant: 88),

            // Manual Add Card - top 8, height 88
            manualAddCard.topAnchor.constraint(equalTo: smartRecommendationsCard.bottomAnchor, constant: 8),
            manualAddCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            manualAddCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            manualAddCard.heightAnchor.constraint(equalToConstant: 88),

            // Category Label - height 24 (top constraint is dynamic)
            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryLabel.heightAnchor.constraint(equalToConstant: 24),

            // Category Stack View - top 16, height 96
            categoryStackView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 16),
            categoryStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryStackView.heightAnchor.constraint(equalToConstant: 96),
        ])

        // Store constraints that need to be toggled based on category visibility
        // When manual not selected: manualAddCard bottom = view.bottom - 32
        manualCardBottomConstraint = manualAddCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        // When manual selected: categoryLabel top = manualAddCard.bottom + 32
        categoryLabelTopConstraint = categoryLabel.topAnchor.constraint(equalTo: manualAddCard.bottomAnchor, constant: 32)
        // When manual selected: categoryStackView bottom = view.bottom - 32
        categoryStackViewBottomConstraint = categoryStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)

        // Initially, manual card is at bottom (categories hidden)
        manualCardBottomConstraint?.isActive = true
        categoryStackViewBottomConstraint?.isActive = false

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

        // Determine selected day index
        if let selectedDay = viewModel.getSelectedDay(),
           let index = days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            selectedDayIndex = index
        }

        dayFilterView.configure(with: days, selectedDay: selectedDayIndex)
    }
    
    private func updateCityButton() {
        citySelectionButton.configure(cityName: viewModel.getSelectedCity()?.name)
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
            updateSelectedButtonStyle(button, isSelected: isSelected)
        }
        
        // Store selected category
        viewModel.setSelectedManualCategory(categoryId)
        updateContinueButtonState()
    }
    
    private func showCityPicker() {
        let citiesForDay = viewModel.getCitiesForSelectedDay()
        let hasMappings = viewModel.hasDateCityMapping()

        // Check if we have any cities to show
        guard !citiesForDay.mapped.isEmpty || !citiesForDay.other.isEmpty else { return }

        let citySelectionVC = AddPlanCitySelectionVC()
        citySelectionVC.mappedCities = citiesForDay.mapped
        citySelectionVC.otherCities = citiesForDay.other
        citySelectionVC.showSections = hasMappings && !citiesForDay.mapped.isEmpty
        citySelectionVC.selectedCity = viewModel.getSelectedCity()
        citySelectionVC.onCitySelected = { [weak self] city in
            self?.viewModel.selectCity(city)
            self?.updateCityButton()
        }

        presentVCWithDynamicHeight(citySelectionVC, prefersGrabberVisible: false)
    }
    
    private func updateSelectionStyles() {
        updateSelectedButtonStyle(smartRecommendationsCard, isSelected: selectedMode == .smartRecommendations)
        updateSelectedButtonStyle(manualAddCard, isSelected: selectedMode == .manual)
    }
    
    private func updateCategorySelectionUI() {
        let showCategories = (selectedMode == .manual)
        categoryLabel.isHidden = !showCategories
        categoryStackView.isHidden = !showCategories

        // Update constraints based on visibility
        manualCardBottomConstraint?.isActive = !showCategories
        categoryLabelTopConstraint?.isActive = showCategories
        categoryStackViewBottomConstraint?.isActive = showCategories

        // Update category button styles based on selected category
        if showCategories {
            let selectedCategoryId = viewModel.getSelectedManualCategory()
            for button in categoryButtons {
                let isSelected = (button.accessibilityIdentifier == selectedCategoryId)
                updateSelectedButtonStyle(button, isSelected: isSelected)
            }
        }

        // Notify container to update sheet height
        containerVC?.notifyContentHeightChanged()
    }
    
    private func updateSelectedButtonStyle(_ view: UIView, isSelected: Bool) {
        if isSelected {
            view.layer.borderColor = ColorSet.fg.uiColor.cgColor
            view.layer.borderWidth = 1.5
        } else {
            view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            view.layer.borderWidth = 1
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
            updateCityButton()  // Update city when day changes (for date-city mapping)
        }
    }
}

// MARK: - AddPlanCitySelectionButtonDelegate
extension AddPlanSelectDayVC: AddPlanCitySelectionButtonDelegate {

    public func citySelectionButtonDidTap(_ view: AddPlanCitySelectionButton) {
        showCityPicker()
    }
}
