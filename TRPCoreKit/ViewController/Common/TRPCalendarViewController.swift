//
//  TRPCalendarViewController.swift
//  TRPCoreKit
//
//  Created on 2025.
//

import UIKit
import FSCalendar
import TRPRestKit

/// Selection mode for the calendar
public enum TRPCalendarSelectionMode {
    case single      // User can select only one date
    case range       // User can select a date range (start and end)
}

protocol TRPCalendarViewControllerDelegate: AnyObject {
    func calendarViewControllerDidSelectDate(_ date: Date)
    func calendarViewControllerDidSelectDateRange(_ startDate: Date, _ endDate: Date)
    func calendarViewControllerDidCancel()
}

@objc(SPMTRPCalendarViewController)
class TRPCalendarViewController: TRPBaseUIViewController {
    
    // MARK: - Properties
    weak var delegate: TRPCalendarViewControllerDelegate?
    
    /// Selection mode: single date or date range
    public var selectionMode: TRPCalendarSelectionMode = .single {
        didSet {
            updateSelectionMode()
        }
    }
    
    private var minimumDate: Date?
    private var maximumDate: Date?
    private var preselectedDate: Date?
    private var preselectedDateRange: (Date, Date)?
    
    // Selectable date range - dates within this range will be selectable and shown with alpha background
    private var selectableStartDate: Date?
    private var selectableEndDate: Date?
    
    private var firstSelectedDate: Date?
    private var lastSelectedDate: Date?
    private var selectedDatesRange: [Date] = []
    
