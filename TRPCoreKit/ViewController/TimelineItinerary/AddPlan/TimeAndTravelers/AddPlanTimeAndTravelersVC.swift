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

    // MARK: - Height Constants
    private let baseContentHeight: CGFloat = 488 // Height without city selection

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        return baseContentHeight
    }

    // MARK: - Properties
    public var viewModel: AddPlanTimeAndTravelersViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0
    
    // MARK: - UI Components

    // Day Selection
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

    // Starting Point
    private lazy var startingPointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectStartingPoint)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var startingPointField: TRPSelectionField = {
        let field = TRPSelectionField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.onTap = { [weak self] in self?.startingPointButtonTapped() }
        return field
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectDateAndTime)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var startTimeField: TRPSelectionField = {
        let field = TRPSelectionField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime)
        field.onTap = { [weak self] in self?.startTimeButtonTapped() }
        return field
    }()

    private lazy var endTimeField: TRPSelectionField = {
        let field = TRPSelectionField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        field.onTap = { [weak self] in self?.endTimeButtonTapped() }
        return field
    }()
    
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
        button.tintColor = ColorSet.lineWeak.uiColor
        button.setImage(TRPImageController().getImage(inFramework: "ic_minus", inApp: nil, withTintColor: true), for: .normal)
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

        // Refresh day filter to show current selections from previous screen
        configureDayFilterView()

        // Update city center as starting point if user hasn't manually changed it
        updateCityCenterIfNeeded()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        // Add all subviews directly to view (scroll is handled by container)
        // Day Selection
        view.addSubview(dayLabel)
        view.addSubview(dayFilterView)

        // Starting Point
        view.addSubview(startingPointLabel)
        view.addSubview(startingPointField)

        // Time Selection
        view.addSubview(timeLabel)
        view.addSubview(startTimeField)
        view.addSubview(endTimeField)

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
            dayFilterView.heightAnchor.constraint(equalToConstant: 74),

            // Starting Point Label
            startingPointLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
            startingPointLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Starting Point Field
            startingPointField.topAnchor.constraint(equalTo: startingPointLabel.bottomAnchor, constant: 16),
            startingPointField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Time Label
            timeLabel.topAnchor.constraint(equalTo: startingPointField.bottomAnchor, constant: 32),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Start Time Field
            startTimeField.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            startTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startTimeField.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),

            // End Time Field
            endTimeField.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            endTimeField.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            endTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Travelers Label
            travelersLabel.topAnchor.constraint(equalTo: startTimeField.bottomAnchor, constant: 32),
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

    private func updateUI() {
        // Update starting point field
        if let startingPointName = viewModel.getStartingPointName() {
            startingPointField.setValue(startingPointName)
        } else {
            startingPointField.clear()
        }

        // Update time fields
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        if let startTime = viewModel.getStartTime() {
            startTimeField.setValue(formatter.string(from: startTime))
        } else {
            startTimeField.clear()
        }

        if let endTime = viewModel.getEndTime() {
            endTimeField.setValue(formatter.string(from: endTime))
        } else {
            endTimeField.clear()
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
            favouriteItems: viewModel.getFavouriteItems(),
            boundarySW: viewModel.getBoundarySW(),
            boundaryNE: viewModel.getBoundaryNE(),
            cityCoordinate: viewModel.getSelectedCity()?.coordinate
        )
        let poiSelectionVC = AddPlanPOISelectionVC()
        poiSelectionVC.viewModel = poiSelectionViewModel
        poiSelectionVC.modalPresentationStyle = .fullScreen
        poiSelectionVC.onLocationSelected = { [weak self] coordinate, name, _ in
            self?.handleLocationSelected(coordinate: coordinate, name: name)
        }

        present(poiSelectionVC, animated: true)
    }

    private func handleLocationSelected(coordinate: TRPLocation, name: String) {
        viewModel.setStartingPoint(location: coordinate, name: name)
        startingPointField.setValue(name)
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
        startingPointField.clear()
        startTimeField.clear()
        endTimeField.clear()
        selectedDayIndex = 0
        configureDayFilterView()
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
            updateCityCenterIfNeeded()  // Update starting point when day changes
        }
    }
}
