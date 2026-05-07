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
    func segmentUpdateDidSucceed()
    func stepUpdateDidSucceed()
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
    private var hasPreloadedSlots: Bool = false

    // Edit mode properties
    private var segment: TRPTimelineSegment?
    private var step: TRPTimelineStep?
    public var isEditMode: Bool { segment != nil || step != nil }
    public var isStepEditMode: Bool { step != nil }

    // MARK: - Initialization
    public init(tour: TRPTourProduct, planData: AddPlanData, tourRepository: TourRepository = TRPTourRepository()) {
        self.tour = tour
        self.planData = planData
        self.tourRepository = tourRepository
        self.selectedDate = planData.selectedDay

        // Only treat the search-preloaded slots as authoritative when there's actually
        // something to render. An empty array means the search response carried the
        // field but the backend had nothing for this product — fall back to the
        // per-day `getTourSchedule` API instead of locking the screen into an empty
        // state.
        if let preloaded = tour.slots, !preloaded.isEmpty {
            prefillCacheFromPreloadedSlots(preloaded)
            hasPreloadedSlots = true
        }
    }

    /// Edit mode initializer - creates TRPTourProduct from segment's additionalData
    public init(segment: TRPTimelineSegment, planData: AddPlanData, tourRepository: TourRepository = TRPTourRepository()) {
        self.segment = segment
        self.planData = planData
        self.tourRepository = tourRepository
        self.selectedDate = planData.selectedDay

        // Extract tour info from segment's additionalData
        guard let additionalData = segment.additionalData else {
            fatalError("Reserved activity segment must have additionalData")
        }

        // Format productId for availability API
        // If activityId doesn't start with "C_", format as "C_{activityId}_15_{cityId}"
        let activityId = additionalData.activityId ?? ""
        let cityId = segment.city?.id ?? planData.selectedCity?.id ?? 0
        let formattedProductId: String
        if activityId.hasPrefix("C_") {
            formattedProductId = activityId
        } else {
            formattedProductId = "C_\(activityId)_15_\(cityId)"
        }

        // Create TRPTourProduct from additionalData (schedule API needs productId)
        let tourImage: TRPImage? = additionalData.imageUrl != nil
            ? TRPImage(url: additionalData.imageUrl!, imageOwner: nil, width: nil, height: nil)
            : nil

        self.tour = TRPTourProduct(
            id: formattedProductId,
            productId: formattedProductId,
            cityId: cityId,
            name: additionalData.title ?? "",
            image: tourImage,
            gallery: nil,
            duration: additionalData.duration != nil ? Int(additionalData.duration!) : nil,
            price: additionalData.price != nil ? Int(additionalData.price!.value) : nil,
            rating: nil,
            ratingCount: nil,
            description: additionalData.description,
            webUrl: nil,
            phone: nil,
            hours: nil,
            address: nil,
            icon: "",
            coordinate: additionalData.coordinate,
            categories: [],
            tags: [],
            distance: nil,
            status: true,
            offers: [],
            additionalData: nil
        )
    }

    /// Step edit mode initializer - for changing time of activity steps in recommendations
    public init(step: TRPTimelineStep, planData: AddPlanData, tourRepository: TourRepository = TRPTourRepository()) {
        self.step = step
        self.planData = planData
        self.tourRepository = tourRepository
        self.selectedDate = planData.selectedDay

        // Extract product info from step's POI
        guard let poi = step.poi else {
            fatalError("Activity step must have POI")
        }

        // Get productId from POI's additionalData or bookings
        let productId: String
        if let additionalProductId = poi.additionalData?.productId {
            productId = additionalProductId
        } else if let bookingProduct = poi.bookings?.first?.firstProduct() {
            productId = bookingProduct.id
        } else {
            productId = poi.id
        }

        // Format productId for availability API
        // If productId doesn't start with "C_", format as "C_{productId}_15_{cityId}"
        let cityId = planData.selectedCity?.id ?? poi.cityId
        let formattedProductId: String
        if productId.hasPrefix("C_") {
            formattedProductId = productId
        } else {
            formattedProductId = "C_\(productId)_15_\(cityId)"
        }

        // Create TRPTourProduct from POI (schedule API needs productId)
        self.tour = TRPTourProduct(
            id: formattedProductId,
            productId: formattedProductId,
            cityId: cityId,
            name: poi.name,
            image: poi.image,
            gallery: poi.gallery,
            duration: poi.duration,
            price: poi.price,
            rating: poi.rating,
            ratingCount: poi.ratingCount,
            description: poi.description,
            webUrl: poi.webUrl,
            phone: poi.phone,
            hours: poi.hours,
            address: poi.address,
            icon: poi.icon ?? "",
            coordinate: poi.coordinate,
            categories: poi.categories,
            tags: poi.tags,
            distance: poi.distance,
            status: poi.status,
            offers: poi.offers,
            additionalData: nil
        )
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

    /// Get selected date
    public func getSelectedDate() -> Date? {
        return selectedDate
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

    /// Get time slots for selected day (filtered for today to exclude past times, deduplicated by time)
    public func getTimeSlots() -> [TimeSlot] {
        guard let selectedDate = selectedDate else { return [] }
        var slots = allTimeSlots[selectedDate] ?? []

        // If today, filter out past times (before current time + 30 minutes)
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            let minimumTime = Date()  // +30 minutes
            let minimumTimeComponents = calendar.dateComponents([.hour, .minute], from: minimumTime)
            let minimumMinutes = (minimumTimeComponents.hour ?? 0) * 60 + (minimumTimeComponents.minute ?? 0)

            slots = slots.filter { slot in
                let timeComponents = slot.time.split(separator: ":")
                guard timeComponents.count >= 2,
                      let hour = Int(timeComponents[0]),
                      let minute = Int(timeComponents[1]) else {
                    return true  // Keep slot if parsing fails
                }
                let slotMinutes = hour * 60 + minute
                return slotMinutes >= minimumMinutes
            }
        }

        // Deduplicate slots by time, keeping the one with lowest price
        return deduplicateSlotsByTime(slots)
    }

    /// Deduplicate time slots by time string, keeping the slot with lowest price for each time
    private func deduplicateSlotsByTime(_ slots: [TimeSlot]) -> [TimeSlot] {
        var slotsByTime: [String: TimeSlot] = [:]

        for slot in slots {
            if let existingSlot = slotsByTime[slot.time] {
                // Keep the one with lower price
                let existingPrice = existingSlot.price ?? Double.greatestFiniteMagnitude
                let newPrice = slot.price ?? Double.greatestFiniteMagnitude
                if newPrice < existingPrice {
                    slotsByTime[slot.time] = slot
                }
            } else {
                slotsByTime[slot.time] = slot
            }
        }

        // Sort by time and return
        return slotsByTime.values.sorted { slot1, slot2 in
            slot1.time < slot2.time
        }
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

        // Preload path: search response already populated cache for all trip days; skip API.
        if hasPreloadedSlots {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.timeSlotsDidLoad()
            }
            return
        }

        // Embed the Lottie loader inside the time-selection screen itself rather than
        // stacking a second bottom sheet on top — TimeSelectionVC is already presented
        // as a sheet, so the loader appears inline within the host's view.
        let loadingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.loadingTimeSlots)
        delegate?.viewModel(showLottieInView: true, text: loadingText)

        // Format date as "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)

        // Get currency and language from settings
        let currency = TRPClient.getCurrency()
        let lang = TRPClient.getLanguage()

        // Call API
        tourRepository.getTourSchedule(productId: tour.id, date: dateString, currency: currency, lang: lang) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showLottieInView: false, text: nil)

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

    /// Bucket preloaded search-response slots into the per-day cache.
    /// Uses string equality on "yyyy-MM-dd" against canonical Date instances from `availableDays`,
    /// so dictionary keys exactly match the Date instances `selectDay(at:)`/`getTimeSlots()` use.
    private func prefillCacheFromPreloadedSlots(_ slots: [TRPTourSlot]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Build map "yyyy-MM-dd" -> canonical Date from availableDays
        var dateByString: [String: Date] = [:]
        for day in planData.availableDays {
            dateByString[formatter.string(from: day)] = day
        }

        // Pre-create empty buckets for every trip day so cache miss never triggers a fetch
        for day in planData.availableDays where allTimeSlots[day] == nil {
            allTimeSlots[day] = []
        }

        // Bucket each preloaded slot under its canonical Date; drop trip-range outliers.
        for slot in slots {
            guard let canonicalDay = dateByString[slot.date] else { continue }
            allTimeSlots[canonicalDay]?.append(TRPTourScheduleSlot(time: slot.time, price: slot.price))
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

        // Get price with currency - prefer slot price over tour price
        var activityPrice: TRPSegmentActivityPrice? = nil
        if let slotPrice = selectedTimeSlot.price, slotPrice > 0 {
            // Use slot price with currency from API request
            let currency = TRPClient.getCurrency()
            activityPrice = TRPSegmentActivityPrice(currency: currency, value: slotPrice)
        } else if let priceValue = tour.price, priceValue > 0 {
            // Fallback to tour price
            let currency = tour.offers.first?.currency.rawValue ?? "EUR"
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

    /// Update existing reserved activity segment (edit mode)
    public func updateReservedActivitySegment() {
        // 1. Validate required data
        guard let tripHash = planData.tripHash else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeline not found. Please try again."]))
            return
        }

        guard let segmentIndex = planData.segmentIndex,
              let segment = segment else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -2, userInfo: [NSLocalizedDescriptionKey: "Segment not found. Please try again."]))
            return
        }

        guard let selectedDate = selectedDate,
              let selectedTimeSlot = selectedTimeSlot else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -3, userInfo: [NSLocalizedDescriptionKey: "Please select a time slot."]))
            return
        }

        // 2. Calculate new times
        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // 3. Update additionalData times
        var updatedAdditionalData = segment.additionalData
        updatedAdditionalData?.startDatetime = startDatetimeString
        updatedAdditionalData?.endDatetime = endDatetimeString

        // 4. Create edit profile from existing segment
        let profile = TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: tripHash, segmentIndex: segmentIndex)
        profile.startDate = startDateString
        profile.endDate = endDateString
        profile.additionalData = updatedAdditionalData

        // 5. Show loading
        delegate?.viewModel(showPreloader: true)

        // 6. Update segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success(let success):
                    if success {
                        self.delegate?.segmentUpdateDidSucceed()
                    } else {
                        let error = NSError(domain: "AddPlanTimeSelection", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to update time. Please try again."])
                        self.delegate?.viewModel(error: error)
                    }

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Update activity step time (step edit mode)
    public func updateActivityStep() {
        guard let step = step else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Step not found. Please try again."]))
            return
        }

        guard let selectedTimeSlot = selectedTimeSlot else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -2, userInfo: [NSLocalizedDescriptionKey: "Please select a time slot."]))
            return
        }

        // Get start time from time slot (format: "HH:mm" or "HH:mm:ss")
        // Extract just the "HH:mm" part
        let startTimeComponents = selectedTimeSlot.time.split(separator: ":")
        guard startTimeComponents.count >= 2 else {
            delegate?.viewModel(error: NSError(domain: "AddPlanTimeSelection", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid time format."]))
            return
        }
        let startTime = "\(startTimeComponents[0]):\(startTimeComponents[1])"

        // Calculate end time based on duration
        let durationMinutes = tour.duration ?? 60
        let endTime = calculateEndTime(startTime: startTime, durationMinutes: durationMinutes)

        // Create step edit request (only time, no date)
        let stepEdit = TRPTimelineStepEdit(
            stepId: step.id,
            startTime: startTime,
            endTime: endTime
        )

        // Show loading
        delegate?.viewModel(showPreloader: true)

        // Update step via repository
        let repository = TRPTimelineStepRepository()
        repository.editStep(step: stepEdit) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                switch result {
                case .success:
                    self.delegate?.stepUpdateDidSucceed()

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

    /// Calculate end time from start time and duration (returns "HH:mm" format)
    private func calculateEndTime(startTime: String, durationMinutes: Int) -> String {
        let components = startTime.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            // Fallback: add 1 hour to a default time
            return "13:00"
        }

        let totalMinutes = hour * 60 + minute + durationMinutes
        let endHour = (totalMinutes / 60) % 24
        let endMinute = totalMinutes % 60

        return String(format: "%02d:%02d", endHour, endMinute)
    }
}
