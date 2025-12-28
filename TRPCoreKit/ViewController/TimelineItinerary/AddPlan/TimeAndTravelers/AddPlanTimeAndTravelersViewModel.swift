//
//  AddPlanTimeAndTravelersViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public class AddPlanTimeAndTravelersViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    private var savedPOIs: [TRPPoi] = [] // TODO: Load from actual data source
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel
        // TODO: Initialize savedPOIs from timeline data or trip data

        // Set default starting point to city center if none is selected
        if containerViewModel.planData.startingPointLocation == nil {
            setStartingPointToCityCenter()
        }

        // Set default traveler count to 1 if not already set
        if containerViewModel.planData.travelers == 0 {
            containerViewModel.planData.travelers = 1
        }
    }
    
    // MARK: - Public Methods
    public func getSelectedDay() -> Date? {
        return containerViewModel?.planData.selectedDay
    }

    public func getStartTime() -> Date? {
        return containerViewModel?.planData.startTime
    }

    public func getEndTime() -> Date? {
        return containerViewModel?.planData.endTime
    }
    
    public func getTravelerCount() -> Int {
        let count = containerViewModel?.planData.travelers ?? 1
        return count > 0 ? count : 1
    }
    
    public func setStartTime(_ time: Date?) {
        containerViewModel?.planData.startTime = time
    }
    
    public func setEndTime(_ time: Date?) {
        containerViewModel?.planData.endTime = time
    }
    
    public func setTravelerCount(_ count: Int) {
        containerViewModel?.planData.travelers = count
    }
    
    public func incrementTravelers() {
        let current = containerViewModel?.planData.travelers ?? 1
        containerViewModel?.planData.travelers = current + 1
    }
    
    public func decrementTravelers() {
        let current = containerViewModel?.planData.travelers ?? 1
        if current > 1 {
            containerViewModel?.planData.travelers = current - 1
        }
    }
    
    public func getStartingPointLocation() -> TRPLocation? {
        return containerViewModel?.planData.startingPointLocation
    }
    
    public func getStartingPointName() -> String? {
        return containerViewModel?.planData.startingPointName
    }
    
    public func setStartingPoint(location: TRPLocation?, name: String?) {
        containerViewModel?.planData.startingPointLocation = location
        containerViewModel?.planData.startingPointName = name
    }
    
    public func getSavedPOIs() -> [TRPPoi] {
        return savedPOIs
    }
    
    public func getCityName() -> String? {
        return containerViewModel?.planData.selectedCity?.name
    }

    public func getCityCenterDisplayName() -> String? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return "\(city.name) - \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))"
    }

    public func setStartingPointToCityCenter() {
        let cityCenterLocation = createCityCenterLocation()
        let cityCenterName = getCityCenterDisplayName()
        containerViewModel?.planData.startingPointLocation = cityCenterLocation
        containerViewModel?.planData.startingPointName = cityCenterName
    }

    public func isStartingPointCityCenter() -> Bool {
        guard let currentLocation = containerViewModel?.planData.startingPointLocation else {
            return true // No starting point set, treat as city center
        }

        // Get all available cities from container
        let availableCities = containerViewModel?.getAvailableCities() ?? []

        // Check if current starting point matches any city's coordinate
        for city in availableCities {
            if areCoordinatesEqual(currentLocation, city.coordinate) {
                return true
            }
        }

        return false
    }

    private func areCoordinatesEqual(_ loc1: TRPLocation, _ loc2: TRPLocation) -> Bool {
        // Compare with small tolerance for floating point precision
        let tolerance = 0.0001
        return abs(loc1.lat - loc2.lat) < tolerance && abs(loc1.lon - loc2.lon) < tolerance
    }

    public func clearSelection() {
        // Reset to city center instead of nil
        setStartingPointToCityCenter()
        containerViewModel?.planData.startTime = nil
        containerViewModel?.planData.endTime = nil
        containerViewModel?.planData.travelers = 1
    }
    
    // MARK: - Private Methods
    private func createCityCenterLocation() -> TRPLocation? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return city.coordinate
    }
    
    // Keep this method for backwards compatibility if needed elsewhere
    public func getCityCenterPOI() -> TRPPoi? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        guard let location = createCityCenterLocation() else { return nil }
        
        let cityCenter = TRPPoi(
            id: "city_center_\(city.id)",
            cityId: city.id,
            name: getCityCenterDisplayName() ?? "City Center",
            image: nil,
            gallery: nil,
            duration: nil,
            price: nil,
            rating: nil,
            ratingCount: nil,
            description: nil,
            webUrl: nil,
            phone: nil,
            hours: nil,
            address: city.name,
            icon: "city_center",
            coordinate: location,
            bookings: nil,
            categories: [],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            locations: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        
        return cityCenter
    }
}
