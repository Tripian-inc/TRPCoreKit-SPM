//
//  AddPlanTimeAndTravelersVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanTimeAndTravelersVC)
public class AddPlanTimeAndTravelersVC: TRPBaseUIViewController, AddPlanChildViewController {

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        return 580 // Updated height to include day filter and city selection
    }

    // MARK: - Properties
    public var viewModel: AddPlanTimeAndTravelersViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0
    
    // MARK: - UI Components

    // Day & City Selection
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

    private let separator0: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()

    // Starting Point
    private lazy var startingPointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectStartingPoint)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var startingPointButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 4
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 40)
        button.addTarget(self, action: #selector(startingPointButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var startingPointClearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        button.isHidden = true
        button.addTarget(self, action: #selector(clearStartingPoint), for: .touchUpInside)
        return button
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectDateAndTime)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var startTimeButton: UIButton = {
        let button = createTimeButton()
        button.addTarget(self, action: #selector(startTimeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var endTimeButton: UIButton = {
        let button = createTimeButton()
        button.addTarget(self, action: #selector(endTimeButtonTapped), for: .touchUpInside)
        return button
    }()

    private func createTimeButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 4
        button.setTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
        button.setTitleColor(ColorSet.primaryWeakText.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.contentHorizontalAlignment = .left

        // Add time icon
        let timeIcon = TRPImageController().getImage(inFramework: "ic_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(timeIcon, for: .normal)
        button.tintColor = ColorSet.primaryWeakText.uiColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        return button
    }
    
    private let bottomSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()
    
    private lazy var travelersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectTravelers)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private let travelersContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var travelersTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.travelers)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private let decrementButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.setImage(TRPImageController().getImage(inFramework: "ic_minus", inApp: nil), for: .normal)
        return button
    }()
    
    private let travelerCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0"
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
    
    // MARK: - Lifecycle
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh day filter and city to show current selections from previous screen
        configureDayFilterView()
        updateCityButton()

        // Update city center as starting point if user hasn't manually changed it
        updateCityCenterIfNeeded()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        // Add all subviews directly to view (scroll is handled by container)
        // Day & City Selection
        view.addSubview(dayLabel)
        view.addSubview(dayFilterView)
        view.addSubview(citySelectionButton)
        view.addSubview(separator0)

        // Starting Point
        view.addSubview(startingPointLabel)
        view.addSubview(startingPointButton)
        view.addSubview(startingPointClearButton)

        // Time Selection
        view.addSubview(timeLabel)
        view.addSubview(startTimeLabel)
        view.addSubview(startTimeButton)
        view.addSubview(endTimeLabel)
        view.addSubview(endTimeButton)

        // Travelers
        view.addSubview(travelersLabel)
        view.addSubview(travelersContainer)

        // Bottom Separator
        view.addSubview(bottomSeparator)

        travelersContainer.addSubview(travelersTextLabel)
        travelersContainer.addSubview(decrementButton)
        travelersContainer.addSubview(travelerCountLabel)
        travelersContainer.addSubview(incrementButton)

        setupConstraints()
        setupActions()
        configureDayFilterView()
        updateCityButton()
        updateUI()
    }

    // MARK: - Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Day Label - top 12, height 16
            dayLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
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

            // Separator 0
            separator0.topAnchor.constraint(equalTo: citySelectionButton.bottomAnchor, constant: 24),
            separator0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator0.heightAnchor.constraint(equalToConstant: 0.5),

            // Starting Point Label
            startingPointLabel.topAnchor.constraint(equalTo: separator0.bottomAnchor, constant: 24),
            startingPointLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Starting Point Button
            startingPointButton.topAnchor.constraint(equalTo: startingPointLabel.bottomAnchor, constant: 16),
            startingPointButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            startingPointButton.heightAnchor.constraint(equalToConstant: 48),

            // Starting Point Clear Button
            startingPointClearButton.centerYAnchor.constraint(equalTo: startingPointButton.centerYAnchor),
            startingPointClearButton.trailingAnchor.constraint(equalTo: startingPointButton.trailingAnchor, constant: -12),
            startingPointClearButton.widthAnchor.constraint(equalToConstant: 12),
            startingPointClearButton.heightAnchor.constraint(equalToConstant: 12),

            // Time Label
            timeLabel.topAnchor.constraint(equalTo: startingPointButton.bottomAnchor, constant: 32),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Start Time Label
            startTimeLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            startTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // End Time Label
            endTimeLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            endTimeLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4),

            // Start Time Button
            startTimeButton.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 4),
            startTimeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startTimeButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -4),
            startTimeButton.heightAnchor.constraint(equalToConstant: 48),

            // End Time Button
            endTimeButton.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 4),
            endTimeButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4),
            endTimeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            endTimeButton.heightAnchor.constraint(equalToConstant: 48),

            // Travelers Label
            travelersLabel.topAnchor.constraint(equalTo: endTimeButton.bottomAnchor, constant: 32),
            travelersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            travelersLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Travelers Container
            travelersContainer.topAnchor.constraint(equalTo: travelersLabel.bottomAnchor, constant: 16),
            travelersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            travelersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            travelersContainer.heightAnchor.constraint(equalToConstant: 32),

            travelersTextLabel.leadingAnchor.constraint(equalTo: travelersContainer.leadingAnchor),
            travelersTextLabel.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),

            incrementButton.trailingAnchor.constraint(equalTo: travelersContainer.trailingAnchor),
            incrementButton.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            incrementButton.widthAnchor.constraint(equalToConstant: 32),
            incrementButton.heightAnchor.constraint(equalToConstant: 32),

            travelerCountLabel.trailingAnchor.constraint(equalTo: incrementButton.leadingAnchor, constant: -16),
            travelerCountLabel.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            travelerCountLabel.widthAnchor.constraint(equalToConstant: 20),

            decrementButton.trailingAnchor.constraint(equalTo: travelerCountLabel.leadingAnchor, constant: -16),
            decrementButton.centerYAnchor.constraint(equalTo: travelersContainer.centerYAnchor),
            decrementButton.widthAnchor.constraint(equalToConstant: 32),
            decrementButton.heightAnchor.constraint(equalToConstant: 32),

            // Bottom Separator
            bottomSeparator.topAnchor.constraint(equalTo: travelersContainer.bottomAnchor, constant: 24),
            bottomSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    private func setupActions() {
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
    }

    private func updateCityCenterIfNeeded() {
        // Always update to current city's center if user hasn't manually selected a POI
        // This handles both initial load and city changes
        if viewModel.isStartingPointCityCenter() {
            viewModel.setStartingPointToCityCenter()
            updateUI()
        }
    }

    private func configureDayFilterView() {
        let days = viewModel.getAvailableDays()

        // Determine selected day index
        selectedDayIndex = viewModel.getSelectedDayIndex()

        dayFilterView.configure(with: days, selectedDay: selectedDayIndex)
    }

    private func updateCityButton() {
        citySelectionButton.configure(cityName: viewModel.getSelectedCity()?.name)
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
            self?.updateCityCenterIfNeeded()
        }

        presentVCWithDynamicHeight(citySelectionVC, prefersGrabberVisible: false)
    }
    
    private func updateUI() {
        // Update starting point button
        if let startingPointName = viewModel.getStartingPointName() {
            startingPointButton.setTitle(startingPointName, for: .normal)
            startingPointClearButton.isHidden = false
        } else {
            startingPointButton.setTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
            startingPointClearButton.isHidden = true
        }

        // Update time buttons
        if let startTime = viewModel.getStartTime() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            startTimeButton.setTitle(formatter.string(from: startTime), for: .normal)
            startTimeButton.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
            startTimeButton.tintColor = ColorSet.primaryText.uiColor
        } else {
            startTimeButton.setTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
            startTimeButton.setTitleColor(ColorSet.primaryWeakText.uiColor, for: .normal)
            startTimeButton.tintColor = ColorSet.primaryWeakText.uiColor
        }

        if let endTime = viewModel.getEndTime() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            endTimeButton.setTitle(formatter.string(from: endTime), for: .normal)
            endTimeButton.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
            endTimeButton.tintColor = ColorSet.primaryText.uiColor
        } else {
            endTimeButton.setTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
            endTimeButton.setTitleColor(ColorSet.primaryWeakText.uiColor, for: .normal)
            endTimeButton.tintColor = ColorSet.primaryWeakText.uiColor
        }

        // Update traveler count
        let travelerCount = viewModel.getTravelerCount()
        travelerCountLabel.text = "\(travelerCount)"

        // Update decrement button state based on traveler count
        if travelerCount <= 1 {
            decrementButton.isEnabled = false
            decrementButton.tintColor = ColorSet.lineWeak.uiColor
        } else {
            decrementButton.isEnabled = true
            decrementButton.tintColor = ColorSet.fgWeak.uiColor
        }
    }
    
    // MARK: - Actions
    @objc private func startingPointButtonTapped() {
        let poiSelectionViewModel = AddPlanPOISelectionViewModel(
            cityName: viewModel.getCityName(),
            cityId: viewModel.getCityId(),
            cityCenterPOI: viewModel.getCityCenterPOI(),
            bookedActivities: viewModel.getBookedActivities(),
            boundarySW: viewModel.getBoundarySW(),
            boundaryNE: viewModel.getBoundaryNE()
        )
        let poiSelectionVC = AddPlanPOISelectionVC()
        poiSelectionVC.viewModel = poiSelectionViewModel
        poiSelectionVC.modalPresentationStyle = .fullScreen
        poiSelectionVC.onLocationSelected = { [weak self] coordinate, name, _ in
            self?.handleLocationSelected(coordinate: coordinate, name: name)
        }

        present(poiSelectionVC, animated: true)
    }

    @objc private func clearStartingPoint() {
        viewModel.setStartingPoint(location: nil, name: nil)
        startingPointButton.setTitle(CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
        startingPointClearButton.isHidden = true
        containerVC?.updateContinueButtonState()
    }

    private func handleLocationSelected(coordinate: TRPLocation, name: String) {
        viewModel.setStartingPoint(location: coordinate, name: name)
        startingPointButton.setTitle(name, for: .normal)
        startingPointClearButton.isHidden = false
        containerVC?.updateContinueButtonState()
    }
    
    @objc private func startTimeButtonTapped() {
        showTimeRangeSelection(focusField: .from)
    }

    @objc private func endTimeButtonTapped() {
        showTimeRangeSelection(focusField: .until)
    }

    private func showTimeRangeSelection(focusField: TRPTimeRangeSelectionViewController.EditingField) {
        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // Set initial focus based on which button was tapped
        timeRangeVC.setInitialFocus(focusField)

        // Set initial times if already selected
        if let startTime = viewModel.getStartTime(), let endTime = viewModel.getEndTime() {
            timeRangeVC.setInitialTimes(from: startTime, to: endTime)
        }

        timeRangeVC.show(from: self)
    }
    
    @objc private func decrementTapped() {
        viewModel.decrementTravelers()
        updateUI()
        containerVC?.updateContinueButtonState()
    }
    
    @objc private func incrementTapped() {
        viewModel.incrementTravelers()
        updateUI()
        containerVC?.updateContinueButtonState()
    }
    
    /// Combines the date component from selectedDay with the time component from timePicker
    private func combineDate(_ selectedDay: Date?, withTime time: Date) -> Date {
        guard let selectedDay = selectedDay else {
            return time
        }

        let calendar = Calendar.current

        // Get date components from selected day
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDay)

        // Get time components from time picker
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        // Combine them
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? time
    }

    // MARK: - Public Methods
    public func clearSelection() {
        viewModel.clearSelection()
        let selectText = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
        startingPointButton.setTitle(selectText, for: .normal)
        startingPointClearButton.isHidden = true
        startTimeButton.setTitle(selectText, for: .normal)
        endTimeButton.setTitle(selectText, for: .normal)
        selectedDayIndex = 0
        configureDayFilterView()
        updateCityButton()
        updateUI()
    }
}

