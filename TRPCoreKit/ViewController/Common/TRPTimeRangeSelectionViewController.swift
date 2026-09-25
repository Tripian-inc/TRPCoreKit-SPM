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
        let base: CGFloat = 56 + 0.5 + 24 + 64 + 16 + 64 + 16 + 52 + 16  // ~308.5
        let timeWarnings = [startTimeWarningRow, endTimeWarningRow]
            .filter { !$0.isHidden }
            .reduce(CGFloat(0)) { $0 + timeWarningHeight($1) }
        return base + timeWarnings + (closedWarningView.isHidden ? 0 : closedWarningHeight)
    }

    /// Extra height a visible time warning row adds: the row itself plus the 8/12 spacing it introduces
    /// around the field, minus the 16 the field already had.
    private func timeWarningHeight(_ row: UIStackView) -> CGFloat {
        let available = max(view.bounds.width, UIScreen.main.bounds.width) - 32 - 16 - 6
        let textHeight = (row.arrangedSubviews.last as? UILabel)?.sizeThatFits(
            CGSize(width: available, height: .greatestFiniteMagnitude)
        ).height ?? 16
        return max(16, textHeight) + 4
    }

    /// Spacing (16) + the warning card's own height, added while it is visible.
    private var closedWarningHeight: CGFloat {
        let available = max(view.bounds.width, UIScreen.main.bounds.width) - 32 - 24 - 20 - 8
        let textHeight = closedWarningLabel.sizeThatFits(
            CGSize(width: available, height: .greatestFiniteMagnitude)
        ).height
        return 16 + max(44, textHeight + 24)
    }

    // MARK: - Properties
    weak var delegate: TRPTimeRangeSelectionDelegate?
    private var fromDate: Date?
    private var toDate: Date?
    private var selectedDate: Date?  // The date being planned for (used for minimum time validation)
    /// Optional. When set, "today" detection and the minimum-time computation
    /// use this city's IANA timezone instead of the device timezone. Mirrors
    /// `selectedDate` — both are call-site optional; without them we silently
    /// fall back to `Calendar.current`.
    private var selectedCity: TRPCity?
    private var editingStartTime = false  // Track which time is being edited
    /// Raw POI `hours` string. With `openingHoursDay` it drives the outside-opening-hours
    /// warning; nil means no warning is ever shown.
    private var openingHours: String?
    /// Day the opening-hours check runs against. Kept separate from `selectedDate`
    /// so callers can warn without also opting into the minimum-time gate.
    private var openingHoursDay: Date?

    private var endTimeFieldTopBelowWarning: NSLayoutConstraint!
    private var closedWarningTopBelowWarning: NSLayoutConstraint!

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

    private lazy var startTimeWarningRow = makeTimeWarningRow(
        text: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTimePassedWarning)
    )

    private lazy var endTimeWarningRow = makeTimeWarningRow(
        text: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTimeBeforeStartWarning)
    )

    private func makeTimeWarningRow(text: String) -> UIStackView {
        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = ColorSet.errorFg.uiColor
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.errorFg.uiColor
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = text

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 6
        row.isHidden = true
        return row
    }

    private let closedWarningView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.warningBg.uiColor
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let closedWarningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let closedWarningLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        updateTimeValidationUI()
        updateClosedWarning()
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
        view.addSubview(startTimeWarningRow)
        view.addSubview(endTimeField)
        view.addSubview(endTimeWarningRow)
        view.addSubview(closedWarningView)
        closedWarningView.addSubview(closedWarningIcon)
        closedWarningView.addSubview(closedWarningLabel)
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

            startTimeWarningRow.topAnchor.constraint(equalTo: startTimeField.bottomAnchor, constant: 8),
            startTimeWarningRow.leadingAnchor.constraint(equalTo: startTimeField.leadingAnchor),
            startTimeWarningRow.trailingAnchor.constraint(equalTo: startTimeField.trailingAnchor),

            // End time field
            endTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            endTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            endTimeWarningRow.topAnchor.constraint(equalTo: endTimeField.bottomAnchor, constant: 8),
            endTimeWarningRow.leadingAnchor.constraint(equalTo: endTimeField.leadingAnchor),
            endTimeWarningRow.trailingAnchor.constraint(equalTo: endTimeField.trailingAnchor),

            // Outside-opening-hours warning
            closedWarningView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closedWarningView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            closedWarningIcon.leadingAnchor.constraint(equalTo: closedWarningView.leadingAnchor, constant: 12),
            closedWarningIcon.topAnchor.constraint(equalTo: closedWarningView.topAnchor, constant: 12),
            closedWarningIcon.widthAnchor.constraint(equalToConstant: 20),
            closedWarningIcon.heightAnchor.constraint(equalToConstant: 20),

            closedWarningLabel.leadingAnchor.constraint(equalTo: closedWarningIcon.trailingAnchor, constant: 8),
            closedWarningLabel.trailingAnchor.constraint(equalTo: closedWarningView.trailingAnchor, constant: -12),
            closedWarningLabel.topAnchor.constraint(equalTo: closedWarningView.topAnchor, constant: 12),
            closedWarningLabel.bottomAnchor.constraint(equalTo: closedWarningView.bottomAnchor, constant: -12),

            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        // A visible warning row pushes the view below it down (`updateTimeValidationUI` toggles the floor constraints).
        let endTimeFieldTopDefault = endTimeField.topAnchor.constraint(equalTo: startTimeField.bottomAnchor, constant: 16)
        endTimeFieldTopDefault.priority = .defaultLow
        endTimeFieldTopDefault.isActive = true
        endTimeFieldTopBelowWarning = endTimeField.topAnchor.constraint(
            greaterThanOrEqualTo: startTimeWarningRow.bottomAnchor, constant: 12
        )

        let closedWarningTopDefault = closedWarningView.topAnchor.constraint(equalTo: endTimeField.bottomAnchor, constant: 16)
        closedWarningTopDefault.priority = .defaultLow
        closedWarningTopDefault.isActive = true
        closedWarningTopBelowWarning = closedWarningView.topAnchor.constraint(
            greaterThanOrEqualTo: endTimeWarningRow.bottomAnchor, constant: 12
        )
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
        // Bounds (minimum + default initial) come from the shared `TimePickerBounds`
        // helper — keeps the city-tz / next-top-of-hour rules out of the VC.
        let initialTime = fromDate ?? TimePickerBounds.defaultInitialTime(
            selectedDay: selectedDate,
            city: selectedCity
        )
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.startTime),
            selectedDate: selectedDate,
            minimumTime: nil,
            maximumTime: nil,
            initialTime: initialTime,
            showBackButton: true
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    private func endTimeFieldTapped() {
        editingStartTime = false
        let initialTime = toDate ?? TimePickerBounds.defaultInitialEndTime(
            selectedDay: selectedDate,
            city: selectedCity,
            currentStartTime: fromDate
        )
        let picker = TRPSingleTimePickerViewController(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.endTime),
            selectedDate: selectedDate,
            minimumTime: nil,
            maximumTime: nil,
            initialTime: initialTime,
            showBackButton: true
        )
        picker.delegate = self
        presentVCWithDynamicHeight(picker)
    }

    // Time-picker bounds (minimum + default initial time) live in
    // `TimePickerBounds` so this VC stays focused on view wiring.

    // MARK: - UI Updates
    private func updateStartTimeDisplay() {
        startTimeField.setValue(fromDate)
    }

    private func updateEndTimeDisplay() {
        endTimeField.setValue(toDate)
    }

    /// Compares HH:mm only: the picker hands back Dates with inconsistent day components.
    private func updateConfirmButtonState() {
        guard let fromDate = fromDate, let toDate = toDate else {
            confirmButton.setEnabled(false)
            return
        }
        let isValid = !startTimeHasPassed() && minutesOfDay(toDate) > minutesOfDay(fromDate)
        confirmButton.setEnabled(isValid)
    }

    private func startTimeHasPassed() -> Bool {
        guard let fromDate = fromDate else { return false }
        return TimePickerBounds.hasPassed(selectedDay: openingHoursDay ?? selectedDate, city: selectedCity, time: fromDate)
    }

    /// Shows the inline warning rows + error styling: start already passed at the destination, or end not after start.
    private func updateTimeValidationUI() {
        let startHasError = startTimeHasPassed()
        let endHasError: Bool
        if let fromDate = fromDate, let toDate = toDate {
            endHasError = minutesOfDay(toDate) <= minutesOfDay(fromDate)
        } else {
            endHasError = false
        }

        let wasShown = (!startTimeWarningRow.isHidden, !endTimeWarningRow.isHidden)
        startTimeField.setErrorState(startHasError)
        endTimeField.setErrorState(endHasError)
        startTimeWarningRow.isHidden = !startHasError
        endTimeWarningRow.isHidden = !endHasError
        endTimeFieldTopBelowWarning.isActive = startHasError
        closedWarningTopBelowWarning.isActive = endHasError

        if wasShown != (startHasError, endHasError) {
            updateSheetHeight()
        }
    }

    /// Shows a non-blocking notice when the picked span falls outside the POI's
    /// opening hours for `selectedDate`. Stays hidden when the hours are unknown or
    /// unparsable, so a missing `hours` string never blocks or nags the user.
    private func updateClosedWarning() {
        let isOpen = TRPOpeningHours.coversSelection(
            openingHours,
            date: openingHoursDay ?? selectedDate,
            startTime: fromDate.map(convertTo24HourFormat),
            endTime: toDate.map(convertTo24HourFormat)
        )

        let shouldShow = isOpen == false
        if shouldShow {
            let closedLabel = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.closedAtSelectedTime)
            if let dayText = TRPOpeningHours.dayText(openingHours, date: openingHoursDay ?? selectedDate) {
                let openLabel = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.openHours)
                closedWarningLabel.text = "\(closedLabel)\n\(openLabel): \(dayText)"
            } else {
                closedWarningLabel.text = closedLabel
            }
        }

        guard closedWarningView.isHidden == shouldShow else { return }
        closedWarningView.isHidden = !shouldShow
        updateSheetHeight()
    }

    /// Minutes since midnight — the only meaningful axis for these time-of-day proxies.
    private func minutesOfDay(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
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

    /// Optional. When set, the minimum-time gate and the default initial time
    /// are computed in this city's IANA timezone instead of the device
    /// timezone. Pass the segment / planData city at the call site.
    func setSelectedCity(_ city: TRPCity?) {
        self.selectedCity = city
    }

    /// Optional POI `hours` string; a selection outside that day's opening hours
    /// raises an inline warning. Pass `day` when the screen has no `selectedDate`
    /// (setting one would also enable the minimum-time gate).
    func setOpeningHours(_ hours: String?, on day: Date? = nil) {
        self.openingHours = hours
        self.openingHoursDay = day
    }

    func setInitialTimes(from: String, to: String) {
        fromDate = dateFromTimeString(from)
        toDate = dateFromTimeString(to)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateStartTimeDisplay()
            self.updateEndTimeDisplay()
            self.updateConfirmButtonState()
            self.updateTimeValidationUI()
            self.updateClosedWarning()
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
            self.updateTimeValidationUI()
            self.updateClosedWarning()
        }
    }
}

// MARK: - TRPSingleTimePickerDelegate
extension TRPTimeRangeSelectionViewController: TRPSingleTimePickerDelegate {

    func singleTimePickerDidSelectTime(_ picker: TRPSingleTimePickerViewController, time: Date) {
        if editingStartTime {
            fromDate = time
            updateStartTimeDisplay()
        } else {
            toDate = time
            updateEndTimeDisplay()
        }

        updateConfirmButtonState()
        updateTimeValidationUI()
        updateClosedWarning()
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
    func setErrorState(_ hasError: Bool) {
        titleLabel.textColor = hasError ? ColorSet.errorFg.uiColor : ColorSet.primaryText.uiColor
        container.layer.borderColor = (hasError ? ColorSet.errorFg.uiColor : ColorSet.lineWeak.uiColor).cgColor
    }

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
