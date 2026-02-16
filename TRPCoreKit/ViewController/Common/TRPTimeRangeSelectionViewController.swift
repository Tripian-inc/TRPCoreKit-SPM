//
//  TRPTimeRangeSelectionViewController.swift
//  TRPCoreKit
//
//  Created on 2.12.2025.

import UIKit
import TRPFoundationKit

protocol TRPTimeRangeSelectionDelegate: AnyObject {
    func timeRangeSelected(fromTime: String, toTime: String)
    func timeRangeSelected(fromDate: Date, toDate: Date)
}

class TRPTimeRangeSelectionViewController: TRPBaseUIViewController {

    // MARK: - Properties
    weak var delegate: TRPTimeRangeSelectionDelegate?
    private var fromTime: String?
    private var toTime: String?
    private var fromDate: Date?
    private var toDate: Date?

    private let contentView = UIView()

    // Track which field is being edited
    enum EditingField {
        case from
        case until
    }
    private var currentEditingField: EditingField = .from
    private var initialFocusField: EditingField = .from

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.timeTitle)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textAlignment = .center
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // From Section
    private let fromLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fromContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let fromClockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let fromTimeLabel: UILabel = {
        let label = UILabel()
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
        label.font = FontSet.montserratLight.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // To Section
    private let toLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let toContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let toClockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let toTimeLabel: UILabel = {
        let label = UILabel()
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
        label.font = FontSet.montserratLight.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "en_US")
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private lazy var confirmButton: TRPButton = {
        let button = TRPButton(
            title: CommonLocalizationKeys.localized(CommonLocalizationKeys.confirm),
            style: .primary
        )
        button.setEnabled(false)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateConfirmButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPickerView()
        // Ensure initial values are displayed
        updateFromDisplay()
        updateToDisplay()
        updateConfirmButtonState()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white

        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(fromLabel)
        contentView.addSubview(fromContainer)
        contentView.addSubview(toLabel)
        contentView.addSubview(toContainer)
        contentView.addSubview(timePicker)
        contentView.addSubview(confirmButton)

        fromContainer.addSubview(fromClockIcon)
        fromContainer.addSubview(fromTimeLabel)
        toContainer.addSubview(toClockIcon)
        toContainer.addSubview(toTimeLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Close button
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // From label
            fromLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            fromLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            // From container
            fromContainer.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 8),
            fromContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fromContainer.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -8),
            fromContainer.heightAnchor.constraint(equalToConstant: 40),

            // From clock icon
            fromClockIcon.leadingAnchor.constraint(equalTo: fromContainer.leadingAnchor, constant: 12),
            fromClockIcon.centerYAnchor.constraint(equalTo: fromContainer.centerYAnchor),
            fromClockIcon.widthAnchor.constraint(equalToConstant: 16),
            fromClockIcon.heightAnchor.constraint(equalToConstant: 16),

            // From time label
            fromTimeLabel.leadingAnchor.constraint(equalTo: fromClockIcon.trailingAnchor, constant: 4),
            fromTimeLabel.centerYAnchor.constraint(equalTo: fromContainer.centerYAnchor),

            // To label
            toLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            toLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),

            // To container
            toContainer.topAnchor.constraint(equalTo: toLabel.bottomAnchor, constant: 8),
            toContainer.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),
            toContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toContainer.heightAnchor.constraint(equalToConstant: 40),

            // To clock icon
            toClockIcon.leadingAnchor.constraint(equalTo: toContainer.leadingAnchor, constant: 12),
            toClockIcon.centerYAnchor.constraint(equalTo: toContainer.centerYAnchor),
            toClockIcon.widthAnchor.constraint(equalToConstant: 16),
            toClockIcon.heightAnchor.constraint(equalToConstant: 16),

            // To time label
            toTimeLabel.leadingAnchor.constraint(equalTo: toClockIcon.trailingAnchor, constant: 4),
            toTimeLabel.centerYAnchor.constraint(equalTo: toContainer.centerYAnchor),

            // Time picker
            timePicker.topAnchor.constraint(equalTo: fromContainer.bottomAnchor, constant: 24),
            timePicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 200),

            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        let fromTapGesture = UITapGestureRecognizer(target: self, action: #selector(fromFieldTapped))
        fromContainer.addGestureRecognizer(fromTapGesture)

        let toTapGesture = UITapGestureRecognizer(target: self, action: #selector(toFieldTapped))
        toContainer.addGestureRecognizer(toTapGesture)
    }

    private func setupPickerView() {
        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)

        // If no initial times were set, default start time to current time
        if fromDate == nil {
            let now = Date()
            fromDate = now
            fromTime = timeStringFromDate(now)
            updateFromDisplay()
        }

        // Set current editing field based on initial focus
        currentEditingField = initialFocusField

        // Set picker to the focused field's time
        let focusedDate = initialFocusField == .from ? fromDate : toDate
        if let date = focusedDate {
            timePicker.date = date
        }

        // Highlight the initial editing field
        highlightContainer(fromContainer, highlight: initialFocusField == .from)
        highlightContainer(toContainer, highlight: initialFocusField == .until)
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func confirmButtonTapped() {
        guard let fromDate = fromDate, let toDate = toDate else {
            return
        }

        // Convert to HH:mm format for service calls
        let fromTimeHHmm = convertTo24HourFormat(fromDate)
        let toTimeHHmm = convertTo24HourFormat(toDate)

        dismiss(animated: true, completion: { [weak self] in
            self?.delegate?.timeRangeSelected(fromTime: fromTimeHHmm, toTime: toTimeHHmm)
            self?.delegate?.timeRangeSelected(fromDate: fromDate, toDate: toDate)
        })
    }

    /// Converts Date to "HH:mm" format string
    private func convertTo24HourFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @objc private func fromFieldTapped() {
        currentEditingField = .from
        highlightContainer(fromContainer, highlight: true)
        highlightContainer(toContainer, highlight: false)
        updatePickerForCurrentField()
    }

    @objc private func toFieldTapped() {
        currentEditingField = .until
        highlightContainer(fromContainer, highlight: false)
        highlightContainer(toContainer, highlight: true)
        updatePickerForCurrentField()
    }

    @objc private func timePickerValueChanged() {
        let selectedDate = timePicker.date
        let timeString = timeStringFromDate(selectedDate)

        switch currentEditingField {
        case .from:
            fromTime = timeString
            fromDate = selectedDate
            updateFromDisplay()
        case .until:
            toTime = timeString
            toDate = selectedDate
            updateToDisplay()
        }

        updateConfirmButtonState()
    }

    // MARK: - UI Updates
    private func highlightContainer(_ container: UIView, highlight: Bool) {
        UIView.animate(withDuration: 0.2) {
            container.layer.borderColor = highlight
                ? ColorSet.borderActive.uiColor.cgColor
                : ColorSet.lineWeak.uiColor.cgColor
        }
    }

    private func updateFromDisplay() {
        if let time = fromTime {
            fromTimeLabel.text = time
            fromTimeLabel.textColor = ColorSet.primaryText.uiColor
        } else {
            fromTimeLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
            fromTimeLabel.textColor = ColorSet.fgWeak.uiColor
        }
    }

    private func updateToDisplay() {
        if let time = toTime {
            toTimeLabel.text = time
            toTimeLabel.textColor = ColorSet.primaryText.uiColor
        } else {
            toTimeLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
            toTimeLabel.textColor = ColorSet.fgWeak.uiColor
        }
    }

    private func updateConfirmButtonState() {
        guard let fromDate = fromDate, let toDate = toDate else {
            confirmButton.setEnabled(false)
            return
        }
        // End time must be greater than start time
        let isValid = toDate > fromDate
        confirmButton.setEnabled(isValid)
    }

    // MARK: - Public Methods
    func show(from parentViewController: UIViewController? = nil) {
        guard let presentingViewController = parentViewController ?? UIApplication.getTopViewController() else {
            print("[Error] TopViewController is nil")
            return
        }

        presentingViewController.presentVCWithModal(self)
    }

    func setInitialFocus(_ field: EditingField) {
        initialFocusField = field
    }

    // MARK: - Helper Methods
    private func updatePickerForCurrentField() {
        let dateToEdit = currentEditingField == .from ? fromDate : toDate

        if let date = dateToEdit {
            DispatchQueue.main.async { [weak self] in
                self?.timePicker.setDate(date, animated: true)
            }
        }
    }

    // MARK: - Time Conversion Helpers
    private func dateFromTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = formatter.date(from: timeString) {
            return date
        }

        // Fallback: try with leading zero
        formatter.dateFormat = "hh:mm a"
        if let date = formatter.date(from: timeString) {
            return date
        }

        // Fallback: try without space
        formatter.dateFormat = "h:mma"
        return formatter.date(from: timeString.replacingOccurrences(of: " ", with: ""))
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"  // No leading zero for hour
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    func setInitialTimes(from: String, to: String) {
        fromTime = from
        toTime = to

        fromDate = dateFromTimeString(from)
        toDate = dateFromTimeString(to)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateFromDisplay()
            self.updateToDisplay()
            self.updateConfirmButtonState()
        }
    }

    func setInitialTimes(from: Date, to: Date) {
        fromDate = from
        toDate = to
        fromTime = timeStringFromDate(from)
        toTime = timeStringFromDate(to)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateFromDisplay()
            self.updateToDisplay()
            self.updateConfirmButtonState()
        }
    }
}
