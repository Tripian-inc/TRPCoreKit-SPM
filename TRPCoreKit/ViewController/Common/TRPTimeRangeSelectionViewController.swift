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

class TRPTimeRangeSelectionViewController: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    var preferredContentHeight: CGFloat {
        // Header (56) + separator (0.5) + content padding (24) + labels+fields (16+8+40) + picker (200) + button padding (16) + button (52) + bottom (16)
        return 56 + 0.5 + 24 + 64 + 200 + 16 + 52 + 16  // ~428.5
    }

    // MARK: - Properties
    weak var delegate: TRPTimeRangeSelectionDelegate?
    private var fromTime: String?
    private var toTime: String?
    private var fromDate: Date?
    private var toDate: Date?

    // Track which field is being edited
    enum EditingField {
        case from
        case until
    }
    private var currentEditingField: EditingField = .from
    private var initialFocusField: EditingField = .from

    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.neutral200.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Time Fields
    private lazy var fromTimeField: TRPTimeFieldView = {
        let field = TRPTimeFieldView(title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime))
        field.onTap = { [weak self] in self?.fromFieldTapped() }
        return field
    }()

    private lazy var toTimeField: TRPTimeFieldView = {
        let field = TRPTimeFieldView(title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime))
        field.onTap = { [weak self] in self?.toFieldTapped() }
        return field
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

        // Header
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        // Separator
        view.addSubview(separatorView)

        // Content
        view.addSubview(fromTimeField)
        view.addSubview(toTimeField)
        view.addSubview(timePicker)
        view.addSubview(confirmButton)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            // Title (centered in header)
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Close button (right side of header)
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            // Separator
            separatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // From time field
            fromTimeField.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            fromTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fromTimeField.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),

            // To time field
            toTimeField.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            toTimeField.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            toTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Time picker
            timePicker.topAnchor.constraint(equalTo: fromTimeField.bottomAnchor, constant: 24),
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 200),

            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        // Tap gestures are handled inside TRPTimeFieldView
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
        fromTimeField.setHighlighted(initialFocusField == .from)
        toTimeField.setHighlighted(initialFocusField == .until)
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

    private func fromFieldTapped() {
        currentEditingField = .from
        fromTimeField.setHighlighted(true)
        toTimeField.setHighlighted(false)
        updatePickerForCurrentField()
    }

    private func toFieldTapped() {
        currentEditingField = .until
        fromTimeField.setHighlighted(false)
        toTimeField.setHighlighted(true)
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
    private func updateFromDisplay() {
        fromTimeField.setValue(fromTime)
    }

    private func updateToDisplay() {
        toTimeField.setValue(toTime)
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

// MARK: - TRPTimeFieldView
private class TRPTimeFieldView: UIView {

    // MARK: - Properties
    var onTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let clockIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
        label.font = FontSet.montserratLight.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(container)
        container.addSubview(clockIcon)
        container.addSubview(valueLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        container.addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            container.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 40),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            clockIcon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            clockIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            clockIcon.widthAnchor.constraint(equalToConstant: 16),
            clockIcon.heightAnchor.constraint(equalToConstant: 16),

            valueLabel.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 4),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Public Methods
    func setValue(_ value: String?) {
        if let value = value {
            valueLabel.text = value
            valueLabel.textColor = ColorSet.primaryText.uiColor
        } else {
            valueLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
            valueLabel.textColor = ColorSet.fgWeak.uiColor
        }
    }

    func setHighlighted(_ highlighted: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.container.layer.borderColor = highlighted
                ? ColorSet.borderActive.uiColor.cgColor
                : ColorSet.lineWeak.uiColor.cgColor
        }
    }
}
