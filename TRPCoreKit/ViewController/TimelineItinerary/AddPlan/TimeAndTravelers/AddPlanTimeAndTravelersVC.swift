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
    /// Extra vertical space taken when the "end time before start" warning is
    /// visible: 8pt above the warning + warning row + 16pt below, minus the 32pt
    /// gap travelersLabel normally claims above it. Computed dynamically from the
    /// warning row's intrinsic height so 1- vs 2-line translations both fit.
    private var endTimeWarningExtraHeight: CGFloat {
        guard !warningStackView.isHidden else { return 0 }
        let warningHeight = warningStackView
            .systemLayoutSizeFitting(
                CGSize(width: view.bounds.width - 32, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        // (8 above warning + warningHeight + 16 below) − 32 baseline travelers gap
        return max(0, warningHeight - 8)
    }

    // MARK: - AddPlanChildViewController
    public var preferredContentHeight: CGFloat {
        return baseContentHeight + endTimeWarningExtraHeight
    }

    // MARK: - Properties
    public var viewModel: AddPlanTimeAndTravelersViewModel!
    public weak var containerVC: AddPlanContainerVC?
    private var selectedDayIndex: Int = 0
    private var editingStartTime = false  // Track which time is being edited

    /// True when the user picked midnight (00:00 / 12:00 AM) for end time. We
    /// snap the stored value to 23:59 of the selected day so `endTime > startTime`
    /// holds and the API sees end-of-day, but the field keeps displaying "00:00"
    /// — matching what the user actually picked. Reset whenever end-time changes
    /// to a non-midnight value, gets auto-cleared, or the whole form is cleared.
    private var endTimeShownAsMidnight = false
    
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

    // MARK: - End-time warning row (shown when end <= start)

    private lazy var warningIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = ColorSet.primary.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var warningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.primary.uiColor
        label.numberOfLines = 2
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTimeBeforeStartWarning)
        return label
    }()

    private lazy var warningStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [warningIconView, warningLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 6
        stack.isHidden = true
        return stack
    }()

    /// Travelers label top constraint when the warning is hidden — 32pt below the
    /// start-time field (existing baseline layout). Active by default.
    private var travelersLabelTopWithoutWarning: NSLayoutConstraint!
    /// Travelers label top constraint when the warning is visible — 16pt below
    /// the warning row, which itself sits 8pt below the end-time field.
    private var travelersLabelTopWithWarning: NSLayoutConstraint!
    
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
        view.addSubview(warningStackView)

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

            // Warning row — sits 8pt below the end-time field, leading-aligned to
            // the end-time field, trailing to view edge. Hidden by default; shown
            // when `updateEndTimeValidationUI` flips its visibility.
            warningStackView.topAnchor.constraint(equalTo: endTimeField.bottomAnchor, constant: 8),
            warningStackView.leadingAnchor.constraint(equalTo: endTimeField.leadingAnchor),
            warningStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Icon — fixed 16x16 inside the warning stack.
            warningIconView.widthAnchor.constraint(equalToConstant: 16),
            warningIconView.heightAnchor.constraint(equalToConstant: 16),

            // Travelers Label
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

        // Two mutually-exclusive top constraints for travelersLabel — swapped by
        // `updateEndTimeValidationUI` so the warning row pushes travelers down
        // when shown, then snaps back when end >= start.
        travelersLabelTopWithoutWarning = travelersLabel.topAnchor.constraint(
            equalTo: startTimeField.bottomAnchor, constant: 32
        )
        travelersLabelTopWithWarning = travelersLabel.topAnchor.constraint(
            equalTo: warningStackView.bottomAnchor, constant: 16
        )
        travelersLabelTopWithoutWarning.isActive = true
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

        dayFilterView.configure(with: days, selectedDay: selectedDayIndex, mode: .addPlan)
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
            // Midnight-picks display as "00:00" even though stored as 23:59 — see
            // `endTimeShownAsMidnight`.
            let displayText = endTimeShownAsMidnight ? "00:00" : formatter.string(from: endTime)
            endTimeField.setValue(displayText)
        } else {
            endTimeField.clear()
            endTimeShownAsMidnight = false
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

        // End time vs start time validation visual feedback.
        updateEndTimeValidationUI()
    }

    /// Reflect end-time vs start-time validity in the UI. When both times are
    /// set AND end is not strictly after start, switch the end-time field to
    /// its error styling, reveal the warning row, and let it push travelers
    /// down. Otherwise restore the baseline layout. Sheet height is refreshed
    /// via `containerVC.notifyContentHeightChanged()` so the bottom sheet grows
    /// when the warning appears and shrinks back when it clears.
    private func updateEndTimeValidationUI() {
        let startTime = viewModel.getStartTime()
        let endTime = viewModel.getEndTime()
        let hasError: Bool
        if let start = startTime, let end = endTime {
            hasError = end <= start
        } else {
            hasError = false
        }

        let wasHidden = warningStackView.isHidden
        endTimeField.setErrorState(hasError)
        warningStackView.isHidden = !hasError
        travelersLabelTopWithoutWarning.isActive = !hasError
        travelersLabelTopWithWarning.isActive = hasError

        if wasHidden != !hasError {
            containerVC?.notifyContentHeightChanged()
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
        editingStartTime = true
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime),
            selectedDate: viewModel.getSelectedDay(),
            minimumTime: getMinimumStartTime(),
            maximumTime: nil,
            initialTime: viewModel.getStartTime()
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    @objc private func endTimeButtonTapped() {
        editingStartTime = false
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime),
            selectedDate: viewModel.getSelectedDay(),
            minimumTime: getMinimumEndTime(),
            maximumTime: nil,
            initialTime: viewModel.getEndTime()
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    private func getMinimumStartTime() -> Date? {
        guard let selectedDay = viewModel.getSelectedDay() else { return nil }

        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDay) {
            // Today: current time + 30 minutes
            return Date().addingTimeInterval(30 * 60)
        }
        // Future dates: no restriction
        return nil
    }

    private func getMinimumEndTime() -> Date? {
        // End time must be at least start time
        if let startTime = viewModel.getStartTime() {
            return startTime
        }
        // If no start time yet, use same logic as start time
        return getMinimumStartTime()
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
        endTimeShownAsMidnight = false
        selectedDayIndex = 0
        configureDayFilterView()
        updateUI()
    }
}