    // Month/Year Picker
    private var isPickerVisible = false
    private let pickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
    private lazy var monthYearPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let months: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TRPClient.getLanguage())
        return formatter.monthSymbols
    }()
    
    private var years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 10)...(currentYear + 10))
    }()
    
    // MARK: - UI Components
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let monthYearButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = trpTheme.font.header2
        button.setTitleColor(trpTheme.color.tripianBlack, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false // Disable interaction
        // Don't add dropdown arrow since it's not clickable
        return button
    }()
    
    private let previousMonthButton: UIButton = {
        let button = UIButton(type: .system)
        let image = TRPImageController().getImage(inFramework: "ic_previous", inApp: nil) ?? UIImage()
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private let nextMonthButton: UIButton = {
        let button = UIButton(type: .system)
        let image = TRPImageController().getImage(inFramework: "ic_next", inApp: nil) ?? UIImage()
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private lazy var calendarView: FSCalendar = {
        let calendar = FSCalendar()
        calendar.dataSource = self
        calendar.delegate = self
        calendar.allowsMultipleSelection = (selectionMode == .range)
        calendar.locale = Locale(identifier: TRPClient.getLanguage())
        calendar.placeholderType = .none
        calendar.scrollEnabled = true
        calendar.pagingEnabled = true
        calendar.translatesAutoresizingMaskIntoConstraints = false
        setupCalendarAppearance(calendar)
        return calendar
    }()
    
    private func updateSelectionMode() {
        calendarView.allowsMultipleSelection = (selectionMode == .range)
        // Clear current selection when mode changes
        if selectionMode == .single {
            // Clear range selection if switching to single mode
            if let first = firstSelectedDate, let last = lastSelectedDate, first != last {
                calendarView.deselect(first)
                calendarView.deselect(last)
                for date in selectedDatesRange {
                    calendarView.deselect(date)
                }
                firstSelectedDate = nil
                lastSelectedDate = nil
                selectedDatesRange = []
            }
        }
    }
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.alignment = .trailing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel".toLocalized(), for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(16)
        button.setTitleColor(ColorSet.primary.uiColor, for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select".toLocalized(), for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ColorSet.primary.uiColor
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    /// Initialize the calendar view controller
    /// - Parameters:
    ///   - selectionMode: Selection mode - `.single` for one date, `.range` for date range
    ///   - minimumDate: Minimum selectable date (optional)
    ///   - maximumDate: Maximum selectable date (optional)
    ///   - preselectedDate: Pre-selected single date (optional)
    ///   - preselectedDateRange: Pre-selected date range (optional)
    ///   - selectableStartDate: Start of selectable date range (optional)
    ///   - selectableEndDate: End of selectable date range (optional)
    init(selectionMode: TRPCalendarSelectionMode = .single,
         minimumDate: Date? = nil,
         maximumDate: Date? = nil,
         preselectedDate: Date? = nil,
         preselectedDateRange: (Date, Date)? = nil,
         selectableStartDate: Date? = nil,
         selectableEndDate: Date? = nil) {
        self.selectionMode = selectionMode
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.preselectedDate = preselectedDate
        self.preselectedDateRange = preselectedDateRange
        self.selectableStartDate = selectableStartDate
        self.selectableEndDate = selectableEndDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    /// Convenience initializer for backward compatibility
    @available(*, deprecated, message: "Use init(selectionMode:) instead")
    convenience init(allowsMultipleSelection: Bool = false,
                     minimumDate: Date? = nil,
                     maximumDate: Date? = nil,
                     preselectedDate: Date? = nil,
                     preselectedDateRange: (Date, Date)? = nil,
                     selectableStartDate: Date? = nil,
                     selectableEndDate: Date? = nil) {
        self.init(
            selectionMode: allowsMultipleSelection ? .range : .single,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            preselectedDate: preselectedDate,
            preselectedDateRange: preselectedDateRange,
            selectableStartDate: selectableStartDate,
            selectableEndDate: selectableEndDate
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateMonthYearLabel()
        
        if let preselectedDate = preselectedDate {
            calendarView.select(preselectedDate)
            firstSelectedDate = preselectedDate
        } else if let range = preselectedDateRange {
            firstSelectedDate = range.0
            lastSelectedDate = range.1
            let dates = generateDateRange(from: range.0, to: range.1)
            selectedDatesRange = dates
            for date in dates {
                calendarView.select(date)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Save selected dates before reload
        let selectedDates = calendarView.selectedDates
        
        // Force reload calendar to apply appearance changes
        calendarView.reloadData()
        
        // Restore selection after reload
        for date in selectedDates {
            calendarView.select(date, scrollToDate: false)
        }
        
        // Force refresh all visible cells to apply custom appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Save selected dates again before second reload
            let selectedDates = self.calendarView.selectedDates
            
            self.calendarView.reloadData()
            
            // Restore selection after second reload
            for date in selectedDates {
                self.calendarView.select(date, scrollToDate: false)
            }
            
            self.configureVisibleCells()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundView)
        view.addSubview(containerView)
        
        containerView.addSubview(headerView)
        containerView.addSubview(calendarView)
        containerView.addSubview(buttonStackView)
        
        headerView.addSubview(monthYearButton)
        headerView.addSubview(previousMonthButton)
        headerView.addSubview(nextMonthButton)
        
        containerView.addSubview(pickerContainerView)
        pickerContainerView.addSubview(monthYearPicker)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(selectButton)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 500),
            
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            monthYearButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            monthYearButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            previousMonthButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            previousMonthButton.trailingAnchor.constraint(equalTo: nextMonthButton.leadingAnchor, constant: -16),
            previousMonthButton.widthAnchor.constraint(equalToConstant: 44),
            previousMonthButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextMonthButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nextMonthButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 44),
            nextMonthButton.heightAnchor.constraint(equalToConstant: 44),
            
            calendarView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            calendarView.heightAnchor.constraint(equalToConstant: 300),
            
            buttonStackView.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            selectButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            pickerContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            pickerContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            pickerContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            pickerContainerView.heightAnchor.constraint(equalToConstant: 200),
            
            monthYearPicker.topAnchor.constraint(equalTo: pickerContainerView.topAnchor, constant: 8),
            monthYearPicker.leadingAnchor.constraint(equalTo: pickerContainerView.leadingAnchor, constant: 8),
            monthYearPicker.trailingAnchor.constraint(equalTo: pickerContainerView.trailingAnchor, constant: -8),
            monthYearPicker.bottomAnchor.constraint(equalTo: pickerContainerView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupCalendarAppearance(_ calendar: FSCalendar) {
        let appearance = calendar.appearance
        
        // Header appearance
        appearance.headerTitleFont = FontSet.montserratMedium.font(14)
        appearance.headerTitleColor = ColorSet.primaryText.uiColor
        appearance.headerDateFormat = "MMMM yyyy"
        appearance.headerMinimumDissolvedAlpha = 0.0
        appearance.headerTitleOffset = CGPoint(x: 0, y: -1000) // Hide default header
        
        // Weekday appearance
        appearance.weekdayFont = FontSet.montserratRegular.font(16)
        appearance.weekdayTextColor = ColorSet.primaryText.uiColor
        
        // Title appearance
        appearance.titleFont = trpTheme.font.body3
        // Don't set titleDefaultColor - let delegate method handle it
        appearance.titleSelectionColor = .white
        // Don't set titleTodayColor - let delegate method handle it
        appearance.titlePlaceholderColor = ColorSet.primaryText.uiColor.withAlphaComponent(0.3)
        
        // Selection colors
        appearance.selectionColor = ColorSet.primary.uiColor
        appearance.todayColor = .clear
        appearance.todaySelectionColor = ColorSet.primary.uiColor
        
        // Border - only for today
        appearance.borderRadius = 1.0 // Circular
        // Don't set borderDefaultColor - let delegate method handle it
        appearance.borderSelectionColor = .clear // No border for selected dates
        
        // Event dot
        appearance.eventDefaultColor = .clear
        appearance.eventSelectionColor = .clear
    }
    
    private func setupActions() {
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(backgroundTap)
        
        previousMonthButton.addTarget(self, action: #selector(previousMonthTapped), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)
        // monthYearButton action removed - button is now disabled
    }
    
    @objc private func pickerBackgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        // Don't close picker if tapping on header buttons
        if previousMonthButton.frame.contains(gesture.location(in: headerView)) ||
           nextMonthButton.frame.contains(gesture.location(in: headerView)) ||
           monthYearButton.frame.contains(gesture.location(in: headerView)) {
            return
        }
        
        if !pickerContainerView.frame.contains(location) && !headerView.frame.contains(location) {
            if isPickerVisible {
                hideMonthYearPicker()
                isPickerVisible = false
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped() {
        dismiss(animated: true) {
            self.delegate?.calendarViewControllerDidCancel()
        }
    }
    
    @objc private func previousMonthTapped() {
        let calendar = Calendar.current
        let currentPage = calendarView.currentPage
        
        // Get the first day of the current month
        let currentComponents = calendar.dateComponents([.year, .month], from: currentPage)
        guard let firstDayOfCurrentMonth = calendar.date(from: currentComponents) else { return }
        
        // Calculate first day of previous month
        guard let firstDayOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfCurrentMonth) else { return }
        
        // Ensure date is within bounds
        let minDate = calendarView.minimumDate
        let maxDate = calendarView.maximumDate
        if firstDayOfPreviousMonth < minDate || firstDayOfPreviousMonth > maxDate {
            return
        }
        
        // Try using select to scroll, then deselect if needed
        let wasSelected = calendarView.selectedDates.contains(firstDayOfPreviousMonth)
        calendarView.select(firstDayOfPreviousMonth, scrollToDate: true)
        
        // If it wasn't selected before, deselect it after scrolling
        if !wasSelected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.calendarView.deselect(firstDayOfPreviousMonth)
            }
        }
    }
    
    @objc private func nextMonthTapped() {
        let calendar = Calendar.current
        let currentPage = calendarView.currentPage
        
        // Get the first day of the current month
        let currentComponents = calendar.dateComponents([.year, .month], from: currentPage)
        guard let firstDayOfCurrentMonth = calendar.date(from: currentComponents) else { return }
        
        // Calculate first day of next month
        guard let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfCurrentMonth) else { return }
        
        // Ensure date is within bounds
        let minDate = calendarView.minimumDate
        let maxDate = calendarView.maximumDate
        if firstDayOfNextMonth < minDate || firstDayOfNextMonth > maxDate {
            return
        }
        
        // Try using select to scroll, then deselect if needed
        let wasSelected = calendarView.selectedDates.contains(firstDayOfNextMonth)
        calendarView.select(firstDayOfNextMonth, scrollToDate: true)
        
        // If it wasn't selected before, deselect it after scrolling
        if !wasSelected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.calendarView.deselect(firstDayOfNextMonth)
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.delegate?.calendarViewControllerDidCancel()
        }
    }
    
    @objc private func selectTapped() {
        switch selectionMode {
        case .range:
            if let startDate = firstSelectedDate, let endDate = lastSelectedDate {
                dismiss(animated: true) {
                    self.delegate?.calendarViewControllerDidSelectDateRange(startDate, endDate)
                }
            } else if let date = firstSelectedDate {
                // If only one date selected in range mode, treat it as single date
                dismiss(animated: true) {
                    self.delegate?.calendarViewControllerDidSelectDate(date)
                }
            }
        case .single:
            if let date = firstSelectedDate {
                dismiss(animated: true) {
                    self.delegate?.calendarViewControllerDidSelectDate(date)
                }
            }
        }
    }
    
    @objc private func monthYearTapped() {
        toggleMonthYearPicker()
    }
    
    private func toggleMonthYearPicker() {
        isPickerVisible.toggle()
        
        if isPickerVisible {
            showMonthYearPicker()
        } else {
            hideMonthYearPicker()
        }
    }
    
    private func showMonthYearPicker() {
        // Set picker to current month/year
        let currentPage = calendarView.currentPage
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentPage) - 1 // 0-indexed
        let year = calendar.component(.year, from: currentPage)
        
        if let yearIndex = years.firstIndex(of: year) {
            monthYearPicker.selectRow(month, inComponent: 0, animated: false)
            monthYearPicker.selectRow(yearIndex, inComponent: 1, animated: false)
        }
        
        // Rotate arrow up
        if let imageView = monthYearButton.imageView {
            UIView.animate(withDuration: 0.3) {
                imageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
        
        pickerContainerView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.pickerContainerView.alpha = 1.0
        }
    }
    
    private func hideMonthYearPicker() {
        // Rotate arrow back down
        if let imageView = monthYearButton.imageView {
            UIView.animate(withDuration: 0.3) {
                imageView.transform = .identity
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.pickerContainerView.alpha = 0.0
        }) { _ in
            self.pickerContainerView.isHidden = true
        }
    }
    
    private func updateCalendarToSelectedMonthYear(month: Int, year: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month + 1 // Convert back to 1-indexed
        components.day = 1
        
        if let newDate = calendar.date(from: components) {
            calendarView.setCurrentPage(newDate, animated: true)
            updateMonthYearLabel()
        }
    }
    
    // MARK: - Helpers
    private func updateMonthYearLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TRPClient.getLanguage())
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: calendarView.currentPage)
        monthYearButton.setTitle(monthYear, for: .normal)
        // No image to align since button is now disabled
    }
    
    private func generateDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    // MARK: - Public Methods
    public func show() {
        guard let topViewController = UIApplication.getTopViewController() else { return }
        topViewController.present(self, animated: true, completion: nil)
    }
}

