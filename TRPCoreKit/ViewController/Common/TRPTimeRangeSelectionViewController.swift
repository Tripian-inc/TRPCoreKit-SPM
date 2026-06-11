//
//  TRPTimeRangeSelectionViewController.swift
//  TRPCoreKit
//
//  Created on 2.12.2025.
//

import UIKit
import TRPFoundationKit

protocol TRPTimeRangeSelectionDelegate: AnyObject {
    func timeRangeSelected(fromTime: String, toTime: String)
    func timeRangeSelected(fromDate: Date, toDate: Date)
}

class TRPTimeRangeSelectionViewController: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    var preferredContentHeight: CGFloat {
        // Header (56) + separator (0.5) + padding (24) + start field (64) + spacing (16) + end field (64) + button padding (16) + button (52) + bottom (16)
        return 56 + 0.5 + 24 + 64 + 16 + 64 + 16 + 52 + 16  // ~308.5
    }

    // MARK: - Properties
    weak var delegate: TRPTimeRangeSelectionDelegate?
    private var fromDate: Date?
    private var toDate: Date?
    private var selectedDate: Date?  // The date being planned for (used for minimum time validation)
    private var editingStartTime = false  // Track which time is being edited

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

    // Time Selection Fields
    private lazy var startTimeField: TRPTimeSelectionField = {
        let field = TRPTimeSelectionField(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime)
        )
        field.onTap = { [weak self] in self?.startTimeFieldTapped() }
        return field
    }()

    private lazy var endTimeField: TRPTimeSelectionField = {
        let field = TRPTimeSelectionField(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime)
        )
        field.onTap = { [weak self] in self?.endTimeFieldTapped() }
        return field
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
        updateStartTimeDisplay()
        updateEndTimeDisplay()
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
        view.addSubview(startTimeField)
        view.addSubview(endTimeField)
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

            // Start time field
            startTimeField.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            startTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // End time field
            endTimeField.topAnchor.constraint(equalTo: startTimeField.bottomAnchor, constant: 16),
            endTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            endTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
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

    private func startTimeFieldTapped() {
        editingStartTime = true
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime),
            selectedDate: selectedDate,
            minimumTime: getMinimumStartTime(),
            maximumTime: nil,
            initialTime: fromDate,
            showBackButton: true
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    private func endTimeFieldTapped() {
        editingStartTime = false
        // Strict-minimum only when an actual start time exists. In that case the
        // picker minimum IS the start time and must NOT itself be confirmable
        // (end > start). Without a start time, the minimum is the earliest
        // sensible moment (today+30m, or unrestricted on future days) and is a
        // valid pick on its own. Mirrors the smart-recommendation screen
        // (`AddPlanTimeAndTravelersVC.endTimeButtonTapped`).
        let hasStartTime = fromDate != nil
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime),
            selectedDate: selectedDate,
            minimumTime: getMinimumEndTime(),
            maximumTime: nil,
            initialTime: toDate,
            showBackButton: true,
            strictMinimum: hasStartTime
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    // MARK: - Time Restriction Logic
    private func getMinimumStartTime() -> Date? {
        guard let selectedDate = selectedDate else { return nil }

        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            // Today: minimum is current time + 30 minutes
            return Date().addingTimeInterval(30 * 60)
        }

        // Future dates: no minimum restriction
        return nil
    }

    private func getMinimumEndTime() -> Date? {
        // End time must be at least start time
        if let fromDate = fromDate {
            return fromDate
        }

        // If no start time yet, use same logic as start time
        return getMinimumStartTime()
    }

    // MARK: - UI Updates
    private func updateStartTimeDisplay() {
        startTimeField.setValue(fromDate)
    }

    private func updateEndTimeDisplay() {
        endTimeField.setValue(toDate)
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

    // MARK: - Helper Methods
    /// Converts Date to "HH:mm" format string
    private func convertTo24HourFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"  // 12-hour format: "9:30 AM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

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

    // MARK: - Public Methods
    func show(from parentViewController: UIViewController? = nil) {
        guard let presentingViewController = parentViewController ?? UIApplication.getTopViewController() else {
            print("[Error] TopViewController is nil")
            return
        }

        presentingViewController.presentVCWithDynamicHeight(self)
    }

    /// Sets the date being planned for (used for minimum time validation)
    func setSelectedDate(_ date: Date) {
        self.selectedDate = date
    }

    func setInitialTimes(from: String, to: String) {
        fromDate = dateFromTimeString(from)
        toDate = dateFromTimeString(to)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateStartTimeDisplay()
            self.updateEndTimeDisplay()
            self.updateConfirmButtonState()
        }
    }

    func setInitialTimes(from: Date, to: Date) {
        fromDate = from
        toDate = to

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateStartTimeDisplay()
            self.updateEndTimeDisplay()
            self.updateConfirmButtonState()
        }
    }
}

// MARK: - TRPSingleTimePickerDelegate
extension TRPTimeRangeSelectionViewController: TRPSingleTimePickerDelegate {

    func singleTimePickerDidSelectTime(_ picker: TRPSingleTimePickerViewController, time: Date) {
        if editingStartTime {  // Start time
            fromDate = time
            updateStartTimeDisplay()

            // Clear end time if it's now invalid (before new start time)
            if let toDate = toDate, toDate <= time {
                self.toDate = nil
                updateEndTimeDisplay()
            }
        } else {  // End time
            toDate = time
            updateEndTimeDisplay()
        }

        updateConfirmButtonState()
    }

    func singleTimePickerDidCancel(_ picker: TRPSingleTimePickerViewController) {
        // No action needed
    }
}

// MARK: - TRPTimeSelectionField
private class TRPTimeSelectionField: UIView {

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
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let arrowIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_next", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        container.addSubview(valueLabel)
        container.addSubview(arrowIcon)

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

            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            arrowIcon.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            arrowIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Public Methods
    func setValue(_ time: Date?) {
        if let time = time {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"  // 12-hour format: "9:30 AM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            valueLabel.text = formatter.string(from: time)
            valueLabel.textColor = ColorSet.primaryText.uiColor
        } else {
            valueLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.select)
            valueLabel.textColor = ColorSet.fgWeak.uiColor
        }
    }
}
