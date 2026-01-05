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

public protocol AddPlanTimeSelectionViewModelDelegate: ViewModelDelegate {
    func timeSlotsDidLoad()
    func segmentCreationDidSucceed()
}

public class AddPlanTimeSelectionViewModel {

    // MARK: - Properties
    public var delegate: AddPlanTimeSelectionViewModelDelegate?

    internal let tour: TRPTourProduct
    internal let planData: AddPlanData
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

    /// Get available days for this activity (from timeline/itinerary)
    public func getAvailableDays() -> [Date] {
        return planData.availableDays
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
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -1, userInfo: [NSLocalizedDescriptionKey: "No date selected"]))
            return
        }

        delegate?.viewModel(showPreloader: true)

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
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(let schedule):
                    // Store slots for selected date
                    self.allTimeSlots[selectedDate] = schedule.slots
                    self.delegate?.timeSlotsDidLoad()

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Create reserved activity segment
    public func createReservedActivitySegment() {
        // 1. Validate required data
        guard let tripHash = planData.tripHash else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeline not found. Please try again."]))
            return
        }

        guard let tourCoordinate = tour.coordinate else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -2, userInfo: [NSLocalizedDescriptionKey: "Activity location not available."]))
            return
        }

        guard let selectedDate = selectedDate,
              let selectedTimeSlot = selectedTimeSlot else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -3, userInfo: [NSLocalizedDescriptionKey: "Please select a time slot."]))
            return
        }

        // 2. Calculate start and end times
        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // 3. Create TRPSegmentActivityItem (additionalData)
        // Get duration (convert Int to Double)
        let durationValue: Double? = tour.duration != nil ? Double(tour.duration!) : nil

        // Get price with currency (from offers or default to USD)
        var activityPrice: TRPSegmentActivityPrice? = nil
        if let priceValue = tour.price, priceValue > 0 {
            let currency = tour.offers.first?.currency.rawValue ?? "USD"
            activityPrice = TRPSegmentActivityPrice(currency: currency, value: Double(priceValue))
        }

        let activityItem = TRPSegmentActivityItem(
            activityId: tour.productId,
            bookingId: nil,  // Not sent for reserved activities
            title: tour.name,
            imageUrl: tour.image?.url,
            description: tour.description,
            startDatetime: startDatetimeString,
            endDatetime: endDatetimeString,
            coordinate: tourCoordinate,
            cancellation: nil,  // Not sent for reserved activities
            adultCount: planData.travelers,
            childCount: 0,
            duration: durationValue,
            price: activityPrice
        )

        // 4. Create TRPCreateEditTimelineSegmentProfile
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)
        profile.segmentType = .reservedActivity
        profile.available = false
        profile.distinctPlan = true
        profile.title = tour.name
        profile.description = tour.description
        profile.startDate = startDateString
        profile.endDate = endDateString
        profile.coordinate = tourCoordinate
        profile.city = planData.selectedCity
        profile.adults = planData.travelers
        profile.children = 0
        profile.pets = 0
        profile.additionalData = activityItem

        // 5. Show loading
        delegate?.viewModel(showPreloader: true)

        // 6. Create segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(let success):
                    if success {
                        self.delegate?.segmentCreationDidSucceed()
                    } else {
                        let error = NSError(domain: "AddPlanTimeSelection", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create reservation. Please try again."])
                        self.delegate?.viewModel(error: error)
                    }

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func calculateSegmentTimes(
        selectedDate: Date,
        selectedTimeSlot: TimeSlot
    ) -> (startDateString: String, endDateString: String, startDatetimeString: String, endDatetimeString: String) {

        // Parse time slot (format: "HH:mm" or "HH:mm:ss")
        let timeComponents = selectedTimeSlot.time.split(separator: ":")
        guard timeComponents.count >= 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            // Fallback to noon if parsing fails
            return calculateTimesWithDefaults(selectedDate: selectedDate, hour: 12, minute: 0)
        }

        return calculateTimesWithDefaults(selectedDate: selectedDate, hour: hour, minute: minute)
    }

    private func calculateTimesWithDefaults(selectedDate: Date, hour: Int, minute: Int) -> (String, String, String, String) {
        // Create start time
        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = hour
        startComponents.minute = minute
        startComponents.second = 0

        guard let startDate = Calendar.current.date(from: startComponents) else {
            // Fallback to selected date if components fail
            return formatDates(start: selectedDate, end: selectedDate.addingTimeInterval(3600))
        }

        // Calculate end time (start + duration or +1 hour)
        let durationMinutes = tour.duration ?? 60
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))

        return formatDates(start: startDate, end: endDate)
    }

    private func formatDates(start: Date, end: Date) -> (String, String, String, String) {
        let dateFormatter = DateFormatter()

        // Format for segment dates (yyyy-MM-dd HH:mm)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let startDateString = dateFormatter.string(from: start)
        let endDateString = dateFormatter.string(from: end)

        // Format for additionalData datetimes (yyyy-MM-dd HH:mm:ss)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let startDatetimeString = dateFormatter.string(from: start)
        let endDatetimeString = dateFormatter.string(from: end)

        return (startDateString, endDateString, startDatetimeString, endDatetimeString)
    }
}
