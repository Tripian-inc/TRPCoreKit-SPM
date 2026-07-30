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

/// UI-level slot model wrapping the schedule slot to carry an `isDisabled` placeholder for a previously-saved time no longer in the response.
public struct DisplayTimeSlot: Equatable {
    public let time: String
    public let price: Double?
    public let isDisabled: Bool

    public init(time: String, price: Double?, isDisabled: Bool) {
        self.time = time
        self.price = price
        self.isDisabled = isDisabled
    }
}

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

    private var allTimeSlots: [Date: [TimeSlot]] = [:]
    /// Days where the activity is flexible (valid any time). A mixed day with any timed slot is NOT flexible — timed grid wins.
    private var flexibleDays: Set<Date> = []
    private var selectedDate: Date?
    private var selectedTimeSlot: TimeSlot?
    private var hasPreloadedSlots: Bool = false

    private let collapsedSlotThreshold: Int = 8
    private let collapsedSlotCount: Int = 7

    private(set) public var isTimeSlotsExpanded: Bool = false

    /// Held strongly so it isn't deallocated mid-poll; cleared once the cycle finishes.
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    private var segment: TRPTimelineSegment?
    private var step: TRPTimelineStep?
    public var isEditMode: Bool { segment != nil || step != nil }
    public var isStepEditMode: Bool { step != nil }

    /// "HH:mm" of the activity being edited; when absent from the schedule response the grid injects a disabled placeholder.
    private var editingTimeString: String?

    /// "yyyy-MM-dd" days already holding this activity. Add flow only — edit modes pass none so the
    /// activity's own day stays selectable.
    private let alreadyAddedDays: Set<String>

    // MARK: - Initialization
    public init(tour: TRPTourProduct,
                planData: AddPlanData,
                alreadyAddedDays: Set<String> = [],
                tourRepository: TourRepository = TRPTourRepository()) {
        self.tour = tour
        self.planData = planData
        self.alreadyAddedDays = alreadyAddedDays
        self.tourRepository = tourRepository
        self.selectedDate = planData.selectedDay

        // Empty preloaded slots mean the search field was present but empty — fall back to per-day schedule instead of locking into an empty state.
        if let preloaded = tour.slots, !preloaded.isEmpty {
            prefillCacheFromPreloadedSlots(preloaded)
            hasPreloadedSlots = true
        }
    }

    /// Edit mode initializer - creates TRPTourProduct from segment's additionalData
    public init(segment: TRPTimelineSegment, planData: AddPlanData, tourRepository: TourRepository = TRPTourRepository()) {
        self.segment = segment
        self.planData = planData
        self.alreadyAddedDays = []
        self.tourRepository = tourRepository
        // Seed selectedDate from the segment's own saved date (timezone-robust).
        let savedYMD = TRPDateHelper.extractDateOnly(from: segment.startDate)
        self.selectedDate = TRPDateHelper.matchDay(ymd: savedYMD, in: planData.availableDays)
            ?? planData.selectedDay
        self.editingTimeString = TRPDateHelper.extractHourMinute(from: segment.startDate)

        guard let additionalData = segment.additionalData else {
            fatalError("Reserved activity segment must have additionalData")
        }

        // Non-"C_" activityId is formatted as "C_{activityId}_15_{cityId}".
        let activityId = additionalData.activityId ?? ""
        let cityId = segment.city?.id ?? planData.selectedCity?.id ?? 0
        let formattedProductId: String
        if activityId.hasPrefix("C_") {
            formattedProductId = activityId
        } else {
            formattedProductId = "C_\(activityId)_15_\(cityId)"
        }

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
            price: additionalData.price?.value,
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
        self.alreadyAddedDays = []
        self.tourRepository = tourRepository
        // Seed selectedDate from the step's own saved date (timezone-robust).
        let savedYMD = TRPDateHelper.extractDateOnly(from: step.startDateTimes)
        self.selectedDate = TRPDateHelper.matchDay(ymd: savedYMD, in: planData.availableDays)
            ?? planData.selectedDay
        self.editingTimeString = TRPDateHelper.extractHourMinute(from: step.startDateTimes)

        guard let poi = step.poi else {
            fatalError("Activity step must have POI")
        }

        let productId: String
        if let additionalProductId = poi.additionalData?.productId {
            productId = additionalProductId
        } else if let bookingProduct = poi.bookings?.first?.firstProduct() {
            productId = bookingProduct.id
        } else {
            productId = poi.id
        }

        // Non-"C_" productId is formatted as "C_{productId}_15_{cityId}".
        let cityId = planData.selectedCity?.id ?? poi.cityId
        let formattedProductId: String
        if productId.hasPrefix("C_") {
            formattedProductId = productId
        } else {
            formattedProductId = "C_\(productId)_15_\(cityId)"
        }

        self.tour = TRPTourProduct(
            id: formattedProductId,
            productId: formattedProductId,
            cityId: cityId,
            name: poi.name,
            image: poi.image,
            gallery: poi.gallery,
            duration: poi.duration,
            // `poi.price` is a dollar-sign tier (1-4), not money — real price lives in `additionalData.price`.
            price: poi.additionalData?.price,
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

    public func getAvailableDays() -> [Date] {
        return planData.availableDays
    }

    public func getSelectedDayIndex() -> Int {
        guard let selectedDate = selectedDate else { return 0 }
        let days = getAvailableDays()
        return days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDate) }) ?? 0
    }

    public func getSelectedDate() -> Date? {
        return selectedDate
    }

    /// Schedule cache is populated up-front for the whole trip range, so day switches are instant (no per-day fetch).
    public func selectDay(at index: Int) {
        let days = getAvailableDays()
        guard index < days.count else { return }
        let newDate = days[index]

        if selectedDate != newDate {
            selectedDate = newDate
            selectedTimeSlot = nil
            isTimeSlotsExpanded = false
            delegate?.timeSlotsDidLoad()
        }
    }

    /// Service slots for the selected day, deduplicated by time. No device-clock filtering — see `timedSlots(for:)`.
    public func getTimeSlots() -> [TimeSlot] {
        guard let selectedDate = selectedDate else { return [] }
        let slots = timedSlots(for: selectedDate)
        return deduplicateSlotsByTime(slots)
    }

    /// Merged display list: schedule slots plus, in edit mode on the activity's own day, a disabled placeholder for a missing editing time.
    private func getAllDisplayTimeSlots() -> [DisplayTimeSlot] {
        let baseSlots = getTimeSlots()
        let base = baseSlots.map {
            DisplayTimeSlot(time: $0.time ?? "", price: $0.price, isDisabled: false)
        }

        guard isEditMode,
              let editingTime = editingTimeString,
              let originalDay = planData.selectedDay,
              let currentDay = selectedDate,
              Calendar.current.isDate(currentDay, inSameDayAs: originalDay),
              !base.contains(where: { $0.time == editingTime })
        else {
            return base
        }

        var merged = base
        merged.append(DisplayTimeSlot(time: editingTime, price: nil, isDisabled: true))
        // "HH:mm" sorts lexicographically == chronologically.
        merged.sort { $0.time < $1.time }
        return merged
    }

    /// Slots shown right now, honouring collapsed/expanded state.
    public func getDisplayedTimeSlots() -> [DisplayTimeSlot] {
        let all = getAllDisplayTimeSlots()
        guard !isTimeSlotsExpanded, all.count > collapsedSlotThreshold else { return all }
        return Array(all.prefix(collapsedSlotCount))
    }

    /// Drives whether the "Show more" link is visible.
    public func hasMoreTimeSlotsToShow() -> Bool {
        return !isTimeSlotsExpanded && getAllDisplayTimeSlots().count > collapsedSlotThreshold
    }

    /// True when the saved editing time is missing from the schedule (sold out / past) — drives the sold-out warning banner.
    public var shouldShowSoldOutWarning: Bool {
        return getAllDisplayTimeSlots().contains { $0.isDisabled }
    }

    public func expandTimeSlots() {
        guard !isTimeSlotsExpanded else { return }
        isTimeSlotsExpanded = true
    }

    /// Availability is service-driven, never device-clock driven — we don't drop slots by comparing against the current time.
    private func timedSlots(for date: Date) -> [TimeSlot] {
        return allTimeSlots[date] ?? []
    }

    /// Dedup by time, keeping lowest price. Flexible (nil-time) slots are skipped — they live in `flexibleDays`.
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

        return slotsByTime.values.sorted { slot1, slot2 in
            (slot1.time ?? "") < (slot2.time ?? "")
        }
    }

    /// No-op for disabled placeholder slots — defense against paths bypassing `shouldSelectItemAt`.
    public func selectTimeSlot(_ displaySlot: DisplayTimeSlot) {
        guard !displaySlot.isDisabled else { return }
        selectedTimeSlot = TimeSlot(time: displaySlot.time, price: displaySlot.price)
    }

    public func getSelectedTimeSlot() -> TimeSlot? {
        return selectedTimeSlot
    }

    /// Mixed-day rule: a day with any timed slot is NOT flexible.
    public func isSelectedDayFlexible() -> Bool {
        guard let selectedDate = selectedDate else { return false }
        let hasTimedSlot = !(allTimeSlots[selectedDate] ?? []).isEmpty
        return !hasTimedSlot && flexibleDays.contains(selectedDate)
    }

    /// Flexible days don't need a slot selection.
    public func canContinue() -> Bool {
        guard selectedDate != nil else { return false }
        return selectedTimeSlot != nil || isSelectedDayFlexible()
    }

    /// Day can't be picked: the service returned nothing for it, or the activity is already on it.
    /// Never driven by the device clock.
    public func isDayUnavailable(_ date: Date) -> Bool {
        if isDayAlreadyAdded(date) { return true }
        let hasTimedSlot = !timedSlots(for: date).isEmpty
        let isFlexible = flexibleDays.contains(date)
        return !hasTimedSlot && !isFlexible
    }

    private func isDayAlreadyAdded(_ date: Date) -> Bool {
        return alreadyAddedDays.contains(TRPDateHelper.formatDateString(date))
    }

    /// Copy for the "no day can take this" banner — distinguishes sold out from already planned.
    public func unavailableBannerText() -> String {
        let allAlreadyAdded = !alreadyAddedDays.isEmpty
            && !planData.availableDays.isEmpty
            && planData.availableDays.allSatisfy { isDayAlreadyAdded($0) }

        let key = allAlreadyAdded
            ? AddPlanLocalizationKeys.activityAlreadyAddedEveryDay
            : AddPlanLocalizationKeys.activityNotAvailableForTrip
        return AddPlanLocalizationKeys.localized(key)
    }

    /// Indices the day filter renders as disabled (same UX as past dates).
    public func unavailableDayIndices() -> Set<Int> {
        var result: Set<Int> = []
        for (index, day) in planData.availableDays.enumerated() where isDayUnavailable(day) {
            result.insert(index)
        }
        return result
    }

    /// True when no day of the trip has availability (every day is fully past or empty). `isPastDay()` is day-granular, not a time-of-day check.
    public func allDaysUnavailable() -> Bool {
        guard !planData.availableDays.isEmpty else { return false }
        return planData.availableDays.allSatisfy { day in
            day.isPastDay() || isDayUnavailable(day)
        }
    }

    /// Fetch slots for the whole trip range in a single call (or skip when `tour.slots` already covers it). Day switches use the cache.
    public func fetchTimeSlots() {
        guard !planData.availableDays.isEmpty else {
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorNoDateSelected))
            return
        }

        if hasPreloadedSlots {
            DispatchQueue.main.async { [weak self] in
                self?.applyEditingTimeSlotIfNeeded()
                self?.delegate?.timeSlotsDidLoad()
            }
            return
        }

        // Embed the loader inline — TimeSelectionVC is already a sheet, so we don't stack a second one.
        let loadingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.loadingTimeSlots)
        delegate?.viewModel(showLottie: .inView, textMode: .single(loadingText))

        let sortedDays = planData.availableDays.sorted()
        let fromDate = TRPDateHelper.formatDateString(sortedDays.first ?? selectedDate ?? Date())
        let toDate = TRPDateHelper.formatDateString(sortedDays.last ?? selectedDate ?? Date())

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
                    self.applyEditingTimeSlotIfNeeded()
                    self.delegate?.timeSlotsDidLoad()

                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Bucket the schedule response into the per-day cache (timed → `allTimeSlots`, flexible → `flexibleDays`), dropping trip-range outliers.
    private func applyScheduleResponse(_ schedule: TRPTourSchedule) {
        var dateByString: [String: Date] = [:]
        for day in planData.availableDays {
            dateByString[TRPDateHelper.formatDateString(day)] = day
        }

        // Pre-fill empty buckets so day switches treat each trip day as loaded.
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

        // Add flow only: jump to the first available day. Edit mode keeps the activity's own day so its saved time can show as a sold-out placeholder.
        if !isEditMode, let current = selectedDate, isDayUnavailable(current) {
            if let firstAvailable = planData.availableDays.first(where: { !isDayUnavailable($0) }) {
                selectedDate = firstAvailable
                selectedTimeSlot = nil
            }
        }
    }

    /// Bucket preloaded search-response slots into the per-day cache, keyed on canonical `availableDays` Date instances.
    private func prefillCacheFromPreloadedSlots(_ slots: [TRPTourSlot]) {
        var dateByString: [String: Date] = [:]
        for day in planData.availableDays {
            dateByString[TRPDateHelper.formatDateString(day)] = day
        }

        // Pre-create empty buckets so a cache miss never triggers a fetch.
        for day in planData.availableDays where allTimeSlots[day] == nil {
            allTimeSlots[day] = []
        }

        for slot in slots {
            guard let canonicalDay = dateByString[slot.date] else { continue }
            if slot.time != nil {
                allTimeSlots[canonicalDay]?.append(TRPTourScheduleSlot(time: slot.time, price: slot.price))
            } else {
                flexibleDays.insert(canonicalDay)
            }
        }

        // Add flow only: auto-shift to the first available day (see `applyScheduleResponse`).
        if !isEditMode, let current = selectedDate, isDayUnavailable(current) {
            if let firstAvailable = planData.availableDays.first(where: { !isDayUnavailable($0) }) {
                selectedDate = firstAvailable
            }
        }
    }

    public func createReservedActivitySegment() {
        guard let tripHash = planData.tripHash else {
            delegate?.viewModel(error: makeLocalizedError(code: -1, key: AddPlanLocalizationKeys.errorTimelineNotFound))
            return
        }

        // Prefer the tour coordinate; fall back to the city's `resolvedCoordinate()` (re-fetched from cache) and flag `isNoLocation`.
        let resolvedCoordinate: TRPLocation
        let isNoLocationActivity: Bool
        if let tourCoordinate = tour.coordinate, !tourCoordinate.isMissingOrZero {
            resolvedCoordinate = tourCoordinate
            isNoLocationActivity = false
        } else if let cityCoordinate = planData.selectedCity?.resolvedCoordinate() {
            resolvedCoordinate = cityCoordinate
            isNoLocationActivity = true
        } else {
            delegate?.viewModel(error: makeLocalizedError(code: -2, key: AddPlanLocalizationKeys.errorActivityLocationNotAvailable))
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

        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // Flexible activities use the sentinel duration `-1` so the read flow can identify them.
        let durationValue: Double?
        if isFlexible {
            durationValue = -1
        } else {
            durationValue = tour.duration != nil ? Double(tour.duration!) : nil
        }

        let activityPrice = resolveActivityPrice()

        let activityItem = TRPSegmentActivityItem(
            activityId: tour.productId,
            bookingId: nil,
            title: tour.name,
            imageUrl: tour.image?.url,
            description: nil,
            startDatetime: startDatetimeString,
            endDatetime: endDatetimeString,
            coordinate: resolvedCoordinate,
            cancellation: nil,
            adultCount: planData.travelers,
            childCount: 0,
            duration: durationValue,
            price: activityPrice,
            isFlexible: isFlexible ? true : nil,
            rating: tour.rating,
            ratingCount: tour.ratingCount,
            isNoLocation: isNoLocationActivity
        )

        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)
        profile.segmentType = .reservedActivity
        profile.available = false
        profile.distinctPlan = true
        profile.title = tour.name
        profile.startDate = startDateString
        profile.endDate = endDateString
        profile.coordinate = resolvedCoordinate
        profile.city = planData.selectedCity
        profile.adults = planData.travelers
        profile.children = 0
        profile.pets = 0
        profile.additionalData = activityItem

        let loadingText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.addingToItinerary)
        delegate?.viewModel(showLottie: .inView, textMode: .single(loadingText))

        // Keep the loader on through both the create API and the regeneration poll for one continuous "Adding…" state.
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

    /// Poll for generation after a create; loader stays visible, then emit shared refresh state, hide loader, signal success.
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

        let (startDateString, endDateString, startDatetimeString, endDatetimeString) = calculateSegmentTimes(
            selectedDate: selectedDate,
            selectedTimeSlot: selectedTimeSlot
        )

        // Price travels with the time — a different slot can have a different price.
        var updatedAdditionalData = segment.additionalData
        updatedAdditionalData?.startDatetime = startDatetimeString
        updatedAdditionalData?.endDatetime = endDatetimeString
        updatedAdditionalData?.isFlexible = isFlexible ? true : nil
        updatedAdditionalData?.price = resolveActivityPrice()

        let profile = TRPCreateEditTimelineSegmentProfile(from: segment, tripHash: tripHash, segmentIndex: segmentIndex)
        profile.startDate = startDateString
        profile.endDate = endDateString
        profile.additionalData = updatedAdditionalData

        // Inline loader stays through the edit API and the host refresh; host dismisses the sheet (tearing down the loader) after.
        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .inView, textMode: .single(changingTimeText))

        let repository = TRPTimelineRepository()
        repository.createEditTimelineSegment(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        // Loader intentionally stays on; host dismisses the sheet after refresh.
                        self.delegate?.segmentUpdateDidSucceed()
                    } else {
                        self.delegate?.viewModel(hideLottie: .inView)
                        let error = self.makeLocalizedError(code: -4, key: AddPlanLocalizationKeys.errorUpdateTimeFailed)
                        self.delegate?.viewModel(error: error)
                    }

                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .inView)
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
            // Step edit requires a concrete time — flexible entries aren't editable here.
            delegate?.viewModel(error: makeLocalizedError(code: -2, key: AddPlanLocalizationKeys.errorSelectTimeSlot))
            return
        }

        let startTimeComponents = timeString.split(separator: ":")
        guard startTimeComponents.count >= 2 else {
            delegate?.viewModel(error: makeLocalizedError(code: -3, key: AddPlanLocalizationKeys.errorInvalidTimeFormat))
            return
        }
        let startTime = "\(startTimeComponents[0]):\(startTimeComponents[1])"

        let durationMinutes = tour.duration ?? 60
        let endTime = TRPDateHelper.addMinutes(toTime: startTime, minutes: durationMinutes) ?? "13:00"

        let stepEdit = TRPTimelineStepEdit(
            stepId: step.id,
            startTime: startTime,
            endTime: endTime
        )

        // Inline loader stays through the step-edit API and the host refresh; host dismisses the sheet after.
        let changingTimeText = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
        delegate?.viewModel(showLottie: .inView, textMode: .single(changingTimeText))

        let repository = TRPTimelineStepRepository()
        repository.editStep(step: stepEdit) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.stepUpdateDidSucceed()

                case .failure(let error):
                    self.delegate?.viewModel(hideLottie: .inView)
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    /// In edit mode, pre-select the slot matching `editingTimeString`. Disabled placeholders are excluded so Continue stays gated.
    private func applyEditingTimeSlotIfNeeded() {
        guard isEditMode,
              selectedTimeSlot == nil,
              let editingTime = editingTimeString,
              let displaySlot = getAllDisplayTimeSlots().first(where: {
                  $0.time == editingTime && !$0.isDisabled
              })
        else { return }
        selectedTimeSlot = TimeSlot(time: displaySlot.time, price: displaySlot.price)
    }

    /// Record this favourite as removed for the current timeline (persisted, per tripHash)
    /// and return its base activity id for the host-delegate callback.
    @discardableResult
    public func excludeFavouriteFromTimeline() -> String {
        let baseId = tour.productId.cleanedAsActivityId()
        if let tripHash = planData.tripHash {
            TRPFavouriteExclusionStorage.addExcludedActivityId(baseId, tripHash: tripHash)
        }
        return baseId
    }

    private func makeLocalizedError(code: Int, key: String) -> NSError {
        let message = AddPlanLocalizationKeys.localized(key)
        return NSError(domain: "AddPlanTimeSelection", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// Prefer the selected slot's price; fall back to `tour.price` (which, in edit mode,
    /// holds the segment's existing price so a slot without a price keeps it unchanged).
    private func resolveActivityPrice() -> TRPSegmentActivityPrice? {
        if let slotPrice = selectedTimeSlot?.price, slotPrice > 0 {
            return TRPSegmentActivityPrice(currency: TRPClient.getCurrency(), value: slotPrice)
        }
        if let priceValue = tour.price, priceValue > 0 {
            let currency = tour.offers.first?.currency.rawValue
                ?? tour.currency
                ?? TRPClient.getCurrency()
            return TRPSegmentActivityPrice(currency: currency, value: priceValue)
        }
        return nil
    }

    // MARK: - Segment Time Calculation

    /// Resolve the four segment date strings. Flexible days pin to a single instant; timed days add the tour duration; noon fallback otherwise.
    private func calculateSegmentTimes(
        selectedDate: Date,
        selectedTimeSlot: TimeSlot?
    ) -> (startDateString: String, endDateString: String, startDatetimeString: String, endDatetimeString: String) {

        if selectedTimeSlot?.time == nil && isSelectedDayFlexible() {
            return flexibleSegmentTimes(for: selectedDate)
        }

        guard let timeString = selectedTimeSlot?.time else {
            return timedSegmentTimes(selectedDate: selectedDate, hour: 12, minute: 0)
        }
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return timedSegmentTimes(selectedDate: selectedDate, hour: 12, minute: 0)
        }
        return timedSegmentTimes(selectedDate: selectedDate, hour: hour, minute: minute)
    }

    /// Flexible activity pins start == end to 00:00, or 23:59 when today so the server doesn't reject a past 00:00. No duration added.
    private func flexibleSegmentTimes(for selectedDate: Date) -> (String, String, String, String) {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = isToday ? 23 : 0
        components.minute = isToday ? 59 : 0
        components.second = 0
        let anchor = Calendar.current.date(from: components) ?? selectedDate
        return segmentDateStrings(start: anchor, end: anchor)
    }

    /// Timed activity starts at `hour:minute`, ends after the tour duration (default 60m). Falls back to +1h on failure.
    private func timedSegmentTimes(selectedDate: Date, hour: Int, minute: Int) -> (String, String, String, String) {
        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = hour
        startComponents.minute = minute
        startComponents.second = 0

        guard let startDate = Calendar.current.date(from: startComponents) else {
            return segmentDateStrings(start: selectedDate, end: selectedDate.addingTimeInterval(3600))
        }
        let durationMinutes = tour.duration ?? 60
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return segmentDateStrings(start: startDate, end: endDate)
    }

    /// Bundle start/end into (date, date, datetime, datetime): "yyyy-MM-dd HH:mm" plus "yyyy-MM-dd HH:mm:ss".
    private func segmentDateStrings(start: Date, end: Date) -> (String, String, String, String) {
        return (
            TRPDateHelper.formatDateTime(start),
            TRPDateHelper.formatDateTime(end),
            TRPDateHelper.formatDateTimeWithSeconds(start),
            TRPDateHelper.formatDateTimeWithSeconds(end)
        )
    }

}
