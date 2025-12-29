//
//  TRPTimeRangeSelectionViewController.swift
//  TRPCoreKit
//
//  Created on 2.12.2025.
//
//  USAGE EXAMPLE:
//
//  class YourViewController: UIViewController, TRPTimeRangeSelectionDelegate {
//
//      func showTimeRangeSelection() {
//          let timeRangeVC = TRPTimeRangeSelectionViewController()
//          timeRangeVC.delegate = self
//
//          // Option 1: Set with String format
//          timeRangeVC.setInitialTimes(from: "11:00 AM", to: "12:00 PM")
//
//          // Option 2: Set with Date objects
//          // let fromDate = Date()
//          // let toDate = Date().addingTimeInterval(3600)
//          // timeRangeVC.setInitialTimes(from: fromDate, to: toDate)
//
//          timeRangeVC.show(from: self) // Presents as pageSheet modal
//      }
//
//      // MARK: - TRPTimeRangeSelectionDelegate
//      func timeRangeSelected(fromTime: String, toTime: String) {
//          print("Selected time range (String): \(fromTime) - \(toTime)")
//      }
//
//      func timeRangeSelected(fromDate: Date, toDate: Date) {
//          print("Selected time range (Date): \(fromDate) - \(toDate)")
//          // Use Date objects for API calls or date calculations
//      }
//  }
//

import UIKit

protocol TRPTimeRangeSelectionDelegate: AnyObject {
    func timeRangeSelected(fromTime: String, toTime: String)
    func timeRangeSelected(fromDate: Date, toDate: Date)
}

class TRPTimeRangeSelectionViewController: UIViewController {

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
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.textColor = TRPColor.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = TRPColor.darkGrey
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // From Section
    private let fromLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = TRPColor.darkGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fromContainer: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.neutral100.uiColor
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let fromTimeLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select)
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fromClearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .light)
        button.setTitleColor(ColorSet.fgWeak.uiColor, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    // To Section
    private let toLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = TRPColor.darkGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let toContainer: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.neutral100.uiColor
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let toTimeLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select)
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let toClearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .light)
        button.setTitleColor(ColorSet.fgWeak.uiColor, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
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
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.confirm),
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

        fromContainer.addSubview(fromTimeLabel)
        fromContainer.addSubview(fromClearButton)
        toContainer.addSubview(toTimeLabel)
        toContainer.addSubview(toClearButton)

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
            fromContainer.heightAnchor.constraint(equalToConstant: 48),

            // From time label
            fromTimeLabel.leadingAnchor.constraint(equalTo: fromContainer.leadingAnchor, constant: 16),
            fromTimeLabel.centerYAnchor.constraint(equalTo: fromContainer.centerYAnchor),

            // From clear button
            fromClearButton.trailingAnchor.constraint(equalTo: fromContainer.trailingAnchor, constant: -12),
            fromClearButton.centerYAnchor.constraint(equalTo: fromContainer.centerYAnchor),
            fromClearButton.widthAnchor.constraint(equalToConstant: 24),
            fromClearButton.heightAnchor.constraint(equalToConstant: 24),

            // To label
            toLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            toLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),

            // To container
            toContainer.topAnchor.constraint(equalTo: toLabel.bottomAnchor, constant: 8),
            toContainer.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),
            toContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toContainer.heightAnchor.constraint(equalToConstant: 48),

            // To time label
            toTimeLabel.leadingAnchor.constraint(equalTo: toContainer.leadingAnchor, constant: 16),
            toTimeLabel.centerYAnchor.constraint(equalTo: toContainer.centerYAnchor),

            // To clear button
            toClearButton.trailingAnchor.constraint(equalTo: toContainer.trailingAnchor, constant: -12),
            toClearButton.centerYAnchor.constraint(equalTo: toContainer.centerYAnchor),
            toClearButton.widthAnchor.constraint(equalToConstant: 24),
            toClearButton.heightAnchor.constraint(equalToConstant: 24),

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
        fromClearButton.addTarget(self, action: #selector(fromClearTapped), for: .touchUpInside)
        toClearButton.addTarget(self, action: #selector(toClearTapped), for: .touchUpInside)

        let fromTapGesture = UITapGestureRecognizer(target: self, action: #selector(fromFieldTapped))
        fromContainer.addGestureRecognizer(fromTapGesture)

        let toTapGesture = UITapGestureRecognizer(target: self, action: #selector(toFieldTapped))
        toContainer.addGestureRecognizer(toTapGesture)
    }

    private func setupPickerView() {
        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)

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
        guard let fromTime = fromTime, let toTime = toTime,
              let fromDate = fromDate, let toDate = toDate else {
            return
        }

        delegate?.timeRangeSelected(fromTime: fromTime, toTime: toTime)
        delegate?.timeRangeSelected(fromDate: fromDate, toDate: toDate)

        dismiss(animated: true, completion: nil)
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

    @objc private func fromClearTapped() {
        fromTime = nil
        fromDate = nil
        updateFromDisplay()
        updateConfirmButtonState()
    }

    @objc private func toClearTapped() {
        toTime = nil
        toDate = nil
        updateToDisplay()
        updateConfirmButtonState()
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
            container.layer.borderWidth = highlight ? 1.5 : 0
            container.layer.borderColor = highlight ? ColorSet.borderActive.uiColor.cgColor : UIColor.clear.cgColor
        }
    }

    private func updateFromDisplay() {
        if let time = fromTime {
            fromTimeLabel.text = time
            fromTimeLabel.textColor = TRPColor.textColor
            fromClearButton.isHidden = false
        } else {
            fromTimeLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select)
            fromTimeLabel.textColor = ColorSet.fgWeak.uiColor
            fromClearButton.isHidden = true
        }
    }

    private func updateToDisplay() {
        if let time = toTime {
            toTimeLabel.text = time
            toTimeLabel.textColor = TRPColor.textColor
            toClearButton.isHidden = false
        } else {
            toTimeLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.select)
            toTimeLabel.textColor = ColorSet.fgWeak.uiColor
            toClearButton.isHidden = true
        }
    }

    private func updateConfirmButtonState() {
        let isValid = fromDate != nil && toDate != nil
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