// MARK: - TRPTimeRangeSelectionDelegate
extension AddPlanTimeAndTravelersVC: TRPTimeRangeSelectionDelegate {

    func timeRangeSelected(fromTime: String, toTime: String) {
        // String version - not used, we use Date version
    }

    func timeRangeSelected(fromDate: Date, toDate: Date) {
        // Combine selected day's date with picked times
        let combinedStartTime = combineDate(viewModel.getSelectedDay(), withTime: fromDate)
        let combinedEndTime = combineDate(viewModel.getSelectedDay(), withTime: toDate)

        viewModel.setStartTime(combinedStartTime)
        viewModel.setEndTime(combinedEndTime)
        updateUI()
        containerVC?.updateContinueButtonState()
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanTimeAndTravelersVC: TRPTimelineDayFilterViewDelegate {

    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        selectedDayIndex = dayIndex
        let days = viewModel.getAvailableDays()
        if dayIndex < days.count {
            viewModel.selectDay(days[dayIndex])
            updateCityButton()  // Update city when day changes (for date-city mapping)
            updateCityCenterIfNeeded()  // Update starting point when city changes
        }
    }
}

// MARK: - AddPlanCitySelectionButtonDelegate
extension AddPlanTimeAndTravelersVC: AddPlanCitySelectionButtonDelegate {

    public func citySelectionButtonDidTap(_ view: AddPlanCitySelectionButton) {
        showCityPicker()
    }
}
