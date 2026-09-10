//
//  NexusDateSelectionVC.swift
//  TRPCoreKit
//
//  Step 2 of the Nexus create-trip flow: pick a date RANGE for the chosen city
//  using an inline FSCalendar, then build the itinerary and hand off to timeline
//  creation. Back / Edit return to the city step. Built from scratch.
//

import UIKit
import FSCalendar
import TRPRestKit

@objc(SPMNexusDateSelectionVC)
public class NexusDateSelectionVC: TRPBaseUIViewController {

    /// Set by the coordinator before presenting.
    public var city: TRPCity!
    public var uniqueId: String?

    public var onBack: (() -> Void)?
    public var onComplete: ((TRPItineraryWithActivities) -> Void)?

    private var viewModel: NexusDateSelectionViewModel!

    /// Longest selectable trip, start and end days included.
    public var maxRangeDays: Int = 30

    private var firstSelectedDate: Date?
    private var lastSelectedDate: Date?
    private var selectedRange: [Date] = []

    // MARK: - UI
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(TRPImageController().getImage(inFramework: "ic_back", inApp: nil), for: .normal)
        b.tintColor = ColorSet.primaryText.uiColor
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratBold.font(16)
        l.textColor = ColorSet.primaryText.uiColor
        l.textAlignment = .center
        l.text = NexusLocalizationKeys.localized(NexusLocalizationKeys.selectDates)
        return l
    }()

    private lazy var cityIcon: UIImageView = {
        let iv = UIImageView(image: TRPImageController().getImage(inFramework: "ic_pin", inApp: nil)?.withRenderingMode(.alwaysTemplate))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ColorSet.primaryText.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var cityLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratSemiBold.font(15)
        l.textColor = ColorSet.primaryText.uiColor
        return l
    }()

    private lazy var editButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(NexusLocalizationKeys.localized(NexusLocalizationKeys.edit), for: .normal)
        b.titleLabel?.font = FontSet.montserratSemiBold.font(14)
        b.setTitleColor(ColorSet.primary.uiColor, for: .normal)
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var calendar: FSCalendar = {
        let c = FSCalendar()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.dataSource = self
        c.delegate = self
        c.allowsMultipleSelection = true
        c.locale = Locale(identifier: TRPClient.getLanguage())
        c.placeholderType = .none
        c.scrollEnabled = true
        c.pagingEnabled = true
        c.appearance.selectionColor = ColorSet.primary.uiColor
        c.appearance.titleSelectionColor = .white
        c.appearance.todayColor = .clear
        c.appearance.todaySelectionColor = ColorSet.primary.uiColor
        c.appearance.headerTitleColor = ColorSet.primaryText.uiColor
        c.appearance.headerDateFormat = "MMMM yyyy"
        c.appearance.weekdayTextColor = ColorSet.primaryText.uiColor
        c.appearance.headerMinimumDissolvedAlpha = 0.0
        return c
    }()

    private lazy var nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(NexusLocalizationKeys.localized(NexusLocalizationKeys.next), for: .normal)
        b.titleLabel?.font = FontSet.montserratSemiBold.font(16)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = ColorSet.primary.uiColor
        b.layer.cornerRadius = 10
        b.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        b.isEnabled = false
        b.alpha = 0.4
        return b
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        viewModel = NexusDateSelectionViewModel(city: city, uniqueId: uniqueId)
        cityLabel.text = city.name

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(cityIcon)
        view.addSubview(cityLabel)
        view.addSubview(editButton)
        view.addSubview(calendar)
        view.addSubview(nextButton)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            cityIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cityIcon.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            cityIcon.widthAnchor.constraint(equalToConstant: 18),
            cityIcon.heightAnchor.constraint(equalToConstant: 18),

            cityLabel.leadingAnchor.constraint(equalTo: cityIcon.trailingAnchor, constant: 8),
            cityLabel.centerYAnchor.constraint(equalTo: cityIcon.centerYAnchor),

            editButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: cityIcon.centerYAnchor),
            editButton.leadingAnchor.constraint(greaterThanOrEqualTo: cityLabel.trailingAnchor, constant: 8),

            calendar.topAnchor.constraint(equalTo: cityIcon.bottomAnchor, constant: 16),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            calendar.heightAnchor.constraint(equalToConstant: 360),

            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Range helpers
    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        let cal = Calendar.current
        while current <= end {
            dates.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    private func clearSelection() {
        for d in calendar.selectedDates { calendar.deselect(d) }
        firstSelectedDate = nil
        lastSelectedDate = nil
        selectedRange = []
    }

    private func updateNextState() {
        let enabled = firstSelectedDate != nil
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.4
    }

    // MARK: - Actions
    @objc private func backTapped() { onBack?() }

    @objc private func nextTapped() {
        guard let start = firstSelectedDate else { return }
        let end = min(lastSelectedDate ?? start, lastAllowedEnd(from: start))
        onComplete?(viewModel.buildItinerary(start: start, end: end))
    }

    /// Last day that keeps a trip starting on `start` within `maxRangeDays`.
    private func lastAllowedEnd(from start: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: maxRangeDays - 1, to: start) ?? start
    }

    /// True while an end day is being picked and `date` would exceed `maxRangeDays`.
    private func exceedsRangeLimit(_ date: Date) -> Bool {
        guard let first = firstSelectedDate, lastSelectedDate == nil else { return false }
        return Calendar.current.startOfDay(for: date) > lastAllowedEnd(from: first)
    }
}

// MARK: - FSCalendar
extension NexusDateSelectionVC: FSCalendarDataSource, FSCalendarDelegate {

    public func minimumDate(for calendar: FSCalendar) -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    public func maximumDate(for calendar: FSCalendar) -> Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    public func calendar(_ calendar: FSCalendar, shouldDeselect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return false
    }

    public func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return !exceedsRangeLimit(date)
    }

    public func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let day = Calendar.current.startOfDay(for: date)

        if firstSelectedDate == nil || (firstSelectedDate != nil && lastSelectedDate != nil) {
            // Start a fresh range.
            clearSelection()
            firstSelectedDate = day
            selectedRange = [day]
            calendar.select(day)
        } else if let first = firstSelectedDate {
            if day < first {
                // Tapped earlier than the start → restart from there.
                clearSelection()
                firstSelectedDate = day
                selectedRange = [day]
                calendar.select(day)
            } else if day > first {
                lastSelectedDate = day
                selectedRange = generateDateRange(from: first, to: day)
                for d in selectedRange { calendar.select(d) }
            }
        }
        calendar.reloadData()
        updateNextState()
    }
}

extension NexusDateSelectionVC: FSCalendarDelegateAppearance {

    public func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        return exceedsRangeLimit(date) ? ColorSet.fgWeaker.uiColor : nil
    }
}
