//
//  AddPlanContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol AddPlanContainerViewModelDelegate: AnyObject {
    func stepChanged()
    func planCompleted(data: AddPlanData)
}

public struct AddPlanData {
    public var selectedDay: Date?
    public var selectedCity: TRPCity?
    public var selectedMode: AddPlanMode = .none
    public var startingPointLocation: TRPLocation? // Latitude/longitude coordinates
    public var startingPointName: String? // Display name for the starting point
    public var startTime: Date?
    public var endTime: Date?
    public var travelers: Int = 0
    public var selectedCategories: [String] = []
    public var tripHash: String? // Timeline trip hash for segment creation
    public var availableDays: [Date] = [] // Available days from timeline/itinerary
}

public enum AddPlanMode {
    case none
    case smartRecommendations
    case manual
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

    // MARK: - Initialization
    public init(days: [Date], cities: [TRPCity], selectedDayIndex: Int, bookedActivities: [TRPTimelineSegment] = [], destinationItems: [TRPSegmentDestinationItem] = [], favouriteItems: [TRPSegmentFavoriteItem] = []) {
        self.availableDays = days
        self.availableCities = cities
        self.selectedDayIndex = selectedDayIndex
        self.bookedActivities = bookedActivities
        self.destinationItems = destinationItems
        self.favouriteItems = favouriteItems

        // Pre-select day and city
        if selectedDayIndex < days.count {
            self.planData.selectedDay = days[selectedDayIndex]
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
            // Last step completed
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
        if currentStep.getNextStep() == nil {
            return "Continuar" // Last step
        }
        return "Continuar"
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

    public func getBookedActivities() -> [TRPTimelineSegment] {
        return bookedActivities
    }

    public func getFavouriteItems() -> [TRPSegmentFavoriteItem] {
        return favouriteItems
    }

    // MARK: - Date-City Mapping

    /// Get cities filtered by date for AddPlan
    /// - Parameter date: The selected date
    /// - Returns: Tuple with (mapped: cities mapped to this date, other: remaining cities)
    public func getCitiesForDate(_ date: Date) -> (mapped: [TRPCity], other: [TRPCity]) {
        // If no destination items, return all as other
        guard !destinationItems.isEmpty else {
            return (mapped: [], other: availableCities)
        }

        // Format date for comparison
        let dateString = date.toString(format: "yyyy-MM-dd")

        // Find city IDs mapped to this date (by cityId or coordinate)
        var mappedCityIds = Set<Int>()
        for item in destinationItems {
            guard let dates = item.dates, dates.contains(dateString) else { continue }

            // Try cityId first
            if let cityId = item.cityId, cityId > 0 {
                mappedCityIds.insert(cityId)
                continue
            }

            // Fallback: Find city by coordinate
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate) {
                mappedCityIds.insert(city.id)
            }
        }

        // No mapping for this date → return all as other
        guard !mappedCityIds.isEmpty else {
            return (mapped: [], other: availableCities)
        }

        // Split cities into mapped and other
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

    /// Parse coordinate string (e.g., "41.3851,2.1734") to TRPLocation
    private func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
    }

    /// Check if any destination items have date mappings
    /// - Returns: True if at least one destination has dates property set
    public func hasDateCityMapping() -> Bool {
        return destinationItems.contains { $0.dates != nil && !($0.dates?.isEmpty ?? true) }
    }
}