// MARK: - TRPSingleTimePickerDelegate
extension AddPlanTimeAndTravelersVC: TRPSingleTimePickerDelegate {

    func singleTimePickerDidSelectTime(_ picker: TRPSingleTimePickerViewController, time: Date) {
        // Combine selected day's date with picked time
        let combinedTime = combineDate(viewModel.getSelectedDay(), withTime: time)

        if editingStartTime {  // Start time
            viewModel.setStartTime(combinedTime)

            // Clear end time if it's now invalid (before new start time)
            if let endTime = viewModel.getEndTime(), endTime <= combinedTime {
                viewModel.setEndTime(nil)
                endTimeShownAsMidnight = false
            }
        } else {  // End time
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: combinedTime)
            if components.hour == 0, components.minute == 0,
               let snapped = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: combinedTime) {
                // Midnight picked → snap stored value to 23:59 of the same day so
                // validation (endTime > startTime) and downstream API both see a
                // sane end-of-day timestamp. The field text stays "00:00" via
                // `endTimeShownAsMidnight`.
                viewModel.setEndTime(snapped)
                endTimeShownAsMidnight = true
            } else {
                viewModel.setEndTime(combinedTime)
                endTimeShownAsMidnight = false
            }
        }

        updateUI()
        containerVC?.updateContinueButtonState()
    }

    func singleTimePickerDidCancel(_ picker: TRPSingleTimePickerViewController) {
        // No action needed on cancel
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanTimeAndTravelersVC: TRPTimelineDayFilterViewDelegate {

    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        let days = viewModel.getAvailableDays()
        guard dayIndex < days.count, !days[dayIndex].isPastDay() else { return }
        selectedDayIndex = dayIndex
        viewModel.selectDay(days[dayIndex])
        updateCityCenterIfNeeded()  // Update starting point when day changes
    }
}
