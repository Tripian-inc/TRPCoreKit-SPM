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
public class AddPlanTimeAndTravelersVC: TRPBaseUIViewController {
    
    // MARK: - Properties
    public var viewModel: AddPlanTimeAndTravelersViewModel!
    public weak var containerVC: AddPlanContainerVC?
    
    // MARK: - UI Components
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
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratRegular.font(16)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 40)
        button.addTarget(self, action: #selector(startingPointButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var startingPointClearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .light)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(clearStartingPoint), for: .touchUpInside)
        return button
    }()
    
    private let separator1: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
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
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 4
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
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
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 4
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: #selector(endTimeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let separator2: UIView = {
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
        label.font = FontSet.montserratMedium.font(16)
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

        // Update city center as starting point if user hasn't manually changed it
        updateCityCenterIfNeeded()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        
        // Create scroll view for flexible height
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
        
        // Create content container
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews to container
        contentContainer.addSubview(startingPointLabel)
        contentContainer.addSubview(startingPointButton)
        contentContainer.addSubview(startingPointClearButton)
        contentContainer.addSubview(separator1)
        contentContainer.addSubview(timeLabel)
        contentContainer.addSubview(startTimeLabel)
        contentContainer.addSubview(startTimeButton)
        contentContainer.addSubview(endTimeLabel)
        contentContainer.addSubview(endTimeButton)
        contentContainer.addSubview(separator2)
        contentContainer.addSubview(travelersLabel)
        contentContainer.addSubview(travelersContainer)
        
        travelersContainer.addSubview(travelersTextLabel)
        travelersContainer.addSubview(decrementButton)
        travelersContainer.addSubview(travelerCountLabel)
        travelersContainer.addSubview(incrementButton)
        
        scrollView.addSubview(contentContainer)
        view.addSubview(scrollView)
        
        setupConstraints(scrollView: scrollView, contentContainer: contentContainer)
        setupActions()
        updateUI()
    }
    
    // MARK: - Setup
    private func setupConstraints(scrollView: UIScrollView, contentContainer: UIView) {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content Container
            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Starting Point Label
            startingPointLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            startingPointLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            startingPointLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            
            // Starting Point Button
            startingPointButton.topAnchor.constraint(equalTo: startingPointLabel.bottomAnchor, constant: 16),
            startingPointButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            startingPointButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            startingPointButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Starting Point Clear Button
            startingPointClearButton.centerYAnchor.constraint(equalTo: startingPointButton.centerYAnchor),
            startingPointClearButton.trailingAnchor.constraint(equalTo: startingPointButton.trailingAnchor, constant: -12),
            startingPointClearButton.widthAnchor.constraint(equalToConstant: 24),
            startingPointClearButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Separator 1
            separator1.topAnchor.constraint(equalTo: startingPointButton.bottomAnchor, constant: 24),
            separator1.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator1.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            separator1.heightAnchor.constraint(equalToConstant: 1),
            
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 24),
            timeLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            
            // Start Time Label
            startTimeLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            startTimeLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            
            // End Time Label
            endTimeLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            endTimeLabel.leadingAnchor.constraint(equalTo: contentContainer.centerXAnchor, constant: 4),
            
            // Start Time Button
            startTimeButton.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 4),
            startTimeButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            startTimeButton.trailingAnchor.constraint(equalTo: contentContainer.centerXAnchor, constant: -4),
            startTimeButton.heightAnchor.constraint(equalToConstant: 48),
            
            // End Time Button
            endTimeButton.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 4),
            endTimeButton.leadingAnchor.constraint(equalTo: contentContainer.centerXAnchor, constant: 4),
            endTimeButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            endTimeButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Separator 2
            separator2.topAnchor.constraint(equalTo: endTimeButton.bottomAnchor, constant: 24),
            separator2.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator2.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            separator2.heightAnchor.constraint(equalToConstant: 1),
            
            // Travelers Label
            travelersLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 24),
            travelersLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            travelersLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            
            // Travelers Container
            travelersContainer.topAnchor.constraint(equalTo: travelersLabel.bottomAnchor, constant: 16),
            travelersContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            travelersContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            travelersContainer.heightAnchor.constraint(equalToConstant: 32),
            travelersContainer.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            
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
    
    private func updateUI() {
        // Update starting point button
        if let startingPointName = viewModel.getStartingPointName() {
            startingPointButton.setTitle(startingPointName, for: .normal)
            startingPointClearButton.isHidden = false
        } else {
            startingPointButton.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select), for: .normal)
            startingPointClearButton.isHidden = true
        }

        // Update time buttons
        if let startTime = viewModel.getStartTime() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            startTimeButton.setTitle(formatter.string(from: startTime), for: .normal)
        }

        if let endTime = viewModel.getEndTime() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            endTimeButton.setTitle(formatter.string(from: endTime), for: .normal)
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
            savedPOIs: viewModel.getSavedPOIs(),
            cityName: viewModel.getCityName(),
            cityCenterPOI: viewModel.getCityCenterPOI()
        )
        let poiSelectionVC = AddPlanPOISelectionVC()
        poiSelectionVC.viewModel = poiSelectionViewModel
        poiSelectionVC.onLocationSelected = { [weak self] coordinate, name in
            self?.handleLocationSelected(coordinate: coordinate, name: name)
        }

        present(poiSelectionVC, animated: true)
    }

    @objc private func clearStartingPoint() {
        viewModel.setStartingPoint(location: nil, name: nil)
        startingPointButton.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select), for: .normal)
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
        showTimePicker(for: .start)
    }
    
    @objc private func endTimeButtonTapped() {
        showTimePicker(for: .end)
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
    
    private enum TimeType {
        case start
        case end
    }
    
    private func showTimePicker(for type: TimeType) {
        let title = type == .start ? 
            AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime) : 
            AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        let alert = UIAlertController(title: title,
                                     message: "\n\n\n\n\n\n\n\n",
                                     preferredStyle: .actionSheet)
        
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.locale = Locale(identifier: "es_ES")
        timePicker.frame = CGRect(x: 0, y: 50, width: alert.view.bounds.width - 20, height: 200)
        
        alert.view.addSubview(timePicker)
        
        let selectAction = UIAlertAction(title: "Seleccionar", style: .default) { [weak self] _ in
            guard let self = self else { return }

            // Combine selected day's date with picked time
            let combinedDateTime = self.combineDate(self.viewModel.getSelectedDay(), withTime: timePicker.date)

            if type == .start {
                self.viewModel.setStartTime(combinedDateTime)
            } else {
                self.viewModel.setEndTime(combinedDateTime)
            }
            self.updateUI()
            self.containerVC?.updateContinueButtonState()
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel)
        
        alert.addAction(selectAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
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
        let selectText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select)
        startingPointButton.setTitle(selectText, for: .normal)
        startingPointClearButton.isHidden = true
        startTimeButton.setTitle(selectText, for: .normal)
        endTimeButton.setTitle(selectText, for: .normal)
        updateUI()
    }
}
