//
//  AddPlanContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol AddPlanContainerViewModelDelegate: AnyObject {
    func stepChanged()
    func planCompleted(data: AddPlanData)
}

public class AddPlanContainerViewModel {

    // MARK: - Properties
    public weak var delegate: AddPlanContainerViewModelDelegate?
    private var currentStep: AddPlanSteps = .selectDayAndCity
    public var planData = AddPlanData()

    private let availableDays: [Date]
    private let availableCities: [TRPCity]
    private let selectedDayIndex: Int
    private let bookedActivities: [TRPTimelineSegment]
    private let destinationItems: [TRPSegmentDestinationItem]
    private let favouriteItems: [TRPSegmentFavoriteItem]
    /// Party size the flow starts with and falls back to when the travelers step is cleared.
    public let defaultTravelers: Int

    // MARK: - Initialization
    public init(days: [Date], cities: [TRPCity], selectedDayIndex: Int, bookedActivities: [TRPTimelineSegment] = [], destinationItems: [TRPSegmentDestinationItem] = [], favouriteItems: [TRPSegmentFavoriteItem] = [], defaultTravelers: Int = 1) {
        self.availableDays = days
        self.availableCities = cities
        self.selectedDayIndex = selectedDayIndex
        self.bookedActivities = bookedActivities
        self.destinationItems = destinationItems
        self.favouriteItems = favouriteItems
        self.defaultTravelers = max(defaultTravelers, 1)
        self.planData.travelers = self.defaultTravelers

        if days.indices.contains(selectedDayIndex) {
            self.planData.selectedDay = AddPlanDaySelection.initialDay(in: days, preferredIndex: selectedDayIndex)
        }
        self.planData.selectedCity = cities.first
        self.planData.availableDays = days
    }
    
    // MARK: - Public Methods
    public func start() {
        currentStep = .selectDayAndCity
        delegate?.stepChanged()
    }
    
    public func goNextStep() {
        if let nextStep = currentStep.getNextStep() {
            currentStep = nextStep
            delegate?.stepChanged()
        } else {
            delegate?.planCompleted(data: planData)
        }
    }
    
    public func backStepAction() {
        if let previousStep = currentStep.getPreviousStep() {
            currentStep = previousStep
            delegate?.stepChanged()
        }
    }
    
    public func getCurrentStep() -> AddPlanSteps {
        return currentStep
    }
    
    public func getButtonTitle() -> String {
        return TRPLanguagesController.shared.getContinueBtnText()
    }
    
    public func getAvailableDays() -> [Date] {
        return availableDays
    }
    
    public func getAvailableCities() -> [TRPCity] {
        return availableCities
    }
    
    public func getSelectedDayIndex() -> Int {
        return selectedDayIndex
    }

    /// Index of the selected day in the available days, or nil when no plannable day is selected.
    public func getSelectedAvailableDayIndex() -> Int? {
        guard let selectedDay = planData.selectedDay, !selectedDay.isPastDay() else { return nil }
        return availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) })
    }

    /// Selects `day` unless it is a past day; past days are never selectable in AddPlan.
    public func selectDay(_ day: Date) {
        guard !day.isPastDay() else { return }
        planData.selectedDay = day
    }

    /// Resets the selected day to today, else the first future day, else nil when every day is past.
    public func resetSelectedDay() {
        planData.selectedDay = AddPlanDaySelection.firstSelectableDay(in: availableDays)
    }

    /// Whether the select-day step allows continuing: a non-past day, a city and a complete mode choice.
    public var canContinueFromSelectDay: Bool {
        guard let selectedDay = planData.selectedDay, !selectedDay.isPastDay(),
              planData.selectedCity != nil else {
            return false
        }
        switch planData.selectedMode {
        case .smartRecommendations:
            return true
        case .manual:
            return !planData.selectedCategories.isEmpty
        case .none:
            return false
        }
    }

    public func getBookedActivities() -> [TRPTimelineSegment] {
        return bookedActivities
    }

    public func getFavouriteItems() -> [TRPSegmentFavoriteItem] {
        return favouriteItems
    }

    // MARK: - Date-City Mapping

    /// Returns (mapped: cities mapped to this date, other: remaining cities).
    public func getCitiesForDate(_ date: Date) -> (mapped: [TRPCity], other: [TRPCity]) {
        guard !destinationItems.isEmpty else {
            return (mapped: [], other: availableCities)
        }

        let dateString = TRPDateHelper.formatDateString(date)

        var mappedCityIds = Set<Int>()
        for item in destinationItems {
            guard let dates = item.dates, dates.contains(dateString) else { continue }

            if let cityId = item.cityId, cityId > 0 {
                mappedCityIds.insert(cityId)
                continue
            }

            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                mappedCityIds.insert(city.id)
            }
        }

        guard !mappedCityIds.isEmpty else {
            return (mapped: [], other: availableCities)
        }

        var mapped: [TRPCity] = []
        var other: [TRPCity] = []
        for city in availableCities {
            if mappedCityIds.contains(city.id) {
                mapped.append(city)
            } else {
                other.append(city)
            }
        }

        return (mapped: mapped, other: other)
    }

    private func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
    }

    public func hasDateCityMapping() -> Bool {
        return destinationItems.contains { $0.dates != nil && !($0.dates?.isEmpty ?? true) }
    }
}
