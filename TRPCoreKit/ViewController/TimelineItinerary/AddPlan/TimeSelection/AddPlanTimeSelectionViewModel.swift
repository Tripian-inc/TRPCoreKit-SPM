//
//  AddPlanTimeSelectionViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public typealias TimeSlot = TRPTourScheduleSlot

public protocol AddPlanTimeSelectionViewModelDelegate: AnyObject {
    func timeSlotsDidLoad()
    func timeSlotsDidFail(error: Error)
    func showLoading(_ show: Bool)
}

public class AddPlanTimeSelectionViewModel {

    // MARK: - Properties
    public weak var delegate: AddPlanTimeSelectionViewModelDelegate?

    private let tour: TRPTourProduct
    private let planData: AddPlanData
    private let tourRepository: TourRepository

    private var allTimeSlots: [Date: [TimeSlot]] = [:] // Date -> TimeSlots
    private var selectedDate: Date?
    private var selectedTimeSlot: TimeSlot?

    // MARK: - Initialization
    public init(tour: TRPTourProduct, planData: AddPlanData, tourRepository: TourRepository = TRPTourRepository()) {
        self.tour = tour
        self.planData = planData
        self.tourRepository = tourRepository
        self.selectedDate = planData.selectedDay
    }

    // MARK: - Public Methods

    /// Get available days for this activity
    public func getAvailableDays() -> [Date] {
        // For now, return plan data days
        // Later, we'll get this from API response
        guard let startDay = planData.selectedDay else { return [] }

        var days: [Date] = []
        for i in 0..<7 {
            if let day = startDay.addDay(i) {
                days.append(day)
            }
        }
        return days
    }

    /// Get selected day index
    public func getSelectedDayIndex() -> Int {
        guard let selectedDate = selectedDate else { return 0 }
        let days = getAvailableDays()
        return days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDate) }) ?? 0
    }

    /// Select a day
    public func selectDay(at index: Int) {
        let days = getAvailableDays()
        guard index < days.count else { return }
        let newDate = days[index]

        // Only fetch if we haven't fetched for this date yet
        if selectedDate != newDate {
            selectedDate = newDate
            selectedTimeSlot = nil // Reset time selection when day changes

            // Check if we already have slots for this date
            if allTimeSlots[newDate] == nil {
                // Fetch time slots for new date
                fetchTimeSlots()
            }
        }
    }

    /// Get time slots for selected day
    public func getTimeSlots() -> [TimeSlot] {
        guard let selectedDate = selectedDate else { return [] }
        return allTimeSlots[selectedDate] ?? []
    }

    /// Select a time slot
    public func selectTimeSlot(_ timeSlot: TimeSlot) {
        selectedTimeSlot = timeSlot
    }

    /// Get selected time slot
    public func getSelectedTimeSlot() -> TimeSlot? {
        return selectedTimeSlot
    }

    /// Check if continue button should be enabled
    public func canContinue() -> Bool {
        return selectedDate != nil && selectedTimeSlot != nil
    }

    /// Fetch available time slots from API
    public func fetchTimeSlots() {
        guard let selectedDate = selectedDate else {
            delegate?.timeSlotsDidFail(error: NSError(domain: "AddPlanTimeSelection", code: -1, userInfo: [NSLocalizedDescriptionKey: "No date selected"]))
            return
        }

        delegate?.showLoading(true)

        // Format date as "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)

        // Get currency and language from settings or use defaults
        let currency = "USD"
        let lang = TRPClient.getLanguage()
        
        // Call API
        tourRepository.getTourSchedule(productId: tour.id, date: dateString, currency: currency, lang: lang) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.showLoading(false)

                switch result {
                case .success(let schedule):
                    // Store slots for selected date
                    self.allTimeSlots[selectedDate] = schedule.slots
                    self.delegate?.timeSlotsDidLoad()

                case .failure(let error):
                    self.delegate?.timeSlotsDidFail(error: error)
                }
            }
        }
    }

    // MARK: - Private Methods
}
