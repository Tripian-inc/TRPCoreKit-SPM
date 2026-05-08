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

    private var allTimeSlots: [Date: [TimeSlot]] = [:] // Date -> Timed slots only
    /// Days where the activity is "flexible" (valid any time). Populated alongside
    /// `allTimeSlots` from the search/schedule response. Mixed days (with both timed
    /// and flexible markers) are NOT considered flexible — timed grid wins.
    private var flexibleDays: Set<Date> = []
    private var selectedDate: Date?
    private var selectedTimeSlot: TimeSlot?
    private var hasPreloadedSlots: Bool = false

    /// Maximum slots shown collapsed before the "More" link appears. When the day has
    /// strictly more than this many slots, the grid renders the first
    /// `collapsedSlotCount` and a "Show more" link below; tapping the link expands the
    /// grid to the full set.
    private let collapsedSlotThreshold: Int = 8
    private let collapsedSlotCount: Int = 7

    /// Expansion flag for the slot grid. Reset to `false` whenever the day changes so
    /// each day starts collapsed.
    private(set) public var isTimeSlotsExpanded: Bool = false

    /// Polling use case retained for the duration of a "wait for timeline regeneration"
    /// step that runs after a successful segment-creation API call. Held as a strong
    /// reference so it isn't deallocated mid-poll; cleared once the cycle finishes.
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

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

    /// Select a day. The schedule cache is populated up-front for the entire trip
    /// range (single fetch in `fetchTimeSlots`), so day switches are instant — no
    /// per-day API call is triggered here.
    public func selectDay(at index: Int) {
        let days = getAvailableDays()
        guard index < days.count else { return }
        let newDate = days[index]

        if selectedDate != newDate {
            selectedDate = newDate
            selectedTimeSlot = nil
            // Each day starts collapsed — user has to expand again per-day if needed.
            isTimeSlotsExpanded = false
            delegate?.timeSlotsDidLoad()
        }
    }

    /// Get time slots for selected day (filtered for today to exclude past times, deduplicated by time)
    public func getTimeSlots() -> [TimeSlot] {
        guard let selectedDate = selectedDate else { return [] }
        let slots = validTimedSlots(for: selectedDate)
        // Deduplicate slots by time, keeping the one with lowest price
        return deduplicateSlotsByTime(slots)
    }

    /// Slots actually shown in the grid right now. Honours the collapsed/expanded state
    /// so the "Show more" link can hide the tail. When the total count is at or below
    /// `collapsedSlotThreshold`, returns everything regardless of expansion state.
    public func getDisplayedTimeSlots() -> [TimeSlot] {
        let all = getTimeSlots()
        guard !isTimeSlotsExpanded, all.count > collapsedSlotThreshold else { return all }
        return Array(all.prefix(collapsedSlotCount))
    }

    /// True when there are strictly more slots than `collapsedSlotThreshold` AND the grid
    /// is still collapsed — drives whether the "Show more" link is visible.
    public func hasMoreTimeSlotsToShow() -> Bool {
        return !isTimeSlotsExpanded && getTimeSlots().count > collapsedSlotThreshold
    }

    /// Expand the slot grid to show every available slot. No-op if already expanded.
    /// Caller should reload the grid + refresh the sheet height afterward.
    public func expandTimeSlots() {
        guard !isTimeSlotsExpanded else { return }
        isTimeSlotsExpanded = true
    }

    /// Returns the cached timed slots for `date` minus any whose time-of-day is already
    /// in the past when `date` is today. For non-today dates this is just the cached
    /// slots. Used by both `getTimeSlots()` (UI) and `isDayUnavailable(_:)` (day filter
    /// gating) so the two stay consistent — a "today" with all slots expired is treated
    /// as having no slots, i.e. unavailable.
    private func validTimedSlots(for date: Date) -> [TimeSlot] {
        let cached = allTimeSlots[date] ?? []
        let calendar = Calendar.current
        guard calendar.isDateInToday(date) else { return cached }

        let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)

        return cached.filter { slot in
            guard let timeString = slot.time else {
                // Defensive: timed grid never holds flexible slots, but if one slipped
                // through, keep it so we don't silently drop entries.
                return true
            }
            let parts = timeString.split(separator: ":")
            guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
                return true  // Keep slot if parsing fails
            }
            return (hour * 60 + minute) >= nowMinutes
        }
    }

    /// Deduplicate time slots by time string, keeping the slot with lowest price for each time.
    /// Slots without a time (flexible) are skipped here — they live in `flexibleDays`.
    private func deduplicateSlotsByTime(_ slots: [TimeSlot]) -> [TimeSlot] {
        var slotsByTime: [String: TimeSlot] = [:]

        for slot in slots {
            guard let timeKey = slot.time else { continue }
            if let existingSlot = slotsByTime[timeKey] {
                let existingPrice = existingSlot.price ?? Double.greatestFiniteMagnitude
                let newPrice = slot.price ?? Double.greatestFiniteMagnitude
                if newPrice < existingPrice {
                    slotsByTime[timeKey] = slot
                }
            } else {
                slotsByTime[timeKey] = slot
            }
        }

        // Sort by time and return
        return slotsByTime.values.sorted { slot1, slot2 in
            (slot1.time ?? "") < (slot2.time ?? "")
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

    /// True when the currently selected day is flexible-time (activity is valid any
    /// time on that date). Mixed-day rule: a day with at least one timed slot is NOT
    /// flexible — the timed grid wins.
    public func isSelectedDayFlexible() -> Bool {
        guard let selectedDate = selectedDate else { return false }
        let hasTimedSlot = !(allTimeSlots[selectedDate] ?? []).isEmpty
        return !hasTimedSlot && flexibleDays.contains(selectedDate)
    }

    /// Check if continue button should be enabled. Flexible days don't need a time
    /// slot selection — the activity is valid any time on that date.
    public func canContinue() -> Bool {
        guard selectedDate != nil else { return false }
        return selectedTimeSlot != nil || isSelectedDayFlexible()
    }

    /// True when the given date has no usable timed slots and no flexible-time marker —
    /// i.e. the activity has no bookable availability for that day. Critically, "today"
    /// is also unavailable when every cached slot is already in the past (current time
    /// has crossed all of them); without this gate the day shows as available in the
    /// filter but tapping it lands on an empty grid.
    public func isDayUnavailable(_ date: Date) -> Bool {
        let hasTimedSlot = !validTimedSlots(for: date).isEmpty
        let isFlexible = flexibleDays.contains(date)
        return !hasTimedSlot && !isFlexible
    }

    /// Indices into `availableDays` whose dates have no availability. The day filter
    /// view uses this to render those entries as disabled (same UX as past dates).
    public func unavailableDayIndices() -> Set<Int> {
        var result: Set<Int> = []
        for (index, day) in planData.availableDays.enumerated() where isDayUnavailable(day) {
            result.insert(index)
        }
        return result
    }

    /// True when the activity has no bookable availability on ANY day of the trip —
    /// every day is either in the past, has no slots, or is today with all slots
    /// already expired. The VC swaps the time grid for a "not available" banner and
    /// keeps the Continue button disabled.
    public func allDaysUnavailable() -> Bool {
        guard !planData.availableDays.isEmpty else { return false }
        return planData.availableDays.allSatisfy { day in
            day.isPastDay() || isDayUnavailable(day)
        }
    }

    /// Fetch available time slots for the entire trip range in a single call.
    /// `tour.slots` from search-response already covers this when available; otherwise
    /// the schedule API is hit once with `date=trip start`, `to=trip end` and the
    /// per-day buckets are inserted into `allTimeSlots` / `flexibleDays`. Subsequent
    /// day picker switches use the cached state — no further network requests.
    public func fetchTimeSlots() {
        guard !planData.availableDays.isEmpty else {
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorNoDateSelected))
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
        delegate?.viewModel(showLottie: .inView, textMode: .single(loadingText))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let sortedDays = planData.availableDays.sorted()
        let fromDate = formatter.string(from: sortedDays.first ?? selectedDate ?? Date())
        let toDate = formatter.string(from: sortedDays.last ?? selectedDate ?? Date())

        let currency = TRPClient.getCurrency()
        let lang = TRPClient.getLanguage()

        tourRepository.getTourSchedule(
            productId: tour.id,
            date: fromDate,
            to: toDate,
            currency: currency,
            lang: lang
        ) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(hideLottie: .inView)

                switch result {
                case .success(let schedule):
                    self.applyScheduleResponse(schedule)
                    self.delegate?.timeSlotsDidLoad()

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Bucket the range-aware schedule response into the per-day cache. Mirrors
    /// `prefillCacheFromPreloadedSlots`: maps "yyyy-MM-dd" strings to the canonical
    /// `availableDays` Date instances so dictionary keys match what the rest of the
    /// VM uses, then splits each day's slots into timed (`allTimeSlots`) vs. flexible
    /// markers (`flexibleDays`). Trip-range outliers (any unexpected dates the
    /// server returned) are dropped silently.
    private func applyScheduleResponse(_ schedule: TRPTourSchedule) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var dateByString: [String: Date] = [:]
        for day in planData.availableDays {
            dateByString[formatter.string(from: day)] = day
        }

        // Pre-fill empty buckets so subsequent day switches treat each trip day as
        // "loaded" (no fetch retry needed).
        for day in planData.availableDays where allTimeSlots[day] == nil {
            allTimeSlots[day] = []
        }

        for scheduleDay in schedule.dates {
            guard let canonicalDay = dateByString[scheduleDay.date] else { continue }
            var timed: [TRPTourScheduleSlot] = []
            var hasFlexible = false
            for slot in scheduleDay.slots {
                if slot.time != nil {
                    timed.append(slot)
                } else {
                    hasFlexible = true
                }
            }
            allTimeSlots[canonicalDay] = (allTimeSlots[canonicalDay] ?? []) + timed
            if hasFlexible {
                flexibleDays.insert(canonicalDay)
            }
        }

        // If the user landed on a day that has no availability after the fetch, jump
        // to the first available day so the screen is in a usable state — the day
        // filter renders the empty days disabled and the user can still see them but
        // not pick them.
        if let current = selectedDate, isDayUnavailable(current) {
            if let firstAvailable = planData.availableDays.first(where: { !isDayUnavailable($0) }) {
                selectedDate = firstAvailable
                selectedTimeSlot = nil
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
        // Timed slots → `allTimeSlots`; nil-time entries → `flexibleDays` marker.
        for slot in slots {
            guard let canonicalDay = dateByString[slot.date] else { continue }
            if slot.time != nil {
                allTimeSlots[canonicalDay]?.append(TRPTourScheduleSlot(time: slot.time, price: slot.price))
            } else {
                flexibleDays.insert(canonicalDay)
            }
        }

        // Auto-shift the initial selection to the first day with availability if the
        // pre-selected day turned out empty — keeps the screen in a usable state.
        if let current = selectedDate, isDayUnavailable(current) {
            if let firstAvailable = planData.availableDays.first(where: { !isDayUnavailable($0) }) {
                selectedDate = firstAvailable
            }
        }
    }

    /// Create reserved activity segment
    public func createReservedActivitySegment() {
        // 1. Validate required data
        guard let tripHash = planData.tripHash else {
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorTimelineNotFound))
            return
        }

        guard let tourCoordinate = tour.coordinate else {
            delegate?.viewModel(error: makeLocalizedError(code: -2, key: AddPlanLocalizationKeys.errorActivityLocationNotAvailable))
            return
        }

        guard let selectedDate = selectedDate else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorSelectDate))
            return
        }

        let isFlexible = isSelectedDayFlexible()
        // Flexible day → no slot selection required; otherwise enforce slot pick.
        guard isFlexible || selectedTimeSlot != nil else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorSelectTimeSlot))
            return
        }

        // 2. Calculate start and end times — `calculateSegmentTimes` handles the
        //    flexible case internally (start = end = 00:00 on selectedDate).
        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // 3. Create TRPSegmentActivityItem (additionalData)
        // Duration: flexible activities are encoded with the sentinel `-1` so the
        // timeline read flow can identify them later without needing a separate
        // field. Timed activities use the tour's natural duration.
        let durationValue: Double?
        if isFlexible {
            durationValue = -1
        } else {
            durationValue = tour.duration != nil ? Double(tour.duration!) : nil
        }

        // Get price with currency - prefer slot price over tour price
        var activityPrice: TRPSegmentActivityPrice? = nil
        if let slotPrice = selectedTimeSlot?.price, slotPrice > 0 {
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
            price: activityPrice,
            isFlexible: isFlexible ? true : nil,
            rating: tour.rating,
            ratingCount: tour.ratingCount
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

        // 5. Show in-view Lottie loader (TimeSelectionVC is itself a bottom sheet —
        //    we embed inside it rather than stacking another sheet on top).
        let loadingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.addingToItinerary)
        delegate?.viewModel(showLottie: .inView, textMode: .single(loadingText))

        // 6. Create segment via repository — keep the loader on through both the
        //    creation API and the timeline-regeneration polling that follows on
        //    success, so the user sees a single continuous "Adding…" state.
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.waitForTimelineRefreshAfterCreation(tripHash: tripHash)
                    } else {
                        self.delegate?.viewModel(hideLottie: .inView)
                        let error = self.makeLocalizedError(code: -4, key: AddPlanLocalizationKeys.errorCreateReservationFailed)
                        self.delegate?.viewModel(error: error)
                    }

                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .inView)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Poll for segment generation completion after a successful create. Loader
    /// stays visible throughout. On completion this method emits the shared
    /// refresh state so any subscribed screen (notably `TRPTimelineItineraryVC`)
    /// can sync its data, then hides the loader and signals success.
    private func waitForTimelineRefreshAfterCreation(tripHash: String) {
        TRPTimelineRefreshState.shared.setRefreshing()

        let timelineRepository = TRPTimelineRepository()
        let modelRepository = TRPTimelineModelRepository()
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: timelineRepository,
            timelineModelRepository: modelRepository
        )

        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self, isGenerated else { return }
            DispatchQueue.main.async {
                TRPTimelineRefreshState.shared.setCompleted()
                self.checkAllPlanUseCase = nil
                self.delegate?.viewModel(hideLottie: .inView)
                self.delegate?.segmentCreationDidSucceed()
            }
        }

        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    TRPTimelineRefreshState.shared.setFailed(error)
                    self.checkAllPlanUseCase = nil
                    self.delegate?.viewModel(hideLottie: .inView)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Update existing reserved activity segment (edit mode)
    public func updateReservedActivitySegment() {
        // 1. Validate required data
        guard let tripHash = planData.tripHash else {
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorTimelineNotFound))
            return
        }

        guard let segmentIndex = planData.segmentIndex,
              let segment = segment else {
            delegate?.viewModel(error: makeLocalizedError(code: -2, key: AddPlanLocalizationKeys.errorSegmentNotFound))
            return
        }

        guard let selectedDate = selectedDate else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorSelectDate))
            return
        }

        let isFlexible = isSelectedDayFlexible()
        guard isFlexible || selectedTimeSlot != nil else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorSelectTimeSlot))
            return
        }

        // 2. Calculate new times — flexible day yields 00:00/00:00 internally.
        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // 3. Update additionalData times + flexible flag
        var updatedAdditionalData = segment.additionalData
        updatedAdditionalData?.startDatetime = startDatetimeString
        updatedAdditionalData?.endDatetime = endDatetimeString
        updatedAdditionalData?.isFlexible = isFlexible ? true : nil

        // 4. Create edit profile from existing segment
        let profile = TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: tripHash, segmentIndex: segmentIndex)
        profile.startDate = startDateString
        profile.endDate = endDateString
        profile.additionalData = updatedAdditionalData

        // 5. Show loading inline (sheet is already presenting — embed the loader in view)
        delegate?.viewModel(showLottie: .inView, textMode: .defaultRotating)

        // 6. Update segment via repository
        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(hideLottie: .inView)

                switch result {
                case .success(let success):
                    if success {
                        self.delegate?.segmentUpdateDidSucceed()
                    } else {
                        let error = self.makeLocalizedError(code: -4, key: AddPlanLocalizationKeys.errorUpdateTimeFailed)
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
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorStepNotFound))
            return
        }

        guard let selectedTimeSlot = selectedTimeSlot,
              let timeString = selectedTimeSlot.time else {
            // Step edit mode requires a specific time — flexible-time entries are not
            // editable here; the user must pick a concrete slot.
            delegate?.viewModel(error: makeLocalizedError(code: -2, key: AddPlanLocalizationKeys.errorSelectTimeSlot))
            return
        }

        // Get start time from time slot (format: "HH:mm" or "HH:mm:ss")
        // Extract just the "HH:mm" part
        let startTimeComponents = timeString.split(separator: ":")
        guard startTimeComponents.count >= 2 else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorInvalidTimeFormat))
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

        // Show loading inline (sheet is already presenting — embed the loader in view)
        delegate?.viewModel(showLottie: .inView, textMode: .defaultRotating)

        // Update step via repository
        let repository = TRPTimelineStepRepository()
        repository.editStep(step: stepEdit) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(hideLottie: .inView)

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

    private func makeLocalizedError(code: Int, key: String) -> NSError {
        let message = AddPlanLocalizationKeys.localized(key)
        return NSError(domain: "AddPlanTimeSelection", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func calculateSegmentTimes(
        selectedDate: Date,
        selectedTimeSlot: TimeSlot?
    ) -> (startDateString: String, endDateString: String, startDatetimeString: String, endDatetimeString: String) {

        // Flexible-time path: no slot selected (or slot has nil time) AND the selected
        // day is flexible. Both start and end pinned to 00:00 — duration is intentionally
        // not added so the segment lands at the top of the day's itinerary.
        if (selectedTimeSlot?.time == nil) && isSelectedDayFlexible() {
            return formatDatesForFlexibleSegment(selectedDate)
        }

        // Parse time slot (format: "HH:mm" or "HH:mm:ss")
        guard let timeString = selectedTimeSlot?.time else {
            // Defensive: shouldn't reach here unless a non-flexible day somehow lacks
            // a time. Fall back to noon to preserve existing safety net.
            return calculateTimesWithDefaults(selectedDate: selectedDate, hour: 12, minute: 0)
        }
        let timeComponents = timeString.split(separator: ":")
        guard timeComponents.count >= 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return calculateTimesWithDefaults(selectedDate: selectedDate, hour: 12, minute: 0)
        }

        return calculateTimesWithDefaults(selectedDate: selectedDate, hour: hour, minute: minute)
    }

    /// Build segment date strings used for flexible-time activities. Both start and
    /// end land on the same instant. Normally that's 00:00 (top of itinerary), but
    /// when the user is creating a flexible activity for **today** the server would
    /// reject 00:00 as a past timestamp — so anchor to 23:59 instead, keeping the
    /// segment in the future while still occupying a single conceptual moment.
    private func formatDatesForFlexibleSegment(_ selectedDate: Date) -> (String, String, String, String) {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = isToday ? 23 : 0
        components.minute = isToday ? 59 : 0
        components.second = 0
        let anchor = Calendar.current.date(from: components) ?? selectedDate
        return formatDates(start: anchor, end: anchor)
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
