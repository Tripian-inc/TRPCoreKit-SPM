//
//  TRPSingleTimePickerViewController.swift
//  TRPCoreKit
//
//  Created on 9.04.2026.
//

import UIKit
import TRPFoundationKit

protocol TRPSingleTimePickerDelegate: AnyObject {
    func singleTimePickerDidSelectTime(_ picker: TRPSingleTimePickerViewController, time: Date)
    func singleTimePickerDidCancel(_ picker: TRPSingleTimePickerViewController)
}

class TRPSingleTimePickerViewController: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    var preferredContentHeight: CGFloat {
        // Header (56) + separator (0.5) + content padding (24) + picker (200) + button padding (16) + button (52) + bottom (16)
        return 56 + 0.5 + 24 + 200 + 16 + 52 + 16  // ~364.5
    }

    // MARK: - Properties
    weak var delegate: TRPSingleTimePickerDelegate?
    private var selectedTime: Date?
    private var selectedDate: Date?      // Day being planned for
    private var minimumTime: Date?       // Min selectable time
    private var maximumTime: Date?       // Max selectable time
    private let pickerTitle: String
    private let showBackButton: Bool     // Show back button instead of close (X)
    /// When `true`, the confirm button stays disabled while the picker is sitting
    /// exactly on `minimumTime` — i.e. the minimum is shown on the wheel but is
    /// not itself a valid selection. Use this for end-time pickers where the
    /// minimum is the *start* time: the user can scroll to it but must move past
    /// it before confirming. Default `false` preserves the original behaviour
    /// (minimum value is selectable like any other).
    private let strictMinimum: Bool

    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratSemiBold.font(18)
        label.textAlignment = .center
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var backButton: UIButton!
    private var closeButton: UIButton!

    private func createBackButton() -> UIButton {
        let button = UIButton(type: .system)
        let image = TRPImageController().getImage(inFramework: "ic_back", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func createCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        let image = TRPImageController().getImage(inFramework: "ic_close", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.neutral200.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        // Force a 12-hour AM/PM wheel regardless of the device's 24h region setting.
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

    // MARK: - Initialization
    init(title: String,
         selectedDate: Date?,
         minimumTime: Date? = nil,
         maximumTime: Date? = nil,
         initialTime: Date? = nil,
         showBackButton: Bool = false,
         strictMinimum: Bool = false) {
        self.pickerTitle = title
        self.selectedDate = selectedDate
        self.minimumTime = minimumTime
        self.maximumTime = maximumTime
        self.selectedTime = initialTime
        self.showBackButton = showBackButton
        self.strictMinimum = strictMinimum
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPickerView()
        applyTimeRestrictions()
        updateConfirmButtonState()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        titleLabel.text = pickerTitle

        // Create buttons
        closeButton = createCloseButton()
        if showBackButton {
            backButton = createBackButton()
        }

        // Add subviews
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        if showBackButton {
            headerView.addSubview(backButton)
        }
        view.addSubview(separatorView)
        view.addSubview(timePicker)
        view.addSubview(confirmButton)

        setupConstraints()
    }

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            // Title (centered in header)
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Close button (always on right side)
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            // Separator
            separatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // Time picker
            timePicker.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 200),

            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ]

        // Add back button constraints if needed
        if showBackButton {
            constraints.append(contentsOf: [
                backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: 24),
                backButton.heightAnchor.constraint(equalToConstant: 24),
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        if showBackButton {
            backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        }
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)
    }

    private func setupPickerView() {
        // If no initial time, set default
        if selectedTime == nil {
            selectedTime = getDefaultTime()
        }

        // Set picker to initial/default time
        if let time = selectedTime {
            timePicker.date = time
        }
    }

    // MARK: - Time Restriction Logic
    private func applyTimeRestrictions() {
        let calendar = Calendar.current
        let referenceDate = calendar.startOfDay(for: Date())

        // Apply minimum time if provided
        if let minTime = minimumTime {
            let minComponents = calendar.dateComponents([.hour, .minute], from: minTime)
            if let minimumDateTime = calendar.date(bySettingHour: minComponents.hour ?? 0,
                                                    minute: minComponents.minute ?? 0,
                                                    second: 0,
                                                    of: referenceDate) {
                timePicker.minimumDate = minimumDateTime
            }
        } else {
            timePicker.minimumDate = nil
        }

        // Apply maximum time if provided
        if let maxTime = maximumTime {
            let maxComponents = calendar.dateComponents([.hour, .minute], from: maxTime)
            if let maximumDateTime = calendar.date(bySettingHour: maxComponents.hour ?? 0,
                                                    minute: maxComponents.minute ?? 0,
                                                    second: 0,
                                                    of: referenceDate) {
                timePicker.maximumDate = maximumDateTime
            }
        } else {
            timePicker.maximumDate = nil
        }

        // If current selectedTime is outside bounds, adjust it
        if let time = selectedTime {
            if let minDate = timePicker.minimumDate, time < minDate {
                selectedTime = minDate
                timePicker.date = minDate
            } else if let maxDate = timePicker.maximumDate, time > maxDate {
                selectedTime = maxDate
                timePicker.date = maxDate
            }
        }
    }

    private func getDefaultTime() -> Date {
        let calendar = Calendar.current

        // Today: current time + 30 minutes
        if let selectedDate = selectedDate, calendar.isDateInToday(selectedDate) {
            let defaultTime = Date().addingTimeInterval(30 * 60)

            // Respect min/max bounds
            if let minTime = minimumTime, defaultTime < minTime {
                return minTime
            }
            if let maxTime = maximumTime, defaultTime > maxTime {
                return maxTime
            }
            return defaultTime
        }

        // Future dates: 09:00 AM (or minimum time if later)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        components.second = 0

        let defaultTime = calendar.date(from: components) ?? Date()

        if let minTime = minimumTime, defaultTime < minTime {
            return minTime
        }

        return defaultTime
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.singleTimePickerDidCancel(self)
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.singleTimePickerDidCancel(self)
        }
    }

    @objc private func confirmButtonTapped() {
        guard let time = selectedTime else { return }

        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.singleTimePickerDidSelectTime(self, time: time)
        }
    }

    @objc private func timePickerValueChanged() {
        selectedTime = timePicker.date
        updateConfirmButtonState()
    }

    // MARK: - UI Updates
    private func updateConfirmButtonState() {
        guard let selectedTime = selectedTime else {
            confirmButton.setEnabled(false)
            return
        }

        // Strict-minimum mode: confirm stays disabled while the user is sitting
        // on the minimum value. We compare HH:mm only — `selectedTime` and
        // `minimumTime` can carry different date components (initialTime is on
        // the planned day, `applyTimeRestrictions` builds `minimumDate` on
        // today), so a full Date comparison would behave inconsistently for
        // future-day pickers. HH:mm is the only meaningful axis for `.time` mode.
        if strictMinimum, let minTime = minimumTime {
            let calendar = Calendar.current
            let selectedComps = calendar.dateComponents([.hour, .minute], from: selectedTime)
            let minComps = calendar.dateComponents([.hour, .minute], from: minTime)
            let selectedMinutes = (selectedComps.hour ?? 0) * 60 + (selectedComps.minute ?? 0)
            let minMinutes = (minComps.hour ?? 0) * 60 + (minComps.minute ?? 0)
            confirmButton.setEnabled(selectedMinutes > minMinutes)
            return
        }

        confirmButton.setEnabled(true)
    }

    // MARK: - Public Methods
    func show(from parentViewController: UIViewController? = nil) {
        guard let presentingViewController = parentViewController ?? UIApplication.getTopViewController() else {
            print("[Error] TopViewController is nil")
            return
        }

        presentingViewController.presentVCWithDynamicHeight(self)
    }
}
