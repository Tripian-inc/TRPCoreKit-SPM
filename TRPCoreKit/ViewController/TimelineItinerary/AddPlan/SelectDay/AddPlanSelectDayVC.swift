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
    private let baseContentHeight: CGFloat = 486
    private let manualModeContentHeight: CGFloat = 654
    private let citySelectionHeight: CGFloat = 84 // button (68) + top margin (24)
    private let travelersSectionHeight: CGFloat = 112 // 24 margin + 24 label + 16 gap + 48 container + 8 padding

    // MARK: - Properties
    public var viewModel: AddPlanSelectDayViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        let showCategories = (viewModel?.getSelectedMode() == .manual)
        let showTravelers = showCategories
        let hasSingleCity = viewModel?.hasSingleCity() ?? false
        let cityOffset = hasSingleCity ? citySelectionHeight : 0
        var height = showCategories ? manualModeContentHeight : baseContentHeight
        if showTravelers { height += travelersSectionHeight }
        return height - cityOffset
    }
    
    // MARK: - UI Components
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addToDay)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var citySelectionField: TRPSelectionField = {
        let field = TRPSelectionField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.destination)
        field.onTap = { [weak self] in self?.citySelectionTapped() }
        return field
    }()

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
        
        let iconCircle = UIView()
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = ColorSet.bgPink.uiColor
        iconCircle.layer.cornerRadius = 26

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = ColorSet.primary.uiColor
        iconView.contentMode = .scaleAspectFit
        if let image = TRPImageController().getImage(inFramework: iconImageName, inApp: nil) {
            iconView.image = image.withRenderingMode(.alwaysTemplate)
        }
        iconCircle.addSubview(iconView)

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
        
        view.addSubview(iconCircle)
        view.addSubview(titleLabel)
        view.addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iconCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            iconCircle.widthAnchor.constraint(equalToConstant: 52),
            iconCircle.heightAnchor.constraint(equalToConstant: 52),

            iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            
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

    // Travelers section (shown when "activities" category is selected)
    private lazy var travelersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectTravelers)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.isHidden = true
        return label
    }()

    private let travelersContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    private lazy var travelersTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.travelers)
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let decrementButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.tintColor = ColorSet.fgWeak.uiColor
        button.setImage(TRPImageController().getImage(inFramework: "ic_minus", inApp: nil, withTintColor: true), for: .normal)
        return button
    }()

    private let travelerCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "1"
        label.font = FontSet.montserratMedium.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        return label
    }()

    private let incrementButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.setImage(TRPImageController().getImage(inFramework: "ic_increase", inApp: nil), for: .normal)
        return button
    }()
    
    private func createCategoryButton(id: String, title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        button.tag = id.hashValue

        button.accessibilityIdentifier = id

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
            contentContainer.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            contentContainer.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 10),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -10),

            iconImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

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
    private var travelersLabelTopConstraint: NSLayoutConstraint?
    private var travelersContainerBottomConstraint: NSLayoutConstraint?
    private var selectionLabelTopToCityConstraint: NSLayoutConstraint?
    private var selectionLabelTopToDayFilterConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh in case selections changed on another screen.
        configureDayFilterView()
        updateCityButton()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        view.addSubview(dayLabel)
        view.addSubview(dayFilterView)
        view.addSubview(citySelectionField)
        view.addSubview(selectionLabel)
        view.addSubview(smartRecommendationsCard)
        view.addSubview(manualAddCard)
        view.addSubview(categoryLabel)
        view.addSubview(categoryStackView)
        view.addSubview(travelersLabel)
        view.addSubview(travelersContainer)

        categoryStackView.addArrangedSubview(activitiesCategoryButton)
        categoryStackView.addArrangedSubview(placesOfInterestCategoryButton)
        categoryStackView.addArrangedSubview(eatAndDrinkCategoryButton)

        travelersContainer.addSubview(travelersTextLabel)
        travelersContainer.addSubview(decrementButton)
        travelersContainer.addSubview(travelerCountLabel)
        travelersContainer.addSubview(incrementButton)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            dayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dayLabel.heightAnchor.constraint(equalToConstant: 16),

            dayFilterView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 12),
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 74),

            citySelectionField.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
            citySelectionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            citySelectionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            selectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectionLabel.heightAnchor.constraint(equalToConstant: 24),

            smartRecommendationsCard.topAnchor.constraint(equalTo: selectionLabel.bottomAnchor, constant: 16),
            smartRecommendationsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            smartRecommendationsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            smartRecommendationsCard.heightAnchor.constraint(equalToConstant: 88),

            manualAddCard.topAnchor.constraint(equalTo: smartRecommendationsCard.bottomAnchor, constant: 8),
            manualAddCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            manualAddCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            manualAddCard.heightAnchor.constraint(equalToConstant: 88),

            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryLabel.heightAnchor.constraint(equalToConstant: 24),

            categoryStackView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 16),
            categoryStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryStackView.heightAnchor.constraint(equalToConstant: 96),

            travelersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            travelersLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            travelersLabel.heightAnchor.constraint(equalToConstant: 24),

            travelersContainer.topAnchor.constraint(equalTo: travelersLabel.bottomAnchor, constant: 16),
            travelersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            travelersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            travelersContainer.heightAnchor.constraint(equalToConstant: 48),

            travelersTextLabel.leadingAnchor.constraint(equalTo: travelersContainer.leadingAnchor),
            travelersTextLabel.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),

            incrementButton.trailingAnchor.constraint(equalTo: travelersContainer.trailingAnchor),
            incrementButton.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            incrementButton.widthAnchor.constraint(equalToConstant: 40),
            incrementButton.heightAnchor.constraint(equalToConstant: 40),

            travelerCountLabel.trailingAnchor.constraint(equalTo: incrementButton.leadingAnchor, constant: -8),
            travelerCountLabel.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            travelerCountLabel.widthAnchor.constraint(equalToConstant: 32),

            decrementButton.trailingAnchor.constraint(equalTo: travelerCountLabel.leadingAnchor, constant: -8),
            decrementButton.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            decrementButton.widthAnchor.constraint(equalToConstant: 40),
            decrementButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        // These constraints are toggled by category / travelers visibility.
        manualCardBottomConstraint = manualAddCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        categoryLabelTopConstraint = categoryLabel.topAnchor.constraint(equalTo: manualAddCard.bottomAnchor, constant: 32)
        categoryStackViewBottomConstraint = categoryStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        travelersLabelTopConstraint = travelersLabel.topAnchor.constraint(equalTo: categoryStackView.bottomAnchor, constant: 24)
        travelersContainerBottomConstraint = travelersContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)

        // selectionLabel top depends on whether the city field is visible.
        selectionLabelTopToCityConstraint = selectionLabel.topAnchor.constraint(equalTo: citySelectionField.bottomAnchor, constant: 24)
        selectionLabelTopToDayFilterConstraint = selectionLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 32)

        manualCardBottomConstraint?.isActive = true
        categoryStackViewBottomConstraint?.isActive = false
        travelersLabelTopConstraint?.isActive = false
        travelersContainerBottomConstraint?.isActive = false

        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)

        configureDayFilterView()
        updateCityButton()
        updateSelectionStyles()
        updateCategorySelectionUI()

        updateContinueButtonState()
    }
    
    // MARK: - Setup
    private func configureDayFilterView() {
        let days = viewModel.getAvailableDays()

        if let selectedDay = viewModel.getSelectedDay(),
           let index = days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            selectedDayIndex = index
        }

        dayFilterView.configure(with: days, selectedDay: selectedDayIndex, mode: .addPlan)
    }
    
    private func updateCityButton() {
        let hasSingleCity = viewModel.hasSingleCity()
        citySelectionField.isHidden = hasSingleCity

        selectionLabelTopToCityConstraint?.isActive = !hasSingleCity
        selectionLabelTopToDayFilterConstraint?.isActive = hasSingleCity

        if !hasSingleCity {
            citySelectionField.setValue(viewModel.getSelectedCity()?.name)
        }
    }
    
    @objc private func smartRecommendationsTapped() {
        selectedMode = .smartRecommendations
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
    }

    @objc private func manualAddTapped() {
        selectedMode = .manual
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        guard let categoryId = sender.accessibilityIdentifier else { return }

        // Single-select: deselect all others first.
        for button in categoryButtons {
            let isSelected = (button.accessibilityIdentifier == categoryId)
            updateSelectedButtonStyle(button, isSelected: isSelected)
        }

        viewModel.setSelectedManualCategory(categoryId)
        updateTravelersSectionUI()
        updateContinueButtonState()
    }

    @objc private func decrementTapped() {
        viewModel.decrementTravelers()
        updateTravelerCountUI()
    }

    @objc private func incrementTapped() {
        viewModel.incrementTravelers()
        updateTravelerCountUI()
    }
    
    private func citySelectionTapped() {
        showCityPicker()
    }

    private func showCityPicker() {
        let citiesForDay = viewModel.getCitiesForSelectedDay()
        let hasMappings = viewModel.hasDateCityMapping()

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

        manualCardBottomConstraint?.isActive = !showCategories
        categoryLabelTopConstraint?.isActive = showCategories

        if showCategories {
            let selectedCategoryId = viewModel.getSelectedManualCategory()
            for button in categoryButtons {
                let isSelected = (button.accessibilityIdentifier == selectedCategoryId)
                updateSelectedButtonStyle(button, isSelected: isSelected)
            }
        }

        updateTravelersSectionUI()
    }

    private func updateTravelersSectionUI() {
        let showTravelers = (selectedMode == .manual)
        travelersLabel.isHidden = !showTravelers
        travelersContainer.isHidden = !showTravelers

        categoryStackViewBottomConstraint?.isActive = !showTravelers && (selectedMode == .manual)
        travelersLabelTopConstraint?.isActive = showTravelers
        travelersContainerBottomConstraint?.isActive = showTravelers

        if showTravelers {
            updateTravelerCountUI()
        }

        containerVC?.notifyContentHeightChanged()
    }

    private func updateTravelerCountUI() {
        let count = viewModel.getTravelerCount()
        travelerCountLabel.text = "\(count)"

        if count <= 1 {
            decrementButton.isEnabled = false
            decrementButton.tintColor = ColorSet.lineWeak.uiColor
        } else {
            decrementButton.isEnabled = true
            decrementButton.tintColor = ColorSet.fgWeak.uiColor
        }
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
            canContinue = viewModel.getSelectedManualCategory() != nil
        } else if selectedMode == .smartRecommendations {
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

        selectedMode = .none
        updateSelectionStyles()
        updateCategorySelectionUI()
        updateContinueButtonState()
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanSelectDayVC: TRPTimelineDayFilterViewDelegate {

    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        let days = viewModel.getAvailableDays()
        guard dayIndex < days.count, !days[dayIndex].isPastDay() else { return }
        selectedDayIndex = dayIndex
        viewModel.selectDay(days[dayIndex])
        updateCityButton()
    }
}

