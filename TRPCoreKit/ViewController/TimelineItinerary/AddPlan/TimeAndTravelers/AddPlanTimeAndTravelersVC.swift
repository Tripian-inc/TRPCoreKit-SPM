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
    private let baseContentHeight: CGFloat = 432
    /// Extra height when the "end before start" warning shows; derived from the row's intrinsic height so 1- vs 2-line translations fit.
    private var endTimeWarningExtraHeight: CGFloat {
        guard !warningStackView.isHidden else { return 0 }
        let warningHeight = warningStackView
            .systemLayoutSizeFitting(
                CGSize(width: view.bounds.width - 32, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
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
    private var editingStartTime = false

    /// Midnight end-time picks are stored as 23:59 (so endTime > startTime / API sees end-of-day) but the field still shows "12:00 AM".
    private var endTimeShownAsMidnight = false

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

    private lazy var startingPointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectStartingPoint)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var startingPointField: TRPSelectionField = {
        let field = TRPSelectionField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.onTap = { [weak self] in self?.startingPointButtonTapped() }
        return field
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

    private var travelersLabelTopWithoutWarning: NSLayoutConstraint!
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

        configureDayFilterView()
        updateCityCenterIfNeeded()
    }

    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        view.addSubview(dayLabel)
        view.addSubview(dayFilterView)

        view.addSubview(startingPointLabel)
        view.addSubview(startingPointField)

        view.addSubview(startTimeField)
        view.addSubview(endTimeField)
        view.addSubview(warningStackView)

        view.addSubview(travelersLabel)
        view.addSubview(travelersContainer)

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
            dayLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            dayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dayLabel.heightAnchor.constraint(equalToConstant: 16),

            dayFilterView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 12),
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 74),

            startingPointLabel.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 24),
            startingPointLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            startingPointField.topAnchor.constraint(equalTo: startingPointLabel.bottomAnchor, constant: 4),
            startingPointField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startingPointField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            startTimeField.topAnchor.constraint(equalTo: startingPointField.bottomAnchor, constant: 24),
            startTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startTimeField.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),

            endTimeField.topAnchor.constraint(equalTo: startingPointField.bottomAnchor, constant: 24),
            endTimeField.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            endTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            warningStackView.topAnchor.constraint(equalTo: endTimeField.bottomAnchor, constant: 8),
            warningStackView.leadingAnchor.constraint(equalTo: endTimeField.leadingAnchor),
            warningStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            warningIconView.widthAnchor.constraint(equalToConstant: 16),
            warningIconView.heightAnchor.constraint(equalToConstant: 16),

            travelersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            travelersLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

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

            bottomSeparator.topAnchor.constraint(equalTo: travelersContainer.bottomAnchor, constant: 24),
            bottomSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // Swapped by `updateEndTimeValidationUI` so the warning row pushes travelers down when shown.
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
        if viewModel.isStartingPointCityCenter() {
            viewModel.setStartingPointToCityCenter()
            updateUI()
        }
    }

    private func configureDayFilterView() {
        let days = viewModel.getAvailableDays()

        selectedDayIndex = viewModel.getSelectedDayIndex()

        dayFilterView.configure(with: days, selectedDay: selectedDayIndex, mode: .addPlan)
    }

    private func updateUI() {
        if let startingPointName = viewModel.getStartingPointName() {
            startingPointField.setValue(startingPointName)
        } else {
            startingPointField.clear()
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let startTime = viewModel.getStartTime() {
            startTimeField.setValue(formatter.string(from: startTime))
        } else {
            startTimeField.clear()
        }

        if let endTime = viewModel.getEndTime() {
            let displayText = endTimeShownAsMidnight ? "12:00 AM" : formatter.string(from: endTime)
            endTimeField.setValue(displayText)
        } else {
            endTimeField.clear()
            endTimeShownAsMidnight = false
        }

        let travelerCount = viewModel.getTravelerCount()
        travelerCountLabel.text = "\(travelerCount)"

        if travelerCount <= 1 {
            decrementButton.isEnabled = false
            decrementButton.tintColor = ColorSet.lineWeak.uiColor
        } else {
            decrementButton.isEnabled = true
            decrementButton.tintColor = ColorSet.fgWeak.uiColor
        }

        updateEndTimeValidationUI()
    }

    /// Shows the warning row + error styling when both times are set and end is not strictly after start; refreshes sheet height.
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
        let initialTime = viewModel.getStartTime() ?? viewModel.getDefaultInitialTime()
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime),
            selectedDate: viewModel.getSelectedDay(),
            minimumTime: viewModel.getMinimumStartTime(),
            maximumTime: nil,
            initialTime: initialTime
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    @objc private func endTimeButtonTapped() {
        editingStartTime = false
        // Strict-minimum only when a start time exists: then the picker minimum IS the start and must not itself be confirmable (end > start).
        let hasStartTime = viewModel.getStartTime() != nil
        let initialTime = viewModel.getEndTime() ?? viewModel.getDefaultInitialEndTime()
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime),
            selectedDate: viewModel.getSelectedDay(),
            minimumTime: viewModel.getMinimumEndTime(),
            maximumTime: nil,
            initialTime: initialTime,
            strictMinimum: hasStartTime
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
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
    
    private func combineDate(_ selectedDay: Date?, withTime time: Date) -> Date {
        guard let selectedDay = selectedDay else {
            return time
        }

        let calendar = Calendar.current

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDay)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

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
        let combinedTime = combineDate(viewModel.getSelectedDay(), withTime: time)

        if editingStartTime {
            viewModel.setStartTime(combinedTime)

            if let endTime = viewModel.getEndTime(), endTime <= combinedTime {
                viewModel.setEndTime(nil)
                endTimeShownAsMidnight = false
            }
        } else {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: combinedTime)
            if components.hour == 0, components.minute == 0,
               let snapped = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: combinedTime) {
                // Midnight snaps to 23:59 so validation (endTime > startTime) and the API see end-of-day; field text stays "12:00 AM".
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
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension AddPlanTimeAndTravelersVC: TRPTimelineDayFilterViewDelegate {

    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        let days = viewModel.getAvailableDays()
        guard dayIndex < days.count, !days[dayIndex].isPastDay() else { return }
        selectedDayIndex = dayIndex
        viewModel.selectDay(days[dayIndex])
        updateCityCenterIfNeeded()
    }
}
