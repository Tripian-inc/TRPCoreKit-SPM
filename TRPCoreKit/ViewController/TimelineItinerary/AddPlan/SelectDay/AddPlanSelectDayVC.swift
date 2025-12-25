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
        if let image = UIImage(systemName: "sparkles") {
            iconView.image = image
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendations)
        titleLabel.font = FontSet.montserratSemiBold.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendationsDescription)
        descLabel.font = FontSet.montserratRegular.font(14)
        descLabel.textColor = ColorSet.fgWeak.uiColor
        descLabel.numberOfLines = 0
        
        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(smartRecommendationsTapped))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    private lazy var manualAddCard: UIView = {
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
        if let image = UIImage(systemName: "hand.tap") {
            iconView.image = image
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addManually)
        titleLabel.font = FontSet.montserratSemiBold.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addManuallyDescription)
        descLabel.font = FontSet.montserratRegular.font(14)
        descLabel.textColor = ColorSet.fgWeak.uiColor
        descLabel.numberOfLines = 0
        
        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(manualAddTapped))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    private var selectedMode: AddPlanMode {
        get {
            return viewModel.getSelectedMode()
        }
        set {
            viewModel.setSelectedMode(newValue)
        }
    }
    
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
            manualAddCard.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
        
        configureDayFilterView()
        updateCityButton()
        updateSelectionStyles()
        
        // Restore continue button state if mode was already selected
        if selectedMode != .none {
            containerVC?.setContinueButtonEnabled(true)
        }
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
        containerVC?.setContinueButtonEnabled(true)
        // This will proceed to the next screens (time/travelers, then categories)
    }
    
    @objc private func manualAddTapped() {
        selectedMode = .manual
        updateSelectionStyles()
        containerVC?.setContinueButtonEnabled(true)
        // This will open the catalog directly
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
        
        // Present as modal sheet (iOS 15+)
        if #available(iOS 15.0, *) {
            if let sheet = citySelectionVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
        } else {
            // For iOS 14 and below, use regular modal presentation
            citySelectionVC.modalPresentationStyle = .pageSheet
        }
        
        present(citySelectionVC, animated: true)
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
    
    // MARK: - Public Methods
    public func clearSelection() {
        viewModel.clearSelection()
        selectedDayIndex = 0
        configureDayFilterView()
        updateCityButton()
        
        // Clear selection mode
        selectedMode = .none
        updateSelectionStyles()
        containerVC?.setContinueButtonEnabled(false)
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