// MARK: - FSCalendarDataSource
extension TRPCalendarViewController: FSCalendarDataSource {
    func minimumDate(for calendar: FSCalendar) -> Date {
        // Return the navigation range minimum (not the selectable range)
        // This allows users to navigate to months outside the selectable date range
        return minimumDate ?? Date()
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        // Return the navigation range maximum (not the selectable range)
        // This allows users to navigate to months outside the selectable date range
        return maximumDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        // Only allow selection if date is within selectable range
        if let start = selectableStartDate, let end = selectableEndDate {
            let gregorian = Calendar.current
            let startOfDay = gregorian.startOfDay(for: start)
            let endOfDay = gregorian.startOfDay(for: end)
            let dateToCheck = gregorian.startOfDay(for: date)
            
            return dateToCheck >= startOfDay && dateToCheck <= endOfDay
        }
        return true // If no selectable range is set, allow all dates
    }
}

// MARK: - FSCalendarDelegate
extension TRPCalendarViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // Double-check that the selected date is within selectable range
        if let start = selectableStartDate, let end = selectableEndDate {
            let gregorian = Calendar.current
            let dateToCheck = gregorian.startOfDay(for: date)
            let startOfDay = gregorian.startOfDay(for: start)
            let endOfDay = gregorian.startOfDay(for: end)
            
            // If date is outside selectable range, deselect it immediately
            if dateToCheck < startOfDay || dateToCheck > endOfDay {
                calendar.deselect(date)
                return
            }
        }
        
        switch selectionMode {
        case .range:
            handleMultipleSelection(date: date, calendar: calendar)
        case .single:
            // In single mode, deselect previous selection and select new one
            if let previousDate = firstSelectedDate, previousDate != date {
                calendar.deselect(previousDate)
            }
            firstSelectedDate = date
        }
        
        // Force update visible cells to apply white text color to selected date
        configureVisibleCells()
        
        // Also force the selected cell to have white text
        if let cell = calendar.cell(for: date, at: monthPosition) as? FSCalendarCell {
            cell.titleLabel.textColor = .white
        }
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        switch selectionMode {
        case .range:
            handleDeselection(date: date, calendar: calendar)
        case .single:
            firstSelectedDate = nil
        }
        
        // Force update visible cells to restore primary color to deselected date
        configureVisibleCells()
        
        // Also force the deselected cell to revert to primary color
        if let cell = calendar.cell(for: date, at: monthPosition) as? FSCalendarCell {
            // Check if date is in selectable range
            if let selectableStart = selectableStartDate, let selectableEnd = selectableEndDate {
                let gregorian = Calendar.current
                let dateToCheck = gregorian.startOfDay(for: date)
                let startOfDay = gregorian.startOfDay(for: selectableStart)
                let endOfDay = gregorian.startOfDay(for: selectableEnd)
                
                if dateToCheck >= startOfDay && dateToCheck <= endOfDay {
                    cell.titleLabel.textColor = ColorSet.primary.uiColor
                }
            }
        }
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        updateMonthYearLabel()
        
        // Save currently selected dates before reload
        let selectedDates = calendar.selectedDates
        
        // Force reload to refresh appearance when month changes
        calendar.reloadData()
        
        // Restore selection after reload
        for date in selectedDates {
            calendar.select(date, scrollToDate: false)
        }
        
        configureVisibleCells()
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date?) -> UIColor? {
        guard let date = date else { return nil }
        let gregorian = Calendar.current
        let dateToCheck = gregorian.startOfDay(for: date)
        
        // Check if date is in selectable range
        if let selectableStart = selectableStartDate, let selectableEnd = selectableEndDate {
            let startOfDay = gregorian.startOfDay(for: selectableStart)
            let endOfDay = gregorian.startOfDay(for: selectableEnd)
            
            // Date is OUTSIDE selectable range - clear background
            if dateToCheck < startOfDay || dateToCheck > endOfDay {
                return .clear
            }
            
            // Date is INSIDE selectable range (trip dates)
            if dateToCheck >= startOfDay && dateToCheck <= endOfDay {
                // Check if it's part of a selected range (for range mode)
                if selectionMode == .range, let start = firstSelectedDate, let end = lastSelectedDate {
                    let selectedStart = gregorian.startOfDay(for: start)
                    let selectedEnd = gregorian.startOfDay(for: end)
                    
                    // If date is in selected range
                    if dateToCheck >= selectedStart && dateToCheck <= selectedEnd {
                        // Check if it's start or end of selected range
                        if gregorian.isDate(date, inSameDayAs: start) || gregorian.isDate(date, inSameDayAs: end) {
                            return nil // Use default selection color (primary)
                        }
                        // Middle dates of selected range - lighter primary color
                        if date > start && date < end {
                            return ColorSet.primary.uiColor.withAlphaComponent(0.15)
                        }
                        return nil
                    }
                }
                
                // Date is in selectable range but not selected - show primary color with alpha
                // This makes it clear these dates are selectable (trip dates)
                return ColorSet.primary.uiColor.withAlphaComponent(0.15)
            }
        }
        
        // Check if date is in selected range (for range selection when no selectable range is set)
        if selectionMode == .range, let start = firstSelectedDate, let end = lastSelectedDate {
            if gregorian.isDate(date, inSameDayAs: start) || gregorian.isDate(date, inSameDayAs: end) {
                return nil // Use default selection color
            }
            if date > start && date < end {
                // Lighter primary color for range dates
                return ColorSet.primary.uiColor.withAlphaComponent(0.15)
            }
        }
        
        // No selectable range set - return clear for unselected dates
        return .clear
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date?) -> UIColor? {
        // Selected dates use solid primary color
        return ColorSet.primary.uiColor
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleSelectionColorFor date: Date?) -> UIColor? {
        // Selected date text should be white for visibility
        return .white
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date?) -> UIColor? {
        guard let date = date else { return ColorSet.primaryText.uiColor }
        
        // Check if date is outside selectable range
        if let selectableStart = selectableStartDate, let selectableEnd = selectableEndDate {
            let gregorian = Calendar.current
            let dateToCheck = gregorian.startOfDay(for: date)
            let startOfDay = gregorian.startOfDay(for: selectableStart)
            let endOfDay = gregorian.startOfDay(for: selectableEnd)
            
            if dateToCheck < startOfDay || dateToCheck > endOfDay {
                // Date is outside selectable range - gray it out to show it's disabled
                return ColorSet.primaryText.uiColor.withAlphaComponent(0.3)
            } else {
                // Date is inside selectable range (trip dates) - use primary color for text
                return ColorSet.primary.uiColor
            }
        }
        
        return ColorSet.primaryText.uiColor // Default color if no selectable range is set
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderDefaultColorFor date: Date?) -> UIColor? {
        guard let date = date else { return nil }
        
        // Show border ONLY for today's date (whether selected or not)
        let gregorian = Calendar.current
        if gregorian.isDateInToday(date) {
            return ColorSet.primaryText.uiColor.withAlphaComponent(0.5)
        }
        
        return .clear // No border for other dates
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderSelectionColorFor date: Date?) -> UIColor? {
        guard let date = date else { return nil }
        
        // Show border for today's date even when selected
        let gregorian = Calendar.current
        if gregorian.isDateInToday(date) {
            return ColorSet.primaryText.uiColor.withAlphaComponent(0.5)
        }
        
        return .clear // No border for selected dates that are not today
    }
    
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at monthPosition: FSCalendarMonthPosition) {
        // This delegate method is called for every cell and allows us to customize appearance
        guard monthPosition == .current else { return }
        
        let gregorian = Calendar.current
        let dateToCheck = gregorian.startOfDay(for: date)
        
        // Check if this date is currently selected
        let isSelected = calendar.selectedDates.contains(where: { gregorian.isDate($0, inSameDayAs: date) })
        
        // Don't override text color for selected cells - let the selection appearance handle it
        if isSelected {
            cell.titleLabel.textColor = ColorSet.primary.uiColor
            return
        }
        
        // Check if date is in selectable range
        if let selectableStart = selectableStartDate, let selectableEnd = selectableEndDate {
            let startOfDay = gregorian.startOfDay(for: selectableStart)
            let endOfDay = gregorian.startOfDay(for: selectableEnd)
            
            let isInRange = dateToCheck >= startOfDay && dateToCheck <= endOfDay
            
            // Update cell appearance based on whether it's selectable
            if isInRange {
                // Selectable date (trip date)
                cell.titleLabel.textColor = ColorSet.primary.uiColor
            } else {
                // Non-selectable date
                cell.titleLabel.textColor = ColorSet.primaryText.uiColor.withAlphaComponent(0.3)
            }
        }
    }
    
    private func configureVisibleCells() {
        calendarView.visibleCells().forEach { cell in
            guard let date = calendarView.date(for: cell) else { return }
            let position = calendarView.monthPosition(for: cell)
            
            if position == .current {
                // Force update cell appearance
                if let calendarCell = cell as? FSCalendarCell {
                    let gregorian = Calendar.current
                    let isSelected = calendarView.selectedDates.contains(where: { gregorian.isDate($0, inSameDayAs: date) })
                    
                    // Always set white text for selected cells
                    if isSelected {
                        calendarCell.titleLabel.textColor = .white
                        return
                    }
                    
                    // Check if date is in selectable range
                    if let selectableStart = selectableStartDate, let selectableEnd = selectableEndDate {
                        let dateToCheck = gregorian.startOfDay(for: date)
                        let startOfDay = gregorian.startOfDay(for: selectableStart)
                        let endOfDay = gregorian.startOfDay(for: selectableEnd)
                        
                        let isSelectable = dateToCheck >= startOfDay && dateToCheck <= endOfDay
                        
                        // Update cell colors for non-selected cells
                        if isSelectable {
                            calendarCell.backgroundView?.backgroundColor = ColorSet.primary.uiColor.withAlphaComponent(0.15)
                            calendarCell.titleLabel.textColor = ColorSet.primary.uiColor
                        } else {
                            calendarCell.backgroundView?.backgroundColor = .clear
                            calendarCell.titleLabel.textColor = ColorSet.primaryText.uiColor.withAlphaComponent(0.3)
                        }
                    }
                }
            }
        }
    }
    
    private func handleMultipleSelection(date: Date, calendar: FSCalendar) {
        if firstSelectedDate == nil {
            // First selection
            firstSelectedDate = date
            selectedDatesRange = [date]
        } else if lastSelectedDate == nil {
            // Second selection - create range
            if date < firstSelectedDate! {
                // If selected date is before first, swap them
                let temp = firstSelectedDate
                firstSelectedDate = date
                lastSelectedDate = temp
            } else {
                lastSelectedDate = date
            }
            
            // Deselect all previous selections
            for selectedDate in calendar.selectedDates {
                if selectedDate != firstSelectedDate && selectedDate != lastSelectedDate {
                    calendar.deselect(selectedDate)
                }
            }
            
            // Select all dates in range
            if let start = firstSelectedDate, let end = lastSelectedDate {
                let range = generateDateRange(from: start, to: end)
                selectedDatesRange = range
                for rangeDate in range {
                    if rangeDate != start && rangeDate != end {
                        calendar.select(rangeDate)
                    }
                }
            }
        } else {
            // Third selection - reset
            for selectedDate in calendar.selectedDates {
                calendar.deselect(selectedDate)
            }
            firstSelectedDate = date
            lastSelectedDate = nil
            selectedDatesRange = [date]
        }
    }
    
    private func handleDeselection(date: Date, calendar: FSCalendar) {
        if let first = firstSelectedDate, let last = lastSelectedDate {
            // If deselecting from a range, clear all and start over
            for selectedDate in calendar.selectedDates {
                calendar.deselect(selectedDate)
            }
            firstSelectedDate = nil
            lastSelectedDate = nil
            selectedDatesRange = []
        } else if firstSelectedDate == date {
            firstSelectedDate = nil
            selectedDatesRange = []
        }
    }
}

// MARK: - UIPickerViewDataSource
extension TRPCalendarViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2 // Month and Year
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: // Month
            return months.count
        case 1: // Year
            return years.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate
extension TRPCalendarViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: // Month
            return months[row]
        case 1: // Year
            return "\(years[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedMonth = pickerView.selectedRow(inComponent: 0)
        let selectedYearIndex = pickerView.selectedRow(inComponent: 1)
        let selectedYear = years[selectedYearIndex]
        
        updateCalendarToSelectedMonthYear(month: selectedMonth, year: selectedYear)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title: String
        switch component {
        case 0: // Month
            title = months[row]
        case 1: // Year
            title = "\(years[row])"
        default:
            title = ""
        }
        
        return NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: ColorSet.primaryText.uiColor,
                .font: FontSet.montserratRegular.font(16)
            ]
        )
    }
}


